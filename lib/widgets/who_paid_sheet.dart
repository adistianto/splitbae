import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:splitbae/core/data/amount_minor.dart';
import 'package:splitbae/core/data/draft_payment_repository.dart';
import 'package:splitbae/core/database/app_database.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/l10n/app_localizations.dart';
import 'package:splitbae/money_format.dart';
import 'package:splitbae/providers.dart';
import 'package:splitbae/src/rust/api/simple.dart' as rust;
import 'package:uuid/uuid.dart';

/// iOS: glass-style modal. Android: M3 bottom sheet.
Future<void> showWhoPaidSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: const WhoPaidSheet(),
        ),
      );
    },
  );
}

class WhoPaidSheet extends ConsumerStatefulWidget {
  const WhoPaidSheet({super.key});

  @override
  ConsumerState<WhoPaidSheet> createState() => _WhoPaidSheetState();
}

class _WhoPaidSheetState extends ConsumerState<WhoPaidSheet> {
  bool _loading = true;
  String? _error;
  Map<String, int> _totalsByCcy = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final repo = DraftPaymentRepository(db);
    final totals = await repo.draftLineTotalsByCurrency(kDefaultLedgerId);
    final payments = await repo.listForDraft(kDefaultLedgerId);
    final participants = ref.read(participantsProvider);

    final paid = <String, Map<String, int>>{};
    for (final p in payments) {
      final m = paid.putIfAbsent(p.participantId, () => {});
      m[p.currencyCode] = (m[p.currencyCode] ?? 0) + p.amountMinor;
    }

    final ccys = totals.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList()
      ..sort();

    for (final participant in participants) {
      for (final ccy in ccys) {
        final key = '${participant.id}|$ccy';
        final minor = paid[participant.id]?[ccy] ?? 0;
        final amount = minorUnitsToAmount(minor, ccy);
        _controllers[key] = TextEditingController(
          text: amountToInputText(amount, ccy),
        );
      }
    }

    if (mounted) {
      setState(() {
        _totalsByCcy = totals;
        _loading = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _error = null);
    final positiveCcys = _totalsByCcy.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (positiveCcys.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final participants = ref.read(participantsProvider);
    final lineTotals = _totalsByCcy.entries
        .where((e) => e.value > 0)
        .map(
          (e) => rust.LineTotalMinor(
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        )
        .toList();
    final payments = <rust.DraftPaymentMinor>[];

    for (final participant in participants) {
      for (final ccy in positiveCcys) {
        final key = '${participant.id}|$ccy';
        final ctrl = _controllers[key];
        if (ctrl == null) continue;
        final raw = ctrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
        if (raw.isEmpty) continue;
        final parsed = double.tryParse(raw);
        if (parsed == null || parsed <= 0) continue;
        final minor = amountToMinorUnits(parsed, ccy);
        payments.add(
          rust.DraftPaymentMinor(
            participantId: participant.id,
            currencyCode: ccy,
            amountMinor: PlatformInt64Util.from(minor),
          ),
        );
      }
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

    final draftTx = draftTransactionIdForLedger(kDefaultLedgerId);
    final rows = <TransactionPayment>[];
    final uuid = const Uuid();
    for (final participant in participants) {
      for (final ccy in positiveCcys) {
        final key = '${participant.id}|$ccy';
        final ctrl = _controllers[key];
        if (ctrl == null) continue;
        final raw = ctrl.text.trim().replaceAll(RegExp(r'[^\d.]'), '');
        if (raw.isEmpty) continue;
        final parsed = double.tryParse(raw);
        if (parsed == null || parsed <= 0) continue;
        final minor = amountToMinorUnits(parsed, ccy);
        rows.add(
          TransactionPayment(
            id: uuid.v4(),
            transactionId: draftTx,
            participantId: participant.id,
            amountMinor: minor,
            currencyCode: ccy,
          ),
        );
      }
    }

    await DraftPaymentRepository(ref.read(appDatabaseProvider))
        .replaceDraftPayments(ledgerId: kDefaultLedgerId, rows: rows);
    ref.invalidate(draftTransactionPaymentsProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await ref.read(draftPaymentRepositoryProvider).resetToFirstPayerFull(
          kDefaultLedgerId,
        );
    ref.invalidate(draftTransactionPaymentsProvider);
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final positiveCcys = _totalsByCcy.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (positiveCcys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.whoPaidEmptyBill),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    }

    final participants = ref.watch(participantsProvider);
    if (participants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.emptyParticipantsHint),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    }

    final maxH = MediaQuery.sizeOf(context).height * 0.55;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.whoPaidTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.whoPaidSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: maxH,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final ccy in positiveCcys) ...[
                    Builder(
                      builder: (context) {
                        final totalMinor = _totalsByCcy[ccy] ?? 0;
                        final amount = minorUnitsToAmount(totalMinor, ccy);
                        final totalLabel = formatCurrencyAmount(
                          amount: amount,
                          currencyCode: ccy,
                          locale: locale,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '$ccy · ${l10n.whoPaidBillTotalLabel}: $totalLabel',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        );
                      },
                    ),
                    for (final p in participants)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _controllers['${p.id}|$ccy'],
                          decoration: InputDecoration(
                            labelText: '${p.displayName} ($ccy)',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _reset,
                child: Text(l10n.whoPaidReset),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _save(l10n),
                child: Text(l10n.whoPaidSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
