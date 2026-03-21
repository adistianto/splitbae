import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prefs_keys.dart';
import 'app_database.dart';
import 'database_files.dart';
import 'sqlcipher_query_executor.dart';

const _kPassphraseStorageKey = 'splitbae_sqlcipher_passphrase_v1';

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

Future<String> _loadOrCreatePassphrase() async {
  final existing = await _secureStorage.read(key: _kPassphraseStorageKey);
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }
  final created = _newCryptographicPassphrase();
  await _secureStorage.write(key: _kPassphraseStorageKey, value: created);
  return created;
}

/// 256 bits of entropy, stored once and reused while encryption stays enabled.
String _newCryptographicPassphrase() {
  final r = Random.secure();
  final bytes = List<int>.generate(32, (_) => r.nextInt(256));
  return base64UrlEncode(bytes);
}

Future<void> _deletePersistedPassphrase() async {
  await _secureStorage.delete(key: _kPassphraseStorageKey);
}

/// Opens the app database. Reads [kEncryptDatabasePreferenceKey] from
/// [SharedPreferences]; when true, uses a passphrase from secure storage.
Future<AppDatabase> openAppDatabase() async {
  final prefs = await SharedPreferences.getInstance();
  final encrypt = prefs.getBool(kEncryptDatabasePreferenceKey) ?? false;
  final String? password = encrypt ? await _loadOrCreatePassphrase() : null;

  final executor = SqlCipherQueryExecutor.inDatabaseFolder(
    path: kAppDatabaseFileName,
    password: password,
    logStatements: kDebugMode,
  );

  return AppDatabase(executor);
}

/// Closes [current], removes on-disk files, drops the SQLCipher passphrase when
/// switching to plain mode, and opens a new database matching current prefs.
///
/// Call after persisting the new encryption flag. Destructive: local data is
/// erased; callers should run [LedgerRepository.ensureSeedData] (or equivalent).
Future<AppDatabase> recreateAppDatabase(AppDatabase current) async {
  await current.close();
  await deleteAppDatabaseFiles();

  final prefs = await SharedPreferences.getInstance();
  final encrypt = prefs.getBool(kEncryptDatabasePreferenceKey) ?? false;
  if (!encrypt) {
    await _deletePersistedPassphrase();
  }

  return openAppDatabase();
}
