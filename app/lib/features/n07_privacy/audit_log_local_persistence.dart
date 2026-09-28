import 'dart:async';
import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/features/n07_privacy/audit_log_models.dart';
import 'package:family_os/features/n07_privacy/audit_log_repository.dart';

/// Durable FAT-060 audit log via `kv_store` (DOM-AUDIT-LOCAL).
///
/// Append-only: insert with conflict abort. No delete/update API.
final class LocalAuditLogRepository implements AuditLogRepository {
  LocalAuditLogRepository(
    this._db, {
    this.namespace = kvNamespace,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const kvNamespace = 'audit_log';
  static const _table = 'kv_store';
  static const _indexKey = '__index__';

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;

  @override
  Future<List<AuditLogEntry>> load() async {
    final ids = await _loadIndex();
    final out = <AuditLogEntry>[];
    for (final id in ids) {
      final entry = await _loadOne(id);
      if (entry != null) out.add(entry);
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  @override
  void append(AuditLogEntry entry) {
    // Fire-and-forget durable flush — matches prior sync append API.
    // Production hosts that need await use [appendDurable].
    unawaited(appendDurable(entry));
  }

  /// Awaitable append for restart proofs / composition.
  Future<void> appendDurable(AuditLogEntry entry) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': entry.id,
        'value': jsonEncode(_toJson(entry)),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.abort,
    );
    final ids = await _loadIndex();
    if (!ids.contains(entry.id)) {
      ids.insert(0, entry.id);
      await _saveIndex(ids);
    }
  }

  Future<List<String>> _loadIndex() async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, _indexKey],
      limit: 1,
    );
    if (rows.isEmpty) return <String>[];
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>[];
    return [for (final e in decoded) e.toString()];
  }

  Future<void> _saveIndex(List<String> ids) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': _indexKey,
        'value': jsonEncode(ids),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  Future<AuditLogEntry?> _loadOne(String id) async {
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
    return _fromJson(decoded.map((k, v) => MapEntry(k.toString(), v)));
  }

  static Map<String, Object?> _toJson(AuditLogEntry e) => {
        'id': e.id,
        'kind': e.kind.name,
        'actor': e.actor.name,
        'at': e.at.toUtc().toIso8601String(),
        'subjectKey': e.subjectKey,
        'detailKey': e.detailKey,
      };

  static AuditLogEntry _fromJson(Map<String, Object?> json) {
    return AuditLogEntry(
      id: json['id']! as String,
      kind: AuditLogEntryKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => AuditLogEntryKind.forgetUsed,
      ),
      actor: AuditLogActor.values.firstWhere(
        (a) => a.name == json['actor'],
        orElse: () => AuditLogActor.system,
      ),
      at: DateTime.parse(json['at']! as String).toUtc(),
      subjectKey: json['subjectKey'] as String?,
      detailKey: json['detailKey'] as String?,
    );
  }
}

/// Composition helpers — DOM-AUDIT-LOCAL.
abstract final class AuditLogLocalPersistence {
  AuditLogLocalPersistence._();

  static LocalAuditLogRepository repository(FamilyLocalDatabase db) =>
      LocalAuditLogRepository(db);

  /// Opens session DB; refuses SQLite→Memory fallback.
  static Future<LocalAuditLogRepository> openRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-AUDIT-LOCAL: AuditLog refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return repository(FsSessionKernel.db);
  }

  /// Soft bind production singleton.
  static Future<void> tryBindStage1() async {
    try {
      final repo = await openRepository();
      rebindStage1AuditLogRepository(repo);
    } catch (_) {
      // Soft-fail — leave InMemory for tests / degraded Memory session.
    }
  }
}
