import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'app_control_exception.dart';
import 'app_control_install.dart';
import 'app_control_lock_now.dart';
import 'app_control_repository.dart';
import 'package_id.dart';

final class LocalAppAccessExceptionStore
    implements AppAccessExceptionRepository {
  LocalAppAccessExceptionStore(this._db);

  final FamilyLocalDatabase _db;
  static const _table = 'ac_exception';

  @override
  Future<void> save(AppAccessException exception) async {
    await _db.insert(
      _table,
      exception.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AppAccessException>> listForChild(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
    return [for (final r in rows) AppAccessException.fromRow(r)];
  }

  @override
  Future<Set<String>> activePackageIds(
    FamilyId familyId,
    ChildId childId,
    DateTime now,
  ) async {
    final all = await listForChild(familyId, childId);
    return {
      for (final e in all)
        if (e.isActiveAt(now)) e.packageId,
    };
  }

  Future<void> clearForChild(FamilyId familyId, ChildId childId) async {
    await _db.delete(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
  }
}

final class LocalAppLockNowStore implements AppLockNowRepository {
  LocalAppLockNowStore(this._db);

  final FamilyLocalDatabase _db;
  static const _table = 'ac_lock_now';

  @override
  Future<void> save(AppLockNowOverlay overlay) async {
    await _db.insert(
      _table,
      overlay.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AppLockNowOverlay>> listForChild(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
    return [for (final r in rows) AppLockNowOverlay.fromRow(r)];
  }

  @override
  Future<Set<String>> activePackageIds(
    FamilyId familyId,
    ChildId childId,
    DateTime now,
  ) async {
    final all = await listForChild(familyId, childId);
    return {
      for (final e in all)
        if (e.isActiveAt(now)) e.packageId,
    };
  }

  Future<void> clearForChild(FamilyId familyId, ChildId childId) async {
    await _db.delete(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
    );
  }
}

final class LocalAppInstallTicketStore implements AppInstallTicketRepository {
  LocalAppInstallTicketStore(this._db);

  final FamilyLocalDatabase _db;
  static const _table = 'ac_install';

  @override
  Future<void> save(AppInstallTicket ticket) async {
    await _db.insert(
      _table,
      ticket.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AppInstallTicket>> listPending(
    FamilyId familyId,
    ChildId childId,
  ) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ? AND status = ?',
      whereArgs: [
        familyId.value,
        childId.value,
        AppInstallDecisionStatus.pendingDecision.name,
      ],
    );
    return [for (final r in rows) AppInstallTicket.fromRow(r)];
  }

  @override
  Future<bool> isPending(
    FamilyId familyId,
    ChildId childId,
    String packageId,
  ) async {
    final pkg = PackageId.normalize(packageId);
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ? AND package_id = ? AND status = ?',
      whereArgs: [
        familyId.value,
        childId.value,
        pkg,
        AppInstallDecisionStatus.pendingDecision.name,
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> clearPendingForChild(FamilyId familyId, ChildId childId) async {
    await _db.delete(
      _table,
      where: 'family_id = ? AND child_id = ? AND status = ?',
      whereArgs: [
        familyId.value,
        childId.value,
        AppInstallDecisionStatus.pendingDecision.name,
      ],
    );
  }
}
