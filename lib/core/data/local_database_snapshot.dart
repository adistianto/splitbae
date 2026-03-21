import 'backup_payload_v1.dart';
import '../database/app_database.dart';

/// In-memory snapshot of all user tables for encryption migration or future
/// backup export.
class LocalDatabaseSnapshot {
  LocalDatabaseSnapshot({
    required this.ledgers,
    required this.participants,
    required this.receiptLines,
  });

  final List<Ledger> ledgers;
  final List<Participant> participants;
  final List<ReceiptLine> receiptLines;

  static Future<LocalDatabaseSnapshot> capture(AppDatabase db) async {
    final ledgers = await db.select(db.ledgers).get();
    final participants = await db.select(db.participants).get();
    final receiptLines = await db.select(db.receiptLines).get();
    return LocalDatabaseSnapshot(
      ledgers: ledgers,
      participants: participants,
      receiptLines: receiptLines,
    );
  }

  /// Inserts into an empty database (or replaces content) in FK-safe order.
  Future<void> restoreIntoEmpty(AppDatabase db) async {
    await db.transaction(() async {
      for (final row in ledgers) {
        await db.into(db.ledgers).insert(row);
      }
      for (final row in participants) {
        await db.into(db.participants).insert(row);
      }
      for (final row in receiptLines) {
        await db.into(db.receiptLines).insert(row);
      }
    });
  }

  factory LocalDatabaseSnapshot.fromBackupPayload(BackupPayloadV1 p) {
    return LocalDatabaseSnapshot(
      ledgers: p.ledgers,
      participants: p.participants,
      receiptLines: p.receiptLines,
    );
  }

  BackupPayloadV1 toBackupPayload({int? exportedAtUtcMs}) {
    return BackupPayloadV1(
      exportedAtUtcMs:
          exportedAtUtcMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      ledgers: ledgers,
      participants: participants,
      receiptLines: receiptLines,
    );
  }

  /// Deletes all rows (FK-safe order) then [restoreIntoEmpty].
  Future<void> replaceEntireDatabase(AppDatabase db) async {
    await db.transaction(() async {
      await db.delete(db.receiptLines).go();
      await db.delete(db.participants).go();
      await db.delete(db.ledgers).go();
    });
    await restoreIntoEmpty(db);
  }
}

