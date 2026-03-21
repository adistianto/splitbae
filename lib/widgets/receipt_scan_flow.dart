import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/platform/receipt_scan_permissions.dart';

class _ManualReceiptEntry {}

class _PickImageFile {}

/// Picks camera/gallery or (without native OCR) camera/file → native OCR on
/// Android/iOS only → optional line picker → fills controllers or batch-adds.
///
/// Returns **null** if the user cancelled or OCR failed; **1** if a single line
/// was applied to the form; **n** if [onAddAllLines] ran with **n** candidates.
Future<int?> runReceiptScanFlow({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController priceController,
  required String currencyCode,
  required void Function() onApplied,
  required AppLocalizations l10n,
  Future<void> Function(List<ReceiptLineCandidate> candidates)? onAddAllLines,
}) async {
  final nativeOcr = ReceiptOcrChannel.isSupported;

  final choice = await _showScanSourceSheet(context, l10n, nativeOcr: nativeOcr);
  if (choice == null || !context.mounted) return null;
  if (choice is _ManualReceiptEntry) return null;

  String? imagePath;

  if (choice is ImageSource) {
    final allowed = await ensureReceiptImageSourcePermission(
      context,
      l10n,
      choice,
    );
    if (!allowed || !context.mounted) return null;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: choice, imageQuality: 85);
    if (xfile == null || !context.mounted) return null;
    imagePath = xfile.path;
  } else if (choice is _PickImageFile) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty || !context.mounted) {
      return null;
    }
    final f = result.files.single;
    imagePath = f.path;
    if (imagePath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
        );
      }
      return null;
    }
  } else {
    return null;
  }

  if (!nativeOcr) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptNoNativeOcr)),
      );
    }
    return null;
  }

  final pathForOcr = imagePath;
  if (pathForOcr.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptErrorGeneric)),
      );
    }
    return null;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  String rawText;
  try {
    rawText = await ReceiptOcrChannel.recognizeText(pathForOcr).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('ocr'),
    );
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scanReceiptTimeout)));
    }
    return null;
  } on ReceiptOcrException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptErrorDetail(e.message))),
      );
    }
    return null;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scanReceiptErrorGeneric)));
    }
    return null;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return null;

  final candidates = parseReceiptLineCandidates(
    rawText,
    currencyCode: currencyCode,
  );
  if (candidates.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.scanReceiptNoLines)));
    return null;
  }

  if (candidates.length == 1) {
    final only = candidates.first;
    nameController.text = only.label;
    priceController.text = amountToInputText(only.amount, currencyCode);
    onApplied();
    HapticFeedback.selectionClick();
    return 1;
  }

  final batchHandler = onAddAllLines;
  final Object? pickResult = await _showLinePickerSheet(
    context,
    l10n,
    candidates,
    currencyCode,
    batchHandler,
  );

  if (!context.mounted) return null;

  if (identical(pickResult, _kAddAllOcrLines)) {
    final handler = batchHandler;
    if (handler == null) return null;
    await handler(candidates);
    onApplied();
    HapticFeedback.mediumImpact();
    return candidates.length;
  }

  if (pickResult is ReceiptLineCandidate) {
    nameController.text = pickResult.label;
    priceController.text = amountToInputText(pickResult.amount, currencyCode);
    onApplied();
    HapticFeedback.selectionClick();
    return 1;
  }

  return null;
}

Future<Object?> _showScanSourceSheet(
  BuildContext context,
  AppLocalizations l10n, {
  required bool nativeOcr,
}) {
  if (!nativeOcr) {
    return _showNonMobileScanSourceSheet(context, l10n);
  }
  if (hostPlatformIsApple()) {
    return showCupertinoModalPopup<Object?>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text(l10n.scanReceiptEnterManuallySubtitle),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: Text(l10n.scanReceiptCamera),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: Text(l10n.scanReceiptGallery),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _ManualReceiptEntry()),
            child: Text(l10n.scanReceiptEnterManually),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
  return showModalBottomSheet<Object?>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.scanReceiptCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.scanReceiptGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.scanReceiptEnterManually),
              subtitle: Text(l10n.scanReceiptEnterManuallySubtitle),
              onTap: () => Navigator.pop(ctx, _ManualReceiptEntry()),
            ),
          ],
        ),
      );
    },
  );
}

/// Desktop / web: camera, file picker, or manual (no on-device OCR in this app).
Future<Object?> _showNonMobileScanSourceSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  if (hostPlatformIsApple()) {
    return showCupertinoModalPopup<Object?>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text(l10n.scanReceiptNonMobileScanHint),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: Text(l10n.scanReceiptCamera),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _PickImageFile()),
            child: Text(l10n.scanReceiptChooseImageFile),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _ManualReceiptEntry()),
            child: Text(l10n.scanReceiptEnterManually),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
  return showModalBottomSheet<Object?>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l10n.scanReceiptNonMobileScanHint,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.scanReceiptCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.scanReceiptChooseImageFile),
              onTap: () => Navigator.pop(ctx, _PickImageFile()),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.scanReceiptEnterManually),
              subtitle: Text(l10n.scanReceiptEnterManuallySubtitle),
              onTap: () => Navigator.pop(ctx, _ManualReceiptEntry()),
            ),
          ],
        ),
      );
    },
  );
}

Future<Object?> _showLinePickerSheet(
  BuildContext context,
  AppLocalizations l10n,
  List<ReceiptLineCandidate> candidates,
  String currencyCode,
  Future<void> Function(List<ReceiptLineCandidate>)? batchHandler,
) {
  if (hostPlatformIsApple()) {
    return showCupertinoModalPopup<Object?>(
      context: context,
      builder: (ctx) {
        final bg = CupertinoColors.systemBackground.resolveFrom(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.scanReceiptPickLine,
                  style: CupertinoTheme.of(ctx).textTheme.navTitleTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              if (batchHandler != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.pop(ctx, _kAddAllOcrLines),
                    child: Text(l10n.scanReceiptAddAllLines(candidates.length)),
                  ),
                ),
              Expanded(
                child: CupertinoScrollbar(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, i) {
                      final c = candidates[i];
                      return Material(
                        color: bg,
                        child: ListTile(
                          title: Text(
                            c.label,
                            style: CupertinoTheme.of(ctx).textTheme.textStyle,
                          ),
                          trailing: Text(
                            amountToInputText(c.amount, currencyCode),
                            style: CupertinoTheme.of(ctx).textTheme.textStyle,
                          ),
                          onTap: () => Navigator.pop(ctx, c),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  return showModalBottomSheet<Object?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.scanReceiptPickLine,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (batchHandler != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, _kAddAllOcrLines),
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: Text(l10n.scanReceiptAddAllLines(candidates.length)),
                ),
              ),
            ],
            for (final c in candidates)
              ListTile(
                title: Text(c.label),
                trailing: Text(amountToInputText(c.amount, currencyCode)),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      );
    },
  );
}

/// Marker returned from the line picker when the user chooses batch import.
const Object _kAddAllOcrLines = Object();
