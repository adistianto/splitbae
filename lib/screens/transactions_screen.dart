import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/domain/bills_insights.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';
import 'package:splitbae/core/ui/category_phosphor_icons.dart';
import 'package:splitbae/features/ledger/application/ledger_search_provider.dart';
import 'package:splitbae/features/bills/application/bills_provider.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/core/data/amount_minor.dart'
    show minorUnitsToAmount;
import 'package:splitbae/screens/transaction_detail_screen.dart';
import 'package:splitbae/widgets/shell/splitbae_shell_search_field.dart';

/// Dense, searchable master ledger of posted bills ("Transactions" tab),
/// integrated into the v0 Bills tab.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(ledgerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearch(String v) {
    ref.read(ledgerSearchQueryProvider.notifier).state = v;
  }

  void _setCategory(LedgerCategoryFilter f) {
    ref.read(ledgerCategoryFilterProvider.notifier).state = f;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.paddingOf(context).top;

    final search = ref.watch(ledgerSearchQueryProvider);
    final category = ref.watch(ledgerCategoryFilterProvider);

    final showHero = search.trim().isEmpty && category == LedgerCategoryFilter.all;

    final billsAsync = ref.watch(billsFeedProvider);
    final filteredAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                SplitBaeV0Layout.screenHorizontalPadding,
                topPad + 8,
                SplitBaeV0Layout.screenHorizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsV0StatTransactions,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SplitBaeShellSearchField(
                    controller: _searchController,
                    hintText: l10n.billsSearchHint,
                    autofocus: false,
                    onChanged: _setSearch,
                  ),
                  const SizedBox(height: 12),
                  _CategoryChipsRow(
                    selected: category,
                    onSelected: _setCategory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredAsync.when(
                data: (filtered) {
                  final all = billsAsync.valueOrNull ?? const <PostedBillSummary>[];
                  return _TransactionsList(
                    all: all,
                    filtered: filtered,
                    showHero: showHero,
                  );
                },
                loading: () => _TransactionsLoadingSkeleton(),
                error: (e, _) => _TransactionsErrorState(message: '$e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        SplitBaeV0Layout.screenHorizontalPadding,
        0,
        SplitBaeV0Layout.screenHorizontalPadding,
        SplitBaeV0Layout.listBottomInsetForShell,
      ),
      itemCount: 8,
      itemBuilder: (ctx, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: m3e.colors.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: m3e.shapes.square.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: m3e.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: m3e.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 160,
                          decoration: BoxDecoration(
                            color: m3e.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 84,
                    height: 22,
                    decoration: BoxDecoration(
                      color: m3e.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionsErrorState extends StatelessWidget {
  const _TransactionsErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        SplitBaeV0Layout.screenHorizontalPadding,
        16,
        SplitBaeV0Layout.screenHorizontalPadding,
        SplitBaeV0Layout.listBottomInsetForShell,
      ),
      children: [
        Icon(
          PhosphorIconsRegular.warningCircle,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.all,
    required this.filtered,
    required this.showHero,
  });

  final List<PostedBillSummary> all;
  final List<PostedBillSummary> filtered;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m3e = context.m3e;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    if (all.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          SplitBaeV0Layout.screenHorizontalPadding,
          32,
          SplitBaeV0Layout.screenHorizontalPadding,
          SplitBaeV0Layout.listBottomInsetForShell,
        ),
        children: [
          Icon(
            PhosphorIconsRegular.tray,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.billsEmptyHeroTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: m3e.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (l10n.billsEmptyHeroSubtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.billsEmptyHeroSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: m3e.colors.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          SplitBaeV0Layout.screenHorizontalPadding,
          32,
          SplitBaeV0Layout.screenHorizontalPadding,
          SplitBaeV0Layout.listBottomInsetForShell,
        ),
        children: [
          Icon(
            PhosphorIconsRegular.receipt,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.billsSearchEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: m3e.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.billsFiltersAdjustHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    final grouped = _groupByMonth(filtered);
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SplitBaeV0Layout.screenHorizontalPadding,
        0,
        SplitBaeV0Layout.screenHorizontalPadding,
        SplitBaeV0Layout.listBottomInsetForShell,
      ),
      children: [
        if (showHero) ...[
          _BillsHero(
            list: all,
            locale: locale,
          ),
          const SizedBox(height: 8),
        ],
        for (final k in keys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              DateFormat.yMMMM(locale.toString()).format(k).toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          for (final s in grouped[k]!) ...[
            _LedgerRow(summary: s, locale: locale),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _BillsHero extends ConsumerWidget {
  const _BillsHero({
    required this.list,
    required this.locale,
  });

  final List<PostedBillSummary> list;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = computeBillsInsights(
      list,
      emptyStateCurrencyCode: ref.watch(defaultCurrencyProvider),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalExpensesHero(insights: insights, locale: locale),
        const SizedBox(height: 12),
        _InsightChipsRow(insights: insights, locale: locale),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TotalExpensesHero extends StatelessWidget {
  const _TotalExpensesHero({
    required this.insights,
    required this.locale,
  });

  final BillsInsights insights;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final totalLabel = formatCurrencyAmount(
      amount: minorUnitsToAmount(insights.totalMinor, insights.currencyCode),
      currencyCode: insights.currencyCode,
      locale: locale,
    );
    final weekLabel = formatCurrencyAmount(
      amount: minorUnitsToAmount(insights.thisWeekMinor, insights.currencyCode),
      currencyCode: insights.currencyCode,
      locale: locale,
    );
    final avgLabel = formatCurrencyAmount(
      amount: minorUnitsToAmount(insights.avgMinor, insights.currencyCode),
      currencyCode: insights.currencyCode,
      locale: locale,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SplitBaeV0Layout.heroBorderRadius),
        gradient: LinearGradient(
          colors: [
            cs.primary,
            Color.lerp(cs.primary, cs.tertiary, 0.15)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.sparkle,
                size: 16,
                color: cs.onPrimary.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.billsTotalExpenses.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.85),
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalLabel,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: l10n.billsThisWeek.toUpperCase(),
                  value: weekLabel,
                  onPrimary: cs.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  label: l10n.billsAverage.toUpperCase(),
                  value: avgLabel,
                  onPrimary: cs.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.onPrimary,
  });

  final String label;
  final String value;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          SplitBaeV0Layout.heroStatBorderRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightChipsRow extends StatelessWidget {
  const _InsightChipsRow({
    required this.insights,
    required this.locale,
  });

  final BillsInsights insights;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sem = context.splitBaeSemantic;
    final m3e = context.m3e;

    final chips = <Widget>[];

    final sign = insights.weekTrendPercent > 0
        ? '+'
        : insights.weekTrendPercent < 0
            ? ''
            : '';
    final trendStr = '$sign${insights.weekTrendPercent.round()}';
    final trendColor = insights.weekTrendPercent > 0
        ? sem.insightTrendWorseFg
        : insights.weekTrendPercent < 0
            ? sem.insightTrendBetterFg
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final trendBg = insights.weekTrendPercent > 0
        ? sem.insightTrendWorseBg
        : insights.weekTrendPercent < 0
            ? sem.insightTrendBetterBg
            : m3e.colors.surfaceContainerHighest;

    chips.add(
      _M3eInsightChip(
        background: trendBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              insights.weekTrendPercent < 0
                  ? PhosphorIconsRegular.arrowDownRight
                  : PhosphorIconsRegular.arrowUpRight,
              size: 16,
              color: trendColor,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.billsInsightVsLastWeek(trendStr),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );

    final topAmt = formatCurrencyAmount(
      amount: minorUnitsToAmount(insights.biggestMinor, insights.currencyCode),
      currencyCode: insights.currencyCode,
      locale: locale,
    );
    chips.add(
      _M3eInsightChip(
        background: sem.insightTopBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.chartLineUp,
              size: 16,
              color: sem.insightTopFg,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.billsInsightTop(topAmt),
              style: TextStyle(
                color: sem.insightTopFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (insights.streakDays > 0) {
      chips.add(
        _M3eInsightChip(
          background: sem.insightStreakBg,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.flame,
                size: 16,
                color: sem.insightStreakFg,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.billsInsightStreak(insights.streakDays),
                style: TextStyle(
                  color: sem.insightStreakFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    chips.add(
      _M3eInsightChip(
        background: m3e.colors.surfaceContainerHighest,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.receipt,
              size: 16,
              color: m3e.colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.billsCountLabel(insights.billCount),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _intersperse(chips, const SizedBox(width: 8))),
    );
  }
}

List<Widget> _intersperse(List<Widget> items, Widget spacer) {
  if (items.isEmpty) return [];
  final o = <Widget>[items.first];
  for (var i = 1; i < items.length; i++) {
    o.add(spacer);
    o.add(items[i]);
  }
  return o;
}

class _M3eInsightChip extends StatelessWidget {
  const _M3eInsightChip({
    required this.background,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SplitBaeV0Layout.insightChipRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.selected,
    required this.onSelected,
  });

  final LedgerCategoryFilter selected;
  final ValueChanged<LedgerCategoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categories = <({LedgerCategoryFilter filter, String label, IconData icon})>[
      (
        filter: LedgerCategoryFilter.all,
        label: 'All',
        icon: PhosphorIconsRegular.receipt,
      ),
      (
        filter: LedgerCategoryFilter.food,
        label: l10n.categoryFood,
        icon: splitBaeCategoryPhosphorIcon('food'),
      ),
      (
        filter: LedgerCategoryFilter.transport,
        label: l10n.categoryTransport,
        icon: splitBaeCategoryPhosphorIcon('transport'),
      ),
      (
        filter: LedgerCategoryFilter.utilities,
        label: l10n.categoryUtilities,
        icon: splitBaeCategoryPhosphorIcon('utilities'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            _LedgerCategoryChip(
              selected: selected == categories[i].filter,
              label: categories[i].label,
              icon: categories[i].icon,
              onTap: () => onSelected(categories[i].filter),
            ),
            if (i != categories.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _LedgerCategoryChip extends StatelessWidget {
  const _LedgerCategoryChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    final cs = Theme.of(context).colorScheme;

    // For "All", fall back to neutral chip colors.
    final (catBg, catFg) = selected
        ? (cs.primary.withValues(alpha: 0.14), cs.primary)
        : (m3e.colors.surfaceContainerLow, m3e.colors.onSurfaceVariant);

    return Material(
      color: selected ? catBg : m3e.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: m3e.shapes.square.sm,
        side: BorderSide(
          color: selected
              ? cs.primary.withValues(alpha: 0.35)
              : m3e.colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? cs.primary
                    : m3e.colors.onSurfaceVariant.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? cs.primary
                          : m3e.colors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.summary,
    required this.locale,
  });

  final PostedBillSummary summary;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = summary.transaction;
    final m3e = context.m3e;
    final cs = Theme.of(context).colorScheme;

    final title = t.description.trim().isEmpty ? l10n.postBillUntitled : t.description;
    final dateStr = DateFormat.MMMd(locale.toString()).format(
      DateTime.fromMillisecondsSinceEpoch(t.createdAtMs),
    );

    final amountLabel = formatCurrencyAmount(
      amount: minorUnitsToAmount(summary.totalMinorPrimary, t.currencyCode),
      currencyCode: t.currencyCode,
      locale: locale,
    );

    final icon = splitBaeCategoryPhosphorIcon(t.category);
    final (catBg, catFg) = context.splitBaeSemantic.categoryIconColors(t.category);

    return Semantics(
      label: '$title, $dateStr, ${summary.participantCount} people',
      button: true,
      child: Material(
        color: m3e.colors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: m3e.shapes.square.lg,
          side: BorderSide(
            color: m3e.colors.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openTransactionDetailScreen(context, t.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: catFg,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.users,
                            size: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$dateStr · ${summary.participantCount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amountLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
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

