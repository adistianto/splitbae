import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sc;

import '../database/app_database.dart';
import '../database/database_files.dart';
import '../database/database_opener.dart';

/// Backup/export engine.
///
/// Produces a zip bundle (`.splitbae`) containing:
/// - `meta/manifest.json`
/// - `db/<splitbae_v1.db>` plus SQLite sidecars (`-wal`, `-shm`, `-journal`)
/// - `receipts/*` (receipt images)
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const String _bundleFormatId = 'splitbae_backup_bundle';
  static const int _manifestVersion = 1;

  Future<Directory> _receiptsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'receipts'));
  }

  Future<Map<String, String>> _appDatabasePaths() async {
    final dbDir = await sc.getDatabasesPath();
    final dbPath = p.join(dbDir, kAppDatabaseFileName);
    return <String, String>{
      'dbDir': dbDir,
      'db': dbPath,
      'wal': '$dbPath-wal',
      'shm': '$dbPath-shm',
      'journal': '$dbPath-journal',
    };
  }

  Future<String> _writeManifestToZip(ZipFileEncoder encoder) async {
    // Manifest is embedded as plain JSON string.
    // Includes only what we need to validate/restore safely.
    final manifest = <String, dynamic>{
      'format': _bundleFormatId,
      'version': _manifestVersion,
      'exportedAtUtcMs': DateTime.now().toUtc().millisecondsSinceEpoch,
      'dbFileName': kAppDatabaseFileName,
      'receiptsDirName': 'receipts',
      'sqliteSidecars': const <String>['-wal', '-shm', '-journal'],
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(manifest);
    encoder.addArchiveFile(ArchiveFile.string('meta/manifest.json', jsonString));
    return jsonString;
  }

  /// Creates a zip bundle `.splitbae` that can later be restored.
  ///
  /// Returns the created file for sharing or user download.
  Future<File> createBackup() async {
    final dbPaths = await _appDatabasePaths();
    final dbFile = File(dbPaths['db']!);
    if (!await dbFile.exists()) {
      throw StateError('Database file missing: ${dbFile.path}');
    }

    final receiptsDir = await _receiptsDirectory();
    final docs = await getApplicationDocumentsDirectory();
    final outDir = p.join(docs.path, 'splitbae_backups');
    await Directory(outDir).create(recursive: true);

    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final zipPath = p.join(outDir, 'SplitBae_Backup_$stamp.splitbae');
    final zipFile = File(zipPath);
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // 1) Manifest
    await _writeManifestToZip(encoder);

    // 2) SQLite DB + sidecars
    await encoder.addFile(
      dbFile,
      p.posix.join('db', kAppDatabaseFileName),
    );

    Future<void> addSidecarIfExists(String sidecarRelName, String fullPath) async {
      final f = File(fullPath);
      if (await f.exists()) {
        await encoder.addFile(f, p.posix.join('db', sidecarRelName));
      }
    }

    await addSidecarIfExists('$kAppDatabaseFileName-wal', dbPaths['wal']!);
    await addSidecarIfExists('$kAppDatabaseFileName-shm', dbPaths['shm']!);
    await addSidecarIfExists(
      '$kAppDatabaseFileName-journal',
      dbPaths['journal']!,
    );

    // 3) Receipt images
    if (await receiptsDir.exists()) {
      // Receipts are stored flat under `receipts/` (UUID filename).
      final files = receiptsDir.listSync(recursive: true, followLinks: false);
      for (final entry in files) {
        if (entry is! File) continue;
        final rel = p.relative(entry.path, from: receiptsDir.path);
        final relPosix = p.posix.fromUri(p.toUri(rel));
        await encoder.addFile(entry, p.posix.join('receipts', relPosix));
      }
    }

    await encoder.close();
    return zipFile;
  }

  /// Restore from a `.splitbae` bundle, safely overwriting the local DB
  /// and `receipts/` directory.
  ///
  /// Returns `true` on success; throws `FormatException` for invalid bundles
  /// and any other exception for I/O or restore failures.
  Future<bool> restoreFromBackup(File backupFile) async {
    if (!await backupFile.exists()) {
      throw StateError('Backup file missing: ${backupFile.path}');
    }

    final input = InputFileStream(backupFile.path);
    late final Archive decodedArchive;
    try {
      decodedArchive = ZipDecoder().decodeStream(input);
    } finally {
      await input.close();
    }

    final manifestEntry = decodedArchive.find('meta/manifest.json');
    final dbEntry = decodedArchive.find(p.posix.join('db', kAppDatabaseFileName));

    if (manifestEntry == null || !manifestEntry.isFile) {
      throw FormatException('Missing meta/manifest.json');
    }
    if (dbEntry == null || !dbEntry.isFile) {
      throw FormatException('Missing db/$kAppDatabaseFileName');
    }

    // Validate manifest
    final manifestBytes = manifestEntry.readBytes();
    if (manifestBytes == null) {
      throw FormatException('Manifest is empty');
    }
    final manifestRaw = utf8.decode(manifestBytes);
    final decoded = jsonDecode(manifestRaw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Manifest root must be a JSON object');
    }
    final format = decoded['format'];
    final version = decoded['version'];
    if (format != _bundleFormatId || version != _manifestVersion) {
      throw FormatException('Unsupported SplitBae backup bundle');
    }

    // Extract to a temp directory first (validation after extraction).
    final tmpRoot = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final tmpDir = Directory(p.join(tmpRoot.path, 'splitbae_restore_$stamp'));
    await tmpDir.create(recursive: true);

    try {
      await extractArchiveToDisk(decodedArchive, tmpDir.path);

      final extractedManifest = File(p.join(tmpDir.path, 'meta', 'manifest.json'));
      final extractedDb = File(p.join(tmpDir.path, 'db', kAppDatabaseFileName));
      if (!await extractedManifest.exists() || !await extractedDb.exists()) {
        throw FormatException('That file is not a valid SplitBae backup.');
      }

      // Close the current DB so we can overwrite the underlying files.
      await _db.close();

      final dbPaths = await _appDatabasePaths();
      final docs = await getApplicationDocumentsDirectory();
      final receiptsTargetDir = Directory(p.join(docs.path, 'receipts'));

      // Copy extracted contents into tmp files/dirs first. Only after all
      // copies succeed do we rename/overwrite.
      final tmpDbPath = p.join(
        dbPaths['dbDir']!,
        '$kAppDatabaseFileName.restore_tmp_$stamp',
      );
      final tmpWalPath = '$tmpDbPath-wal';
      final tmpShmPath = '$tmpDbPath-shm';
      final tmpJournalPath = '$tmpDbPath-journal';

      final extractedDbWal =
          File(p.join(tmpDir.path, 'db', '$kAppDatabaseFileName-wal'));
      final extractedDbShm =
          File(p.join(tmpDir.path, 'db', '$kAppDatabaseFileName-shm'));
      final extractedDbJournal = File(
        p.join(
          tmpDir.path,
          'db',
          '$kAppDatabaseFileName-journal',
        ),
      );

      await extractedDb.copy(tmpDbPath);
      if (await extractedDbWal.exists()) {
        await extractedDbWal.copy(tmpWalPath);
      }
      if (await extractedDbShm.exists()) {
        await extractedDbShm.copy(tmpShmPath);
      }
      if (await extractedDbJournal.exists()) {
        await extractedDbJournal.copy(tmpJournalPath);
      }

      final receiptsTmpDir = Directory(p.join(
        docs.path,
        'receipts_restore_tmp_$stamp',
      ));
      if (await receiptsTmpDir.exists()) {
        await receiptsTmpDir.delete(recursive: true);
      }
      await receiptsTmpDir.create(recursive: true);

      final extractedReceiptsDir = Directory(p.join(tmpDir.path, 'receipts'));
      if (await extractedReceiptsDir.exists()) {
        final entries = extractedReceiptsDir.listSync(
          recursive: true,
          followLinks: false,
        );
        for (final entry in entries) {
          if (entry is! File) continue;
          final rel = p.relative(entry.path, from: extractedReceiptsDir.path);
          final destPath = p.join(receiptsTmpDir.path, rel);
          final destDir = Directory(p.dirname(destPath));
          if (!await destDir.exists()) {
            await destDir.create(recursive: true);
          }
          await entry.copy(destPath);
        }
      }

      // Overwrite DB + receipts via atomic renames (same directories).
      final rollbackDbPath = p.join(
        dbPaths['dbDir']!,
        '$kAppDatabaseFileName.restore_rollback_$stamp',
      );
      final rollbackWalPath = '$rollbackDbPath-wal';
      final rollbackShmPath = '$rollbackDbPath-shm';
      final rollbackJournalPath = '$rollbackDbPath-journal';

      final receiptsRollbackDir = Directory(p.join(
        docs.path,
        'receipts_restore_rollback_$stamp',
      ));

      final hadExistingDb = await File(dbPaths['db']!).exists();
      final hadExistingReceipts = await receiptsTargetDir.exists();

      // Ensure rollback paths are clean.
      if (await File(rollbackDbPath).exists()) {
        await File(rollbackDbPath).delete();
      }
      if (await File(rollbackWalPath).exists()) {
        await File(rollbackWalPath).delete();
      }
      if (await File(rollbackShmPath).exists()) {
        await File(rollbackShmPath).delete();
      }
      if (await File(rollbackJournalPath).exists()) {
        await File(rollbackJournalPath).delete();
      }
      if (await receiptsRollbackDir.exists()) {
        await receiptsRollbackDir.delete(recursive: true);
      }

      try {
        // Move existing files out of the way.
        if (hadExistingDb) {
          await File(dbPaths['db']!).rename(rollbackDbPath);
        }
        final existingWal = File(dbPaths['wal']!);
        if (await existingWal.exists()) {
          await existingWal.rename(rollbackWalPath);
        }
        final existingShm = File(dbPaths['shm']!);
        if (await existingShm.exists()) {
          await existingShm.rename(rollbackShmPath);
        }
        final existingJournal = File(dbPaths['journal']!);
        if (await existingJournal.exists()) {
          await existingJournal.rename(rollbackJournalPath);
        }

        // Move tmp into final.
        await File(tmpDbPath).rename(dbPaths['db']!);
        if (await File(tmpWalPath).exists()) {
          await File(tmpWalPath).rename(dbPaths['wal']!);
        }
        if (await File(tmpShmPath).exists()) {
          await File(tmpShmPath).rename(dbPaths['shm']!);
        }
        if (await File(tmpJournalPath).exists()) {
          await File(tmpJournalPath).rename(dbPaths['journal']!);
        }

        // Move receipts tmp into place.
        if (hadExistingReceipts) {
          await receiptsTargetDir.rename(receiptsRollbackDir.path);
        }
        await receiptsTmpDir.rename(receiptsTargetDir.path);

        // Update receiptImagePath values to the *current* documents/receipts
        // directory, so restore works even if sandbox paths differ.
        final receiptsBasenames = <String>{};
        final receiptsEntries = receiptsTargetDir.listSync(followLinks: false);
        for (final e in receiptsEntries) {
          if (e is File) {
            receiptsBasenames.add(p.basename(e.path));
          }
        }

        final reopened = await openAppDatabase();
        try {
          final rows = await (
            reopened.select(reopened.transactions)
              ..where((t) => t.receiptImagePath.isNotNull())
          ).get();
          if (rows.isNotEmpty && receiptsBasenames.isNotEmpty) {
            await reopened.transaction(() async {
              for (final row in rows) {
                final oldPath = row.receiptImagePath;
                if (oldPath == null) continue;
                final base = p.basename(oldPath);
                if (!receiptsBasenames.contains(base)) continue;
                final nextPath = p.join(receiptsTargetDir.path, base);
                await (
                  reopened.update(reopened.transactions)
                    ..where((t) => t.id.equals(row.id))
                ).write(
                  TransactionsCompanion(
                    receiptImagePath: Value(nextPath),
                  ),
                );
              }
            });
          }
        } finally {
          await reopened.close();
        }

        // Cleanup rollback after success.
        if (hadExistingDb && await File(rollbackDbPath).exists()) {
          await File(rollbackDbPath).delete();
        }
        if (await File(rollbackWalPath).exists()) {
          await File(rollbackWalPath).delete();
        }
        if (await File(rollbackShmPath).exists()) {
          await File(rollbackShmPath).delete();
        }
        if (await File(rollbackJournalPath).exists()) {
          await File(rollbackJournalPath).delete();
        }
        if (await receiptsRollbackDir.exists()) {
          await receiptsRollbackDir.delete(recursive: true);
        }

        return true;
      } catch (e) {
        // Best-effort revert.
        try {
          // Delete any partially-written finals.
          final finalDb = File(dbPaths['db']!);
          if (await finalDb.exists()) {
            await finalDb.delete();
          }
          final finalWal = File(dbPaths['wal']!);
          if (await finalWal.exists()) {
            await finalWal.delete();
          }
          final finalShm = File(dbPaths['shm']!);
          if (await finalShm.exists()) {
            await finalShm.delete();
          }
          final finalJournal = File(dbPaths['journal']!);
          if (await finalJournal.exists()) {
            await finalJournal.delete();
          }

          if (hadExistingDb && await File(rollbackDbPath).exists()) {
            await File(rollbackDbPath).rename(dbPaths['db']!);
          }
          if (await File(rollbackWalPath).exists()) {
            await File(rollbackWalPath).rename(dbPaths['wal']!);
          }
          if (await File(rollbackShmPath).exists()) {
            await File(rollbackShmPath).rename(dbPaths['shm']!);
          }
          if (await File(rollbackJournalPath).exists()) {
            await File(rollbackJournalPath).rename(dbPaths['journal']!);
          }

          if (await receiptsRollbackDir.exists()) {
            if (await receiptsTargetDir.exists()) {
              await receiptsTargetDir.delete(recursive: true);
            }
            await receiptsRollbackDir.rename(receiptsTargetDir.path);
          }
        } catch (_) {
          // ignore revert failure; rethrow original.
        }
        rethrow;
      } finally {
        // Always cleanup temp receipts tmp if it still exists.
        if (await receiptsTmpDir.exists()) {
          await receiptsTmpDir.delete(recursive: true);
        }
      }
    } finally {
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    }
  }

  Future<void> shareBackupFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: 'SplitBae backup',
      ),
    );
  }

  /// Backwards-compatible: still used by older UI code.
  /// Exports a `.splitbae` bundle and returns it for sharing.
  Future<File> writeExportFile() => createBackup();

  /// Backwards-compatible: share the exported `.splitbae` bundle.
  Future<void> shareExportFile(File file) => shareBackupFile(file);

  /// Backwards-compatible: file picker import of `.splitbae`.
  ///
  /// Returns `true` if a file was chosen and imported; `false` if the user
  /// cancelled the picker.
  Future<bool> importFromUserPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['splitbae'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return false;
    }

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes != null) {
      final tmpRoot = await getTemporaryDirectory();
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final tmpFile = File(p.join(tmpRoot.path, 'splitbae_import_$stamp.splitbae'));
      await tmpFile.writeAsBytes(bytes, flush: true);
      try {
        await restoreFromBackup(tmpFile);
        return true;
      } finally {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      }
    }

    final path = picked.path;
    if (path == null) {
      throw StateError('No file bytes or path');
    }

    await restoreFromBackup(File(path));
    return true;
  }
}
