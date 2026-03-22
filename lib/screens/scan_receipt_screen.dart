import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/ocr/receipt_spatial_parse.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/receipt_scan_permissions.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/draft_split_screen.dart';

/// Full-screen receipt capture aligned with v0 `scan-tab.tsx`: hero card, large
/// take-photo control, gallery / file, processing overlay with shimmer, then
/// editable chips → draft split or add-item form.
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
    this.onDismiss,
    this.onNavigateToDraft,
  });

  final TextEditingController? nameController;
  final TextEditingController? priceController;
  final TextEditingController? quantityController;

  final String currencyCode;
  final VoidCallback? onApplied;
  final Future<void> Function(List<ReceiptLineCandidate>)? onAddAllLines;

  final bool openDraftAfterBatchAdd;

  final VoidCallback? onDismiss;

  final VoidCallback? onNavigateToDraft;

  @override
  ConsumerState<ScanReceiptScreen> createState() =>
      _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen> {
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _ocrBusy = false;
  int? _detectedCount;

  /// Multi-line OCR: editable chips before confirm.
  List<ReceiptLineCandidate>? _reviewCandidates;

  static const Color _galleryRowBg = Color(0xFF161B22);

  bool get _showFilePicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  void _exitScan([Object? result]) {
    final d = widget.onDismiss;
    if (d != null) {
      d();
    } else {
      Navigator.of(context).pop(result);
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _detectedCount = null;
      _reviewCandidates = null;
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
          _reviewCandidates = null;
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
      _reviewCandidates = null;
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
    ReceiptOcrNativeResult structured;
    try {
      structured = await ReceiptOcrChannel.recognizeTextStructured(path).timeout(
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

    final candidates = parseReceiptLineCandidatesFromNative(
      structured,
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
      await _applySingle(l10n, candidates.first);
      return;
    }

    setState(() => _reviewCandidates = List<ReceiptLineCandidate>.from(candidates));
  }

  Future<void> _onConfirmReviewedLines(AppLocalizations l10n) async {
    final pending = _reviewCandidates;
    if (pending == null || !mounted) return;
    final handler = widget.onAddAllLines;
    if (handler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptPickLine)),
      );
      return;
    }
    await handler(pending);
    widget.onApplied?.call();
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    if (widget.openDraftAfterBatchAdd) {
      _goDraftReplace();
    } else {
      _exitScan(pending.length);
    }
  }

  Future<void> _onChipTap(AppLocalizations l10n, int index) async {
    final list = _reviewCandidates;
    if (list == null || index < 0 || index >= list.length) return;

    if (widget.onAddAllLines != null) {
      await _showEditLineDialog(l10n, index);
    } else {
      await _applySingle(l10n, list[index]);
    }
  }

  Future<void> _showEditLineDialog(AppLocalizations l10n, int index) async {
    final list = _reviewCandidates;
    if (list == null) return;
    final c = list[index];
    final cc = widget.currencyCode;
    final amtCtrl = TextEditingController(
      text: amountToInputText(c.lineTotalMajor(cc), cc),
    );
    final nameCtrl = TextEditingController(
      text: resolvedReceiptLineLabel(
        c,
        l10n.scanReceiptUnknownOcrItemName,
      ),
    );

    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.scanReceiptEditOcrLineTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.itemNameLabel),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.priceLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    final name = nameCtrl.text.trim();
    final raw = amtCtrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(raw);
    amtCtrl.dispose();
    nameCtrl.dispose();
    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPriceInvalid)),
      );
      return;
    }
    final minor = amountToMinorUnits(price, cc);
    setState(() {
      _reviewCandidates = List<ReceiptLineCandidate>.from(list);
      _reviewCandidates![index] = c.copyWith(
        label: name,
        amountMinor: minor,
      );
    });
  }

  Future<void> _applySingle(
    AppLocalizations l10n,
    ReceiptLineCandidate c,
  ) async {
    final name = widget.nameController;
    final price = widget.priceController;
    if (name != null && price != null) {
      name.text = resolvedReceiptLineLabel(
        c,
        l10n.scanReceiptUnknownOcrItemName,
      );
      price.text = amountToInputText(
        c.lineTotalMajor(widget.currencyCode),
        widget.currencyCode,
      );
      widget.quantityController?.text = '${c.quantity ?? 1}';
      widget.onApplied?.call();
      HapticFeedback.selectionClick();
      if (mounted) _exitScan(1);
      return;
    }

    final notifier = ref.read(itemsProvider.notifier);
    final participants =
        await ref.read(draftBillActiveParticipantsProvider.future);
    final allIds = participants.map((e) => e.id).toSet();
    final id = await notifier.addItem(
      resolvedReceiptLineLabel(
        c,
        l10n.scanReceiptUnknownOcrItemName,
      ),
      c.lineTotalMajor(widget.currencyCode),
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
      _exitScan(1);
    }
  }

  void _goDraftReplace() {
    final overlay = widget.onNavigateToDraft;
    if (overlay != null) {
      overlay();
      return;
    }
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
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
                          onPressed: () => _exitScan(null),
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.scanReceiptScreenTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.scanReceiptScreenSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HeroCard(
                    quickAddLabel: l10n.scanReceiptHeroQuickAdd,
                    headline: _detectedCount != null
                        ? l10n.scanReceiptHeroItemsDetected(_detectedCount!)
                        : l10n.scanReceiptHeroPointCamera,
                    colorScheme: cs,
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
                              color: Colors.black.withValues(alpha: 0.42),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _processingTitle(l10n, theme, cs),
                                      const SizedBox(height: 6),
                                      Text(
                                        l10n.scanReceiptExtractingSubtitle,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_reviewCandidates != null &&
                            _reviewCandidates!.isNotEmpty &&
                            !_ocrBusy) ...[
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    cs.surface.withValues(alpha: 0),
                                    cs.surface.withValues(alpha: 0.92),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  24,
                                  12,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.scanReceiptOcrReviewHint,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        for (var i = 0;
                                            i < _reviewCandidates!.length;
                                            i++)
                                          _OcrLineChip(
                                            index: i,
                                            candidate: _reviewCandidates![i],
                                            displayLabel:
                                                resolvedReceiptLineLabel(
                                              _reviewCandidates![i],
                                              l10n.scanReceiptUnknownOcrItemName,
                                            ),
                                            currencyCode: widget.currencyCode,
                                            colorScheme: cs,
                                            onTap: () => _onChipTap(l10n, i),
                                          ),
                                      ],
                                    ),
                                    if (widget.onAddAllLines != null) ...[
                                      const SizedBox(height: 14),
                                      FilledButton.icon(
                                        onPressed: () =>
                                            _onConfirmReviewedLines(l10n),
                                        icon: const Icon(Icons.check_rounded),
                                        label: Text(
                                          l10n.scanReceiptAddAllLines(
                                            _reviewCandidates!.length,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _ocrBusy ? null : _clearImage,
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _TakePhotoCard(
                            onTap: () => _pickCamera(l10n),
                            title: l10n.scanReceiptCamera,
                            subtitle: l10n.scanReceiptTakePhotoSubtitle,
                            colorScheme: cs,
                          ),
                          const _ReceiptScanCornerOverlay(),
                        ],
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
                                    style: theme.textTheme.titleSmall?.copyWith(
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
                        onPressed: () => _exitScan(null),
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
  }

  Widget _processingTitle(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final t = Text(
      l10n.scanReceiptExtractingTitle,
      style: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
    if (MediaQuery.disableAnimationsOf(context)) return t;
    return t
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: cs.primary.withValues(alpha: 0.45),
        );
  }
}

class _OcrLineChip extends StatelessWidget {
  const _OcrLineChip({
    required this.index,
    required this.candidate,
    required this.displayLabel,
    required this.currencyCode,
    required this.colorScheme,
    required this.onTap,
  });

  final int index;
  final ReceiptLineCandidate candidate;
  final String displayLabel;
  final String currencyCode;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final line = amountToInputText(
      candidate.lineTotalMajor(currencyCode),
      currencyCode,
    );
    final sub = candidate.quantity != null
        ? '×${candidate.quantity} · $line'
        : line;

    return InputChip(
      onPressed: onTap,
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              sub,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
      avatar: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Text('${index + 1}'),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.quickAddLabel,
    required this.headline,
    required this.colorScheme,
  });

  final String quickAddLabel;
  final String headline;
  final ColorScheme colorScheme;

  static const _gradientStart = Color(0xFF2DD4BF);
  static const _gradientEnd = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    const onGrad = Color(0xFF0F172A);
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
              color: onGrad.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.crop_free,
              color: onGrad,
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
                        color: onGrad.withValues(alpha: 0.75),
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onGrad,
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
    required this.colorScheme,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
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
              color: cs.primary.withValues(alpha: 0.65),
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
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 40,
                      color: cs.primary,
                    ),
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

/// M3-style corner brackets suggesting a camera / document frame (no full blur).
class _ReceiptScanCornerOverlay extends StatelessWidget {
  const _ReceiptScanCornerOverlay();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CornerBracketsPainter(color: cs.primary.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter({required this.color});

  final Color color;

  static const double _len = 28;
  static const double _stroke = 3;
  static const double _inset = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(_inset, _inset, size.width - 2 * _inset, size.height - 2 * _inset),
      const Radius.circular(20),
    );

    void corner(double x0, double y0, double dx, double dy) {
      canvas.drawLine(Offset(x0, y0), Offset(x0 + dx * _len, y0), paint);
      canvas.drawLine(Offset(x0, y0), Offset(x0, y0 + dy * _len), paint);
    }

    final outer = r.outerRect;
    corner(outer.left, outer.top, 1, 1);
    corner(outer.right, outer.top, -1, 1);
    corner(outer.left, outer.bottom, 1, -1);
    corner(outer.right, outer.bottom, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
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
