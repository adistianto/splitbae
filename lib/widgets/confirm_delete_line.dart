import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/providers.dart';

Future<void> confirmDeleteLine(
  BuildContext context,
  WidgetRef ref,
  LedgerLineItem line,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showAdaptiveConfirmDialog(
    context: context,
    title: Text(l10n.deleteItemTitle),
    content: Text(l10n.deleteItemBody),
    cancelLabel: l10n.cancel,
    confirmLabel: l10n.deleteAction,
    confirmIsDestructive: true,
  );
  if (ok == true && context.mounted) {
    await ref.read(itemsProvider.notifier).deleteItem(line.id);
  }
}
