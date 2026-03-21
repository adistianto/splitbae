import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/data/local_database_snapshot.dart';
import 'package:splitbae/core/database/app_database.dart';
import 'package:splitbae/core/domain/ledger_ids.dart';

void main() {
  test('LocalDatabaseSnapshot roundtrip preserves tables', () async {
    final db1 = AppDatabase(NativeDatabase.memory());
    await LedgerRepository(db1).ensureSeedData();
    final snap = await LocalDatabaseSnapshot.capture(db1);
    await db1.close();

    final db2 = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db2.close();
    });

    await snap.restoreIntoEmpty(db2);

    final ledgers = await db2.select(db2.ledgers).get();
    final participants = await db2.select(db2.participants).get();
    final lines = await db2.select(db2.receiptLines).get();
    final txs = await db2.select(db2.transactions).get();

    expect(ledgers, hasLength(1));
    expect(ledgers.single.id, kDefaultLedgerId);
    expect(participants, isEmpty);
    expect(lines, isEmpty);
    expect(txs, hasLength(1));
    expect(txs.single.id, draftTransactionIdForLedger(kDefaultLedgerId));
  });
}
