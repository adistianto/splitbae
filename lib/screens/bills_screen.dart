import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/layout/adaptive_insets.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/screens/transaction_detail_screen.dart';

/// Posted bills feed (v0 “Bills” tab): month groups + row → detail.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key, required this.onComposeNewBill});

  final VoidCallback onComposeNewBill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final hPad = splitBaePageHorizontalPadding(context);
    final async = ref.watch(postedBillSummariesProvider);

    final body = async.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(hPad + 8),
              child: Text(
                l10n.billsEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        final groups = _groupByMonth(list);
        final keys = groups.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final children = <Widget>[];
        for (final k in keys) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Text(
                    DateFormat.yMMMM(locale.toString()).format(k),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
            ),
          );
          for (final s in groups[k]!) {
            children.add(
              _BillRowCard(
                summary: s,
                locale: locale,
                onTap: () {
                  HapticFeedback.selectionClick();
                  openTransactionDetailScreen(context, s.transaction.id);
                },
              ),
            );
          }
        }
        return ListView(
          padding: EdgeInsets.only(bottom: 88, left: hPad, right: hPad),
          children: children,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.billsScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.addItemTooltip,
            icon: const Icon(Icons.add),
            onPressed: onComposeNewBill,
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

Map<DateTime, List<PostedBillSummary>> _groupByMonth(
  List<PostedBillSummary> list,
) {
  final out = <DateTime, List<PostedBillSummary>>{};
  for (final s in list) {
    final d = DateTime.fromMillisecondsSinceEpoch(s.transaction.createdAtMs);
    final key = DateTime(d.year, d.month);
    out.putIfAbsent(key, () => []).add(s);
  }
  return out;
}

class _BillRowCard extends StatelessWidget {
  const _BillRowCard({
    required this.summary,
    required this.locale,
    required this.onTap,
  });

  final PostedBillSummary summary;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = summary.transaction;
    final title = t.description.trim().isEmpty
        ? AppLocalizations.of(context)!.postBillUntitled
        : t.description;
    final date = DateFormat.MMMd(locale.toString()).format(
      DateTime.fromMillisecondsSinceEpoch(t.createdAtMs),
    );
    final amount = minorUnitsToAmount(
      summary.totalMinorPrimary,
      t.currencyCode,
    );
    final amountLabel = formatCurrencyAmount(
      amount: amount,
      currencyCode: t.currencyCode,
      locale: locale,
    );
    final icon = splitBaeCategoryIcon(t.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '$date · ${summary.participantCount}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
