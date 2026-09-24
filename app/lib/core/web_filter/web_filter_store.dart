import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'web_filter_document.dart';
import 'web_filter_engine.dart';
import 'web_filter_repository.dart';

/// [FamilyLocalDatabase]-backed Web Filter store (schema v4 `wf_document`).
final class LocalWebFilterStore implements WebFilterDomainRepository {
  LocalWebFilterStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'wf_document';

  @override
  Future<WebFilterDocument?> loadFamilyBaseline(FamilyId familyId) async {
    final rows = await _db.query(
      _table,
      where: 'scope_key = ? AND family_id = ?',
      whereArgs: ['family', familyId.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WebFilterDocument.fromRow(rows.first);
  }

  @override
  Future<WebFilterDocument?> loadChildOverride(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final key = 'child:${childId.value}';
    final rows = await _db.query(
      _table,
      where: 'scope_key = ? AND family_id = ?',
      whereArgs: [key, familyId.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WebFilterDocument.fromRow(rows.first);
  }

  @override
  Future<WebFilterDocument> loadEffective(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final override = await loadChildOverride(familyId, childId);
    final baseline = await loadFamilyBaseline(familyId);
    return WebFilterEngine.resolveEffective(
      familyBaseline: baseline,
      childOverride: override,
      familyId: familyId,
    );
  }

  @override
  Future<void> save(WebFilterDocument document) async {
    final stamped = document.copyWith(updatedAt: _clock().toUtc());
    await _db.insert(
      _table,
      stamped.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeChildOverride(FamilyId familyId, ChildId childId) async {
    await _db.delete(
      _table,
      where: 'scope_key = ? AND family_id = ?',
      whereArgs: ['child:${childId.value}', familyId.value],
    );
  }
}
