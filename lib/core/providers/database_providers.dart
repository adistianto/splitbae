import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ledger_repository.dart';
import '../data/line_item_repository.dart';
import '../data/participant_repository.dart';
import '../database/app_database.dart';
import '../database/database_opener.dart';

/// Holds the active [AppDatabase] and can recreate it after encryption changes.
class AppDatabaseController extends StateNotifier<AppDatabase> {
  AppDatabaseController(super.db);

  /// Closes the DB, deletes on-disk files, reopens per prefs, re-seeds defaults.
  ///
  /// If the primary path fails after files are removed, opens a fresh DB with
  /// current preferences so in-memory state never stays closed.
  Future<void> resetLocalDatabase() async {
    try {
      final next = await recreateAppDatabase(state);
      await LedgerRepository(next).ensureSeedData();
      state = next;
    } catch (e, st) {
      debugPrint('resetLocalDatabase: $e\n$st');
      try {
        final fallback = await openAppDatabase();
        await LedgerRepository(fallback).ensureSeedData();
        state = fallback;
      } catch (e2, st2) {
        debugPrint('resetLocalDatabase recovery failed: $e2\n$st2');
        rethrow;
      }
    }
  }
}

/// Injected from [main] after [openAppDatabase].
final appDatabaseProvider =
    StateNotifierProvider<AppDatabaseController, AppDatabase>((ref) {
  throw StateError('appDatabaseProvider must be overridden in main()');
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(appDatabaseProvider));
});

final lineItemRepositoryProvider = Provider<LineItemRepository>((ref) {
  return LineItemRepository(ref.watch(appDatabaseProvider));
});

final participantRepositoryProvider = Provider<ParticipantRepository>((ref) {
  return ParticipantRepository(ref.watch(appDatabaseProvider));
});
