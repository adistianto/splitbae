import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';

typedef ConfirmDeleteLine =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      LedgerLineItem line,
    );

/// Bill lines + per-person split. [twoColumn] uses a side-by-side layout on
/// wide tablets / desktop when true.
class SplitHomeContent extends ConsumerWidget {
  const SplitHomeContent({
    super.key,
    required this.horizontalPadding,
    required this.onConfirmDeleteLine,
    this.twoColumn = false,
  });

  final double horizontalPadding;
  final bool twoColumn;
  final ConfirmDeleteLine onConfirmDeleteLine;

  List<Widget> _lineCards(
    BuildContext context,
    WidgetRef ref,
    List<LedgerLineItem> items,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return items
        .map(
          (line) => Card(
            margin: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 6,
            ),
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              title: Text(
                line.receiptItem.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(line.receiptItem.currencyCode),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCurrencyAmount(
                      amount: line.receiptItem.price,
                      currencyCode: line.receiptItem.currencyCode,
                      locale: locale,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  splitBaeAdaptiveToolbarIcon(
                    context: context,
                    tooltip: l10n.deleteAction,
                    icon: Icons.delete_outline,
                    onPressed: () => onConfirmDeleteLine(context, ref, line),
                  ),
                ],
              ),
              onTap: () =>
                  showAddReceiptItemSheet(context, ref, existingLine: line),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _splitCards(
    BuildContext context,
    List<SplitResult> results,
    Locale locale,
  ) {
    return results
        .map(
          (res) => Card(
            margin: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 6,
            ),
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  splitBaeInitialGrapheme(res.personName),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(
                res.personName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(res.currencyCode),
              trailing: Text(
                formatCurrencyAmount(
                  amount: res.totalOwed,
                  currencyCode: res.currencyCode,
                  locale: locale,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final splitAsync = ref.watch(splitProvider);
    final locale = Localizations.localeOf(context);
    final items = ref.watch(itemsProvider);
    final participants = ref.watch(participantsProvider);

    final intro = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 4),
      child: Text(
        l10n.splitSubtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final billHeader = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
      child: Text(
        l10n.billItemsTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );

    final emptyBill = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Text(
        l10n.emptyBillHint,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final lineCards = _lineCards(context, ref, items, locale);

    final perPersonHeader = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 8),
      child: Text(
        l10n.perPersonTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );

    final emptyParticipants = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Text(
        l10n.emptyParticipantsHint,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    Widget splitPane(AsyncValue<List<SplitResult>> async) {
      if (participants.isEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [perPersonHeader, emptyParticipants],
        );
      }
      return async.when(
        data: (results) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [perPersonHeader, ..._splitCards(context, results, locale)],
        ),
        loading: () => Padding(
          padding: EdgeInsets.all(horizontalPadding + 8),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: EdgeInsets.all(horizontalPadding + 8),
          child: Text('Error: $err'),
        ),
      );
    }

    final billChildren = <Widget>[
      intro,
      billHeader,
      if (items.isEmpty) emptyBill else ...lineCards,
    ];

    if (!twoColumn) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [...billChildren, splitPane(splitAsync)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: billChildren,
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Scrollbar(
            child: participants.isEmpty
                ? ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [perPersonHeader, emptyParticipants],
                  )
                : splitAsync.when(
                    data: (results) => ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        perPersonHeader,
                        ..._splitCards(context, results, locale),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
          ),
        ),
      ],
    );
  }
}
