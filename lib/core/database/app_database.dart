import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Ledgers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Speeds up FK lookups and `WHERE ledger_id = ?`.
@TableIndex(name: 'idx_participants_ledger_id', columns: {#ledgerId})
class Participants extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.cascade)();
  TextColumn get displayName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Covers list queries: filter by ledger + order by `created_at_ms`.
@TableIndex(
  name: 'idx_receipt_lines_ledger_created',
  columns: {#ledgerId, #createdAtMs},
)
class ReceiptLines extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Which participants share a receipt line (equal split of that line’s amount).
/// **No rows** for a line means “everyone” (same as all participants).
@TableIndex(
  name: 'idx_receipt_line_assignments_line_id',
  columns: {#lineId},
)
class ReceiptLineAssignments extends Table {
  TextColumn get lineId =>
      text().references(ReceiptLines, #id, onDelete: KeyAction.cascade)();
  TextColumn get participantId =>
      text().references(Participants, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {lineId, participantId};
}

@DriftDatabase(
  tables: [Ledgers, Participants, ReceiptLines, ReceiptLineAssignments],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createIndex(idxParticipantsLedgerId);
        await m.createIndex(idxReceiptLinesLedgerCreated);
      }
      if (from < 3) {
        await m.createTable(receiptLineAssignments);
        await m.createIndex(idxReceiptLineAssignmentsLineId);
      }
    },
  );
}
