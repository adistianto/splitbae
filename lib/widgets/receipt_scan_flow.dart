import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/screens/scan_receipt_screen.dart';

/// Pushes the v0-style [ScanReceiptScreen] → on-device OCR → editable chips →
/// fills controllers or batch-adds.
///
/// Returns **null** if the user cancelled or OCR failed; **1** if a single line
/// was applied to the form; **n** if [onAddAllLines] ran with **n** candidates.
Future<int?> runReceiptScanFlow({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController priceController,
  TextEditingController? quantityController,
  required String currencyCode,
  required void Function() onApplied,
  required AppLocalizations l10n,
  Future<void> Function(List<ReceiptLineCandidate> candidates)? onAddAllLines,
}) async {
  Widget buildScreen() => ScanReceiptScreen(
        nameController: nameController,
        priceController: priceController,
        quantityController: quantityController,
        currencyCode: currencyCode,
        onApplied: onApplied,
        onAddAllLines: onAddAllLines,
      );
  if (hostPlatformIsApple()) {
    return Navigator.of(context, rootNavigator: true).push<int?>(
      CupertinoPageRoute(builder: (_) => buildScreen()),
    );
  }
  return Navigator.of(context, rootNavigator: true).push<int?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => buildScreen(),
    ),
  );
}
