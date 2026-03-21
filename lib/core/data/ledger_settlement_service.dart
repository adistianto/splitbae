import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import 'amount_minor.dart';
import 'bill_payment_validation.dart';
import 'draft_payment_repository.dart';
import 'line_item_repository.dart';
import 'participant_repository.dart';
import '../../src/rust/api/simple.dart' as rust;
import '../../src/rust/api/settlement.dart';

/// Builds [NetBalance] rows (paid − owed ± recorded settlements) and runs Rust netting.
///
/// **Paid** amounts come from `transaction_payments` on the draft bill (per currency).
/// Rows are seeded when the bill has lines so totals match; use **Who paid** to edit.
class LedgerSettlementService {
  LedgerSettlementService(this._db);

  final AppDatabase _db;

  Future<List<NetBalance>> computeNetBalances(String ledgerId) async {
    final participants = await ParticipantRepository(
      _db,
    ).listParticipants(ledgerId);
    if (participants.isEmpty) return [];

    final lines = await LineItemRepository(_db).listLedgerLines(ledgerId);
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final settlementRows = await (_db.select(_db.settlementTransfers)
          ..where((t) => t.ledgerId.equals(ledgerId)))
        .get();

    if (lines.isEmpty && settlementRows.isEmpty) return [];

    final lineRows = await (_db.select(_db.receiptLines)
          ..where((t) => t.ledgerId.equals(ledgerId))
          ..where((t) => t.transactionId.equals(draftTx)))
        .get();

    final totalByCcy = <String, int>{};
    for (final r in lineRows) {
      totalByCcy[r.currencyCode] =
          (totalByCcy[r.currencyCode] ?? 0) + r.amountMinor;
    }

    final paymentRows = await DraftPaymentRepository(_db).listForDraft(ledgerId);
    final payerId = participants.first.id;

    final lineTotalsForValidate = <rust.LineTotalMinor>[];
    for (final e in totalByCcy.entries) {
      if (e.value > 0) {
        lineTotalsForValidate.add(
          rust.LineTotalMinor(
            currencyCode: e.key,
            amountMinor: PlatformInt64Util.from(e.value),
          ),
        );
      }
    }

    if (lineTotalsForValidate.isNotEmpty) {
      final paymentsForValidate = <rust.DraftPaymentMinor>[];
      if (paymentRows.isEmpty) {
        for (final e in totalByCcy.entries) {
          if (e.value <= 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: payerId,
              currencyCode: e.key,
              amountMinor: PlatformInt64Util.from(e.value),
            ),
          );
        }
      } else {
        for (final r in paymentRows) {
          if (r.amountMinor == 0) continue;
          paymentsForValidate.add(
            rust.DraftPaymentMinor(
              participantId: r.participantId,
              currencyCode: r.currencyCode,
              amountMinor: PlatformInt64Util.from(r.amountMinor),
            ),
          );
        }
      }
      try {
        rust.validateBillPaymentsSum(
          lineTotalsMinor: lineTotalsForValidate,
          payments: paymentsForValidate,
        );
      } catch (e) {
        throw BillPaymentsMismatchException(e.toString());
      }
    }

    final splits = rust.calculateSplitAssigned(
      lines: lines
          .map(
            (e) => rust.AssignedReceiptLine(
              item: e.receiptItem,
              assigneeIds: e.assignedParticipantIds,
            ),
          )
          .toList(),
      participants: participants
          .map(
            (e) => rust.ParticipantRef(id: e.id, displayName: e.displayName),
          )
          .toList(),
    );

    final net = <String, Map<String, int>>{};
    for (final p in participants) {
      net[p.id] = {};
    }

    void bump(String participantId, String currencyCode, int delta) {
      final m = net[participantId]!;
      m[currencyCode] = (m[currencyCode] ?? 0) + delta;
    }

    for (final row in splits) {
      final owedMinor = amountToMinorUnits(row.totalOwed, row.currencyCode);
      bump(row.participantId, row.currencyCode, -owedMinor);
    }

    if (lineTotalsForValidate.isNotEmpty) {
      if (paymentRows.isEmpty) {
        for (final e in totalByCcy.entries) {
          if (e.value > 0) {
            bump(payerId, e.key, e.value);
          }
        }
      } else {
        for (final r in paymentRows) {
          if (r.amountMinor != 0) {
            bump(r.participantId, r.currencyCode, r.amountMinor);
          }
        }
      }
    }

    for (final s in settlementRows) {
      bump(s.fromParticipantId, s.currencyCode, s.amountMinor);
      bump(s.toParticipantId, s.currencyCode, -s.amountMinor);
    }

    final allCcy = <String>{};
    for (final m in net.values) {
      allCcy.addAll(m.keys);
    }

    for (final ccy in allCcy) {
      var sum = 0;
      for (final p in participants) {
        sum += net[p.id]![ccy] ?? 0;
      }
      if (sum != 0) {
        bump(payerId, ccy, -sum);
      }
    }

    final out = <NetBalance>[];
    for (final p in participants) {
      final m = net[p.id]!;
      for (final e in m.entries) {
        if (e.value != 0) {
          out.add(
            NetBalance(
              participantId: p.id,
              amountMinor: PlatformInt64Util.from(e.value),
              currencyCode: e.key,
            ),
          );
        }
      }
    }
    return out;
  }

  Future<List<SettlementEdge>> suggestedEdges(String ledgerId) async {
    final nets = await computeNetBalances(ledgerId);
    if (nets.isEmpty) return [];
    return calculateMinimalSettlementEdges(balances: nets);
  }
}
