import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

import 'package:family_os/core/data/device_repository.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/permission_repository.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/family_members_drift_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Stage-2 composition root for the devices domain (SCR-FAT-025/026).
///
/// Same shape as `Stage1LocationRuntime`: one process-wide [FamilyDatabase],
/// the real Drift repositories built once, and a [DeviceHealthSeam] adapter
/// over them. The screens default to this seam; tests keep injecting
/// [FakeDeviceHealthSeam], so nothing in the existing suite changes.
final class Stage1DevicesRuntime {
  Stage1DevicesRuntime._();

  static FamilyDatabase? _db;
  static DriftDeviceRepository? _devices;
  static DriftPermissionRepository? _permissions;
  static DeviceHealthSeam? _seam;
  static var _opened = false;

  /// Opens once. Pass [override] to inject a database (tests own its lifecycle).
  ///
  /// Without an override the store is an in-process Drift database — honest for
  /// this slice: with no sync backend yet there is nothing to persist against,
  /// and device persistence swaps in behind the same repos when it lands.
  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    if (_opened && override == null) return;
    if (override != null) {
      _db = override;
    } else {
      _db ??= FamilyDatabase(NativeDatabase.memory());
    }
    _devices = DriftDeviceRepository(_db!);
    _permissions = DriftPermissionRepository(_db!);
    _seam = DriftDeviceHealthSeam(
      devices: _devices!,
      permissions: _permissions!,
    );
    _opened = true;
  }

  static FamilyDatabase get db => _require(_db, 'database');

  static DeviceRepository get devices => _require(_devices, 'devices');

  static PermissionRepository get permissions =>
      _require(_permissions, 'permissions');

  /// The shared seam the device screens bind to.
  static DeviceHealthSeam get seam => _require(_seam, 'seam');

  /// DEV-2 — the roster seam over `member` + `account` + `child`.
  static FamilyMembersRepository members({String? selfAccountId}) =>
      DriftFamilyMembersRepository(db, selfAccountId: selfAccountId);

  static T _require<T>(T? value, String what) {
    if (value == null) {
      throw StateError('Call Stage1DevicesRuntime.ensureOpen() first');
    }
    return value;
  }

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() {
    _opened = false;
    _db = null;
    _devices = null;
    _permissions = null;
    _seam = null;
  }
}

/// The device screens over real rows: `device` + `device_health` and the
/// observed `device_permission` rows (ADR-050 — observed, never assumed).
///
/// Mirrors [FakeDeviceHealthSeam]'s contract exactly: same fail-closed family
/// scope, same level rule, same repair round-trip — but the values come from
/// storage instead of a fixture.
final class DriftDeviceHealthSeam implements DeviceHealthSeam {
  DriftDeviceHealthSeam({
    required this.devices,
    required this.permissions,
    DateTime Function()? clock,
    String Function(Device)? labelFor,
    String Function(Device)? modelFor,
    Duration staleAfter = const Duration(minutes: 30),
  }) : clock = clock ?? DateTime.now,
       _labelFor = labelFor,
       _modelFor = modelFor,
       _staleAfter = staleAfter;

  final DeviceRepository devices;
  final PermissionRepository permissions;
  final DateTime Function() clock;
  final String Function(Device)? _labelFor;
  final String Function(Device)? _modelFor;
  final Duration _staleAfter;

  final _changes = StreamController<void>.broadcast();
  var _closed = false;

  /// The four rows SCR-FAT-026 shows, in the contract's own vocabulary.
  static const Map<DevicePermissionKind, PermKey> _kindToKey = {
    DevicePermissionKind.locationAlways: PermKey.locationBg,
    DevicePermissionKind.accessibility: PermKey.accessibility,
    DevicePermissionKind.batteryExemption: PermKey.batteryUnrestricted,
    DevicePermissionKind.autoStart: PermKey.autostart,
  };

  @override
  Stream<List<DeviceHealthSnapshot>> watchDevices({String? familyId}) async* {
    final fid = (familyId ?? '').trim();
    if (fid.isEmpty) {
      // Fail closed — an unscoped watch would leak across families.
      yield const <DeviceHealthSnapshot>[];
      return;
    }
    yield await _load(fid);
    await for (final _ in _changes.stream) {
      yield await _load(fid);
    }
  }

  @override
  Stream<DeviceHealthSnapshot?> watchDevice(
    String deviceId, {
    String? familyId,
  }) {
    return watchDevices(familyId: familyId).map((list) {
      for (final d in list) {
        if (d.deviceId == deviceId) return d;
      }
      return null;
    });
  }

