import 'package:drift/drift.dart';

import 'backup_payload_v1.dart';
import '../database/app_database.dart';
import '../domain/ledger_ids.dart';

/// In-memory snapshot of user tables for encryption migration or backup export.
class LocalDatabaseSnapshot {
  LocalDatabaseSnapshot({
    required this.ledgers,
    required this.transactions,
    required this.participants,
    required this.transactionParticipants,
    required this.transactionPayments,
    required this.settlementTransfers,
    required this.receiptLines,
    required this.receiptLineAssignments,
  });

  final List<Ledger> ledgers;
  final List<Transaction> transactions;
  final List<Participant> participants;
  final List<TransactionParticipant> transactionParticipants;
  final List<TransactionPayment> transactionPayments;
  final List<SettlementTransfer> settlementTransfers;
  final List<ReceiptLine> receiptLines;
  final List<ReceiptLineAssignment> receiptLineAssignments;

  static Future<LocalDatabaseSnapshot> capture(AppDatabase db) async {
    final ledgers = await db.select(db.ledgers).get();
    final transactions = await db.select(db.transactions).get();
    final participants = await db.select(db.participants).get();
    final transactionParticipants =
        await db.select(db.transactionParticipants).get();
    final transactionPayments = await db.select(db.transactionPayments).get();
    final settlementTransfers = await db.select(db.settlementTransfers).get();
    final receiptLines = await db.select(db.receiptLines).get();
    final receiptLineAssignments =
        await db.select(db.receiptLineAssignments).get();
    return LocalDatabaseSnapshot(
      ledgers: ledgers,
      transactions: transactions,
      participants: participants,
      transactionParticipants: transactionParticipants,
      transactionPayments: transactionPayments,
      settlementTransfers: settlementTransfers,
      receiptLines: receiptLines,
      receiptLineAssignments: receiptLineAssignments,
    );
  }

  /// Inserts into an empty database (or replaces content) in FK-safe order.
  Future<void> restoreIntoEmpty(AppDatabase db) async {
    await db.transaction(() async {
      for (final row in ledgers) {
        await db.into(db.ledgers).insert(row);
      }
      for (final row in transactions) {
        await db.into(db.transactions).insert(row);
      }
      for (final row in participants) {
        await db.into(db.participants).insert(row);
      }
      for (final row in transactionParticipants) {
        await db.into(db.transactionParticipants).insert(row);
      }
      for (final row in transactionPayments) {
        await db.into(db.transactionPayments).insert(row);
      }
      for (final row in settlementTransfers) {
        await db.into(db.settlementTransfers).insert(row);
      }
      for (final row in _receiptLinesWithDraftIds()) {
        await db.into(db.receiptLines).insert(row);
      }
      for (final row in receiptLineAssignments) {
        await db.into(db.receiptLineAssignments).insert(row);
      }
    });
  }

  /// v1 backups omit `transactionId`; attach each line to that ledger’s draft tx.
  List<ReceiptLine> _receiptLinesWithDraftIds() {
    return receiptLines
        .map(
          (line) => line.transactionId == null
              ? line.copyWith(
                  transactionId: Value(draftTransactionIdForLedger(line.ledgerId)),
                )
              : line,
        )
        .toList();
  }

  factory LocalDatabaseSnapshot.fromBackupPayload(BackupPayloadV1 p) {
    return LocalDatabaseSnapshot(
      ledgers: p.ledgers,
      transactions: p.transactions,
      participants: p.participants,
      transactionParticipants: p.transactionParticipants,
      transactionPayments: p.transactionPayments,
      settlementTransfers: p.settlementTransfers,
      receiptLines: p.receiptLines,
      receiptLineAssignments: p.receiptLineAssignments,
    );
  }

  /// When importing a **format v1** backup (no `transactions` array), synthesize
  /// draft transaction rows so schema v4+ stays consistent.
  factory LocalDatabaseSnapshot.fromLegacyV1Payload(BackupPayloadV1 p) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final transactions = <Transaction>[];
    for (final ledger in p.ledgers) {
      transactions.add(
        Transaction(
          id: draftTransactionIdForLedger(ledger.id),
          ledgerId: ledger.id,
          description: '',
          category: 'other',
          taxAmountMinor: 0,
          currencyCode: 'IDR',
          kind: 'normal',
          createdAtMs: now,
          updatedAtMs: now,
        ),
      );
    }
    return LocalDatabaseSnapshot(
      ledgers: p.ledgers,
      transactions: transactions,
      participants: p.participants,
      transactionParticipants: const [],
      transactionPayments: const [],
      settlementTransfers: const [],
      receiptLines: p.receiptLines,
      receiptLineAssignments: p.receiptLineAssignments,
    );
  }

  BackupPayloadV1 toBackupPayload({int? exportedAtUtcMs}) {
    return BackupPayloadV1(
      exportedAtUtcMs:
          exportedAtUtcMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      ledgers: ledgers,
      transactions: transactions,
      participants: participants,
      transactionParticipants: transactionParticipants,
      transactionPayments: transactionPayments,
      settlementTransfers: settlementTransfers,
      receiptLines: receiptLines,
      receiptLineAssignments: receiptLineAssignments,
    );
  }

  /// Deletes all rows (FK-safe order) then [restoreIntoEmpty].
  Future<void> replaceEntireDatabase(AppDatabase db) async {
    await db.transaction(() async {
      await db.delete(db.receiptLineAssignments).go();
      await db.delete(db.receiptLines).go();
      await db.delete(db.transactionPayments).go();
      await db.delete(db.transactionParticipants).go();
      await db.delete(db.settlementTransfers).go();
      await db.delete(db.transactions).go();
      await db.delete(db.participants).go();
      await db.delete(db.ledgers).go();
    });
    await restoreIntoEmpty(db);
  }
}
