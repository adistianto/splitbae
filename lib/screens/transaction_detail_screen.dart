import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:splitbae/core/data/amount_minor.dart'
    show amountToMinorUnits, minorUnitsToAmount;
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/features/split/application/draft_split_provider.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/draft_split_screen.dart';
import 'package:splitbae/widgets/transaction_detail_tab_views.dart';

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
        final dateStr = DateFormat.MMMd(
          locale.toString(),
        ).format(DateTime.fromMillisecondsSinceEpoch(t.createdAtMs));
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
        final (catBg, catFg) = context.splitBaeSemantic.categoryIconColors(
          t.category,
        );

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            floatingActionButton: t.kind == 'normal'
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await beginEditPostedBill(ref, transactionId);
                        if (!context.mounted) return;
                        openDraftSplitScreen(context, ref);
                      } catch (e) {
                        if (!context.mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    icon: Icon(PhosphorIconsRegular.pencilSimple),
                    label: Text(l10n.editPostedBillAction),
                  )
                : null,
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
                      color: catBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: catFg),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                TransactionDetailItemsBody(detail: detail),
                TransactionDetailPersonsBody(transactionId: transactionId),
                TransactionDetailPaymentsBody(detail: detail),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}
