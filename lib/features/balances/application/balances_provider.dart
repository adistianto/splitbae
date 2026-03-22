import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/ledger_ids.dart';
import '../../../src/rust/api/settlement.dart';

/// Loads posted [transaction_split_obligations] + [transaction_payments] for the ledger,
/// maps to Rust structs, applies [settlement_transfers], and returns **pairwise** net edges.
/// All aggregation and cancellation math runs in Rust ([calculateNetBalances]).
Future<List<SettlementEdge>> loadBalancesFeed({
  required AppDatabase db,
  required String ledgerId,
}) async {
  final draftId = draftTransactionIdForLedger(ledgerId);
  final postedTxs =
      await (db.select(db.transactions)
            ..where((t) => t.ledgerId.equals(ledgerId))
            ..where((t) => t.kind.equals('normal'))
            ..where((t) => t.id.isNotValue(draftId)))
          .get();
  final txIds = postedTxs.map((t) => t.id).toList();

  final obligations = <SplitObligationRow>[];
  final payments = <SplitPaymentRow>[];

  if (txIds.isNotEmpty) {
    final oRows =
        await (db.select(
          db.transactionSplitObligations,
        )..where((o) => o.transactionId.isIn(txIds))).get();
    for (final o in oRows) {
      obligations.add(
        SplitObligationRow(
          transactionId: o.transactionId,
          owerId: o.participantId,
          amountMinor: PlatformInt64Util.from(o.amountMinor),
          currencyCode: o.currencyCode,
        ),
      );
    }

    final pRows =
        await (db.select(
          db.transactionPayments,
        )..where((p) => p.transactionId.isIn(txIds))).get();
    for (final p in pRows) {
      payments.add(
        SplitPaymentRow(
          transactionId: p.transactionId,
          payerId: p.participantId,
          amountMinor: PlatformInt64Util.from(p.amountMinor),
          currencyCode: p.currencyCode,
        ),
      );
    }
  }

  final settlementRows =
      await (db.select(
        db.settlementTransfers,
      )..where((s) => s.ledgerId.equals(ledgerId))).get();

  final recorded = <SettlementEdge>[];
  for (final s in settlementRows) {
    recorded.add(
      SettlementEdge(
        fromParticipantId: s.fromParticipantId,
        toParticipantId: s.toParticipantId,
        amountMinor: PlatformInt64Util.from(s.amountMinor),
        currencyCode: s.currencyCode.trim().toUpperCase(),
      ),
    );
  }

  return calculateNetBalances(
    obligations: obligations,
    payments: payments,
    recordedSettlements: recorded,
  );
}
