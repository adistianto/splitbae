import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/transaction_detail_data.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart'
    show AssignedReceiptLine, ParticipantRef, calculateSplitAssigned;

/// Line items + per-line split (Items tab).
class TransactionDetailItemsBody extends ConsumerWidget {
  const TransactionDetailItemsBody({super.key, required this.detail});

  final TransactionDetailData detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(participantsProvider);
    final participantRefs = participants
        .map(
          (e) => ParticipantRef(id: e.id, displayName: e.displayName),
        )
        .toList();
    final locale = Localizations.localeOf(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        for (final line in detail.lines)
          TransactionLineBreakdownCard(
            line: line,
            participantRefs: participantRefs,
            locale: locale,
          ),
      ],
    );
  }
}

class TransactionLineBreakdownCard extends StatelessWidget {
  const TransactionLineBreakdownCard({
    super.key,
    required this.line,
    required this.participantRefs,
    required this.locale,
  });

  final LedgerLineItem line;
  final List<ParticipantRef> participantRefs;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final splits = calculateSplitAssigned(
      lines: [
        AssignedReceiptLine(
          item: line.receiptItem,
          assigneeIds: line.assignedParticipantIds,
        ),
      ],
      participants: participantRefs,
    );
    final lineTotal = formatCurrencyAmount(
      amount: line.receiptItem.price,
      currencyCode: line.receiptItem.currencyCode,
      locale: locale,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.receiptItem.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  lineTotal,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in splits)
              if (s.totalOwed > 1e-9)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.personName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                      Text(
                        formatCurrencyAmount(
                          amount: s.totalOwed,
                          currencyCode: s.currencyCode,
                          locale: locale,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            if (splits.every((s) => s.totalOwed <= 1e-9))
              Text(
                l10n.transactionDetailNoShares,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// Persons tab.
class TransactionDetailPersonsBody extends ConsumerWidget {
  const TransactionDetailPersonsBody({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final rows = ref.watch(postedTransactionSplitProvider(transactionId));
    final visible = rows.where((s) => s.totalOwed > 1e-9).toList()
      ..sort((a, b) {
        final c = a.personName.compareTo(b.personName);
        if (c != 0) return c;
        return a.currencyCode.compareTo(b.currencyCode);
      });

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.transactionDetailPersonsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final s = visible[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(
              splitBaeDisplayInitials(s.personName),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          title: Text(s.personName),
          subtitle: Text(s.currencyCode),
          trailing: Text(
            formatCurrencyAmount(
              amount: s.totalOwed,
              currencyCode: s.currencyCode,
              locale: locale,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      },
    );
  }
}

/// Payments tab.
class TransactionDetailPaymentsBody extends StatelessWidget {
  const TransactionDetailPaymentsBody({super.key, required this.detail});

  final TransactionDetailData detail;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final payments = detail.payments;
    if (payments.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.transactionDetailNoPayments,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, i) {
        final p = payments[i];
        final name =
            detail.participantNames[p.participantId] ?? p.participantId;
        final amount = minorUnitsToAmount(p.amountMinor, p.currencyCode);
        return ListTile(
          title: Text(name),
          subtitle: Text(p.currencyCode),
          trailing: Text(
            formatCurrencyAmount(
              amount: amount,
              currencyCode: p.currencyCode,
              locale: locale,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}
