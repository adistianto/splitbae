import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as sc;

/// Primary SQLite file name (same folder as [sc.getDatabasesPath]).
const kAppDatabaseFileName = 'splitbae_v1.db';

/// Deletes the database file and SQLite journal/WAL sidecars (best-effort).
Future<void> deleteAppDatabaseFiles() async {
  final dir = await sc.getDatabasesPath();
  final base = p.join(dir, kAppDatabaseFileName);
  for (final path in _sqliteRelatedPaths(base)) {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Ignore missing or locked files; next open creates a fresh file.
    }
  }
}

Iterable<String> _sqliteRelatedPaths(String mainPath) sync* {
  yield mainPath;
  yield '$mainPath-wal';
  yield '$mainPath-shm';
  yield '$mainPath-journal';
}
