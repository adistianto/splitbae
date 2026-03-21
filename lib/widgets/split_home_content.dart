import 'package:flutter/material.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart';
import 'package:splitbae/widgets/add_receipt_item_sheet.dart';
import 'package:splitbae/widgets/item_assignee_chips.dart';
import 'package:splitbae/widgets/post_bill_sheet.dart';

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
    List<ParticipantEntry> participants,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return items.map((line) {
      final amountStr = formatCurrencyAmount(
        amount: line.receiptItem.price,
        currencyCode: line.receiptItem.currencyCode,
        locale: locale,
      );
      final unitStr = formatCurrencyAmount(
        amount: line.unitPrice,
        currencyCode: line.receiptItem.currencyCode,
        locale: locale,
      );
      return Semantics(
        label: l10n.semanticsDraftBillLine(line.receiptItem.name, amountStr),
        hint: l10n.semanticsDraftLineHint,
        button: true,
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 6,
          ),
          elevation: 0,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: () =>
                    showAddReceiptItemSheet(context, ref, existingLine: line),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              line.receiptItem.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          splitBaeAdaptiveToolbarIcon(
                            context: context,
                            tooltip: l10n.deleteAction,
                            icon: Icons.delete_outline,
                            onPressed: () =>
                                onConfirmDeleteLine(context, ref, line),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _DraftLineMetric(
                              label: l10n.draftBillLineQtyColumn,
                              value: '${line.quantity}',
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _DraftLineMetric(
                              label: l10n.draftBillLineUnitColumn,
                              value: unitStr,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _DraftLineMetric(
                              label: l10n.draftBillLineLineTotalColumn,
                              value: amountStr,
                              emphasize: true,
                              valueColor: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          line.receiptItem.currencyCode,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ItemAssigneeChips(
                  participants: participants,
                  assigneeIds: line.assignedParticipantIds.toSet(),
                  dense: true,
                  onAssigneesChanged: (ids) {
                    ref
                        .read(itemsProvider.notifier)
                        .setLineAssignments(
                          lineId: line.id,
                          selectedParticipantIds: ids,
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _splitCards(
    BuildContext context,
    List<SplitResult> results,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return results.map((res) {
      final formatted = formatCurrencyAmount(
        amount: res.totalOwed,
        currencyCode: res.currencyCode,
        locale: locale,
      );
      return Semantics(
        label: l10n.semanticsSplitPersonRow(res.personName, formatted),
        child: Card(
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              res.currencyCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              formatted,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }).toList();
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

    final lineCards = _lineCards(context, ref, items, participants, locale);

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
      if (items.isNotEmpty && participants.isNotEmpty)
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            4,
          ),
          child: FilledButton.tonal(
            onPressed: () => showPostBillSheet(context, ref),
            child: Text(l10n.postBillAction),
          ),
        ),
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

class _DraftLineMetric extends StatelessWidget {
  const _DraftLineMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vc = valueColor ?? scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: (emphasize
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: vc,
              ),
        ),
      ],
    );
  }
}
