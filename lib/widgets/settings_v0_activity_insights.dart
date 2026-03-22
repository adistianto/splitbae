import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/posted_bill_summary.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/ui/category_icons.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';

/// v0 [settings-tab] “Your activity” summary: spend, month, categories, partner.
class SettingsV0ActivityInsightsCard extends ConsumerWidget {
  const SettingsV0ActivityInsightsCard({super.key});

  static List<PostedBillSummary> _rowsForPreferredCurrency(
    List<PostedBillSummary> all,
    String preferredCcy,
  ) {
    final m = all.where((s) => s.transaction.currencyCode == preferredCcy).toList();
    if (m.isNotEmpty) return m;
    if (all.isEmpty) return [];
    final fb = all.first.transaction.currencyCode;
    return all.where((s) => s.transaction.currencyCode == fb).toList();
  }

  static String _categoryLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'food':
        return l10n.categoryFood;
      case 'transport':
        return l10n.categoryTransport;
      case 'accommodation':
        return l10n.categoryAccommodation;
      case 'entertainment':
        return l10n.categoryEntertainment;
      case 'shopping':
        return l10n.categoryShopping;
      case 'utilities':
        return l10n.categoryUtilities;
      case 'settlement':
        return l10n.categorySettlement;
      default:
        return l10n.categoryOther;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(postedBillSummariesProvider);
    final people = ref.watch(participantsProvider);
    final preferredCcy = ref.watch(appSettingsProvider).defaultCurrencyCode;

    return async.when(
      data: (summaries) {
        final rows = _rowsForPreferredCurrency(summaries, preferredCcy);
        final ccy = rows.isEmpty ? preferredCcy : rows.first.transaction.currencyCode;

        var totalMinor = 0;
        var thisMonthMinor = 0;
        final now = DateTime.now();
        final catTotals = <String, int>{};
        final partnerHits = <String, int>{};

        for (final s in rows) {
          totalMinor += s.totalMinorPrimary;
          final d = DateTime.fromMillisecondsSinceEpoch(s.transaction.createdAtMs);
          if (d.year == now.year && d.month == now.month) {
            thisMonthMinor += s.totalMinorPrimary;
          }
          final c = s.transaction.category;
          catTotals[c] = (catTotals[c] ?? 0) + s.totalMinorPrimary;
          for (final id in s.participantIds) {
            partnerHits[id] = (partnerHits[id] ?? 0) + 1;
          }
        }

        final n = rows.length;
        final avgMinor = n == 0 ? 0 : totalMinor ~/ n;

        var topPartnerId = '';
        var topPartnerCount = 0;
        for (final e in partnerHits.entries) {
          if (e.value > topPartnerCount) {
            topPartnerCount = e.value;
            topPartnerId = e.key;
          }
        }

        final topCats = catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top3 = topCats.take(3).toList();

        String fmt(int minor) => formatCurrencyAmount(
              amount: minorUnitsToAmount(minor, ccy),
              currencyCode: ccy,
              locale: locale,
            );

        var partnerName = topPartnerId;
        var partnerInitial = '?';
        for (final p in people) {
          if (p.id == topPartnerId) {
            partnerName = p.displayName;
            partnerInitial = splitBaeInitialGrapheme(p.displayName);
            break;
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.12),
                      cs.primary.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settingsV0ActivityTitle,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statPill(
                            context,
                            l10n.settingsV0TotalSpent,
                            fmt(totalMinor),
                            emphasize: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statPill(
                            context,
                            l10n.settingsV0ThisMonth,
                            fmt(thisMonthMinor),
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _miniStat(
                            context,
                            Icons.calendar_today_outlined,
                            '$n',
                            l10n.settingsV0StatTransactions,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                        Expanded(
                          child: _miniStat(
                            context,
                            Icons.person_outline,
                            '${people.length}',
                            l10n.settingsV0StatFriends,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                        Expanded(
                          child: _miniStat(
                            context,
                            Icons.schedule,
                            n == 0 ? '—' : fmt(avgMinor),
                            l10n.settingsV0StatAvgPerTxn,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (top3.isNotEmpty && totalMinor > 0) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.settingsV0TopCategories,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < top3.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _CategoryRow(
                            categoryId: top3[i].key,
                            amountMinor: top3[i].value,
                            totalMinor: totalMinor,
                            label: _categoryLabel(top3[i].key, l10n),
                            locale: locale,
                            currencyCode: ccy,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (topPartnerId.isNotEmpty && topPartnerCount > 0) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.settingsV0TopPartner,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            partnerInitial,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partnerName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.settingsV0PartnerTxCount(topPartnerCount),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$e'),
      ),
    );
  }

  Widget _statPill(
    BuildContext context,
    String label,
    String value, {
    required bool emphasize,
  }) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    IconData icon,
    String value,
    String subtitle,
    Color iconColor,
  ) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.amountMinor,
    required this.totalMinor,
    required this.label,
    required this.locale,
    required this.currencyCode,
  });

  final String categoryId;
  final int amountMinor;
  final int totalMinor;
  final String label;
  final Locale locale;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = totalMinor == 0 ? 0 : ((amountMinor / totalMinor) * 100).round();
    final (bg, fg) = context.splitBaeSemantic.categoryIconColors(categoryId);
    final icon = splitBaeCategoryIcon(categoryId);
    final amountLabel = formatCurrencyAmount(
      amount: minorUnitsToAmount(amountMinor, currencyCode),
      currencyCode: currencyCode,
      locale: locale,
    );
    final barColor = cs.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    amountLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
