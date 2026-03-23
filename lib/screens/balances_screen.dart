import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:splitbae/app_settings.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/domain/bills_insights.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/theme/splitbae_semantic_colors.dart';
import 'package:splitbae/core/ui/splitbae_motion.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/settlement.dart' show SettlementEdge;

part 'balances_embedded_part.dart';

/// Suggested settlement edges (Rust) + recorded settlement transfer rows.
class BalancesScreen extends ConsumerStatefulWidget {
  const BalancesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends ConsumerState<BalancesScreen> {
  String? _expandedSettlementKey;

  String _keyFor(SettlementEdge e) =>
      '${e.fromParticipantId}|${e.toParticipantId}|${e.currencyCode}|${e.amountMinor}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final participants = ref.watch(participantsProvider);
    final nameById = {for (final p in participants) p.id: p.displayName};

    final balancesAsync = ref.watch(balancesFeedProvider);
    final recordedAsync = ref.watch(settlementTransfersListProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settlementPayerModelHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.settleUpSectionTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        balancesAsync.when(
          data: (edges) {
            if (edges.isEmpty) {
              final empty = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  l10n.allSettledUp,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
              return splitBaeAnimationsEnabled(context)
                  ? empty
                      .animate()
                      .fadeIn(
                        duration: splitBaeMountDuration(context),
                        curve: splitBaeMountCurve(context),
                      )
                  : empty;
            }
            return Column(
              children: [
                for (var i = 0; i < edges.length; i++)
                  Builder(
                    builder: (context) {
                      final edge = edges[i];
                      final key = _keyFor(edge);
                      final fromName =
                          nameById[edge.fromParticipantId] ??
                              edge.fromParticipantId;
                      final toName =
                          nameById[edge.toParticipantId] ??
                              edge.toParticipantId;
                      final minor = int.parse(edge.amountMinor.toString());
                      final amount = minorUnitsToAmount(
                        minor,
                        edge.currencyCode,
                      );
                      final amountLabel = formatCurrencyAmount(
                        amount: amount,
                        currencyCode: edge.currencyCode,
                        locale: locale,
                      );
                      final card = _SettlementEdgeCard(
                        key: ValueKey(key),
                        edge: edge,
                        fromName: fromName,
                        toName: toName,
                        amountLabel: amountLabel,
                        maxMinor: minor,
                        currencyCode: edge.currencyCode,
                        locale: locale,
                        expanded: _expandedSettlementKey == key,
                        onExpand: () =>
                            setState(() => _expandedSettlementKey = key),
                        onCollapse: () =>
                            setState(() => _expandedSettlementKey = null),
                      );
                      if (!splitBaeAnimationsEnabled(context)) return card;
                      return card
                          .animate()
                          .fadeIn(
                            duration: splitBaeMountDuration(context),
                            delay: splitBaeStaggerDelay(context, i),
                            curve: splitBaeMountCurve(context),
                          )
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: splitBaeMountDuration(context),
                            delay: splitBaeStaggerDelay(context, i),
                            curve: splitBaeMountCurve(context),
                          );
                    },
                  ),
              ],
            );
          },
          loading: () => const _BalancesLoadingSkeleton(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$e',
              style: TextStyle(color: context.splitBaeSemantic.destructive),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            l10n.recordedSettlementsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        recordedAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: rows.map((r) {
                final fromName =
                    nameById[r.fromParticipantId] ?? r.fromParticipantId;
                final toName = nameById[r.toParticipantId] ?? r.toParticipantId;
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
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) =>
              Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
        ),
      ],
    );

    if (widget.embedded) {
      return const _BalancesEmbeddedV0();
    }

    return Scaffold(
      appBar: splitBaeAdaptiveAppBar(
        context: context,
        title: l10n.balancesTitle,
      ),
      body: SingleChildScrollView(child: content),
    );
  }
}

class _BalancesLoadingSkeleton extends StatelessWidget {
  const _BalancesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    final disableMotion = !splitBaeAnimationsEnabled(context);
    final base = m3e.colors.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(3, (index) {
          final row = Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: m3e.colors.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: m3e.colors.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (disableMotion) return row;
          return row
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1400.ms,
                delay: splitBaeStaggerDelay(context, index),
                color: m3e.colors.onSurface.withValues(alpha: 0.14),
              );
        }),
      ),
    );
  }
}

class _SettlementEdgeCard extends ConsumerStatefulWidget {
  const _SettlementEdgeCard({
    super.key,
    required this.edge,
    required this.fromName,
    required this.toName,
    required this.amountLabel,
    required this.maxMinor,
    required this.currencyCode,
    required this.locale,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
  });

  final SettlementEdge edge;
  final String fromName;
  final String toName;
  final String amountLabel;
  final int maxMinor;
  final String currencyCode;
  final Locale locale;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  ConsumerState<_SettlementEdgeCard> createState() =>
      _SettlementEdgeCardState();
}

class _SettlementEdgeCardState extends ConsumerState<_SettlementEdgeCard> {
  late final TextEditingController _partialCtrl;
  bool _partialMode = false;
  String? _partialError;

