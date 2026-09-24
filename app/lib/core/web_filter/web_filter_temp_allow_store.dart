import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';

import 'web_filter_temp_allow.dart';

/// SQLite / Memory-backed timed temporary allows (schema v5).
final class LocalWebFilterTempAllowStore
    implements WebFilterTempAllowRepository {
  LocalWebFilterTempAllowStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'wf_temp_allow';

  @override
  Future<void> save(WebFilterTempAllow allow) async {
    await _db.insert(
      _table,
      allow.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<WebFilterTempAllow?> getById(String id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WebFilterTempAllow.fromRow(rows.first);
  }

  @override
  Future<List<WebFilterTempAllow>> listForChild(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
      orderBy: 'expires_at DESC',
    );
    return rows.map(WebFilterTempAllow.fromRow).toList(growable: false);
  }

  @override
  Future<Set<String>> activeHosts(
    FamilyId familyId,
    ChildId childId, {
    DateTime? now,
  }) async {
    final clock = (now ?? _clock()).toUtc();
    final all = await listForChild(familyId, childId);
    final active = <String>{};
    for (final a in all) {
      if (a.status == WebFilterTempAllowStatus.active &&
          !clock.isBefore(a.expiresAt.toUtc())) {
        await save(a.copyWith(status: WebFilterTempAllowStatus.expired));
        continue;
      }
      if (a.isActiveAt(clock)) {
        active.add(a.host);
      }
    }
    return active;
  }

  @override
  Future<void> revokeForHost(
    FamilyId familyId,
    ChildId childId,
    String host,
  ) async {
    final normalized = WebFilterPolicy.normalizeHost(host);
    final all = await listForChild(familyId, childId);
    for (final a in all) {
      if (a.host == normalized && a.status == WebFilterTempAllowStatus.active) {
        await save(a.copyWith(status: WebFilterTempAllowStatus.revoked));
      }
    }
  }
}

/// In-memory alternate for unit tests (Rule 25).
final class InMemoryWebFilterTempAllowStore
    implements WebFilterTempAllowRepository {
  InMemoryWebFilterTempAllowStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, WebFilterTempAllow> _byId = {};

  @override
  Future<void> save(WebFilterTempAllow allow) async {
    _byId[allow.id] = allow;
  }

  @override
  Future<WebFilterTempAllow?> getById(String id) async => _byId[id];

  @override
  Future<List<WebFilterTempAllow>> listForChild(
    FamilyId familyId,
    ChildId childId,
  ) async {
    return [
      for (final a in _byId.values)
        if (a.familyId == familyId && a.childId == childId) a,
    ];
  }

  @override
  Future<Set<String>> activeHosts(
    FamilyId familyId,
    ChildId childId, {
    DateTime? now,
  }) async {
    final clock = (now ?? _clock()).toUtc();
    final active = <String>{};
    for (final a in await listForChild(familyId, childId)) {
      if (a.status == WebFilterTempAllowStatus.active &&
          !clock.isBefore(a.expiresAt.toUtc())) {
        _byId[a.id] = a.copyWith(status: WebFilterTempAllowStatus.expired);
        continue;
      }
      if (a.isActiveAt(clock)) active.add(a.host);
    }
    return active;
  }

  @override
  Future<void> revokeForHost(
    FamilyId familyId,
    ChildId childId,
    String host,
  ) async {
    final normalized = WebFilterPolicy.normalizeHost(host);
    for (final a in await listForChild(familyId, childId)) {
      if (a.host == normalized && a.status == WebFilterTempAllowStatus.active) {
        _byId[a.id] = a.copyWith(status: WebFilterTempAllowStatus.revoked);
      }
    }
  }
}
