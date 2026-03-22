import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/participant_entry.dart';
import 'draft_payment_repository.dart';
import 'participant_repository.dart';

/// Persists which ledger participants are on the **draft** bill. Empty table =
/// everyone on the ledger.
class DraftBillInclusionRepository {
  DraftBillInclusionRepository(this._db);

  final AppDatabase _db;

  Future<Set<String>> _explicitIncludedIds(String ledgerId) async {
    final rows =
        await (_db.select(_db.draftBillIncludedParticipants)
              ..where((t) => t.ledgerId.equals(ledgerId)))
            .get();
    return rows.map((e) => e.participantId).toSet();
  }

  /// Included participant ids for this draft bill. When the table is empty,
  /// returns every ledger participant.
  Future<Set<String>> effectiveIncludedIds(
    String ledgerId,
    List<ParticipantEntry> ledgerParticipants,
  ) async {
    final explicit = await _explicitIncludedIds(ledgerId);
    if (explicit.isEmpty) {
      return ledgerParticipants.map((e) => e.id).toSet();
    }
    return explicit;
  }

  Future<void> setIncludedParticipants(
    String ledgerId,
    Set<String> participantIds,
  ) async {
    final all = await ParticipantRepository(_db).listParticipants(ledgerId);
    final allIds = all.map((e) => e.id).toSet();
    final cleaned = participantIds.where(allIds.contains).toSet();
    if (cleaned.isEmpty) {
      throw StateError('no_one_on_bill');
    }
    if (cleaned.length == allIds.length && cleaned.containsAll(allIds)) {
      await (_db.delete(_db.draftBillIncludedParticipants)
            ..where((t) => t.ledgerId.equals(ledgerId)))
          .go();
    } else {
      await _db.transaction(() async {
        await (_db.delete(_db.draftBillIncludedParticipants)
              ..where((t) => t.ledgerId.equals(ledgerId)))
            .go();
        for (final id in cleaned) {
          await _db.into(_db.draftBillIncludedParticipants).insert(
                DraftBillIncludedParticipantsCompanion.insert(
                  ledgerId: ledgerId,
                  participantId: id,
                ),
              );
        }
      });
    }
    await _sanitizeDraftLineAssignments(ledgerId, cleaned);
    await DraftPaymentRepository(
      _db,
    ).syncAfterInclusionChange(ledgerId, cleaned);
  }

  Future<void> _sanitizeDraftLineAssignments(
    String ledgerId,
    Set<String> effectiveIds,
  ) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final lineRows =
        await (_db.select(_db.receiptLines)
              ..where((t) => t.ledgerId.equals(ledgerId))
              ..where((t) => t.transactionId.equals(draftTx)))
            .get();
    final all = effectiveIds;
    for (final line in lineRows) {
      final assigns =
          await (_db.select(_db.receiptLineAssignments)
                ..where((a) => a.lineId.equals(line.id)))
              .get();
      final selected =
          assigns.map((e) => e.participantId).where(all.contains).toSet();
      final isEveryone =
          selected.length == all.length && selected.containsAll(all);

      await _db.transaction(() async {
        await (_db.delete(_db.receiptLineAssignments)
              ..where((a) => a.lineId.equals(line.id)))
            .go();
        if (isEveryone || selected.isEmpty) {
          return;
        }
        for (final pid in selected) {
          await _db.into(_db.receiptLineAssignments).insert(
                ReceiptLineAssignmentsCompanion.insert(
                  lineId: line.id,
                  participantId: pid,
                ),
              );
        }
      });
    }
  }
}
