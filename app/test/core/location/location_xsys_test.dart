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
import 'package:family_os/core/location/modes_location_fact_feed.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/sos_location_handoff.dart';
import 'package:family_os/core/location/sos_location_handoff_service.dart';
import 'package:family_os/core/location/zone_geometry.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalLocationStore store;
  late SosLocationHandoff handoff;
  late ModesLocationFactFeed modesFeed;
  final family = FamilyId('fam_test');
  final child = ChildId('child_a');
  final device = DeviceId('dev_1');
  final now = DateTime.utc(2026, 9, 24, 14);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalLocationStore(db, clock: () => now);
    handoff = SosLocationHandoff(db, store, clock: () => now);
    modesFeed = ModesLocationFactFeed(db, clock: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  group('schema v3 XSYS tables', () {
    test('loc_sos_evidence and loc_mode_fact accept inserts', () async {
      await db.insert('loc_sos_evidence', {
        'id': 'e1',
        'incident_id': 'inc_1',
        'family_id': family.value,
        'child_id': child.value,
        'device_id': device.value,
        'honesty': 'UNAVAILABLE',
        'fix_id': null,
        'lat': null,
        'lng': null,
        'accuracy_m': null,
        'attached_at': now.millisecondsSinceEpoch,
      });
      await db.insert('loc_mode_fact', {
        'id': 'mf1',
        'family_id': family.value,
        'child_id': child.value,
        'kind': 'PRESENCE',
        'zone_id': 'zone_home',
        'inside': 1,
        'occurred_at': now.millisecondsSinceEpoch,
      });
      expect((await db.query('loc_sos_evidence')).length, 1);
      expect((await db.query('loc_mode_fact')).length, 1);
    });
  });

  group('SosLocationHandoff', () {
    test('GPS missing → UNAVAILABLE honesty but never blocks SOS', () async {
      final result = await handoff.attachForIncident(
        incidentId: 'inc_no_gps',
        familyId: family,
        childId: child,
        deviceId: device,
      );
      expect(result.firedWithoutLocationBlocked, isTrue);
      expect(result.honesty, SosLocationHonesty.unavailable);
      expect(result.childStatusWord, 'unavailable');
      expect(result.evidence?.hasCoordinates, isFalse);

      final word = await handoff.childStatusWordForIncident('inc_no_gps');
      expect(word, 'unavailable');
      expect(SosBreakGlassLocationLaw.breakGlassIsFindMyChild, isFalse);
    });

    test('located fix attaches coordinates + LOCATED honesty', () async {
      await store.appendFix(
        LocationFix(
          id: 'fix_live',
          familyId: family,
          childId: child,
          deviceId: device,
          acquisition: LocationAcquisitionStatus.located,
          point: const GeoPoint(latitude: 24.7136, longitude: 46.6753),
          accuracyMeters: 12,
          recordedAt: now,
        ),
      );

      final result = await handoff.attachForIncident(
        incidentId: 'inc_ok',
        familyId: family,
        childId: child,
        deviceId: device,
      );
      expect(result.firedWithoutLocationBlocked, isTrue);
      expect(result.honesty, SosLocationHonesty.located);
      expect(result.childStatusWord, 'located');
      expect(result.evidence?.hasCoordinates, isTrue);
      expect(result.evidence?.latitude, 24.7136);
      expect(SosLocationClassMapper.toSosUiToken(result.honesty), 'ready');

      final listed = await handoff.listEvidence('inc_ok');
      expect(listed, hasLength(1));
      expect(listed.single.fixId, 'fix_live');
    });

    test('stale last-known maps honesty + SOS UI token', () async {
      await store.appendFix(
        LocationFix(
          id: 'fix_stale',
          familyId: family,
          childId: child,
          deviceId: device,
          acquisition: LocationAcquisitionStatus.staleLastKnown,
          point: const GeoPoint(latitude: 24.71, longitude: 46.67),
          recordedAt: now.subtract(const Duration(hours: 2)),
        ),
      );
      final result = await handoff.attachForIncident(
        incidentId: 'inc_stale',
        familyId: family,
        childId: child,
        deviceId: device,
      );
      expect(result.honesty, SosLocationHonesty.staleLastKnown);
      expect(result.childStatusWord, 'stale');
      expect(SosLocationClassMapper.toSosUiToken(result.honesty), 'stale');
    });
  });

  group('ModesLocationFactFeed', () {
    test('publishFromGeofenceEvent maps ENTER/EXIT/NO_SHOW', () async {
      final enter = GeofenceEvent(
        eventId: 'ev_enter',
        familyId: family,
        childId: child,
        deviceId: device,
        zoneId: 'zone_home',
        kind: GeofenceEventKind.enter,
        occurredAt: now,
      );
      final fact = await modesFeed.publishFromGeofenceEvent(enter);
      expect(fact.kind, LocationModeFactKind.zoneEnter);
      expect(fact.zoneId, 'zone_home');

      await modesFeed.publishFromGeofenceEvent(
        GeofenceEvent(
          eventId: 'ev_exit',
          familyId: family,
          childId: child,
          deviceId: device,
          zoneId: 'zone_home',
          kind: GeofenceEventKind.exit,
          occurredAt: now.add(const Duration(minutes: 1)),
        ),
      );
      await modesFeed.publishFromGeofenceEvent(
        GeofenceEvent(
          eventId: 'ev_ns',
          familyId: family,
          childId: child,
          deviceId: device,
          zoneId: 'zone_school',
          kind: GeofenceEventKind.noShow,
          occurredAt: now.add(const Duration(minutes: 2)),
        ),
      );

      final forChild = await modesFeed.listForChild(family, child);
      expect(forChild.map((f) => f.kind), [
        LocationModeFactKind.zoneNoShow,
        LocationModeFactKind.zoneExit,
        LocationModeFactKind.zoneEnter,
      ]);
      // Feed has no Mode activation API — facts only.
      expect(modesFeed, isA<ModesLocationFactFeed>());
    });

    test(
      'evaluateAndRecord with modesFeed publishes presence + enter',
      () async {
        final zone = SafeZoneDefinition(
          id: 'zone_home',
          familyId: family,
          name: 'Home',
          geometry: const CircleGeometry(
            center: GeoPoint(latitude: 24.7136, longitude: 46.6753),
            radiusMeters: 150,
          ),
          assignedChildIds: [child],
          createdAt: now,
          updatedAt: now,
        );
        await store.saveZone(zone);

        // Establish outside first so ENTER can fire.
        final outside = LocationFix(
          id: 'fix_out',
          familyId: family,
          childId: child,
          deviceId: device,
          acquisition: LocationAcquisitionStatus.located,
          point: const GeoPoint(latitude: 24.7200, longitude: 46.6753),
          recordedAt: now,
        );
        await store.appendFix(outside);
        await store.evaluateAndRecord(
          zone: zone,
          fix: outside,
          eventId: 'ev_seed',
          modesFeed: modesFeed,
        );

        final inside = LocationFix(
          id: 'fix_in',
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
          eventId: 'ev_enter2',
          modesFeed: modesFeed,
        );
        expect(enter?.kind, GeofenceEventKind.enter);

        final facts = await modesFeed.listForZone(family, 'zone_home');
        expect(
          facts.any((f) => f.kind == LocationModeFactKind.zoneEnter),
          isTrue,
        );
        expect(
          facts.any((f) => f.kind == LocationModeFactKind.presence),
          isTrue,
        );
      },
    );
  });

  test('applyFs001XsysCapabilities upgrades handoff + feed rows', () async {
    final registry = CapabilityRegistry(db, clock: () => now);
    await registry.ensureSeeded();
    await registry.setStatus(
      'fs001.sos_location_handoff',
      CapabilityStatus.notImplemented,
    );
    await registry.applyFs001XsysCapabilities();
    expect(
      (await registry.get('fs001.sos_location_handoff'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs001.modes_fact_feed'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs001.native_gps'))!.status,
      CapabilityStatus.notImplemented,
    );
  });
}
