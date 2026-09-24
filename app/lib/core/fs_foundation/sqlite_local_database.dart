import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Device SQLite implementation of [FamilyLocalDatabase].
///
/// Path defaults to app documents `family_os_fs.db`. Tests should prefer
/// [MemoryLocalDatabase] or construct with an explicit [databaseFactory] /
/// file path via [SqliteLocalDatabase.openAt].
final class SqliteLocalDatabase implements FamilyLocalDatabase {
  SqliteLocalDatabase._(this._db);

  final Database _db;

  /// Opens (and migrates) the default on-device database file.
  static Future<SqliteLocalDatabase> openDefault() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'family_os_fs.db');
    return openAt(path);
  }

  /// Opens a database at [path] (useful for instrumentation / device tests).
  static Future<SqliteLocalDatabase> openAt(String path) async {
    final db = await openDatabase(
      path,
      version: FamilyLocalSchema.currentVersion,
      onCreate: (db, version) async {
        for (final sql in FamilyLocalSchema.createStatements) {
          await db.execute(sql);
        }
        await db.insert('schema_meta', {
          'key': 'schema_version',
          'value': '$version',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final sql in FamilyLocalSchema.locationStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 3) {
          for (final sql in FamilyLocalSchema.locationXsysStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 4) {
          for (final sql in FamilyLocalSchema.webFilterStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 5) {
          for (final sql in FamilyLocalSchema.webFilterEnfStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 6) {
          for (final sql in FamilyLocalSchema.appControlStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 7) {
          for (final sql in FamilyLocalSchema.screenCameraStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 8) {
          for (final sql in FamilyLocalSchema.modesStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 9) {
          for (final sql in FamilyLocalSchema.sosFinalStatements) {
            await db.execute(sql);
          }
        }
        if (oldVersion < 10) {
          for (final sql in FamilyLocalSchema.offlineAiSafetyStatements) {
            await db.execute(sql);
          }
        }
        await db.insert('schema_meta', {
          'key': 'schema_version',
          'value': '$newVersion',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      },
    );
    return SqliteLocalDatabase._(db);
  }

  @override
  Future<void> open() async {
    // Already open via factory.
  }

  @override
  Future<void> close() => _db.close();

  @override
  Future<int> schemaVersion() async {
    final rows = await _db.query(
      'schema_meta',
      where: 'key = ?',
      whereArgs: const ['schema_version'],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return int.parse(rows.first['value']! as String);
  }

  ConflictAlgorithm _mapConflict(LocalConflictAlgorithm a) {
    return switch (a) {
      LocalConflictAlgorithm.abort => ConflictAlgorithm.abort,
      LocalConflictAlgorithm.replace => ConflictAlgorithm.replace,
      LocalConflictAlgorithm.ignore => ConflictAlgorithm.ignore,
    };
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    LocalConflictAlgorithm conflictAlgorithm = LocalConflictAlgorithm.abort,
  }) {
    return _db.insert(
      table,
      values,
      conflictAlgorithm: _mapConflict(conflictAlgorithm),
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final rows = await _db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<void> execute(String sql, [List<Object?>? args]) {
    return _db.execute(sql, args);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final rows = await _db.rawQuery(sql, args);
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }
}
