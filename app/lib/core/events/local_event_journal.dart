import 'dart:convert';

import 'package:family_os/core/fs_foundation/local_database.dart';

import 'local_event_envelope.dart';

/// Append-only local event journal via `kv_store` (EVT-01-A).
///
/// Namespace [kvNamespace]. Keys are event ids; values are JSON envelopes.
/// Restart-safe on SQLite. Does not claim remote delivery.
final class LocalEventJournal {
  LocalEventJournal(
    this._db, {
    this.namespace = kvNamespace,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const kvNamespace = 'evt_journal';
  static const _table = 'kv_store';

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;

  Future<void> append(LocalEventEnvelope event) async {
    await _db.insert(_table, {
      'namespace': namespace,
      'key': event.id,
      'value': jsonEncode(event.toJson()),
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.abort);
  }

  Future<LocalEventEnvelope?> load(String id) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return LocalEventEnvelope.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<List<LocalEventEnvelope>> listRecent({int limit = 50}) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ?',
      whereArgs: [namespace],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    final out = <LocalEventEnvelope>[];
    for (final row in rows) {
      final raw = row['value'] as String?;
      if (raw == null || raw.isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;
      out.add(
        LocalEventEnvelope.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    }
    return out;
  }
}
