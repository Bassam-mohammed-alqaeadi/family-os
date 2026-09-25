import 'package:drift/drift.dart';

import 'family_database.dart';

/// The contract's `mode_owner_xor` CHECK, raised on device too — the SQL
/// constraint only guards the server copy.
class DeviceModeOwnershipException implements Exception {
  const DeviceModeOwnershipException(
    this.mode, {
    required this.hasAccount,
    required this.hasChild,
  });

  final DeviceMode mode;
  final bool hasAccount;
  final bool hasChild;

  @override
  String toString() => 'device.mode_owner_xor violated: ${mode.name} '
      '(account=$hasAccount, child=$hasChild)';
}

/// The triple lock, from the contract's own comment: "٣ محاولات ⇒ ٢٤ ساعة".
const int kMaxUnlockAttempts = 3;
const Duration kUnlockLockDuration = Duration(hours: 24);

/// Rule 25 seam — devices, their health and the triple lock as real rows.
abstract class DeviceRepository {
  Future<void> upsert(DevicesCompanion device);

  Future<Device?> byId(String deviceId);

  Future<List<Device>> allInFamily(String familyId);

  Future<void> saveHealth(DeviceHealthsCompanion health);

  Future<DeviceHealth?> healthFor(String deviceId);

  /// Persists one unlock attempt and returns the **stored** row, so callers
  /// never act on a value that failed to write.
  Future<ModeUnlockAttempt> recordUnlockAttempt({
    required String id,
    required String deviceId,
    required bool passwordOk,
    DateTime? at,
  });

  Future<ModeUnlockAttempt?> attemptById(String id);

  Future<List<ModeUnlockAttempt>> attemptsFor(String deviceId, {int limit = 20});

  /// True while the latest lock window has not expired.
  Future<bool> isLocked(String deviceId, {DateTime? now});
}

final class DriftDeviceRepository implements DeviceRepository {
  DriftDeviceRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<void> upsert(DevicesCompanion device) async {
    final mode = device.mode.value;
    final accountId = device.accountId.present ? device.accountId.value : null;
    final childId = device.childId.present ? device.childId.value : null;

    final ownedCorrectly = switch (mode) {
      DeviceMode.parent => accountId != null && childId == null,
      DeviceMode.childLocked => childId != null && accountId == null,
      DeviceMode.childPreview => accountId != null,
    };
    if (!ownedCorrectly) {
      throw DeviceModeOwnershipException(
        mode,
        hasAccount: accountId != null,
        hasChild: childId != null,
      );
    }

    await _db.into(_db.devices).insertOnConflictUpdate(device);
  }

  @override
  Future<Device?> byId(String deviceId) {
    return (_db.select(_db.devices)..where((t) => t.id.equals(deviceId)))
        .getSingleOrNull();
  }

  @override
  Future<List<Device>> allInFamily(String familyId) {
    return (_db.select(_db.devices)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.asc(t.pairedAt)]))
        .get();
  }

  @override
  Future<void> saveHealth(DeviceHealthsCompanion health) async {
    // `device_health.score` and `.reason` are `text` in the contract, with a
    // documented value set — the store is where it is kept honest, since the
    // SQL CHECK only guards the server copy.
    final score = health.score.present ? health.score.value : kHealthGood;
    if (!kHealthScores.contains(score)) {
      throw ArgumentError.value(score, 'score', 'allowed: $kHealthScores');
    }
    if (health.reason.present &&
        health.reason.value != null &&
        !kHealthReasons.contains(health.reason.value)) {
      throw ArgumentError.value(
        health.reason.value,
        'reason',
        'allowed: $kHealthReasons',
      );
    }
    final level = health.batteryLevel.present ? health.batteryLevel.value : null;
    if (level != null && (level < 0 || level > 100)) {
      throw ArgumentError.value(level, 'batteryLevel', '0..100');
    }

    await _db.into(_db.deviceHealths).insertOnConflictUpdate(health);
  }

  @override
  Future<DeviceHealth?> healthFor(String deviceId) {
    return (_db.select(_db.deviceHealths)
          ..where((t) => t.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  @override
  Future<ModeUnlockAttempt> recordUnlockAttempt({
    required String id,
    required String deviceId,
    required bool passwordOk,
    DateTime? at,
  }) async {
    final attemptedAt = at ?? DateTime.now();

    DateTime? lockedUntil;
    if (!passwordOk) {
      final failures = await _consecutiveFailures(deviceId);
      if (failures + 1 >= kMaxUnlockAttempts) {
        lockedUntil = attemptedAt.add(kUnlockLockDuration);
      }
    }

    await _db.into(_db.modeUnlockAttempts).insert(
          ModeUnlockAttemptsCompanion.insert(
            id: id,
            deviceId: deviceId,
            attemptedAt: Value(attemptedAt),
            passwordOk: passwordOk,
            lockedUntil: Value(lockedUntil),
          ),
        );

    return (await attemptById(id))!;
  }

  @override
  Future<ModeUnlockAttempt?> attemptById(String id) {
    return (_db.select(_db.modeUnlockAttempts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<ModeUnlockAttempt>> attemptsFor(String deviceId, {int limit = 20}) {
    return (_db.select(_db.modeUnlockAttempts)
          ..where((t) => t.deviceId.equals(deviceId))
          // `id` breaks timestamp ties so the order is total and reproducible:
          // the lock streak is derived from this order, and an unstable sort
          // would make "٣ محاولات" depend on luck.
          ..orderBy([
            (t) => OrderingTerm.desc(t.attemptedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<bool> isLocked(String deviceId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final rows = await attemptsFor(deviceId, limit: 50);
    return rows.any((r) => r.lockedUntil != null && r.lockedUntil!.isAfter(at));
  }

  /// Failures since the last successful attempt — the streak that arms the lock.
  Future<int> _consecutiveFailures(String deviceId) async {
    final rows = await attemptsFor(deviceId, limit: 50);
    var count = 0;
    for (final row in rows) {
      if (row.passwordOk) break;
      count++;
    }
    return count;
  }
}
