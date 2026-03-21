import 'package:drift/drift.dart';

import '../domain/ledger_ids.dart';

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

/// Bill / settlement record (v0 **transaction**); lines and payments hang off this.
@TableIndex(
  name: 'idx_transactions_ledger_created',
  columns: {#ledgerId, #createdAtMs},
)
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text().withDefault(const Constant(''))();
  /// v0 category id: food, transport, accommodation, …, settlement, other.
  TextColumn get category => text().withDefault(const Constant('other'))();
  IntColumn get taxAmountMinor => integer().withDefault(const Constant(0))();
  TextColumn get currencyCode => text().withDefault(const Constant('IDR'))();
  /// `normal` | `settlement` — extensible for future kinds without migration churn.
  TextColumn get kind => text().withDefault(const Constant('normal'))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'idx_tx_participants_tx', columns: {#transactionId})
class TransactionParticipants extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get participantId =>
      text().references(Participants, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, participantId};
}

@TableIndex(name: 'idx_tx_payments_tx', columns: {#transactionId})
class TransactionPayments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get participantId =>
      text().references(Participants, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer()();
  /// ISO 4217; matches receipt line currency for this payment slice.
  TextColumn get currencyCode => text().withDefault(const Constant('IDR'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Recorded peer-to-peer settlement (who paid whom); optional link to a settlement tx
/// row for audit. Keeps graph/settlement math in Rust separate from UI.
@TableIndex(name: 'idx_settlement_transfers_ledger', columns: {#ledgerId})
class SettlementTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('settlement_from_participant')
  TextColumn get fromParticipantId =>
      text().references(Participants, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('settlement_to_participant')
  TextColumn get toParticipantId =>
      text().references(Participants, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  IntColumn get createdAtMs => integer()();
  TextColumn get transactionId => text().nullable().references(
        Transactions,
        #id,
        onDelete: KeyAction.setNull,
      )();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Covers list queries: filter by ledger + order by `created_at_ms`.
@TableIndex(
  name: 'idx_receipt_lines_ledger_created',
  columns: {#ledgerId, #createdAtMs},
)
@TableIndex(name: 'idx_receipt_lines_transaction_id', columns: {#transactionId})
class ReceiptLines extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.cascade)();
  TextColumn get transactionId => text().nullable().references(
        Transactions,
        #id,
        onDelete: KeyAction.cascade,
      )();
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
  tables: [
    Ledgers,
    Participants,
    Transactions,
    TransactionParticipants,
    TransactionPayments,
    SettlementTransfers,
    ReceiptLines,
    ReceiptLineAssignments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await m.createTable(transactions);
        await m.createTable(transactionParticipants);
        await m.createTable(transactionPayments);
        await m.createTable(settlementTransfers);
        await m.createIndex(idxTransactionsLedgerCreated);
        await m.createIndex(idxTxParticipantsTx);
        await m.createIndex(idxTxPaymentsTx);
        await m.createIndex(idxSettlementTransfersLedger);

        final ledgerRows = await select(ledgers).get();
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final ledger in ledgerRows) {
          final draftId = draftTransactionIdForLedger(ledger.id);
          await into(transactions).insert(
            TransactionsCompanion.insert(
              id: draftId,
              ledgerId: ledger.id,
              description: const Value(''),
              category: const Value('other'),
              taxAmountMinor: const Value(0),
              currencyCode: const Value('IDR'),
              kind: const Value('normal'),
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
        }

        await m.addColumn(receiptLines, receiptLines.transactionId);
        await m.createIndex(idxReceiptLinesTransactionId);

        for (final ledger in ledgerRows) {
          final draftId = draftTransactionIdForLedger(ledger.id);
          await (update(receiptLines)..where((t) => t.ledgerId.equals(ledger.id)))
              .write(ReceiptLinesCompanion(transactionId: Value(draftId)));
        }
      }
      if (from < 5) {
        await m.addColumn(transactionPayments, transactionPayments.currencyCode);
      }
    },
  );
}
