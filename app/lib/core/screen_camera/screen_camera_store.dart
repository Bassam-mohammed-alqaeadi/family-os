import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'screen_camera_document.dart';
import 'screen_camera_engine.dart';
import 'screen_camera_repository.dart';

/// SQLite / memory-backed Screen & Camera store (schema v7 `sc_document`).
final class LocalScreenCameraStore implements ScreenCameraDomainRepository {
  LocalScreenCameraStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'sc_document';

  @override
  Future<ScreenCameraDocument?> loadFamilyBaseline(FamilyId familyId) async {
    final rows = await _db.query(
      _table,
      where: 'scope_key = ? AND family_id = ?',
      whereArgs: ['family', familyId.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScreenCameraDocument.fromRow(rows.first);
  }

  @override
  Future<ScreenCameraDocument?> loadChildOverride(
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
    return ScreenCameraDocument.fromRow(rows.first);
  }

  @override
  Future<ScreenCameraDocument> loadEffective(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final override = await loadChildOverride(familyId, childId);
    final baseline = await loadFamilyBaseline(familyId);
    return ScreenCameraEngine.resolveEffective(
      familyBaseline: baseline,
      childOverride: override,
      familyId: familyId,
    );
  }

  @override
  Future<void> save(ScreenCameraDocument document) async {
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
