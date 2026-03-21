import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/core/ocr/receipt_ocr_channel.dart';

class _ManualReceiptEntry {}

/// Picks camera/gallery → native OCR → optional line picker → fills controllers.
/// Never blocks manual entry: on failure or timeout, user can still type below.
Future<void> runReceiptScanFlow({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController priceController,
  required String currencyCode,
  required void Function() onApplied,
  required AppLocalizations l10n,
}) async {
  if (!ReceiptOcrChannel.isSupported) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.scanReceiptUnavailable)),
    );
    return;
  }

  final choice = await showModalBottomSheet<Object?>(
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
  if (choice == null || !context.mounted) return;
  if (choice is _ManualReceiptEntry) return;

  final source = choice is ImageSource ? choice : null;
  if (source == null) return;

  final picker = ImagePicker();
  final xfile = await picker.pickImage(source: source, imageQuality: 85);
  if (xfile == null || !context.mounted) return;

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
    rawText = await ReceiptOcrChannel.recognizeText(xfile.path).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('ocr'),
    );
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptTimeout)),
      );
    }
    return;
  } on ReceiptOcrException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptErrorDetail(e.message))),
      );
    }
    return;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanReceiptErrorGeneric)),
      );
    }
    return;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;

  final candidates = parseReceiptLineCandidates(rawText);
  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.scanReceiptNoLines)),
    );
    return;
  }

  ReceiptLineCandidate? chosen;
  if (candidates.length == 1) {
    chosen = candidates.first;
  } else {
    chosen = await showModalBottomSheet<ReceiptLineCandidate>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.scanReceiptPickLine,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
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

  if (chosen != null && context.mounted) {
    nameController.text = chosen.label;
    priceController.text = amountToInputText(chosen.amount, currencyCode);
    onApplied();
  }
}
