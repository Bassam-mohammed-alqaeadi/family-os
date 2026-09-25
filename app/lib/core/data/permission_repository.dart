import 'package:drift/drift.dart';

import 'family_database.dart';

/// Rule 25 seam — permission state as observed rows (they were mock-only).
///
/// This is the store behind ADR-050 rule 4: every permission that is missing is
/// one row here, and the UI reads these rows instead of interrupting the parent
/// with popups. The table comment in the contract is the rule:
/// "حالة مرصودة لا مفترضة" — observed, never assumed.
abstract class PermissionRepository {
  /// Writes the observed state. [checkedAt] defaults to now; pass a value when
  /// the OS check happened earlier.
  Future<void> setStatus({
    required String deviceId,
    required PermKey key,
    required PermStatus status,
    DateTime? checkedAt,
  });

  Future<DevicePermission?> get(String deviceId, PermKey key);

  Future<List<DevicePermission>> forDevice(String deviceId);

  /// Everything still missing — i.e. neither granted nor inapplicable.
  /// This is the list the device-health surface renders.
  Future<List<DevicePermission>> missingFor(String deviceId);
}

final class DriftPermissionRepository implements PermissionRepository {
  DriftPermissionRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<void> setStatus({
    required String deviceId,
    required PermKey key,
    required PermStatus status,
    DateTime? checkedAt,
  }) {
    return _db.into(_db.devicePermissions).insertOnConflictUpdate(
          DevicePermissionsCompanion.insert(
            deviceId: deviceId,
            permKey: key,
            status: status,
            checkedAt: Value(checkedAt ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<DevicePermission?> get(String deviceId, PermKey key) {
    return (_db.select(_db.devicePermissions)
          ..where((t) => t.deviceId.equals(deviceId) & t.permKey.equalsValue(key)))
        .getSingleOrNull();
  }

  @override
  Future<List<DevicePermission>> forDevice(String deviceId) {
    return (_db.select(_db.devicePermissions)
          ..where((t) => t.deviceId.equals(deviceId))
          ..orderBy([(t) => OrderingTerm.asc(t.permKey)]))
        .get();
  }

  @override
  Future<List<DevicePermission>> missingFor(String deviceId) {
    return (_db.select(_db.devicePermissions)
          ..where(
            (t) =>
                t.deviceId.equals(deviceId) &
                t.status.isNotInValues(
                  const [PermStatus.granted, PermStatus.notApplicable],
                ),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.permKey)]))
        .get();
  }
}
