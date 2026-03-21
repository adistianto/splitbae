import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/database/app_database.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';

void main() {
  test('ensureSeedData creates default ledger and is idempotent', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
    });

    await LedgerRepository(db).ensureSeedData();
    var rows = await db.select(db.ledgers).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, kDefaultLedgerId);

    expect(await db.select(db.participants).get(), isEmpty);
    expect(await db.select(db.receiptLines).get(), isEmpty);
    final txs = await db.select(db.transactions).get();
    expect(txs, hasLength(1));
    expect(txs.single.id, draftTransactionIdForLedger(kDefaultLedgerId));

    await LedgerRepository(db).ensureSeedData();
    rows = await db.select(db.ledgers).get();
    expect(rows, hasLength(1));
  });
}
