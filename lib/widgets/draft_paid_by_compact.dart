import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:splitbae/core/data/amount_minor.dart' as amt;
import 'package:splitbae/core/data/draft_payment_repository.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/domain/participant_entry.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/core/widgets/adaptive_app_bar.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart' as rust;
import 'package:uuid/uuid.dart';

import 'package:splitbae/core/database/app_database.dart' show TransactionPayment;
import 'package:splitbae/widgets/who_paid_sheet.dart';

/// v0-style **Paid by**: one person vs split (single recording currency on draft).
/// Multiple currencies open the full [showWhoPaidSheet].
class DraftPaidByCompact extends ConsumerStatefulWidget {
  const DraftPaidByCompact({super.key});

  @override
  ConsumerState<DraftPaidByCompact> createState() => _DraftPaidByCompactState();
}

enum _PaidMode { single, split }

class _DraftPaidByCompactState extends ConsumerState<DraftPaidByCompact> {
  _PaidMode _mode = _PaidMode.single;
  String? _singlePayerId;
  final _splitControllers = <String, TextEditingController>{};
  String? _error;
  bool _splitDirty = false;
  bool _didInitFromPayments = false;

  @override
  void dispose() {
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, int> _totalsMinorFromItems() {
    final items = ref.read(itemsProvider);
    final m = <String, int>{};
    for (final line in items) {
      final ccy = line.receiptItem.currencyCode;
      final mi = amt.amountToMinorUnits(line.receiptItem.price, ccy);
      m[ccy] = (m[ccy] ?? 0) + mi;
    }
    return m;
  }

  void _ensureSplitControllers(
    List<ParticipantEntry> people,
    List<TransactionPayment> payments,
    String ccy,
  ) {
    for (final p in people) {
      _splitControllers.putIfAbsent(
        p.id,
        () => TextEditingController(),
      );
    }
    for (final k in _splitControllers.keys.toList()) {
      if (!people.any((p) => p.id == k)) {
        _splitControllers.remove(k)?.dispose();
      }
    }
    for (final p in people) {
      final paid = payments
          .where((x) => x.participantId == p.id && x.currencyCode == ccy)
          .fold<int>(0, (a, b) => a + b.amountMinor);
      final paidAmount = amt.minorUnitsToAmount(paid, ccy);
      final c = _splitControllers[p.id]!;
      final t = amt.amountToInputText(paidAmount, ccy);
      if (c.text != t) c.text = t;
    }
  }

  Future<void> _applySplitSave(AppLocalizations l10n, String ccy) async {
    setState(() => _error = null);
    final totals = _totalsMinorFromItems();
    final totalMinor = totals[ccy] ?? 0;
    if (totalMinor <= 0) return;

    final participants =
        await ref.read(draftBillActiveParticipantsProvider.future);
    final lineTotals = [
      rust.LineTotalMinor(
        currencyCode: ccy,
        amountMinor: PlatformInt64Util.from(totalMinor),
      ),
    ];
    final payments = <rust.DraftPaymentMinor>[];
    final rows = <TransactionPayment>[];
    final uuid = const Uuid();
    final draftTx = draftTransactionIdForLedger(kDefaultLedgerId);

    for (final p in participants) {
      final ctrl = _splitControllers[p.id];
      if (ctrl == null) continue;
      final raw = ctrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
      if (raw.isEmpty) continue;
      final parsed = double.tryParse(raw);
      if (parsed == null || parsed <= 0) continue;
      final minor = amt.amountToMinorUnits(parsed, ccy);
      payments.add(
        rust.DraftPaymentMinor(
          participantId: p.id,
          currencyCode: ccy,
          amountMinor: PlatformInt64Util.from(minor),
        ),
      );
      rows.add(
        TransactionPayment(
          id: uuid.v4(),
          transactionId: draftTx,
          participantId: p.id,
          amountMinor: minor,
          currencyCode: ccy,
        ),
      );
    }

    try {
      rust.validateBillPaymentsSum(
        lineTotalsMinor: lineTotals,
        payments: payments,
      );
    } catch (e) {
      setState(() => _error = e.toString());
      return;
    }

    await DraftPaymentRepository(ref.read(appDatabaseProvider))
        .replaceDraftPayments(ledgerId: kDefaultLedgerId, rows: rows);
    ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
    setState(() {
      _splitDirty = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;

    ref.watch(itemsProvider);
    ref.watch(draftBillInclusionRevisionProvider);
    final payAsync = ref.watch(draftTransactionPaymentsProvider);
    final payments = payAsync.asData?.value ?? <TransactionPayment>[];
    final peopleAsync = ref.watch(draftBillActiveParticipantsProvider);

    ref.listen<AsyncValue<List<TransactionPayment>>>(
      draftTransactionPaymentsProvider,
      (prev, next) {
        next.whenData((list) {
          if (_didInitFromPayments || !mounted) return;
          final totals = _totalsMinorFromItems();
          final positive = totals.entries.where((e) => e.value > 0).toList();
          if (positive.length != 1) return;
          final ccy = positive.first.key;
          final payers = list
              .where((p) => p.currencyCode == ccy && p.amountMinor > 0)
              .map((p) => p.participantId)
              .toSet();
          final currentPeople =
              ref.read(draftBillActiveParticipantsProvider).valueOrNull ?? [];
          if (payers.length > 1) {
            setState(() {
              _mode = _PaidMode.split;
              _didInitFromPayments = true;
            });
            _ensureSplitControllers(currentPeople, list, ccy);
          } else if (payers.length == 1) {
            setState(() {
              _mode = _PaidMode.single;
              _singlePayerId = payers.first;
              _didInitFromPayments = true;
            });
          }
        });
      },
    );

    final totals = _totalsMinorFromItems();
    final positive = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return peopleAsync.when(
      data: (people) {
        if (people.isEmpty || positive.isEmpty) {
          return const SizedBox.shrink();
        }

        return _paidByBody(
          context,
          ref,
          l10n,
          locale,
          scheme,
          people,
          positive,
          payments,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _paidByBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Locale locale,
    ColorScheme scheme,
    List<ParticipantEntry> people,
    List<MapEntry<String, int>> positive,
    List<TransactionPayment> payments,
  ) {
    if (positive.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.paidByMultiCurrencyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showWhoPaidSheet(context, ref),
            icon: const Icon(Icons.payments_outlined),
            label: Text(l10n.whoPaidTitle),
          ),
        ],
      );
    }

    final ccy = positive.first.key;
    final totalMinor = positive.first.value;
    final totalAmount = amt.minorUnitsToAmount(totalMinor, ccy);

    if (_mode == _PaidMode.split) {
      _ensureSplitControllers(people, payments, ccy);
    }

    if (_mode == _PaidMode.single && _singlePayerId == null && people.isNotEmpty) {
      _singlePayerId = people.first.id;
    }

    int splitSumMinor() {
      var s = 0;
      for (final p in people) {
        final ctrl = _splitControllers[p.id];
        if (ctrl == null) continue;
        final raw = ctrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
        if (raw.isEmpty) continue;
        final parsed = double.tryParse(raw);
        if (parsed == null || parsed <= 0) continue;
        s += amt.amountToMinorUnits(parsed, ccy);
      }
      return s;
    }

    final balance = totalMinor - splitSumMinor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.whoPaidTitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SegmentedButton<_PaidMode>(
              segments: [
                ButtonSegment(
                  value: _PaidMode.single,
                  label: Text(l10n.paidByModeSingle),
                ),
                ButtonSegment(
                  value: _PaidMode.split,
                  label: Text(l10n.paidByModeSplit),
                ),
              ],
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              selected: {_mode},
              onSelectionChanged: (s) async {
                if (s.isEmpty) return;
                final m = s.first;
                setState(() => _mode = m);
                if (m == _PaidMode.single) {
                  final id = _singlePayerId ?? people.first.id;
                  _singlePayerId = id;
                  await ref
                      .read(draftPaymentRepositoryProvider)
                      .setSinglePayerFull(kDefaultLedgerId, id);
                  ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
                } else {
                  _ensureSplitControllers(people, payments, ccy);
                  setState(() => _splitDirty = true);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.whoPaidBillTotalLabel}: ${formatCurrencyAmount(amount: totalAmount, currencyCode: ccy, locale: locale)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        if (_mode == _PaidMode.single) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in people)
                FilterChip(
                  showCheckmark: false,
                  selected: _singlePayerId == p.id,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          splitBaeInitialGrapheme(p.displayName),
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(p.displayName, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  onSelected: (_) async {
                    setState(() => _singlePayerId = p.id);
                    await ref
                        .read(draftPaymentRepositoryProvider)
                        .setSinglePayerFull(kDefaultLedgerId, p.id);
                    ref.read(draftPaymentsDbRevisionProvider.notifier).state++;
                  },
                ),
            ],
          ),
        ] else ...[
          for (final p in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _splitControllers[p.id],
                onChanged: (_) => setState(() {
                  _splitDirty = true;
                  _error = null;
                }),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: p.displayName,
                  prefixText: '$ccy ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: balance.abs() < 2
                  ? scheme.primaryContainer.withValues(alpha: 0.35)
                  : scheme.tertiaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  balance == 0
                      ? l10n.paidByBalanced
                      : l10n.paidByRemainingLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  formatCurrencyAmount(
                    amount: amt.minorUnitsToAmount(balance.abs(), ccy),
                    currencyCode: ccy,
                    locale: locale,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (_splitDirty) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _applySplitSave(l10n, ccy),
              child: Text(l10n.whoPaidSave),
            ),
          ],
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
