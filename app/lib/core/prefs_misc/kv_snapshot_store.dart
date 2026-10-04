import 'dart:convert';

import 'package:family_os/core/fs_foundation/local_database.dart';

/// Tiny kv_store snapshot helper for CE-B1 Local binds.
final class KvSnapshotStore {
  KvSnapshotStore(
    this._db, {
    required this.namespace,
    this.key = 'snapshot',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final String namespace;
  final String key;
  final DateTime Function() _clock;

  Future<Map<String, Object?>?> readMap() async {
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
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }

  Future<void> writeMap(Map<String, Object?> map) async {
    await _db.insert(_table, {
      'namespace': namespace,
      'key': key,
      'value': jsonEncode(map),
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }
}
