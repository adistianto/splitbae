import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';

class LedgerRepository {
  LedgerRepository(this._db);

  final AppDatabase _db;

  Stream<List<Ledger>> watchLedgers() => _db.select(_db.ledgers).watch();

  Future<void> ensureSeedData() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.ledgers,
      )..where((t) => t.id.equals(kDefaultLedgerId))).get();
      if (existing.isNotEmpty) {
        return;
      }

      await _db
          .into(_db.ledgers)
          .insert(
            LedgersCompanion.insert(
              id: kDefaultLedgerId,
              name: 'Default',
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: draftTransactionIdForLedger(kDefaultLedgerId),
              ledgerId: kDefaultLedgerId,
              description: const Value(''),
              category: const Value('other'),
              taxAmountMinor: const Value(0),
              currencyCode: const Value('IDR'),
              kind: const Value('normal'),
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
    });
  }
}
