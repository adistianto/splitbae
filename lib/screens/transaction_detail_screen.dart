import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/ledger_line_item.dart';
import 'package:splitbae/core/domain/transaction_detail_data.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart'
    show AssignedReceiptLine, ParticipantRef, calculateSplitAssigned;

void openTransactionDetailScreen(BuildContext context, String transactionId) {
  final route = hostPlatformIsApple()
      ? CupertinoPageRoute<void>(
          builder: (_) => TransactionDetailScreen(transactionId: transactionId),
        )
      : MaterialPageRoute<void>(
          builder: (_) => TransactionDetailScreen(transactionId: transactionId),
        );
  Navigator.of(context).push(route);
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final async = ref.watch(transactionDetailProvider(transactionId));

    return async.when(
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.transactionDetailMissing)),
          );
        }
        final t = detail.transaction;
        final title = t.description.trim().isEmpty
            ? l10n.postBillUntitled
            : t.description;
        final dateStr = DateFormat.MMMd(locale.toString()).format(
          DateTime.fromMillisecondsSinceEpoch(t.createdAtMs),
        );
        var sumPrimary = 0;
        for (final line in detail.lines) {
          if (line.receiptItem.currencyCode == t.currencyCode) {
            sumPrimary += amountToMinorUnits(
              line.receiptItem.price,
              line.receiptItem.currencyCode,
            );
          }
        }
        final totalLabel = formatCurrencyAmount(
          amount: minorUnitsToAmount(sumPrimary, t.currencyCode),
          currencyCode: t.currencyCode,
          locale: locale,
        );
        final icon = splitBaeCategoryIcon(t.category);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$dateStr · ${detail.participantCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    totalLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.transactionDetailTabItems),
                  Tab(text: l10n.transactionDetailTabPersons),
                  Tab(text: l10n.transactionDetailTabPayments),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ItemsTab(detail: detail),
                _PersonsTab(transactionId: transactionId),
                _PaymentsTab(detail: detail),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}

class _ItemsTab extends ConsumerWidget {
  const _ItemsTab({required this.detail});

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
      children: [
        for (final line in detail.lines)
          _LineBreakdownCard(
            line: line,
            participantRefs: participantRefs,
            locale: locale,
          ),
      ],
    );
  }
}

class _LineBreakdownCard extends StatelessWidget {
  const _LineBreakdownCard({
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

class _PersonsTab extends ConsumerWidget {
  const _PersonsTab({required this.transactionId});

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
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final s = visible[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(
              splitBaeInitialGrapheme(s.personName),
              style: const TextStyle(fontSize: 14),
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

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.detail});

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
