import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/participant_entry.dart';
import 'participant_repository.dart';

/// Draft bill `transaction_payments` rows (per participant × currency).
class DraftPaymentRepository {
  DraftPaymentRepository(this._db);

  final AppDatabase _db;

  Future<Set<String>> _effectiveIncludedIds(
    String ledgerId,
    List<ParticipantEntry> ledgerParticipants,
  ) async {
    final rows =
        await (_db.select(_db.draftBillIncludedParticipants)
              ..where((t) => t.ledgerId.equals(ledgerId)))
            .get();
    final explicit = rows.map((e) => e.participantId).toSet();
    if (explicit.isEmpty) {
      return ledgerParticipants.map((e) => e.id).toSet();
    }
    return explicit;
  }

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

    final included = await _effectiveIncludedIds(ledgerId, participants);
    if (included.isEmpty) return;

    final payerId = participants.firstWhere((p) => included.contains(p.id)).id;
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
    final included = await _effectiveIncludedIds(ledgerId, participants);
    if (included.isEmpty) return;
    final payerId = participants.firstWhere((p) => included.contains(p.id)).id;
    await setSinglePayerFull(ledgerId, payerId);
  }

  /// Drops payment rows for participants not on this bill; **Who paid** is reset
  /// to a single payer when the inclusion set changes.
  Future<void> syncAfterInclusionChange(
    String ledgerId,
    Set<String> includedParticipantIds,
  ) async {
    final totals = await draftLineTotalsByCurrency(ledgerId);
    if (!totals.values.any((v) => v > 0)) {
      final draftTx = draftTransactionIdForLedger(ledgerId);
      await (_db.delete(_db.transactionPayments)
            ..where((t) => t.transactionId.equals(draftTx)))
          .go();
      return;
    }
    final participants = await ParticipantRepository(_db).listParticipants(ledgerId);
    if (participants.isEmpty) return;
    final payerId = participants
        .firstWhere((p) => includedParticipantIds.contains(p.id))
        .id;
    await setSinglePayerFull(ledgerId, payerId);
  }

  /// Removes draft payment rows whose payers are not in [includedParticipantIds].
  Future<void> pruneExcludedDraftPayments(
    String ledgerId,
    Set<String> includedParticipantIds,
  ) async {
    final existing = await listForDraft(ledgerId);
    final kept = existing
        .where((r) => includedParticipantIds.contains(r.participantId))
        .toList();
    if (kept.length == existing.length) return;
    await replaceDraftPayments(ledgerId: ledgerId, rows: kept);
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
