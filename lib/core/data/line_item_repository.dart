import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';
import '../domain/ledger_line_item.dart';
import 'amount_minor.dart';
import '../../src/rust/api/simple.dart' show ReceiptItem;

class LineItemRepository {
  LineItemRepository(this._db);

  final AppDatabase _db;

  /// Lines for any transaction (draft or posted).
  Future<List<LedgerLineItem>> listLinesForTransaction({
    required String ledgerId,
    required String transactionId,
  }) async {
    final rows =
        await (_db.select(_db.receiptLines)
              ..where(
                (t) =>
                    t.ledgerId.equals(ledgerId) &
                    t.transactionId.equals(transactionId),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    return await _mapRowsToLineItems(rows);
  }

  /// Lines for the ledger’s **draft** transaction (in-progress bill).
  Future<List<LedgerLineItem>> listLedgerLines(String ledgerId) async {
    final draftTx = draftTransactionIdForLedger(ledgerId);
    final rows =
        await (_db.select(_db.receiptLines)
              ..where(
                (t) =>
                    t.ledgerId.equals(ledgerId) &
                    t.transactionId.equals(draftTx),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    return await _mapRowsToLineItems(rows);
  }

  Future<List<LedgerLineItem>> _mapRowsToLineItems(
    List<ReceiptLine> rows,
  ) async {
    if (rows.isEmpty) return [];

    final lineIds = rows.map((r) => r.id).toList();
    final assigns =
        await (_db.select(_db.receiptLineAssignments)
              ..where((a) => a.lineId.isIn(lineIds)))
            .get();

    final byLine = <String, List<String>>{};
    for (final a in assigns) {
      byLine.putIfAbsent(a.lineId, () => []).add(a.participantId);
    }

    return rows
        .map(
          (row) => LedgerLineItem(
            id: row.id,
            receiptItem: _toReceiptItem(row),
            assignedParticipantIds: byLine[row.id] ?? const [],
          ),
        )
        .toList();
  }

  /// Returns the new line id.
  Future<String> addLine({
    required String ledgerId,
    required String label,
    required double amount,
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    final id = const Uuid().v4();
    await _db
        .into(_db.receiptLines)
        .insert(
          ReceiptLinesCompanion.insert(
            id: id,
            ledgerId: ledgerId,
            transactionId: Value(draftTransactionIdForLedger(ledgerId)),
            label: label,
            amountMinor: minor,
            currencyCode: currencyCode,
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
    return id;
  }

  Future<void> updateLine({
    required String id,
    required String label,
    required double amount,
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    await (_db.update(_db.receiptLines)..where((t) => t.id.equals(id))).write(
      ReceiptLinesCompanion(
        label: Value(label),
        amountMinor: Value(minor),
        currencyCode: Value(currencyCode),
        updatedAtMs: Value(now),
      ),
    );
  }

  Future<void> deleteLine(String id) async {
    await (_db.delete(_db.receiptLines)..where((t) => t.id.equals(id))).go();
  }

  /// Persists who shares this line. Empty selection or “everyone” clears rows
  /// (meaning split with all participants).
  Future<void> replaceLineAssignments({
    required String lineId,
    required Set<String> selectedParticipantIds,
    required Set<String> allParticipantIds,
  }) async {
    final all = allParticipantIds;
    if (all.isEmpty) {
      await (_db.delete(_db.receiptLineAssignments)
            ..where((a) => a.lineId.equals(lineId)))
          .go();
      return;
    }

    final sel = selectedParticipantIds.where(all.contains).toSet();
    final isEveryone =
        sel.length == all.length && sel.containsAll(all);

    await _db.transaction(() async {
      await (_db.delete(_db.receiptLineAssignments)
            ..where((a) => a.lineId.equals(lineId)))
          .go();
      if (isEveryone || sel.isEmpty) {
        return;
      }
      for (final pid in sel) {
        await _db.into(_db.receiptLineAssignments).insert(
              ReceiptLineAssignmentsCompanion.insert(
                lineId: lineId,
                participantId: pid,
              ),
            );
      }
    });
  }

  ReceiptItem _toReceiptItem(ReceiptLine row) {
    return ReceiptItem(
      name: row.label,
      price: minorUnitsToAmount(row.amountMinor, row.currencyCode),
      currencyCode: row.currencyCode,
    );
  }
}
