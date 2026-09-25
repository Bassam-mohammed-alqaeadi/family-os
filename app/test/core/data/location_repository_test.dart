import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/geofence_engine.dart';
import 'package:family_os/core/data/location_repository.dart';

/// PERS-2c — location history, fence shapes and their events as real rows.
///
/// The contract's rules are measured here, not assumed: the ٩٠-day retention,
/// the shape/radius pairing, the three-vertex floor, and the fact that a
/// polygon is stored as a boundary rather than a radius.
const double _baseLat = 24.7136;
const double _baseLon = 46.6753;

GeoPoint _p(double dLat, double dLon) =>
    GeoPoint(_baseLat + dLat, _baseLon + dLon);

List<GeoPoint> _square({double side = 0.001}) => [
      _p(0, 0),
      _p(0, side),
      _p(side, side),
      _p(side, 0),
    ];

LocationPingsCompanion _ping({
  String childId = 'child-1',
  double lat = _baseLat,
  double lon = _baseLon,
  double? accuracyM,
  int? battery,
  required DateTime at,
}) =>
    LocationPingsCompanion.insert(
      childId: childId,
      lat: lat,
      lon: lon,
      accuracyM: Value(accuracyM),
      battery: Value(battery),
      recordedAt: at,
    );

void main() {
  late FamilyDatabase db;
  late DriftLocationRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftLocationRepository(db);
  });

  tearDown(() => db.close());

  Future<Geofence> saveHome() => repo.saveFence(
        id: 'gf-home',
        familyId: 'fam-1',
        name: 'البيت',
        shape: CircleShape(center: _p(0, 0), radiusM: 150),
        createdBy: 'acc-1',
      );

  group('location pings', () {
    test('a fix is stored with its accuracy and battery', () async {
      await repo.recordPing(
        _ping(at: DateTime(2026, 9, 24, 12), accuracyM: 12, battery: 64),
      );

      final latest = await repo.latestPing('child-1');

      expect(latest, isNotNull);
      expect(latest!.lat, _baseLat);
      expect(latest.accuracyM, 12);
      expect(latest.battery, 64);
      expect(latest.receivedAt, isNotNull, reason: 'contract DEFAULT now()');
    });

    test('the trail is newest-first and can be windowed', () async {
      final base = DateTime(2026, 9, 24, 10);
      for (var i = 0; i < 5; i++) {
        await repo.recordPing(_ping(at: base.add(Duration(minutes: i))));
      }

      final all = await repo.pingsFor('child-1');
      expect(all, hasLength(5));
      expect(all.first.recordedAt, base.add(const Duration(minutes: 4)),
          reason: 'newest first');

      final recent = await repo.pingsFor(
        'child-1',
        since: base.add(const Duration(minutes: 3)),
      );
      expect(recent, hasLength(2));
    });

    test('one child never sees another child trail', () async {
      await repo.recordPing(_ping(at: DateTime(2026, 9, 24, 12)));
      await repo.recordPing(
        _ping(childId: 'child-2', at: DateTime(2026, 9, 24, 12)),
      );

      expect(await repo.pingsFor('child-1'), hasLength(1));
      expect(await repo.pingsFor('child-2'), hasLength(1));
    });

    test('the ٩٠-day retention deletes the old and spares the recent', () async {
      final now = DateTime(2026, 9, 24, 12);
      await repo.recordPing(_ping(at: now.subtract(const Duration(days: 89))));
      await repo.recordPing(_ping(at: now.subtract(const Duration(days: 91))));

      expect(await repo.prunePings(now: now), 1);

      final left = await repo.pingsFor('child-1');
      expect(left, hasLength(1));
      expect(left.single.recordedAt, now.subtract(const Duration(days: 89)));
    });
  });

  group('fences', () {
    test('a circle is stored with its centre and radius', () async {
      final fence = await saveHome();

      expect(fence.shape, GeofenceShape.circle);
      expect(fence.radiusM, 150);
      expect(fence.lat, closeTo(_baseLat, 1e-9));
      expect(fence.lon, closeTo(_baseLon, 1e-9));
      expect(fence.icon, 'home');
      expect(fence.createdAt, isNotNull);
      expect(await repo.verticesOf('gf-home'), isEmpty);
    });

    test('a polygon is stored as a boundary, not a radius', () async {
      final square = _square();
      final fence = await repo.saveFence(
        id: 'gf-yard',
        familyId: 'fam-1',
        name: 'ساحة المدرسة',
        shape: PolygonShape(square),
        createdBy: 'acc-1',
        altitudeM: 612,
        floorLabel: 'الطابق الأرضي',
      );

      expect(fence.shape, GeofenceShape.polygon);
      expect(fence.radiusM, isNull,
          reason: 'the contract pairs POLYGON with a NULL radius');

      final stored = await repo.verticesOf('gf-yard');
      expect(stored, hasLength(4));
      expect(stored.first.lat, closeTo(square.first.lat, 1e-9));
      expect(stored.last.lon, closeTo(square.last.lon, 1e-9));

      // The stored centre is the bounding circle's centre — what the OS gets.
      final box = boundingCircleOf(square);
      expect(fence.lat, closeTo(box.center.lat, 1e-9));
      expect(fence.lon, closeTo(box.center.lon, 1e-9));

      // Altitude and floor are kept for display; the engine's shapes carry
      // neither, so they cannot enter a containment decision.
      expect(fence.altitudeM, 612);
      expect(fence.floorLabel, 'الطابق الأرضي');
    });

    test('redrawing a polygon replaces its vertices instead of widening it', () async {
      await repo.saveFence(
        id: 'gf-yard', familyId: 'fam-1', name: 'ساحة',
        shape: PolygonShape(_square(side: 0.004)), createdBy: 'acc-1',
      );
      await repo.saveFence(
        id: 'gf-yard', familyId: 'fam-1', name: 'ساحة',
        shape: PolygonShape(_square(side: 0.001)), createdBy: 'acc-1',
      );

      final stored = await repo.verticesOf('gf-yard');
      expect(stored, hasLength(4));
      expect(stored[2].lat, closeTo(_baseLat + 0.001, 1e-9),
          reason: 'the small square, not a leftover of the large one');
    });

    test('geometry is read back as the engine value type', () async {
      await saveHome();
      final shape = await repo.shapeOf('gf-home');
      expect(shape, isA<CircleShape>());
      expect((shape as CircleShape).radiusM, 150);

      await repo.saveFence(
        id: 'gf-yard', familyId: 'fam-1', name: 'ساحة',
        shape: PolygonShape(_square()), createdBy: 'acc-1',
      );
      final yard = await repo.shapeOf('gf-yard');
      expect(yard, isA<PolygonShape>());
      expect((yard as PolygonShape).vertices, hasLength(4));
    });

    test('fences are scoped to the family, and to a child when asked', () async {
      await saveHome();
      await repo.saveFence(
        id: 'gf-school', familyId: 'fam-1', name: 'المدرسة',
        shape: CircleShape(center: _p(0.01, 0.01), radiusM: 200),
        createdBy: 'acc-1', childId: 'child-1',
      );
      await repo.saveFence(
        id: 'gf-other', familyId: 'fam-2', name: 'جهة أخرى',
        shape: CircleShape(center: _p(0.02, 0.02), radiusM: 200),
        createdBy: 'acc-9',
      );

      expect(await repo.fencesForFamily('fam-1'), hasLength(2));
      expect(
        await repo.fencesForFamily('fam-1', childId: 'child-1'),
        hasLength(2),
        reason: 'the family-wide fence and this child fence',
      );
      expect(
        await repo.fencesForFamily('fam-1', childId: 'child-2'),
        hasLength(1),
        reason: 'only the family-wide fence applies',
      );
    });

    test('an invalid shape never reaches the store', () async {
      Future<void> save(FenceShape shape) => repo.saveFence(
            id: 'gf-bad', familyId: 'fam-1', name: 'خطأ',
            shape: shape, createdBy: 'acc-1',
          );

      await expectLater(
        save(PolygonShape([_p(0, 0), _p(0, 0.001)])),
        throwsA(isA<ArgumentError>()),
        reason: 'المضلّع يحتاج ثلاثة رؤوس',
      );
      await expectLater(
        save(CircleShape(center: _p(0, 0), radiusM: 5)),
        throwsA(isA<ArgumentError>()),
        reason: 'below the contract floor of $kMinFenceRadiusM م',
      );
      await expectLater(
        save(CircleShape(center: _p(0, 0), radiusM: 9000)),
        throwsA(isA<ArgumentError>()),
      );

      expect(await repo.fenceById('gf-bad'), isNull);
    });

    test('a schedule window off the week or out of order is refused', () async {
      Future<void> save(List<ScheduleWindow> schedule) => repo.saveFence(
            id: 'gf-s', familyId: 'fam-1', name: 'بجدول',
            shape: CircleShape(center: _p(0, 0), radiusM: 100),
            createdBy: 'acc-1', schedule: schedule,
          );

      await expectLater(
        save(const [
          ScheduleWindow(weekday: 8, startMinute: 100, endMinute: 200),
        ]),
        throwsA(isA<ArgumentError>()),
        reason: 'weekday is 1..7 (ISO-8601)',
      );
      await expectLater(
        save(const [
          ScheduleWindow(weekday: 1, startMinute: 100, endMinute: 100),
        ]),
        throwsA(isA<ArgumentError>()),
        reason: 'نافذة فارغة',
      );
      await expectLater(
        save(const [
          ScheduleWindow(
            weekday: 1, startMinute: 480, endMinute: 900, expectBy: 420,
          ),
        ]),
        throwsA(isA<ArgumentError>()),
        reason: 'الوصول المتوقّع لا يسبق بداية النافذة',
      );
    });

    test('a schedule is stored and read back as engine windows', () async {
      await repo.saveFence(
        id: 'gf-school', familyId: 'fam-1', name: 'المدرسة',
        shape: CircleShape(center: _p(0.01, 0.01), radiusM: 200),
        createdBy: 'acc-1',
        schedule: const [
          ScheduleWindow(weekday: 1, startMinute: 420, endMinute: 840, expectBy: 480),
          ScheduleWindow(weekday: 2, startMinute: 420, endMinute: 840),
        ],
      );

      final windows = await repo.scheduleOf('gf-school');

      expect(windows, hasLength(2));
      expect(windows.first.weekday, 1);
      expect(windows.first.expectBy, 480);
      expect(windows.last.expectBy, isNull);
    });

    test('deleting a fence takes its geometry, schedule and events with it', () async {
      await repo.saveFence(
        id: 'gf-yard', familyId: 'fam-1', name: 'ساحة',
        shape: PolygonShape(_square()), createdBy: 'acc-1',
        schedule: const [
          ScheduleWindow(weekday: 1, startMinute: 420, endMinute: 840),
        ],
      );
      await repo.appendEvent(GeofenceEventsCompanion.insert(
        geofenceId: 'gf-yard',
        childId: 'child-1',
        kind: GeofenceEventKind.enter,
        occurredAt: DateTime(2026, 9, 24, 12),
      ));

      expect(await repo.deleteFence('gf-yard'), 1);

      expect(await repo.fenceById('gf-yard'), isNull);
      expect(await repo.verticesOf('gf-yard'), isEmpty);
      expect(await repo.scheduleOf('gf-yard'), isEmpty);
      expect(await repo.eventsFor('gf-yard'), isEmpty);
    });
  });

  group('events', () {
    test('an ENTER is the fact a NO_SHOW is decided against', () async {
      await saveHome();
      final since = DateTime(2026, 9, 24, 7);

      expect(await repo.hasEnteredSince('gf-home', 'child-1', since), isFalse);

      await repo.appendEvent(GeofenceEventsCompanion.insert(
        geofenceId: 'gf-home',
        childId: 'child-1',
        kind: GeofenceEventKind.enter,
        occurredAt: DateTime(2026, 9, 24, 8, 5),
        accuracyM: const Value(9),
      ));

      expect(await repo.hasEnteredSince('gf-home', 'child-1', since), isTrue);
      expect(
        await repo.hasEnteredSince(
          'gf-home', 'child-1', DateTime(2026, 9, 24, 9),
        ),
        isFalse,
        reason: 'the arrival was at 08:05 — before this window',
      );
      expect(
        await repo.hasEnteredSince('gf-home', 'child-2', since),
        isFalse,
        reason: 'another child did not arrive',
      );
    });

    test('the decision log keeps the evidence it was built on', () async {
      await saveHome();
      await repo.appendEvent(GeofenceEventsCompanion.insert(
        geofenceId: 'gf-home',
        childId: 'child-1',
        kind: GeofenceEventKind.noShow,
        occurredAt: DateTime(2026, 9, 24, 8),
        accuracyM: const Value(40),
      ));

      final events = await repo.eventsFor('gf-home');

      expect(events, hasLength(1));
      expect(events.single.kind, GeofenceEventKind.noShow);
      expect(events.single.accuracyM, 40);
    });
  });

  group('acceptance — the fence trail survives a database reopen', () {
    test('write fence + vertices + ping + event, close, reopen, read', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2c_loc');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        var fileRepo = DriftLocationRepository(fileDb);
        await fileRepo.saveFence(
          id: 'gf-yard', familyId: 'fam-1', name: 'ساحة',
          shape: PolygonShape(_square()), createdBy: 'acc-1',
        );
        await fileRepo.recordPing(_ping(at: DateTime(2026, 9, 24, 12)));
        await fileRepo.appendEvent(GeofenceEventsCompanion.insert(
          geofenceId: 'gf-yard',
          childId: 'child-1',
          kind: GeofenceEventKind.enter,
          occurredAt: DateTime(2026, 9, 24, 12),
        ));
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        fileRepo = DriftLocationRepository(fileDb);

        final fence = await fileRepo.fenceById('gf-yard');
        final shape = await fileRepo.shapeOf('gf-yard');

        expect(fence, isNotNull);
        expect(fence!.shape, GeofenceShape.polygon);
        expect((shape as PolygonShape).vertices, hasLength(4));
        expect(await fileRepo.latestPing('child-1'), isNotNull);
        expect(await fileRepo.eventsFor('gf-yard'), hasLength(1));
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
