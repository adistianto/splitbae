import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ledger_repository.dart';
import '../data/line_item_repository.dart';
import '../data/participant_repository.dart';
import '../data/backup_service.dart';
import '../data/local_database_snapshot.dart';
import '../database/app_database.dart';
import '../database/database_files.dart';
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

  /// Exports the current DB, applies the new encryption preference, recreates
  /// on-disk storage, and imports rows back. Returns `true` on success; `false`
  /// if the switch was rolled back (snapshot restored; prefs match previous).
  Future<bool> migrateEncryptionPreservingData({
    required Future<void> Function() persistNewEncryptionPreference,
    required Future<void> Function(bool encrypt) setEncryptionPreference,
    required bool previousEncryption,
  }) async {
    final db = state;
    final snapshot = await LocalDatabaseSnapshot.capture(db);

    try {
      await persistNewEncryptionPreference();
    } catch (e, st) {
      debugPrint('migrateEncryptionPreservingData persist: $e\n$st');
      rethrow;
    }

    AppDatabase? newDb;
    try {
      newDb = await recreateAppDatabase(db);
      await snapshot.restoreIntoEmpty(newDb);
      await LedgerRepository(newDb).ensureSeedData();
      state = newDb;
      return true;
    } catch (e, st) {
      debugPrint('migrateEncryptionPreservingData: $e\n$st');
      try {
        await newDb?.close();
      } catch (_) {}

      await deleteAppDatabaseFiles();
      try {
        await setEncryptionPreference(previousEncryption);
        final recovered = await openAppDatabase();
        await snapshot.restoreIntoEmpty(recovered);
        await LedgerRepository(recovered).ensureSeedData();
        state = recovered;
        return false;
      } catch (e2, st2) {
        debugPrint('migrateEncryptionPreservingData recovery failed: $e2\n$st2');
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

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});
