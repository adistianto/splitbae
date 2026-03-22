// ignore_for_file: prefer_relative_imports

part of 'balances_screen.dart';

/// v0 [balances-tab] layout: hero, debtor/creditor chips, individual list, settle up.
class _BalancesEmbeddedV0 extends ConsumerStatefulWidget {
  const _BalancesEmbeddedV0();

  @override
  ConsumerState<_BalancesEmbeddedV0> createState() =>
      _BalancesEmbeddedV0State();
}

class _BalancesEmbeddedV0State extends ConsumerState<_BalancesEmbeddedV0> {
  String? _expandedSettlementKey;
  bool _showAllBalances = false;

  String _keyFor(SettlementEdge e) =>
      '${e.fromParticipantId}|${e.toParticipantId}|${e.currencyCode}|${e.amountMinor}';

  Future<void> _shareSummary({
    required AppLocalizations l10n,
    required List<SettlementEdge> edges,
    required Map<String, String> nameById,
    required String defaultCcy,
    required BillsInsights insights,
  }) async {
    final buf = StringBuffer()
      ..writeln(l10n.balancesTitle)
      ..writeln()
      ..writeln('${l10n.balancesTotalSpentLabel}: ${formatCurrencyAmount(amount: minorUnitsToAmount(insights.totalMinor, insights.currencyCode), currencyCode: insights.currencyCode, locale: Localizations.localeOf(context))}');
    if (edges.isEmpty) {
      buf.writeln(l10n.allSettledUp);
    } else {
      buf.writeln();
      for (final e in edges) {
        final from = nameById[e.fromParticipantId] ?? e.fromParticipantId;
        final to = nameById[e.toParticipantId] ?? e.toParticipantId;
        final minor = int.parse(e.amountMinor.toString());
        final label = formatCurrencyAmount(
          amount: minorUnitsToAmount(minor, e.currencyCode),
          currencyCode: e.currencyCode,
          locale: Localizations.localeOf(context),
        );
        buf.writeln('$from → $to: $label');
      }
    }
    await SharePlus.instance.share(
      ShareParams(text: buf.toString(), subject: l10n.balancesTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final cs = Theme.of(context).colorScheme;
    final defaultCcy = ref.watch(defaultCurrencyProvider);
    final participants = ref.watch(participantsProvider);
    final nameById = {for (final p in participants) p.id: p.displayName};
    final posted = ref.watch(postedBillSummariesProvider);
    final netsAsync = ref.watch(ledgerNetBalancesProvider);
    final edgesAsync = ref.watch(suggestedSettlementEdgesProvider);
    final recordedAsync = ref.watch(settlementTransfersListProvider);

    return posted.when(
      data: (all) {
        final insights = computeBillsInsights(
          all,
          emptyStateCurrencyCode: defaultCcy,
        );
        return netsAsync.when(
          data: (nets) {
            return edgesAsync.when(
              data: (edges) {
                return recordedAsync.when(
                  data: (recordedRows) {
                    if (all.isEmpty) {
                      return _emptyState(
                        context,
                        l10n,
                        topPad,
                        cs,
                      );
                    }
                    final netById = <String, int>{};
                    for (final n in nets) {
                      if (n.currencyCode != defaultCcy) continue;
                      final v = int.parse(n.amountMinor.toString());
                      netById[n.participantId] =
                          (netById[n.participantId] ?? 0) + v;
                    }
                    var totalToSettleMinor = 0;
                    for (final e in edges) {
                      if (e.currencyCode != defaultCcy) continue;
                      totalToSettleMinor +=
                          int.parse(e.amountMinor.toString());
                    }
                    final allSettled = edges.isEmpty && all.isNotEmpty;

                    String? debtorId;
                    var minDebt = 0;
                    for (final e in netById.entries) {
                      if (e.value < minDebt) {
                        minDebt = e.value;
                        debtorId = e.key;
                      }
                    }
                    if (minDebt >= -1) debtorId = null;

                    String? creditorId;
                    var maxCr = 0;
                    for (final e in netById.entries) {
                      if (e.value > maxCr) {
                        maxCr = e.value;
                        creditorId = e.key;
                      }
                    }
                    if (maxCr <= 1) creditorId = null;

                    var rows = participants
                        .map((p) => MapEntry(p, netById[p.id] ?? 0))
                        .toList();
                    rows.sort((a, b) {
                      final av = a.value.abs() < 1;
                      final bv = b.value.abs() < 1;
                      if (av && !bv) return 1;
                      if (!av && bv) return -1;
                      if (av && bv) return 0;
                      if (a.value > 0 && b.value < 0) return -1;
                      if (a.value < 0 && b.value > 0) return 1;
                      if (a.value > 0 && b.value > 0) {
                        return b.value.compareTo(a.value);
                      }
                      return a.value.compareTo(b.value);
                    });

                    final shellQ = ref
                        .watch(v0ShellSearchQueryProvider)
                        .trim()
                        .toLowerCase();
                    if (shellQ.isNotEmpty) {
                      rows = rows
                          .where(
                            (e) => e.key.displayName
                                .toLowerCase()
                                .contains(shellQ),
                          )
                          .toList();
                    }

                    final displayRows = _showAllBalances || rows.length <= 4
                        ? rows
                        : rows.take(4).toList();
                    final hasMore = rows.length > 4;

                    final totalLabel = formatCurrencyAmount(
                      amount: minorUnitsToAmount(
                        insights.totalMinor,
                        insights.currencyCode,
                      ),
                      currencyCode: insights.currencyCode,
                      locale: locale,
                    );
                    final avgMinor = participants.isEmpty
                        ? 0
                        : insights.totalMinor ~/ participants.length;
                    final avgLabel = formatCurrencyAmount(
                      amount: minorUnitsToAmount(
                        avgMinor,
                        insights.currencyCode,
                      ),
                      currencyCode: insights.currencyCode,
                      locale: locale,
                    );
                    final settleHeadline = allSettled
                        ? l10n.balancesHeroAllSettledTitle
                        : formatCurrencyAmount(
                            amount: minorUnitsToAmount(
                              totalToSettleMinor,
                              defaultCcy,
                            ),
                            currencyCode: defaultCcy,
                            locale: locale,
                          );

                    return ListView(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: topPad + 8,
                            bottom: 120,
                          ),
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.balancesTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.balancesScreenSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.balancesShareSummary,
                                  onPressed: () => _shareSummary(
                                    l10n: l10n,
                                    edges: edges,
                                    nameById: nameById,
                                    defaultCcy: defaultCcy,
                                    insights: insights,
                                  ),
                                  icon: const Icon(Icons.ios_share_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _V0BalancesHero(
                              allSettled: allSettled,
                              settleHeadline: settleHeadline,
                              edgesCount: edges.length,
                              totalSpentLabel: totalLabel,
                              avgPerPersonLabel: avgLabel,
                              l10n: l10n,
                            ),
                            if (debtorId != null || creditorId != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (debtorId != null)
                                    Expanded(
                                      child: _InsightMiniCard(
                                        title: l10n.balancesInsightOwesMost,
                                        name: nameById[debtorId] ?? debtorId,
                                        color: const Color(0xFFFB7185),
                                        bg: const Color(0xFFFFF1F2),
                                        down: true,
                                      ),
                                    ),
                                  if (debtorId != null && creditorId != null)
                                    const SizedBox(width: 8),
                                  if (creditorId != null)
                                    Expanded(
                                      child: _InsightMiniCard(
                                        title: l10n.balancesInsightOwedMost,
                                        name:
                                            nameById[creditorId] ?? creditorId,
                                        color: const Color(0xFF34D399),
                                        bg: const Color(0xFFECFDF5),
                                        down: false,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.balancesSectionIndividual,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        letterSpacing: 0.4,
                                      ),
                                ),
                                Text(
                                  '${participants.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < displayRows.length;
                                      i++) ...[
                                    _PersonBalanceTile(
                                      name: displayRows[i].key.displayName,
                                      balanceMinor: displayRows[i].value,
                                      currencyCode: defaultCcy,
                                      locale: locale,
                                      l10n: l10n,
                                    ),
                                    if (i < displayRows.length - 1)
                                      Divider(
                                        height: 1,
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.35),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            if (hasMore)
                              TextButton(
                                onPressed: () => setState(
                                  () => _showAllBalances = !_showAllBalances,
                                ),
                                child: Text(
                                  _showAllBalances
                                      ? l10n.balancesShowLess
                                      : l10n.balancesShowMore(
                                          rows.length - 4,
                                        ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.settleUpSectionTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    letterSpacing: 0.6,
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            if (edges.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  l10n.allSettledUp,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              )
                            else
                              ...edges.map((edge) {
                                final key = _keyFor(edge);
                                final fromName = nameById[edge.fromParticipantId] ??
                                    edge.fromParticipantId;
                                final toName = nameById[edge.toParticipantId] ??
                                    edge.toParticipantId;
                                final minor =
                                    int.parse(edge.amountMinor.toString());
                                final amount = minorUnitsToAmount(
                                  minor,
                                  edge.currencyCode,
                                );
                                final amountLabel = formatCurrencyAmount(
                                  amount: amount,
                                  currencyCode: edge.currencyCode,
                                  locale: locale,
                                );
                                return _SettlementEdgeCard(
                                  key: ValueKey(key),
                                  edge: edge,
                                  fromName: fromName,
                                  toName: toName,
                                  amountLabel: amountLabel,
                                  maxMinor: minor,
                                  currencyCode: edge.currencyCode,
                                  locale: locale,
                                  expanded: _expandedSettlementKey == key,
                                  onExpand: () => setState(
                                    () => _expandedSettlementKey = key,
                                  ),
                                  onCollapse: () => setState(
                                    () => _expandedSettlementKey = null,
                                  ),
                                );
                              }),
                            const SizedBox(height: 16),
                            Text(
                              l10n.recordedSettlementsTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (recordedRows.isEmpty)
                              Text(
                                '—',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              )
                            else
                              ...recordedRows.map((r) {
                                final fromName =
                                    nameById[r.fromParticipantId] ??
                                        r.fromParticipantId;
                                final toName = nameById[r.toParticipantId] ??
                                    r.toParticipantId;
                                final amount = minorUnitsToAmount(
                                  r.amountMinor,
                                  r.currencyCode,
                                );
                                final amountLabel = formatCurrencyAmount(
                                  amount: amount,
                                  currencyCode: r.currencyCode,
                                  locale: locale,
                                );
                                return Semantics(
                                  label: l10n.semanticsRecordedSettlement(
                                    fromName,
                                    toName,
                                    amountLabel,
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text('$fromName → $toName'),
                                    subtitle: Text(r.currencyCode),
                                    trailing: Text(amountLabel),
                                  ),
                                );
                              }),
                          ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _emptyState(
    BuildContext context,
    AppLocalizations l10n,
    double topPad,
    ColorScheme cs,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ListView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: topPad + 24,
            bottom: 120,
          ),
          children: [
            Text(
              l10n.balancesTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: cs.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.balancesEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.balancesEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _V0BalancesHero extends StatelessWidget {
  const _V0BalancesHero({
    required this.allSettled,
    required this.settleHeadline,
    required this.edgesCount,
    required this.totalSpentLabel,
    required this.avgPerPersonLabel,
    required this.l10n,
  });

  final bool allSettled;
  final String settleHeadline;
  final int edgesCount;
  final String totalSpentLabel;
  final String avgPerPersonLabel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final gradient = allSettled
        ? const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: (allSettled ? const Color(0xFF059669) : const Color(0xFFEA580C))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allSettled ? Icons.check_circle_outline : Icons.payments_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    allSettled
                        ? l10n.balancesHeroStatus
                        : l10n.balancesHeroToSettle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                settleHeadline,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                allSettled
                    ? l10n.balancesHeroEveryoneEven
                    : l10n.balancesHeroPaymentsNeeded(edgesCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniStat(
                      label: l10n.balancesTotalSpentLabel,
                      value: totalSpentLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HeroMiniStat(
                      label: l10n.balancesAvgPerPersonLabel,
                      value: avgPerPersonLabel,
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

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightMiniCard extends StatelessWidget {
  const _InsightMiniCard({
    required this.title,
    required this.name,
    required this.color,
    required this.bg,
    required this.down,
  });

  final String title;
  final String name;
  final Color color;
  final Color bg;
  final bool down;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              down ? Icons.trending_down : Icons.trending_up,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.85),
                        letterSpacing: 0.4,
                      ),
                ),
                Text(
                  name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.95),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonBalanceTile extends StatelessWidget {
  const _PersonBalanceTile({
    required this.name,
    required this.balanceMinor,
    required this.currencyCode,
    required this.locale,
    required this.l10n,
  });

  final String name;
  final int balanceMinor;
  final String currencyCode;
  final Locale locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settled = balanceMinor.abs() < 1;
    final positive = balanceMinor > 1;
    final bg = settled
        ? cs.surfaceContainerHighest
        : positive
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFF1F2);
    final fg = settled
        ? cs.onSurfaceVariant
        : positive
            ? const Color(0xFF059669)
            : const Color(0xFFE11D48);
    final label = settled
        ? l10n.balancesNetSettled
        : positive
            ? l10n.balancesNetGetsBack
            : l10n.balancesNetOwes;
    final amountLabel = settled
        ? formatCurrencyAmount(
            amount: 0,
            currencyCode: currencyCode,
            locale: locale,
          )
        : formatCurrencyAmount(
            amount: minorUnitsToAmount(balanceMinor.abs(), currencyCode),
            currencyCode: currencyCode,
            locale: locale,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              splitBaeDisplayInitials(name),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            amountLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }
}
