import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/bills_insights.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/screens/settings_screen.dart';
import 'package:splitbae/widgets/posted_bill_expandable_card.dart';
import 'package:splitbae/widgets/splitbae_fab_menu.dart';

/// Bills dashboard: v0 hero, insight chips, month groups, expandable cards, FAB speed dial.
class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({
    super.key,
    required this.onNewBill,
    required this.onScanBillEntry,
    required this.onSwitchToBalances,
  });

  final VoidCallback onNewBill;
  final VoidCallback onScanBillEntry;
  final VoidCallback onSwitchToBalances;

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PostedBillSummary> _filter(List<PostedBillSummary> list, String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return list;
    return list
        .where(
          (s) => s.transaction.description.toLowerCase().contains(t),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final async = ref.watch(postedBillSummariesProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: async.when(
        data: (all) {
          final insights = computeBillsInsights(all);
          final filtered = _filter(all, _searchCtrl.text);
          final groups = _groupByMonth(filtered);
          final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

          return Stack(
            fit: StackFit.expand,
            children: [
              ListView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: topPad + 8,
                  bottom: 120,
                ),
                children: [
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _TotalExpensesHero(
                    insights: insights,
                    locale: locale,
                  ),
                  const SizedBox(height: 12),
                  _InsightChipsRow(insights: insights, locale: locale),
                  const SizedBox(height: 20),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            all.isEmpty
                                ? l10n.billsEmptyHeroTitle
                                : l10n.billsSearchEmpty,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (all.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.billsEmptyHeroSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...[
                      for (final k in keys) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Text(
                                DateFormat.yMMMM(
                                  locale.toString(),
                                ).format(k).toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        for (final s in groups[k]!)
                          PostedBillExpandableCard(
                            key: ValueKey(s.transaction.id),
                            summary: s,
                            locale: locale,
                          ),
                      ],
                    ],
                ],
              ),
              Positioned(
                top: topPad + 8,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleChromeButton(
                      icon: _searchOpen ? Icons.close : Icons.search,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _searchOpen = !_searchOpen;
                          if (!_searchOpen) {
                            _searchCtrl.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _CircleChromeButton(
                      icon: Icons.person_outline,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_searchOpen)
                Positioned(
                  top: topPad + 56,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: cs.surface,
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.billsSearchHint,
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => _searchCtrl.clear());
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              SplitBaeFabMenu(
                onNewBill: widget.onNewBill,
                onScanBill: widget.onScanBillEntry,
                onCreateReport: widget.onSwitchToBalances,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _CircleChromeButton extends StatelessWidget {
  const _CircleChromeButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: cs.onSurface),
        ),
      ),
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
        borderRadius: BorderRadius.circular(28),
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
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: cs.onPrimary.withValues(alpha: 0.85)),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.75),
                  fontSize: 10,
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
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    chips.add(
      _Chip(
        background: trendBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              insights.weekTrendPercent < 0
                  ? Icons.south_east
                  : Icons.north_east,
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
      _Chip(
        background: sem.insightTopBg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 16, color: sem.insightTopFg),
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
        _Chip(
          background: sem.insightStreakBg,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
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
      _Chip(
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
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
