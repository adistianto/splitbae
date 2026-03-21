import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'amount_minor.dart';
import '../../src/rust/api/simple.dart' show ReceiptItem;

class LineItemRepository {
  LineItemRepository(this._db);

  final AppDatabase _db;

  Future<List<ReceiptItem>> listForLedger(String ledgerId) async {
    final rows = await (_db.select(_db.receiptLines)
          ..where((t) => t.ledgerId.equals(ledgerId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAtMs)]))
        .get();
    return rows.map(_toReceiptItem).toList();
  }

  Future<void> addLine({
    required String ledgerId,
    required String label,
    required double amount,
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final minor = amountToMinorUnits(amount, currencyCode);
    await _db.into(_db.receiptLines).insert(
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

  ReceiptItem _toReceiptItem(ReceiptLine row) {
    return ReceiptItem(
      name: row.label,
      price: minorUnitsToAmount(row.amountMinor, row.currencyCode),
      currencyCode: row.currencyCode,
    );
  }
}
