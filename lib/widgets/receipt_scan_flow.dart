import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/ocr/receipt_line_parse.dart';
import 'package:splitbae/screens/scan_receipt_screen.dart';

/// Marker returned from [showReceiptLinePickerSheet] when the user chooses
/// batch import of all OCR lines.
const Object receiptLinePickerAddAllMarker = Object();

/// Pushes the v0-style [ScanReceiptScreen] → on-device OCR → line picker when
/// needed → fills controllers or batch-adds.
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

/// Sheet listing parsed OCR lines; batch action when [onAddAllLines] is set.
Future<Object?> showReceiptLinePickerSheet(
  BuildContext context,
  AppLocalizations l10n, {
  required List<ReceiptLineCandidate> candidates,
  required String currencyCode,
  Future<void> Function(List<ReceiptLineCandidate>)? onAddAllLines,
}) =>
    _showLinePickerSheet(
      context,
      l10n,
      candidates,
      currencyCode,
      onAddAllLines,
    );

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
                    onPressed: () =>
                        Navigator.pop(ctx, receiptLinePickerAddAllMarker),
                    child: Text(l10n.scanReceiptAddAllLines(candidates.length)),
                  ),
                ),
              Expanded(
                child: CupertinoScrollbar(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, i) {
                      final c = candidates[i];
                      final q = c.quantity;
                      return Material(
                        color: bg,
                        child: ListTile(
                          title: Text(
                            c.label,
                            style: CupertinoTheme.of(ctx).textTheme.textStyle,
                          ),
                          subtitle: q != null
                              ? Text(
                                  l10n.scanReceiptOcrLineDetail(
                                    q,
                                    amountToInputText(
                                      c.unitPrice,
                                      currencyCode,
                                    ),
                                    amountToInputText(
                                      c.amount,
                                      currencyCode,
                                    ),
                                  ),
                                  style: CupertinoTheme.of(ctx)
                                      .textTheme
                                      .textStyle
                                      .copyWith(
                                        fontSize: 13,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(ctx),
                                      ),
                                )
                              : null,
                          trailing: q == null
                              ? Text(
                                  amountToInputText(c.amount, currencyCode),
                                  style: CupertinoTheme.of(ctx).textTheme.textStyle,
                                )
                              : null,
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
                  onPressed: () =>
                      Navigator.pop(ctx, receiptLinePickerAddAllMarker),
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: Text(l10n.scanReceiptAddAllLines(candidates.length)),
                ),
              ),
            ],
            for (final c in candidates)
              ListTile(
                title: Text(c.label),
                subtitle: c.quantity != null
                    ? Text(
                        l10n.scanReceiptOcrLineDetail(
                          c.quantity!,
                          amountToInputText(
                            c.unitPrice,
                            currencyCode,
                          ),
                          amountToInputText(c.amount, currencyCode),
                        ),
                      )
                    : null,
                trailing: c.quantity == null
                    ? Text(amountToInputText(c.amount, currencyCode))
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      );
    },
  );
}
