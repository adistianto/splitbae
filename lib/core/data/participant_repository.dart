import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/participant_entry.dart';

class ParticipantRepository {
  ParticipantRepository(this._db);

  final AppDatabase _db;

  Future<List<ParticipantEntry>> listParticipants(String ledgerId) async {
    final rows =
        await (_db.select(_db.participants)
              ..where((t) => t.ledgerId.equals(ledgerId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    return rows
        .map((r) => ParticipantEntry(id: r.id, displayName: r.displayName))
        .toList();
  }

  Future<List<String>> listDisplayNames(String ledgerId) async {
    final rows = await listParticipants(ledgerId);
    return rows.map((r) => r.displayName).toList();
  }

  Future<void> addParticipant(String displayName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await (_db.select(
      _db.participants,
    )..where((t) => t.ledgerId.equals(kDefaultLedgerId))).get();
    final sortOrder = existing.length;

    await _db
        .into(_db.participants)
        .insert(
          ParticipantsCompanion.insert(
            id: const Uuid().v4(),
            ledgerId: kDefaultLedgerId,
            displayName: displayName,
            sortOrder: Value(sortOrder),
            createdAtMs: now,
          ),
        );
  }

  Future<void> updateDisplayName({
    required String participantId,
    required String displayName,
  }) async {
    await (_db.update(_db.participants)
          ..where((t) => t.id.equals(participantId)))
        .write(ParticipantsCompanion(displayName: Value(displayName)));
  }

  Future<void> deleteParticipant(String participantId) async {
    await (_db.delete(
      _db.participants,
    )..where((t) => t.id.equals(participantId))).go();
  }
}
