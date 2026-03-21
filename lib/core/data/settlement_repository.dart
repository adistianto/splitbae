import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class SettlementRepository {
  SettlementRepository(this._db);

  final AppDatabase _db;

  Future<List<SettlementTransfer>> listForLedger(String ledgerId) async {
    return (_db.select(_db.settlementTransfers)
          ..where((t) => t.ledgerId.equals(ledgerId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAtMs, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> recordTransfer({
    required String ledgerId,
    required String fromParticipantId,
    required String toParticipantId,
    required int amountMinor,
    required String currencyCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();
    await _db.into(_db.settlementTransfers).insert(
          SettlementTransfersCompanion.insert(
            id: id,
            ledgerId: ledgerId,
            fromParticipantId: fromParticipantId,
            toParticipantId: toParticipantId,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            createdAtMs: now,
            transactionId: const Value.absent(),
          ),
        );
  }
}
