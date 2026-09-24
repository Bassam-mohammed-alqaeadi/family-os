import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/device_repository.dart';
import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/permission_repository.dart';
import 'package:family_os/features/n12_devices/device_health_seam.dart';
import 'package:family_os/features/n12_devices/devices_ux_bridge.dart';

/// DEV-1 — the devices domain over real rows.
///
/// The acceptance for Stage 2 is a stored change, not a fixture: these tests
/// write through the repositories and read back through the seam the screens
/// bind to, including across a close + reopen (ADR-042).
void main() {
  group('DEV-1 — devices domain over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DriftDeviceRepository devices;
    late DriftPermissionRepository permissions;
    late DriftDeviceHealthSeam seam;
    var dbClosed = false;

    // Heartbeat 12:00Z, clock 12:10Z → 10 min old, inside the stale window.
    DateTime clock() => DateTime.utc(2026, 9, 24, 12, 10);

    setUp(() async {
      dbClosed = false;
      dir = await Directory.systemTemp.createTemp('dev1_');
      file = File('${dir.path}/dev1.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
      devices = DriftDeviceRepository(db);
      permissions = DriftPermissionRepository(db);
      seam = DriftDeviceHealthSeam(
        devices: devices,
        permissions: permissions,
        clock: clock,
      );
    });

    tearDown(() async {
      seam.dispose();
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> seed() async {
      await devices.upsert(
        DevicesCompanion.insert(
          id: 'dev_a',
          familyId: 'fam_1',
          childId: const Value('child_a'),
          mode: DeviceMode.childLocked,
          platform: 'android',
          manufacturer: const Value('Xiaomi'),
          model: const Value('Redmi Note 13'),
        ),
      );
      await devices.saveHealth(
        DeviceHealthsCompanion.insert(
          deviceId: 'dev_a',
          lastHeartbeat: Value(DateTime.utc(2026, 9, 24, 12)),
          batteryLevel: const Value(40),
        ),
      );
      await permissions.setStatus(
        deviceId: 'dev_a',
        key: PermKey.locationBg,
        status: PermStatus.granted,
      );
      await permissions.setStatus(
        deviceId: 'dev_a',
        key: PermKey.accessibility,
        status: PermStatus.granted,
      );
      await permissions.setStatus(
        deviceId: 'dev_a',
        key: PermKey.batteryUnrestricted,
        status: PermStatus.deniedSoft,
      );
      await permissions.setStatus(
        deviceId: 'dev_a',
        key: PermKey.autostart,
        status: PermStatus.deniedPermanent,
      );
    }

    test('reads the stored device, its health and its permissions', () async {
      await seed();

      final list = await seam.watchDevices(familyId: 'fam_1').first;

      expect(list, hasLength(1));
      final snap = list.single;
      expect(snap.deviceId, 'dev_a');
      expect(snap.childId, 'child_a');
      expect(snap.familyId, 'fam_1');
      expect(snap.batteryPercent, 40);
      expect(snap.oemFamily, 'Xiaomi');
      expect(snap.offline, isFalse);
      expect(snap.level, DeviceHealthLevel.atRisk);
      expect(snap.permissions, hasLength(4));
      expect(
        snap.permissions
            .firstWhere((p) => p.kind == DevicePermissionKind.batteryExemption)
            .status,
        DevicePermissionStatus.denied,
      );
      expect(
        snap.permissions
            .firstWhere((p) => p.kind == DevicePermissionKind.autoStart)
            .status,
        DevicePermissionStatus.permanentlyDenied,
      );
    });

    test('a repair writes a row and turns the card green', () async {
      await seed();

      await seam.observePermission(
        deviceId: 'dev_a',
        kind: DevicePermissionKind.batteryExemption,
        status: DevicePermissionStatus.granted,
      );
      await seam.observePermission(
        deviceId: 'dev_a',
        kind: DevicePermissionKind.autoStart,
        status: DevicePermissionStatus.granted,
      );

      // Read back from the database, not from the call site.
      final stored = await permissions.get('dev_a', PermKey.batteryUnrestricted);
      expect(stored?.status, PermStatus.granted);

      final snap = (await seam.watchDevices(familyId: 'fam_1').first).single;
      expect(snap.level, DeviceHealthLevel.healthy);
      expect(snap.hasRepairableDeny, isFalse);
    });

    test('openSettings hands off, and recheck re-reads storage', () async {
      await seed();

      expect(
        await seam.openSettings(
          deviceId: 'dev_a',
          kind: DevicePermissionKind.batteryExemption,
        ),
        isTrue,
      );

      // A write that did not go through the seam is still what the next read
      // reports — the seam keeps no private cache that could go stale.
      await permissions.setStatus(
        deviceId: 'dev_a',
        key: PermKey.batteryUnrestricted,
        status: PermStatus.granted,
      );
      await seam.recheck('dev_a');

      final snap = (await seam.watchDevices(familyId: 'fam_1').first).single;
      expect(
        snap.permissions
            .firstWhere((p) => p.kind == DevicePermissionKind.batteryExemption)
            .status,
        DevicePermissionStatus.granted,
      );
    });

    test('a stale heartbeat reads as offline, never as healthy', () async {
      await seed();

      final stale = DriftDeviceHealthSeam(
        devices: devices,
        permissions: permissions,
        clock: () => DateTime.utc(2026, 9, 24, 16),
      );
      addTearDown(stale.dispose);

      final snap = (await stale.watchDevices(familyId: 'fam_1').first).single;
      expect(snap.level, DeviceHealthLevel.offline);
      expect(snap.offline, isTrue);
    });

    test('an unscoped family fails closed', () async {
      await seed();

      expect(await seam.watchDevices().first, isEmpty);
      expect(await seam.watchDevices(familyId: '   ').first, isEmpty);
      expect(await seam.watchDevices(familyId: 'fam_other').first, isEmpty);
    });

    test('ADR-042 — the device and its repair survive close + reopen', () async {
      await seed();
      await seam.observePermission(
        deviceId: 'dev_a',
        kind: DevicePermissionKind.batteryExemption,
        status: DevicePermissionStatus.granted,
      );
      await db.close();
      dbClosed = true;

      final reopened = FamilyDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final reopenedSeam = DriftDeviceHealthSeam(
        devices: DriftDeviceRepository(reopened),
        permissions: DriftPermissionRepository(reopened),
        clock: clock,
      );
      addTearDown(reopenedSeam.dispose);

      final snap = (await reopenedSeam.watchDevices(familyId: 'fam_1').first)
          .single;
      expect(snap.deviceId, 'dev_a');
      expect(snap.batteryPercent, 40);
      expect(
        snap.permissions
            .firstWhere((p) => p.kind == DevicePermissionKind.batteryExemption)
            .status,
        DevicePermissionStatus.granted,
      );
    });
  });
}
