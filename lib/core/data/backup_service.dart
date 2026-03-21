import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import 'backup_payload_v1.dart';
import 'ledger_repository.dart';
import 'local_database_snapshot.dart';

/// Writes `.sb_backup` JSON and restores from it (plain UTF-8; see UI disclaimer).
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Creates a JSON file under app documents and returns it for sharing.
  Future<File> writeExportFile() async {
    final snap = await LocalDatabaseSnapshot.capture(_db);
    final payload = snap.toBackupPayload();
    final baseDir = await getApplicationDocumentsDirectory();
    final outDir = p.join(baseDir.path, 'splitbae_backups');
    await Directory(outDir).create(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(outDir, 'splitbae_backup_$stamp.sb_backup'));
    await file.writeAsString(payload.toJsonString(), encoding: utf8);
    return file;
  }

  Future<void> shareExportFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'SplitBae backup',
      ),
    );
  }

  /// Returns `true` if a file was chosen and imported; `false` if the user
  /// cancelled the picker.
  Future<bool> importFromUserPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['sb_backup'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return false;
    }
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes != null) {
      await _importBytes(bytes);
      return true;
    }
    final path = picked.path;
    if (path == null) {
      throw StateError('No file bytes or path');
    }
    await _importBytes(await File(path).readAsBytes());
    return true;
  }

  Future<void> _importBytes(List<int> bytes) async {
    final raw = utf8.decode(bytes);
    final payload = BackupPayloadV1.fromJsonString(raw);
    final LocalDatabaseSnapshot snap = payload.formatVersion < 2
        ? LocalDatabaseSnapshot.fromLegacyV1Payload(payload)
        : LocalDatabaseSnapshot.fromBackupPayload(payload);
    await snap.replaceEntireDatabase(_db);
    await LedgerRepository(_db).ensureSeedData();
  }
}
