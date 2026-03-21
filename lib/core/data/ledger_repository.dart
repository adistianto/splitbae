import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/ledger_ids.dart';

class LedgerRepository {
  LedgerRepository(this._db);

  final AppDatabase _db;

  Stream<List<Ledger>> watchLedgers() =>
      _db.select(_db.ledgers).watch();

  Future<void> ensureSeedData() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      final existing = await (_db.select(_db.ledgers)
            ..where((t) => t.id.equals(kDefaultLedgerId)))
          .get();
      if (existing.isNotEmpty) {
        return;
      }

      await _db.into(_db.ledgers).insert(
            LedgersCompanion.insert(
              id: kDefaultLedgerId,
              name: 'Default',
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );

      const seedPeople = ['Adistianto', 'Gemini', 'Nic'];
      for (var i = 0; i < seedPeople.length; i++) {
        await _db.into(_db.participants).insert(
              ParticipantsCompanion.insert(
                id: const Uuid().v4(),
                ledgerId: kDefaultLedgerId,
                displayName: seedPeople[i],
                sortOrder: Value(i),
                createdAtMs: now,
              ),
            );
      }

      await _db.into(_db.receiptLines).insert(
            ReceiptLinesCompanion.insert(
              id: const Uuid().v4(),
              ledgerId: kDefaultLedgerId,
              label: 'Nasi Goreng',
              amountMinor: 45000,
              currencyCode: 'IDR',
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
      await _db.into(_db.receiptLines).insert(
            ReceiptLinesCompanion.insert(
              id: const Uuid().v4(),
              ledgerId: kDefaultLedgerId,
              label: 'Es Teh',
              amountMinor: 15000,
              currencyCode: 'IDR',
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
    });
  }
}
