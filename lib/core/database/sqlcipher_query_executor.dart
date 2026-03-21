// Derived from package:drift_sqflite (MIT) — opens via sqflite_sqlcipher for optional encryption.

import 'dart:async';
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as sc;

typedef DatabaseCreator = FutureOr<void> Function(File file);

class _SqlCipherDelegate extends DatabaseDelegate {
  _SqlCipherDelegate(
    this._inDbFolder,
    this._path, {
    this.singleInstance = true,
    this.creator,
    this.password,
  });

  final bool _inDbFolder;
  final String _path;
  final bool singleInstance;
  final DatabaseCreator? creator;
  final String? password;

  late sc.Database db;
  bool _isOpen = false;

  @override
  late final DbVersionDelegate versionDelegate = _SqlCipherVersionDelegate(db);

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open(QueryExecutorUser user) async {
    final String resolvedPath;
    if (_inDbFolder) {
      resolvedPath = p.join(await sc.getDatabasesPath(), _path);
    } else {
      resolvedPath = _path;
    }

    final file = File(resolvedPath);
    if (creator != null && !await file.exists()) {
      await creator!(file);
    }

    db = await sc.openDatabase(
      resolvedPath,
      password: password,
      singleInstance: singleInstance,
    );
    await db.execute('PRAGMA foreign_keys = ON');
    _isOpen = true;
  }

  @override
  Future<void> close() => db.close();

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final batch = db.batch();
    for (final arg in statements.arguments) {
      batch.execute(statements.statements[arg.statementIndex], arg.arguments);
    }
    await batch.apply(noResult: true);
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) =>
      db.execute(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      db.rawInsert(statement, args);

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final result = await db.rawQuery(statement, args);
    return QueryResult.fromRows(result);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      db.rawUpdate(statement, args);
}

class _SqlCipherVersionDelegate extends DynamicVersionDelegate {
  _SqlCipherVersionDelegate(this._db);

  final sc.Database _db;

  @override
  Future<int> get schemaVersion async {
    final result = await _db.rawQuery('PRAGMA user_version;');
    return result.single.values.first as int;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await _db.rawUpdate('PRAGMA user_version = $version;');
  }
}

/// Drift executor using [sqflite_sqlcipher]. Pass [password] when the DB should
/// be encrypted; omit or pass `null` for a plain SQLite file.
class SqlCipherQueryExecutor extends DelegatedDatabase {
  SqlCipherQueryExecutor({
    required String path,
    bool? logStatements,
    bool singleInstance = true,
    DatabaseCreator? creator,
    String? password,
  }) : super(
         _SqlCipherDelegate(
           false,
           path,
           singleInstance: singleInstance,
           creator: creator,
           password: password,
         ),
         logStatements: logStatements,
       );

  SqlCipherQueryExecutor.inDatabaseFolder({
    required String path,
    bool? logStatements,
    bool singleInstance = true,
    DatabaseCreator? creator,
    String? password,
  }) : super(
         _SqlCipherDelegate(
           true,
           path,
           singleInstance: singleInstance,
           creator: creator,
           password: password,
         ),
         logStatements: logStatements,
       );

  sc.Database? get sqlCipherDb {
    final d = delegate as _SqlCipherDelegate;
    return d.isOpen ? d.db : null;
  }

  @override
  bool get isSequential => true;
}
