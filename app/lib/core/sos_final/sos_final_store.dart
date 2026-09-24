import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/sos_alert.dart';

import 'sos_evidence_policy.dart';
import 'sos_incident.dart';

/// Rule 25 seam for FS-006 SOS Final durable store.
abstract class SosFinalRepository {
  Future<SosIncident?> loadOpen({FamilyId? familyId, ChildId? childId});
  Future<SosIncident?> loadById(String id);
  Future<List<SosIncident>> listIncidents(FamilyId familyId);
  Future<void> saveIncident(SosIncident incident);
  Future<void> appendAudit(SosLifecycleAuditEntry entry);
  Future<List<SosLifecycleAuditEntry>> listAudit(String incidentId);
  Future<void> appendOpsSample(SosOpsSample sample);
  Future<List<SosOpsSample>> listOpsSamples(String incidentId);
  Future<int> purgeExpiredOpsSamples({required DateTime now});
  Future<void> saveBreakGlass(Map<String, Object?> row);
  Future<List<Map<String, Object?>>> listBreakGlass({String? incidentId});
}

/// SQLite / memory-backed SOS Final store (schema v9).
final class LocalSosFinalStore implements SosFinalRepository {
  LocalSosFinalStore(this._db);

  final FamilyLocalDatabase _db;

  static const _inc = 'sos_incident';
  static const _audit = 'sos_lifecycle_audit';
  static const _ops = 'sos_ops_sample';
  static const _bg = 'sos_break_glass';

  @override
  Future<SosIncident?> loadOpen({FamilyId? familyId, ChildId? childId}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (familyId != null) {
      where.add('family_id = ?');
      args.add(familyId.value);
    }
    if (childId != null) {
      where.add('child_id = ?');
      args.add(childId.value);
    }
    final rows = await _db.query(
      _inc,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'triggered_at DESC',
    );
    for (final r in rows) {
      final incident = SosIncident.fromRow(r);
      if (incident.isOpen) return incident;
    }
    return null;
  }

  @override
  Future<SosIncident?> loadById(String id) async {
    final rows = await _db.query(
      _inc,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SosIncident.fromRow(rows.first);
  }

  @override
  Future<List<SosIncident>> listIncidents(FamilyId familyId) async {
    final rows = await _db.query(
      _inc,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'triggered_at DESC',
    );
    return [for (final r in rows) SosIncident.fromRow(r)];
  }

  @override
  Future<void> saveIncident(SosIncident incident) async {
    await _db.insert(
      _inc,
      incident.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> appendAudit(SosLifecycleAuditEntry entry) async {
    await _db.insert(
      _audit,
      entry.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SosLifecycleAuditEntry>> listAudit(String incidentId) async {
    final rows = await _db.query(
      _audit,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'at_ms ASC',
    );
    return [for (final r in rows) SosLifecycleAuditEntry.fromRow(r)];
  }

  @override
  Future<void> appendOpsSample(SosOpsSample sample) async {
    await _db.insert(
      _ops,
      sample.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SosOpsSample>> listOpsSamples(String incidentId) async {
    final rows = await _db.query(
      _ops,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'captured_at ASC',
    );
    return [for (final r in rows) SosOpsSample.fromRow(r)];
  }

  @override
  Future<int> purgeExpiredOpsSamples({required DateTime now}) async {
    final cutoff = now.toUtc().millisecondsSinceEpoch;
    final rows = await _db.query(_ops);
    var deleted = 0;
    for (final r in rows) {
      final retain = r['retain_until']! as int;
      if (retain < cutoff) {
        deleted += await _db.delete(
          _ops,
          where: 'id = ?',
          whereArgs: [r['id']],
        );
      }
    }
    return deleted;
  }

  @override
  Future<void> saveBreakGlass(Map<String, Object?> row) async {
    await _db.insert(
      _bg,
      row,
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listBreakGlass({String? incidentId}) async {
    if (incidentId == null) {
      return _db.query(_bg, orderBy: 'started_at DESC');
    }
    return _db.query(
      _bg,
      where: 'incident_id = ?',
      whereArgs: [incidentId],
      orderBy: 'started_at DESC',
    );
  }

  /// Resolve must never delete core/audit — OD-18 / RD-03.
  Future<void> assertRetentionInvariants(String incidentId) async {
    final incident = await loadById(incidentId);
    if (incident == null) {
      throw StateError('Incident missing');
    }
    if (incident.isResolved && incident.status != SosAlertStatus.resolved) {
      throw StateError('Resolved flag inconsistent');
    }
    assert(SosEvidencePolicy.coreAuditIndefinite);
    assert(SosEvidencePolicy.audioVideoForbidden);
  }
}