  @override
  Future<bool> openSettings({
    required String deviceId,
    required DevicePermissionKind kind,
  }) async {
    // The OS dialog belongs to the device; this layer only records what is
    // observed afterwards (ADR-050). True = the caller may hand off.
    return true;
  }

  @override
  Future<void> recheck(String deviceId) async {
    // The OS re-check happens on the device; when it lands it writes rows and
    // notifies. Re-reading stored rows until then is the honest answer.
    _notify();
  }

  /// The write half of ADR-050 — records one observed permission state.
  Future<void> observePermission({
    required String deviceId,
    required DevicePermissionKind kind,
    required DevicePermissionStatus status,
    DateTime? checkedAt,
  }) async {
    final key = _kindToKey[kind];
    if (key == null) return;
    await permissions.setStatus(
      deviceId: deviceId,
      key: key,
      status: _statusToDb(status),
      checkedAt: checkedAt,
    );
    _notify();
  }

  /// Keeps the battery line honest; the repo enforces 0..100.
  Future<void> observeBattery(
    String deviceId, {
    required int? level,
    DateTime? at,
  }) async {
    await devices.saveHealth(
      DeviceHealthsCompanion.insert(
        deviceId: deviceId,
        lastHeartbeat: Value(at ?? clock()),
        batteryLevel: Value(level),
      ),
    );
    _notify();
  }

  void dispose() {
    _closed = true;
    _changes.close();
  }

  Future<List<DeviceHealthSnapshot>> _load(String familyId) async {
    final rows = await devices.allInFamily(familyId);
    final out = <DeviceHealthSnapshot>[];
    for (final d in rows) {
      out.add(await _snapshot(d));
    }
    return out;
  }

  Future<DeviceHealthSnapshot> _snapshot(Device d) async {
    final health = await devices.healthFor(d.id);
    final mapped = _mapPerms(await permissions.forDevice(d.id));
    final heartbeat = health?.lastHeartbeat;
    final offline =
        heartbeat == null || clock().difference(heartbeat) > _staleAfter;
    final level = offline
        ? DeviceHealthLevel.offline
        : mapped.any((p) => p.status != DevicePermissionStatus.granted)
        ? DeviceHealthLevel.atRisk
        : DeviceHealthLevel.healthy;
    return DeviceHealthSnapshot(
      deviceId: d.id,
      familyId: d.familyId,
      childId: d.childId ?? '',
      displayLabel: _labelFor?.call(d) ?? (d.childId ?? d.id),
      modelLabel: _modelFor?.call(d) ?? _modelOf(d),
      level: level,
      permissions: mapped,
      batteryPercent: health?.batteryLevel,
      offline: offline,
      oemFamily: d.manufacturer,
    );
  }

  List<DevicePermissionRow> _mapPerms(List<DevicePermission> rows) {
    final out = <DevicePermissionRow>[];
    for (final kind in DevicePermissionKind.values) {
      final key = _kindToKey[kind];
      DevicePermission? row;
      for (final r in rows) {
        if (r.permKey == key) {
          row = r;
          break;
        }
      }
      if (row == null) continue;
      final status = _statusOf(row.status);
      if (status == null) continue;
      out.add(DevicePermissionRow(kind: kind, status: status));
    }
    return out;
  }

  static DevicePermissionStatus? _statusOf(PermStatus s) => switch (s) {
    PermStatus.granted => DevicePermissionStatus.granted,
    PermStatus.notApplicable => null, // not a row on SCR-FAT-026
    PermStatus.deniedPermanent => DevicePermissionStatus.permanentlyDenied,
    PermStatus.restrictedByOs => DevicePermissionStatus.permanentlyDenied,
    PermStatus.notAsked => DevicePermissionStatus.denied,
    PermStatus.deniedSoft => DevicePermissionStatus.denied,
  };

  static PermStatus _statusToDb(DevicePermissionStatus s) => switch (s) {
    DevicePermissionStatus.granted => PermStatus.granted,
    DevicePermissionStatus.denied => PermStatus.deniedSoft,
    DevicePermissionStatus.permanentlyDenied => PermStatus.deniedPermanent,
  };

  static String _modelOf(Device d) {
    final parts = [d.manufacturer, d.model]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? d.platform : parts.join(' ');
  }

  void _notify() {
    if (!_closed && !_changes.isClosed) _changes.add(null);
  }
}
