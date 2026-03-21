import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/platform/adaptive_confirm_dialog.dart';
import 'package:splitbae/core/platform/host_platform.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';

import '../core/data/amount_minor.dart';

/// Suggested settlement edges (Rust) + recorded settlement transfer rows.
class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final participants = ref.watch(participantsProvider);
    final nameById = {for (final p in participants) p.id: p.displayName};

    final suggestedAsync = ref.watch(suggestedSettlementEdgesProvider);
    final recordedAsync = ref.watch(settlementTransfersListProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            l10n.suggestedSettlementsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        suggestedAsync.when(
          data: (edges) {
            if (edges.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.allSettledUp,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }
            return Column(
              children: edges.map((edge) {
                final fromName =
                    nameById[edge.fromParticipantId] ?? edge.fromParticipantId;
                final toName =
                    nameById[edge.toParticipantId] ?? edge.toParticipantId;
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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text('$fromName → $toName'),
                    subtitle: Text(edge.currencyCode),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          amountLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final ok = await showAdaptiveConfirmDialog(
                              context: context,
                              title: Text(l10n.recordSettlementConfirmTitle),
                              content: Text(
                                l10n.recordSettlementConfirmBody(
                                  fromName,
                                  toName,
                                  amountLabel,
                                ),
                              ),
                              cancelLabel: l10n.cancel,
                              confirmLabel: l10n.recordSettlementAction,
                            );
                            if (ok != true || !context.mounted) return;
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(settlementRepositoryProvider)
                                .recordTransfer(
                                  ledgerId: kDefaultLedgerId,
                                  fromParticipantId: edge.fromParticipantId,
                                  toParticipantId: edge.toParticipantId,
                                  amountMinor: minor,
                                  currencyCode: edge.currencyCode,
                                );
                            ref.invalidate(settlementTransfersListProvider);
                          },
                          child: Text(l10n.recordSettlementAction),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                final toName =
                    nameById[r.toParticipantId] ?? r.toParticipantId;
                final amount = minorUnitsToAmount(
                  r.amountMinor,
                  r.currencyCode,
                );
                final amountLabel = formatCurrencyAmount(
                  amount: amount,
                  currencyCode: r.currencyCode,
                  locale: locale,
                );
                return ListTile(
                  dense: true,
                  title: Text('$fromName → $toName'),
                  subtitle: Text(r.currencyCode),
                  trailing: Text(amountLabel),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
        ),
      ],
    );

    if (embedded) {
      return SingleChildScrollView(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.balancesTitle),
      ),
      body: SingleChildScrollView(child: content),
    );
  }
}

void openBalancesScreen(BuildContext context) {
  if (hostPlatformIsApple()) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const BalancesScreen(),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BalancesScreen(),
      ),
    );
  }
}
