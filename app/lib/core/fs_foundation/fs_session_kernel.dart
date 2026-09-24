import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'capability_registry.dart';
import 'local_database.dart';
import 'memory_local_database.dart';
import 'sqlite_local_database.dart';

/// Single shared [FamilyLocalDatabase] for all Stage-1 FS runtimes.
///
/// Phase 1.5 fix: Location / WF / AC / SC / Modes / SOS / AI must share one
/// store so cross-system tables (facts, SOS evidence, capabilities, outbox)
/// are visible. Outside tests, prefers on-device SQLite with Memory fallback
/// (DEGRADED honesty — never silent).
final class FsSessionKernel {
  FsSessionKernel._();

  static FamilyLocalDatabase? _db;
  static var _opened = false;
  static var _usingSqlite = false;
  static var _sqliteFallback = false;

  /// True when the live session DB is SQLite (restart-capable).
  static bool get usingSqlite => _usingSqlite;

  /// True when SQLite open failed and Memory was used instead.
  static bool get sqliteFallbackToMemory => _sqliteFallback;

  static FamilyLocalDatabase get db {
    final existing = _db;
    if (existing != null) return existing;
    // Lazy Memory placeholder; [ensureOpen] may replace with SQLite.
    final created = MemoryLocalDatabase();
    _db = created;
    return created;
  }

  /// Opens (once) and applies post-campaign capability honesty.
  ///
  /// Pass [override] to inject a DB (tests). Pass [preferSqlite]: false to
  /// force Memory even outside tests.
  static Future<void> ensureOpen({
    FamilyLocalDatabase? override,
    bool? preferSqlite,
  }) async {
    if (_opened) return;

    if (override != null) {
      _db = override;
      _usingSqlite = override is SqliteLocalDatabase;
      _sqliteFallback = false;
    } else if (_db == null) {
      final wantSqlite = preferSqlite ?? !_isTestEnvironment;
      _db = await _createDefault(preferSqlite: wantSqlite);
    }

    await _db!.open();
    await CapabilityRegistry(_db!).applyAllCampaignCapabilities();
    _opened = true;
  }

  static bool get _isTestEnvironment {
    if (const bool.fromEnvironment('FLUTTER_TEST')) return true;
    // flutter_test sets this process env at runtime (compile-time flag may be absent).
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static Future<FamilyLocalDatabase> _createDefault({
    required bool preferSqlite,
  }) async {
    if (!preferSqlite) {
      _usingSqlite = false;
      _sqliteFallback = false;
      return MemoryLocalDatabase();
    }
    try {
      final sqlite = await SqliteLocalDatabase.openDefault();
      _usingSqlite = true;
      _sqliteFallback = false;
      return sqlite;
    } catch (e) {
      debugPrint(
        'FsSessionKernel: SQLite open failed — Memory fallback ($e)',
      );
      _usingSqlite = false;
      _sqliteFallback = true;
      return MemoryLocalDatabase();
    }
  }

  /// Test / DI seam — replaces session DB and clears open flag.
  static Future<void> resetForTest() async {
    _opened = false;
    _usingSqlite = false;
    _sqliteFallback = false;
    final existing = _db;
    _db = null;
    if (existing != null) {
      try {
        await existing.close();
      } catch (_) {
        // Ignore double-close in tearDown.
      }
    }
  }

  static bool get isOpen => _opened;
}
