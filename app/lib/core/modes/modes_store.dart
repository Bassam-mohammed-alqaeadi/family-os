import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'mode_activation.dart';
import 'mode_definition.dart';
import 'mode_exception.dart';
import 'modes_repository.dart';

/// SQLite / memory-backed Modes store (schema v8).
final class LocalModesStore implements ModesDomainRepository {
  LocalModesStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _modes = 'mode_document';
  static const _acts = 'mode_activation';
  static const _ex = 'mode_exception';

  @override
  Future<List<ModeDefinition>> listModes(FamilyId familyId) async {
    final rows = await _db.query(
      _modes,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'catalog_id ASC, id ASC',
    );
    return [for (final r in rows) ModeDefinition.fromRow(r)];
  }

  @override
  Future<ModeDefinition?> getMode(FamilyId familyId, String modeId) async {
    final rows = await _db.query(
      _modes,
      where: 'family_id = ? AND id = ?',
      whereArgs: [familyId.value, modeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ModeDefinition.fromRow(rows.first);
  }

  @override
  Future<void> saveMode(ModeDefinition mode) async {
    final stamped = mode.copyWith(updatedAt: _clock().toUtc());
    await _db.insert(
      _modes,
      stamped.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteMode(FamilyId familyId, String modeId) async {
    await _db.delete(
      _modes,
      where: 'family_id = ? AND id = ?',
      whereArgs: [familyId.value, modeId],
    );
  }

  @override
  Future<List<ModeActivation>> listActivations(
    FamilyId familyId, {
    ChildId? childId,
  }) async {
    if (childId == null) {
      final rows = await _db.query(
        _acts,
        where: 'family_id = ?',
        whereArgs: [familyId.value],
      );
      return [for (final r in rows) ModeActivation.fromRow(r)];
    }
    final rows = await _db.query(
      _acts,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
    return [for (final r in rows) ModeActivation.fromRow(r)];
  }

  @override
  Future<void> saveActivation(ModeActivation activation) async {
    await _db.insert(
      _acts,
      activation.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deactivateManual({
    required FamilyId familyId,
    required String modeId,
    required ChildId childId,
  }) async {
    final rows = await _db.query(
      _acts,
      where: 'family_id = ? AND mode_id = ? AND child_id = ? AND channel = ?',
      whereArgs: [
        familyId.value,
        modeId,
        childId.value,
        ModeActivationChannel.manual.wireName,
      ],
    );
    for (final r in rows) {
      final act = ModeActivation.fromRow(r);
      await saveActivation(
        ModeActivation(
          id: act.id,
          familyId: act.familyId,
          modeId: act.modeId,
          childId: act.childId,
          channel: act.channel,
          active: false,
          startedAt: act.startedAt,
          endsAt: _clock().toUtc(),
        ),
      );
    }
  }

  @override
  Future<List<ModeException>> listExceptions(
    FamilyId familyId, {
    ChildId? childId,
  }) async {
    if (childId == null) {
      final rows = await _db.query(
        _ex,
        where: 'family_id = ?',
        whereArgs: [familyId.value],
      );
      return [for (final r in rows) ModeException.fromRow(r)];
    }
    final rows = await _db.query(
      _ex,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
    return [for (final r in rows) ModeException.fromRow(r)];
  }

  @override
  Future<void> saveException(ModeException exception) async {
    await _db.insert(
      _ex,
      exception.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}
