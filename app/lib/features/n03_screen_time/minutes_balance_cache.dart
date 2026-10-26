import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

/// S3 — the last good server reading of a minutes balance, kept on this device.
///
/// A read cache of values the server stated. It is never a ledger: nothing here adds,
/// subtracts or decides minutes. It lets a balance be shown offline, flagged stale.
///
/// Every entry carries its [scope] — the pairing it was read under: the paired device id for the
/// child's handset, the family id for the guardian. An entry whose scope differs from the current
/// one is ignored, never shown. A changed pairing is a different account of minutes.
final class CachedMinutesBalance {
  const CachedMinutesBalance({
    required this.scope,
    required this.total,
    required this.byApp,
  });

  final String scope;
  final int total;
  final Map<String, int> byApp;
}

abstract interface class MinutesBalanceCache {
  /// The entry under [key] when its scope is [scope]; otherwise null.
  Future<CachedMinutesBalance?> read(String key, {required String scope});

  Future<void> write(String key, CachedMinutesBalance entry);
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
  Future<CachedMinutesBalance?> read(
    String key, {
    required String scope,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    if (decoded['scope'] != scope) return null;
    final total = decoded['total'];
    final byApp = decoded['byApp'];
    if (total is! int || total < 0 || byApp is! Map) return null;
    final out = <String, int>{};
    for (final entry in byApp.entries) {
      final minutes = entry.value;
      if (minutes is! int || minutes < 0) return null;
      out[entry.key.toString()] = minutes;
    }
    return CachedMinutesBalance(scope: scope, total: total, byApp: out);
  }

  @override
  Future<void> write(String key, CachedMinutesBalance entry) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': key,
        'value': jsonEncode({
          'scope': entry.scope,
          'total': entry.total,
          'byApp': entry.byApp,
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

/// Reads an entry, treating any cache failure as "no entry": a broken store never shows a number.
Future<CachedMinutesBalance?> readCachedMinutes(
  MinutesBalanceCache? cache,
  String key, {
  required String scope,
}) async {
  if (cache == null) return null;
  try {
    return await cache.read(key, scope: scope);
  } on Object {
    return null;
  }
}

/// Writes an entry. A failed write never hides a fresh answer.
Future<void> writeCachedMinutes(
  MinutesBalanceCache? cache,
  String key,
  CachedMinutesBalance entry,
) async {
  if (cache == null) return;
  try {
    await cache.write(key, entry);
  } on Object {
    return;
  }
}
