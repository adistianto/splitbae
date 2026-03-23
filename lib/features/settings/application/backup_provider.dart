import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../providers.dart';

/// Manages backup/export/import async operations.
///
/// Exposes `AsyncValue<void>` so the UI can disable actions during file I/O.
final backupOperationProvider = StateNotifierProvider<
    BackupOperationNotifier, AsyncValue<void>>(
  BackupOperationNotifier.new,
);

class BackupOperationNotifier extends StateNotifier<AsyncValue<void>> {
  BackupOperationNotifier(this._ref) : super(const AsyncValue.data(null)) {
    // idle
  }

  final Ref _ref;

  Future<void> exportData() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final svc = _ref.read(backupServiceProvider);
      final file = await svc.createBackup();
      await svc.shareBackupFile(file);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importBackup() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['splitbae'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled.
        state = const AsyncValue.data(null);
        return;
      }

      final picked = result.files.single;

      final svc = _ref.read(backupServiceProvider);
      if (picked.bytes != null) {
        final tmpRoot = await Directory.systemTemp.createTemp('splitbae_imp_');
        final tmpFile = File('${tmpRoot.path}/import.splitbae');
        await tmpFile.writeAsBytes(picked.bytes!, flush: true);
        try {
          await svc.restoreFromBackup(tmpFile);
        } finally {
          await tmpRoot.delete(recursive: true);
        }
      } else {
        final path = picked.path;
        if (path == null) throw StateError('No file bytes or path');
        await svc.restoreFromBackup(File(path));
      }

      await _ref.read(appDatabaseProvider.notifier).reopenFromDisk();
      await _ref.read(itemsProvider.notifier).reloadFromDatabase();
      await _ref.read(participantsProvider.notifier).reloadFromDatabase();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

