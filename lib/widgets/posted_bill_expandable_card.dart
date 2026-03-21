import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/widgets/transaction_detail_tab_views.dart';

/// v0-style expandable bill row: header + optional Items / Persons / Payments.
class PostedBillExpandableCard extends ConsumerStatefulWidget {
  const PostedBillExpandableCard({
    super.key,
    required this.summary,
    required this.locale,
  });

  final PostedBillSummary summary;
  final Locale locale;

  @override
  ConsumerState<PostedBillExpandableCard> createState() =>
      _PostedBillExpandableCardState();
}

class _PostedBillExpandableCardState extends ConsumerState<PostedBillExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = widget.summary.transaction;
    final title = t.description.trim().isEmpty ? l10n.postBillUntitled : t.description;
    final date = DateFormat.MMMd(widget.locale.toString()).format(
      DateTime.fromMillisecondsSinceEpoch(t.createdAtMs),
    );
    final amount = minorUnitsToAmount(
      widget.summary.totalMinorPrimary,
      t.currencyCode,
    );
    final amountLabel = formatCurrencyAmount(
      amount: amount,
      currencyCode: t.currencyCode,
      locale: widget.locale,
    );
    final icon = splitBaeCategoryIcon(t.category);
    final id = t.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
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
                      children: [
                        Text(
                          title,
                          maxLines: _expanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              date,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              ' · ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.summary.participantCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amountLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _expanded
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Consumer(
              builder: (context, ref, _) {
                return ref.watch(transactionDetailProvider(id)).when(
                  data: (detail) {
                    if (detail == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.transactionDetailMissing),
                      );
                    }
                    return Column(
                      children: [
                        Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Theme.of(context).colorScheme.onSurface,
                            unselectedLabelColor:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            indicator: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: l10n.transactionDetailTabItems),
                              Tab(text: l10n.transactionDetailTabPersons),
                              Tab(text: l10n.transactionDetailTabPayments),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 320,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              TransactionDetailItemsBody(detail: detail),
                              TransactionDetailPersonsBody(transactionId: id),
                              TransactionDetailPaymentsBody(detail: detail),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('$e'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
