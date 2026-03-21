import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/receipt_scan_permissions.dart';
import 'package:splitbae/core/theme/splitbae_v0_theme.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/draft_split_screen.dart';
import 'package:splitbae/widgets/receipt_scan_flow.dart';

/// Full-screen receipt capture aligned with v0 `scan-tab.tsx`: hero card, large
/// take-photo control, gallery / file, processing overlay, then line pick or
/// add-to-draft (FAB entry).
class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({
    super.key,
    this.nameController,
    this.priceController,
    this.quantityController,
    required this.currencyCode,
    this.onApplied,
    this.onAddAllLines,
    this.openDraftAfterBatchAdd = false,
  });

  /// When set (add-item sheet flow), single-line OCR fills these and pops [1].
  final TextEditingController? nameController;
  final TextEditingController? priceController;
  final TextEditingController? quantityController;

  final String currencyCode;
  final VoidCallback? onApplied;
  final Future<void> Function(List<ReceiptLineCandidate>)? onAddAllLines;

  /// When true (FAB entry), after importing lines navigate to [DraftSplitScreen].
  final bool openDraftAfterBatchAdd;

  @override
  ConsumerState<ScanReceiptScreen> createState() =>
      _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen> {
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _ocrBusy = false;
  int? _detectedCount;

  /// Multi-line OCR: hold until user taps "Continue to Split" (v0 mock).
  List<ReceiptLineCandidate>? _pendingReviewCandidates;

  static const Color _v0Bg = Color(0xFF0D1117);
  static const Color _heroOnGradient = Color(0xFF0F172A);
  static const Color _extractingOverlay = Color(0xFF14B8A6);
  static const Color _galleryRowBg = Color(0xFF161B22);

  bool get _showFilePicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _detectedCount = null;
      _pendingReviewCandidates = null;
    });
  }

  Future<void> _pickCamera(AppLocalizations l10n) async {
    final allowed = await ensureReceiptImageSourcePermission(
      context,
      l10n,
      ImageSource.camera,
    );
    if (!allowed || !mounted) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    await _useXFile(x);
  }

  Future<void> _pickGallery(AppLocalizations l10n) async {
    final allowed = await ensureReceiptImageSourcePermission(
      context,
      l10n,
      ImageSource.gallery,
    );
    if (!allowed || !mounted) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    await _useXFile(x);
  }

  Future<void> _pickFile(AppLocalizations l10n) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.single;
    if (kIsWeb) {
      if (f.bytes != null) {
        setState(() {
          _imageBytes = f.bytes;
          _imagePath = null;
          _pendingReviewCandidates = null;
        });
        await _runOcr(l10n);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
        );
      }
      return;
    }
    final path = f.path;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
      );
      return;
    }
    final x = XFile(path);
    await _useXFile(x);
  }

  Future<void> _useXFile(XFile x) async {
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imagePath = x.path;
      _detectedCount = null;
      _pendingReviewCandidates = null;
    });
    final l10n = AppLocalizations.of(context)!;
    await _runOcr(l10n);
  }

  Future<void> _runOcr(AppLocalizations l10n) async {
    if (!ReceiptOcrChannel.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
      );
      return;
    }
    final path = _imagePath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
      );
      return;
    }

    setState(() => _ocrBusy = true);
    String rawText;
    try {
      rawText = await ReceiptOcrChannel.recognizeText(path).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException('ocr'),
      );
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanReceiptTimeout)),
        );
      }
      setState(() => _ocrBusy = false);
      return;
    } on ReceiptOcrException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanReceiptErrorDetail(e.message))),
        );
      }
      setState(() => _ocrBusy = false);
      return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanReceiptErrorGeneric)),
        );
      }
      setState(() => _ocrBusy = false);
      return;
    }

    if (!mounted) return;
    setState(() => _ocrBusy = false);

    final candidates = parseReceiptLineCandidates(
      rawText,
      currencyCode: widget.currencyCode,
    );
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptNoLines)),
      );
      return;
    }

    setState(() => _detectedCount = candidates.length);

    if (candidates.length == 1) {
      await _resolveCandidates(l10n, candidates);
      return;
    }

    setState(() => _pendingReviewCandidates = candidates);
  }

  Future<void> _onContinueToSplit(AppLocalizations l10n) async {
    final pending = _pendingReviewCandidates;
    if (pending == null || !mounted) return;
    await _resolveCandidates(l10n, pending);
  }

  Future<void> _resolveCandidates(
    AppLocalizations l10n,
    List<ReceiptLineCandidate> candidates,
  ) async {
    if (candidates.length == 1) {
      await _applySingle(l10n, candidates.first);
      return;
    }

    final pick = await showReceiptLinePickerSheet(
      context,
      l10n,
      candidates: candidates,
      currencyCode: widget.currencyCode,
      onAddAllLines: widget.onAddAllLines,
    );
    if (!mounted) return;

    if (identical(pick, receiptLinePickerAddAllMarker)) {
      final handler = widget.onAddAllLines;
      if (handler == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }
      await handler(candidates);
      widget.onApplied?.call();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (widget.openDraftAfterBatchAdd) {
        _goDraftReplace();
      } else {
        Navigator.of(context).pop(candidates.length);
      }
      return;
    }

    if (pick is ReceiptLineCandidate) {
      await _applySingle(l10n, pick);
    }
  }

  Future<void> _applySingle(
    AppLocalizations l10n,
    ReceiptLineCandidate c,
  ) async {
    final name = widget.nameController;
    final price = widget.priceController;
    if (name != null && price != null) {
      name.text = c.label;
      price.text = amountToInputText(c.amount, widget.currencyCode);
      widget.quantityController?.text = '${c.quantity ?? 1}';
      widget.onApplied?.call();
      HapticFeedback.selectionClick();
      if (mounted) Navigator.of(context).pop(1);
      return;
    }

    final notifier = ref.read(itemsProvider.notifier);
    final participants = ref.read(participantsProvider);
    final allIds = participants.map((e) => e.id).toSet();
    final id = await notifier.addItem(
      c.label,
      c.amount,
      quantity: c.quantity ?? 1,
    );
    await notifier.setLineAssignments(
      lineId: id,
      selectedParticipantIds: allIds,
    );
    HapticFeedback.selectionClick();
    if (!mounted) return;
    if (widget.openDraftAfterBatchAdd) {
      _goDraftReplace();
    } else {
      Navigator.of(context).pop(1);
    }
  }

  void _goDraftReplace() {
    Navigator.of(context).pushReplacement(
      hostPlatformIsApple()
          ? CupertinoPageRoute<void>(
              builder: (_) => const DraftSplitScreen(),
            )
          : MaterialPageRoute<void>(
              builder: (_) => const DraftSplitScreen(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPad = MediaQuery.paddingOf(context).top;

    return Theme(
      data: ThemeData(
        colorScheme: splitBaeV0DarkColorScheme(),
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _v0Bg,
      ),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: _v0Bg,
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            Material(
                              color: cs.surfaceContainerHighest,
                              shape: const CircleBorder(),
                              child: IconButton(
                                padding: const EdgeInsets.only(left: 10),
                                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                                onPressed: () => Navigator.of(context).pop(null),
                                tooltip: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.scanReceiptScreenTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.scanReceiptScreenSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _HeroCard(
                          quickAddLabel: l10n.scanReceiptHeroQuickAdd,
                          headline: _detectedCount != null
                              ? l10n.scanReceiptHeroItemsDetected(_detectedCount!)
                              : l10n.scanReceiptHeroPointCamera,
                          heroTextColor: _heroOnGradient,
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                  if (_imageBytes != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AspectRatio(
                                aspectRatio: 3 / 4,
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_ocrBusy)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: _extractingOverlay,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 44,
                                                  height: 44,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: _heroOnGradient,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: -4,
                                                  right: -4,
                                                  child: Icon(
                                                    Icons.auto_awesome,
                                                    size: 18,
                                                    color: _heroOnGradient,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              l10n.scanReceiptExtractingTitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: _heroOnGradient,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              l10n.scanReceiptExtractingSubtitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: _heroOnGradient
                                                        .withValues(alpha: 0.85),
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_pendingReviewCandidates != null && !_ocrBusy)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                  child: FilledButton(
                                    onPressed: () => _onContinueToSplit(l10n),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.primary,
                                      foregroundColor: _heroOnGradient,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l10n.scanReceiptContinueToSplit,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed:
                                        _ocrBusy ? null : _clearImage,
                                    tooltip: MaterialLocalizations.of(context)
                                        .cancelButtonLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_imageBytes == null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _TakePhotoCard(
                              onTap: () => _pickCamera(l10n),
                              title: l10n.scanReceiptCamera,
                              subtitle: l10n.scanReceiptTakePhotoSubtitle,
                              accent: cs.primary,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Material(
                                color: _galleryRowBg,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  onTap: () => _pickGallery(l10n),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          color: cs.onSurface,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.scanReceiptGallery,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: cs.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_showFilePicker) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () => _pickFile(l10n),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.onSurfaceVariant,
                                    side: BorderSide(color: cs.outline),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(l10n.scanReceiptChooseImageFile),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: Text(l10n.scanReceiptEnterManually),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: topPad > 0 ? 24 : 48),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.quickAddLabel,
    required this.headline,
    required this.heroTextColor,
  });

  final String quickAddLabel;
  final String headline;
  final Color heroTextColor;

  static const _gradientStart = Color(0xFF2DD4BF);
  static const _gradientEnd = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gradientStart,
            _gradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _gradientStart.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: heroTextColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.crop_free,
              color: heroTextColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quickAddLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: heroTextColor.withValues(alpha: 0.75),
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: heroTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TakePhotoCard extends StatelessWidget {
  const _TakePhotoCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: accent.withValues(alpha: 0.65),
              strokeWidth: 2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.photo_camera_outlined, size: 40, color: accent),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, this.strokeWidth = 2});

  final Color color;
  final double strokeWidth;

  static const double _dash = 8;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      const Radius.circular(24),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + _dash, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
