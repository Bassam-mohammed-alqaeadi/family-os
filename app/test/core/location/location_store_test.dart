import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/core/location/location_fix.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/zone_geometry.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalLocationStore store;
  final family = FamilyId('fam_test');
  final child = ChildId('child_a');
  final device = DeviceId('dev_1');
  final now = DateTime.utc(2026, 9, 24, 12);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalLocationStore(db, clock: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  SafeZoneDefinition circleZone({
    List<ChildId>? kids,
    String id = 'zone_home',
  }) {
    return SafeZoneDefinition(
      id: id,
      familyId: family,
      name: 'Home',
      geometry: const CircleGeometry(
        center: GeoPoint(latitude: 24.7136, longitude: 46.6753),
        radiusMeters: 150,
      ),
      assignedChildIds: kids ?? [child],
      createdAt: now,
      updatedAt: now,
    );
  }

  test('schema v3 exposes location + XSYS tables', () async {
    await db.insert('loc_zone', {
      'id': 'z',
      'family_id': 'f',
      'name': 'n',
      'emoji': '🏠',
      'active': 1,
      'archived': 0,
      'alert_enter': 1,
      'alert_exit': 1,
      'alert_no_show': 0,
      'created_at': 1,
      'updated_at': 1,
    });
    expect((await db.query('loc_zone')).length, 1);
    expect(FamilyLocalSchema.currentVersion, 10);
  });

  test('saveZone rejects empty assignment (Q-LOC-12=B)', () async {
    final zone = circleZone(kids: const []);
    expect(
      () => store.saveZone(zone),
      throwsA(isA<ZoneAssignmentRequiredException>()),
    );
  });

  test('saveZone persists circle + assignment and reloads', () async {
    await store.saveZone(circleZone());
    final loaded = await store.getZone('zone_home');
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Home');
    expect(loaded.geometry, isA<CircleGeometry>());
    expect(loaded.assignedChildIds, [child]);
  });

  test('saveZone persists polygon geometry', () async {
    final zone = SafeZoneDefinition(
      id: 'zone_school',
      familyId: family,
      name: 'School',
      geometry: const PolygonGeometry(
        vertices: [
          GeoPoint(latitude: 24.71, longitude: 46.67),
          GeoPoint(latitude: 24.71, longitude: 46.68),
          GeoPoint(latitude: 24.72, longitude: 46.68),
          GeoPoint(latitude: 24.72, longitude: 46.67),
        ],
      ),
      assignedChildIds: [child],
      createdAt: now,
      updatedAt: now,
    );
    await store.saveZone(zone);
    final loaded = await store.getZone('zone_school');
    expect(loaded!.geometry, isA<PolygonGeometry>());
    expect((loaded.geometry as PolygonGeometry).vertices.length, 4);
  });

  test('appendFix rejects dishonest LOCATED without coords', () async {
    final bad = LocationFix(
      id: 'fix_bad',
      familyId: family,
      childId: child,
      deviceId: device,
      acquisition: LocationAcquisitionStatus.located,
      recordedAt: now,
    );
    expect(
      () => store.appendFix(bad),
      throwsA(isA<DishonestLocationFixException>()),
    );
  });

  test('appendFix allows UNAVAILABLE without coords', () async {
    await store.appendFix(
      LocationFix(
        id: 'fix_ua',
        familyId: family,
        childId: child,
        deviceId: device,
        acquisition: LocationAcquisitionStatus.unavailable,
        recordedAt: now,
      ),
    );
    expect(await store.latestFix(family, child), isNull);
  });

  test('trail + ENTER/EXIT evaluateAndRecord', () async {
    await store.saveZone(circleZone());
    final zone = (await store.getZone('zone_home'))!;

    final outside = LocationFix(
      id: 'fix_1',
      familyId: family,
      childId: child,
      deviceId: device,
      acquisition: LocationAcquisitionStatus.located,
      point: const GeoPoint(latitude: 24.7200, longitude: 46.6753),
      recordedAt: now,
    );
    await store.appendFix(outside);
    final noEvent = await store.evaluateAndRecord(
      zone: zone,
      fix: outside,
      eventId: 'ev_none',
    );
    expect(noEvent, isNull);

    final inside = LocationFix(
      id: 'fix_2',
      familyId: family,
      childId: child,
      deviceId: device,
      acquisition: LocationAcquisitionStatus.located,
      point: const GeoPoint(latitude: 24.7136, longitude: 46.6753),
      recordedAt: now.add(const Duration(minutes: 1)),
    );
    await store.appendFix(inside);
    final enter = await store.evaluateAndRecord(
      zone: zone,
      fix: inside,
      eventId: 'ev_enter',
    );
    expect(enter?.kind, GeofenceEventKind.enter);

    final leave = LocationFix(
      id: 'fix_3',
      familyId: family,
      childId: child,
      deviceId: device,
      acquisition: LocationAcquisitionStatus.located,
      point: const GeoPoint(latitude: 24.7200, longitude: 46.6753),
      recordedAt: now.add(const Duration(minutes: 2)),
    );
    await store.appendFix(leave);
    final exit = await store.evaluateAndRecord(
      zone: zone,
      fix: leave,
      eventId: 'ev_exit',
    );
    expect(exit?.kind, GeofenceEventKind.exit);

    final events = await store.listGeofenceEvents(family, zoneId: 'zone_home');
    expect(events.map((e) => e.kind), [
      GeofenceEventKind.exit,
      GeofenceEventKind.enter,
    ]);
    expect(await store.latestFix(family, child), isNotNull);
  });

  test('explicit NO_SHOW append works', () async {
    await store.appendGeofenceEvent(
      GeofenceEvent(
        eventId: 'ev_ns',
        familyId: family,
        childId: child,
        deviceId: device,
        zoneId: 'zone_home',
        kind: GeofenceEventKind.noShow,
        occurredAt: now,
      ),
    );
    final events = await store.listGeofenceEvents(family);
    expect(events.single.kind, GeofenceEventKind.noShow);
  });

  test('applyFs001DomCapabilities upgrades honesty rows', () async {
    final registry = CapabilityRegistry(db, clock: () => now);
    await registry.ensureSeeded();
    // Simulate pre-DOM seed override
    await registry.setStatus(
      'fs001.location_domain',
      CapabilityStatus.notImplemented,
    );
    await registry.applyFs001DomCapabilities();
    expect(
      (await registry.get('fs001.location_domain'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs001.geofence_eval'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs001.native_gps'))!.status,
      CapabilityStatus.notImplemented,
    );
  });
}
