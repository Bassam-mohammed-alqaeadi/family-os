import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'app_control_document.dart';
import 'app_control_engine.dart';
import 'app_control_repository.dart';

/// SQLite / memory-backed App Control store (schema v6 `ac_document`).
final class LocalAppControlStore implements AppControlDomainRepository {
  LocalAppControlStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'ac_document';

  @override
  Future<AppControlDocument?> loadFamilyBaseline(FamilyId familyId) async {
    final rows = await _db.query(
      _table,
      where: 'scope_key = ? AND family_id = ?',
      whereArgs: ['family', familyId.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppControlDocument.fromRow(rows.first);
  }

  @override
  Future<AppControlDocument?> loadChildOverride(
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
    return AppControlDocument.fromRow(rows.first);
  }

  @override
  Future<AppControlDocument> loadEffective(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final override = await loadChildOverride(familyId, childId);
    final baseline = await loadFamilyBaseline(familyId);
    return AppControlEngine.resolveEffective(
      familyBaseline: baseline,
      childOverride: override,
      familyId: familyId,
    );
  }

  @override
  Future<void> save(AppControlDocument document) async {
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

  /// APP-OD-19: clear child override + temporary overlays for [childId].
  Future<void> restoreBaseline(
    FamilyId familyId,
    ChildId childId, {
    required Future<void> Function() clearOverlays,
  }) async {
    await removeChildOverride(familyId, childId);
    await clearOverlays();
  }
}
