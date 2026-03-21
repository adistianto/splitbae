import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_line_item.dart';
import 'amount_minor.dart';
import '../../src/rust/api/simple.dart' show ReceiptItem;

class LineItemRepository {
  LineItemRepository(this._db);

  final AppDatabase _db;

  Future<List<LedgerLineItem>> listLedgerLines(String ledgerId) async {
    final rows =
        await (_db.select(_db.receiptLines)
              ..where((t) => t.ledgerId.equals(ledgerId))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
            .get();
    return rows
        .map(
          (row) => LedgerLineItem(id: row.id, receiptItem: _toReceiptItem(row)),
        )
        .toList();
  }

  Future<void> addLine({
    required String ledgerId,
    required String label,
    required double amount,
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    await _db
        .into(_db.receiptLines)
        .insert(
          ReceiptLinesCompanion.insert(
            id: const Uuid().v4(),
            ledgerId: ledgerId,
            label: label,
            amountMinor: minor,
            currencyCode: currencyCode,
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
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

  ReceiptItem _toReceiptItem(ReceiptLine row) {
    return ReceiptItem(
      name: row.label,
      price: minorUnitsToAmount(row.amountMinor, row.currencyCode),
      currencyCode: row.currencyCode,
    );
  }
}
