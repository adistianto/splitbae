import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:splitbae/core/data/ledger_repository.dart';
import 'package:splitbae/core/database/database_opener.dart';
import 'package:splitbae/core/providers/database_providers.dart';
import 'package:splitbae/main.dart';
import 'package:splitbae/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  testWidgets('App loads with database', (WidgetTester tester) async {
    final db = await openAppDatabase();
    await LedgerRepository(db).ensureSeedData();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabaseController(db)),
        ],
        child: const SplitBaeApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    await db.close();
  });
}
