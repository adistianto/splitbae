import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/ui/splitbae_motion.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/transaction_detail_screen.dart';
import 'package:splitbae/widgets/add_transaction_sheet.dart';
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

  Future<void> _shareBill(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final t = widget.summary.transaction;
    final title = t.description.trim().isEmpty ? l10n.postBillUntitled : t.description;
    final date = DateFormat.yMMMd(widget.locale.toString()).format(
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
    final text = '$title\n$date · $amountLabel';
    await SharePlus.instance.share(
      ShareParams(text: text, subject: title),
    );
  }

  Future<bool?> _confirmReplaceDraft(BuildContext context, AppLocalizations l10n) {
    return showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(l10n.draftReplaceFromPostedTitle),
        content: Text(l10n.draftReplaceFromPostedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.draftReplaceFromPostedAction),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPostedToDraftAndOpenSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final hasDraft = ref.read(itemsProvider).isNotEmpty;
    if (hasDraft) {
      final ok = await _confirmReplaceDraft(context, l10n);
      if (ok != true || !context.mounted) return;
    }
    try {
      await ref
          .read(itemsProvider.notifier)
          .copyPostedBillToDraft(widget.summary.transaction.id);
      if (!context.mounted) return;
      HapticFeedback.mediumImpact();
      showAddTransactionSheet(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.billCopyToDraftFailed)),
      );
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations l10n) {
    return showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(l10n.billDeleteConfirmTitle),
        content: Text(l10n.billDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.billCardDelete),
          ),
        ],
      ),
    );
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
    final receiptPath = t.receiptImagePath;
    final (catBg, catFg) = context.splitBaeSemantic.categoryIconColors(t.category);

    final card = Card(
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
                      color: catBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: catFg,
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
                    duration: splitBaeAnimationDuration(
                      context,
                      const Duration(milliseconds: 200),
                    ),
                    curve: splitBaeAnimationCurve(context),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _shareBill(context, l10n);
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.billCardShare),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyPostedToDraftAndOpenSheet(context, l10n);
                  },
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: Text(l10n.billCardAdjustDraft),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    openTransactionDetailScreen(context, id);
                  },
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: Text(l10n.billCardEdit),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await _confirmDelete(context, l10n);
                    if (ok != true || !context.mounted) return;
                    try {
                      await ref.read(itemsProvider.notifier).deletePostedBill(id);
                      HapticFeedback.mediumImpact();
                    } catch (_) {}
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    l10n.billCardDelete,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            if (receiptPath != null && receiptPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(receiptPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ref.watch(transactionDetailProvider(id)).when(
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
                        physics: splitBaeAnimationsEnabled(context)
                            ? null
                            : const NeverScrollableScrollPhysics(),
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
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: '$title, $amountLabel, $date',
      expanded: _expanded,
      hint: l10n.billSwipeDeleteHint,
      child: Dismissible(
        key: ValueKey(id),
        direction: _expanded ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Theme.of(context).colorScheme.error,
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        confirmDismiss: (direction) async {
          final ok = await _confirmDelete(context, l10n);
          if (ok != true) return false;
          try {
            await ref.read(itemsProvider.notifier).deletePostedBill(id);
            HapticFeedback.mediumImpact();
            return true;
          } catch (_) {
            return false;
          }
        },
        child: card,
      ),
    );
  }
}
