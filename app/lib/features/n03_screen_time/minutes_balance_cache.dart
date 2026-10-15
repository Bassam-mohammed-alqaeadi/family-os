import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

/// S3 — the last good server reading of a child's minutes balance, kept on this device.
///
/// This is a read cache of values the server stated. It is never a ledger: nothing here adds,
/// subtracts or decides minutes. It lets the parent's screen show the balance offline, flagged
/// stale, instead of an empty screen.
abstract interface class MinutesBalanceCache {
  Future<Map<String, int>?> read(String childId);

  Future<void> write(String childId, Map<String, int> byApp);
}

/// The durable cache, in the device's SQLite `kv_store` (the same store the family tasks use).
final class SqliteMinutesBalanceCache implements MinutesBalanceCache {
  SqliteMinutesBalanceCache(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const namespace = 'minutes_balance_cache';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<Map<String, int>?> read(String childId) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, childId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final byApp = decoded['byApp'];
    if (byApp is! Map) return null;
    final out = <String, int>{};
    for (final entry in byApp.entries) {
      final minutes = entry.value;
      if (minutes is! int || minutes < 0) return null;
      out[entry.key.toString()] = minutes;
    }
    return out;
  }

  @override
  Future<void> write(String childId, Map<String, int> byApp) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': childId,
        'value': jsonEncode({
          'byApp': byApp,
          'asOf': _clock().toUtc().toIso8601String(),
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}

/// The device's durable cache, or null when this device has no honest SQLite store.
/// There is no silent fallback to memory: a cache that does not survive a restart would be
/// a number that only looked durable.
Future<MinutesBalanceCache?> openDurableMinutesBalanceCache() async {
  await FsSessionKernel.ensureOpen();
  if (FsSessionKernel.sqliteFallbackToMemory) return null;
  return SqliteMinutesBalanceCache(FsSessionKernel.db);
}