  @override
  void initState() {
    super.initState();
    _partialCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _partialCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SettlementEdgeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded && !widget.expanded) {
      _partialMode = false;
      _partialError = null;
      _partialCtrl.clear();
    }
  }

  void _useFullAmount() {
    final full = minorUnitsToAmount(widget.maxMinor, widget.currencyCode);
    setState(() {
      _partialError = null;
      _partialCtrl.text = amountToInputText(full, widget.currencyCode);
    });
  }

  Future<void> _recordFull() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showAdaptiveConfirmDialog(
      context: context,
      title: Text(l10n.recordSettlementConfirmTitle),
      content: Text(
        l10n.recordSettlementConfirmBody(
          widget.fromName,
          widget.toName,
          widget.amountLabel,
        ),
      ),
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.settleUpPayFull,
    );
    if (ok != true || !mounted) return;
    HapticFeedback.mediumImpact();
    await ref
        .read(settlementRepositoryProvider)
        .recordTransfer(
          ledgerId: kDefaultLedgerId,
          fromParticipantId: widget.edge.fromParticipantId,
          toParticipantId: widget.edge.toParticipantId,
          amountMinor: widget.maxMinor,
          currencyCode: widget.currencyCode,
        );
    ref.invalidate(settlementTransfersListProvider);
    ref.invalidate(balancesFeedProvider);
    widget.onCollapse();
  }

  Future<void> _recordPartial() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _partialError = null);
    final raw = _partialCtrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _partialError = l10n.settleUpPartialInvalid);
      return;
    }
    final minor = amountToMinorUnits(parsed, widget.currencyCode);
    if (minor <= 0 || minor > widget.maxMinor) {
      setState(() => _partialError = l10n.settleUpPartialInvalid);
      return;
    }
    HapticFeedback.mediumImpact();
    await ref
        .read(settlementRepositoryProvider)
        .recordTransfer(
          ledgerId: kDefaultLedgerId,
          fromParticipantId: widget.edge.fromParticipantId,
          toParticipantId: widget.edge.toParticipantId,
          amountMinor: minor,
          currencyCode: widget.currencyCode,
        );
    ref.invalidate(settlementTransfersListProvider);
    ref.invalidate(balancesFeedProvider);
    widget.onCollapse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final m3e = context.m3e;
    final sem = context.splitBaeSemantic;
    final paysColor = sem.balancePay;
    final receivesColor = sem.balanceReceive;

    Widget phosphorPersonAvatar({
      required Color backgroundColor,
      required Color foregroundColor,
      required String displayName,
    }) {
      return CircleAvatar(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.userCircle,
              size: 36,
              color: foregroundColor.withValues(alpha: 0.22),
            ),
            Text(
              splitBaeDisplayInitials(displayName),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Widget participantRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          phosphorPersonAvatar(
            backgroundColor: sem.balancePayContainer,
            foregroundColor: sem.onBalancePayContainer,
            displayName: widget.fromName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fromName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.settlementPayerPays,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: paysColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              PhosphorIconsRegular.arrowRight,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.toName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.settlementPayeeReceives,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: receivesColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          phosphorPersonAvatar(
            backgroundColor: sem.balanceReceiveContainer,
            foregroundColor: sem.onBalanceReceiveContainer,
            displayName: widget.toName,
          ),
        ],
      );
    }

    Widget edgeSurface({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: m3e.colors.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: m3e.colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      );
    }

    Widget amountRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              l10n.settleUpAmountLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            widget.amountLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    final settlementLabel = l10n.semanticsSettlementEdge(
      widget.fromName,
      widget.toName,
      widget.amountLabel,
    );

    if (!widget.expanded) {
      return Semantics(
        label: settlementLabel,
        expanded: false,
        button: true,
        child: edgeSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              participantRow(),
              const SizedBox(height: 12),
              Text(
                widget.currencyCode,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                widget.amountLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: widget.onExpand,
                icon: Icon(PhosphorIconsRegular.currencyCircleDollar, size: 20),
                label: Text(l10n.markAsPaid),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: settlementLabel,
      expanded: true,
      child: edgeSurface(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              participantRow(),
              const SizedBox(height: 12),
              amountRow(),
              if (!_partialMode) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _partialMode = true;
                      _partialError = null;
                      _partialCtrl.clear();
                    }),
                    icon: Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                    label: Text(l10n.settleUpPartialPayment),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCollapse,
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _recordFull,
                        icon: Icon(PhosphorIconsRegular.check, size: 20),
                        label: Text(l10n.settleUpPayFull),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _useFullAmount,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                      label: Text(l10n.settleUpUseFullAmount),
                    ),
                    const Spacer(),
                    Text(
                      l10n.settleUpAmountOfTotal(widget.amountLabel),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _partialCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    hintText: l10n.settleUpPartialHint,
                    errorText: _partialError,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCollapse,
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _recordPartial,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        icon: Icon(PhosphorIconsRegular.check, size: 20),
                        label: Text(l10n.settleUpPayPartial),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
    );
  }
}

void openBalancesScreen(BuildContext context) {
  if (hostPlatformIsApple()) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const BalancesScreen()));
  } else {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BalancesScreen()));
  }
}
