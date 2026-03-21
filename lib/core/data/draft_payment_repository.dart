import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import 'participant_repository.dart';

/// Draft bill `transaction_payments` rows (per participant × currency).
class DraftPaymentRepository {
  DraftPaymentRepository(this._db);

  final AppDatabase _db;

  Future<List<TransactionPayment>> listForDraft(String ledgerId) async {
    final txId = draftTransactionIdForLedger(ledgerId);
    return (_db.select(_db.transactionPayments)
          ..where((t) => t.transactionId.equals(txId)))
        .get();
  }

  Future<Map<String, int>> draftLineTotalsByCurrency(String ledgerId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final lineRows = await (_db.select(_db.receiptLines)
          ..where((t) => t.ledgerId.equals(ledgerId))
          ..where((t) => t.transactionId.equals(draftTx)))
        .get();
    final totalByCcy = <String, int>{};
    for (final r in lineRows) {
      totalByCcy[r.currencyCode] =
          (totalByCcy[r.currencyCode] ?? 0) + r.amountMinor;
    }
    return totalByCcy;
  }

  Future<void> replaceDraftPayments({
    required String ledgerId,
    required List<TransactionPayment> rows,
  }) async {
    final txId = draftTransactionIdForLedger(ledgerId);
    await _db.transaction(() async {
      await (_db.delete(_db.transactionPayments)
            ..where((t) => t.transactionId.equals(txId)))
          .go();
      for (final r in rows) {
        await _db.into(_db.transactionPayments).insert(
              TransactionPaymentsCompanion.insert(
                id: r.id,
                transactionId: txId,
                participantId: r.participantId,
                amountMinor: r.amountMinor,
                currencyCode: Value(r.currencyCode),
              ),
            );
      }
    });
  }

  /// Clears draft payments when there are no bill lines; otherwise seeds the first
  /// participant as paying each currency total when no rows exist.
  Future<void> syncDraftPaymentsWithBill(String ledgerId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final totals = await draftLineTotalsByCurrency(ledgerId);
    final hasPositiveLines = totals.values.any((v) => v > 0);

    if (!hasPositiveLines) {
      await (_db.delete(_db.transactionPayments)
            ..where((t) => t.transactionId.equals(draftTx)))
          .go();
      return;
    }

    final existing = await (_db.select(_db.transactionPayments)
          ..where((t) => t.transactionId.equals(draftTx)))
        .get();
    if (existing.isNotEmpty) return;

    final participants = await ParticipantRepository(_db).listParticipants(ledgerId);
    if (participants.isEmpty) return;

    final payerId = participants.first.id;
    final uuid = const Uuid();
    await _db.transaction(() async {
      for (final e in totals.entries) {
        if (e.value <= 0) continue;
        await _db.into(_db.transactionPayments).insert(
              TransactionPaymentsCompanion.insert(
                id: uuid.v4(),
                transactionId: draftTx,
                participantId: payerId,
                amountMinor: e.value,
                currencyCode: Value(e.key),
              ),
            );
      }
    });
  }

  Future<void> resetToFirstPayerFull(String ledgerId) async {
    final participants = await ParticipantRepository(_db).listParticipants(ledgerId);
    if (participants.isEmpty) return;
    await setSinglePayerFull(ledgerId, participants.first.id);
  }

  /// One participant pays the full line-total for each currency (no tax).
  Future<void> setSinglePayerFull(String ledgerId, String participantId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final totals = await draftLineTotalsByCurrency(ledgerId);
    final uuid = const Uuid();
    final rows = <TransactionPayment>[];
    for (final e in totals.entries) {
      if (e.value <= 0) continue;
      rows.add(
        TransactionPayment(
          id: uuid.v4(),
          transactionId: draftTx,
          participantId: participantId,
          amountMinor: e.value,
          currencyCode: e.key,
        ),
      );
    }
    await replaceDraftPayments(ledgerId: ledgerId, rows: rows);
  }
}
