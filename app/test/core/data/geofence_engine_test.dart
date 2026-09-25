import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/geofence_engine.dart';

/// PERS-2c — the geometry and the decision rules of a geofence.
///
/// These are the tests that stand between a GPS artefact and a parent being
/// told their child left the house, so they measure the awkward cases: the
/// concave boundary, the fix sitting on the line, the fix too poor to trust.
const double _baseLat = 24.7136;
const double _baseLon = 46.6753;

GeoPoint _p(double dLat, double dLon) =>
    GeoPoint(_baseLat + dLat, _baseLon + dLon);

/// [meters] due north of [from] — latitude degrees are a constant scale.
GeoPoint _north(GeoPoint from, double meters) =>
    GeoPoint(from.lat + meters / 111132.0, from.lon);

/// A square yard, [side] degrees on a side (~111 m by ~101 m at this latitude).
List<GeoPoint> _square({double side = 0.001}) => [
      _p(0, 0),
      _p(0, side),
      _p(side, side),
      _p(side, 0),
    ];

/// An L-shaped yard: the big square minus the notch at x 1..3, y 0..2.
final List<GeoPoint> _lShape = [
  _p(0, 0),
  _p(3, 0),
  _p(3, 3),
  _p(2, 3),
  _p(2, 1),
  _p(0, 1),
];

void main() {
  group('distance', () {
    test('haversine measures a degree of latitude', () {
      // 1° of latitude is ~111.2 km on the WGS-84 mean sphere.
      expect(
        haversineMeters(const GeoPoint(0, 0), const GeoPoint(1, 0)),
        closeTo(111195, 60),
      );
    });

    test('a point is zero metres from itself', () {
      final p = _p(0.0005, 0.0005);
      expect(haversineMeters(p, p), 0);
    });
  });

  group('containment', () {
    test('circle: inside, boundary and outside', () {
      final center = _p(0, 0);

      expect(
        circleContains(center: center, radiusM: 200, point: _north(center, 100)),
        isTrue,
      );
      expect(
        circleContains(center: center, radiusM: 200, point: _north(center, 199)),
        isTrue,
      );
      expect(
        circleContains(center: center, radiusM: 200, point: _north(center, 300)),
        isFalse,
      );
    });

    test('polygon: a square knows its inside and its outside', () {
      final square = _square();

      expect(polygonContains(square, _p(0.0005, 0.0005)), isTrue);
      expect(polygonContains(square, _p(0.002, 0.0005)), isFalse);
      expect(polygonContains(square, _p(0.0005, 0.002)), isFalse);
      expect(polygonContains(square, _p(-0.001, -0.001)), isFalse);
    });

    test('polygon: the concave notch is outside — the whole point of the shape', () {
      expect(polygonContains(_lShape, _p(0.5, 0.5)), isTrue,
          reason: 'the left arm of the L');
      expect(polygonContains(_lShape, _p(2.5, 2)), isTrue,
          reason: 'the top band of the L');
      expect(polygonContains(_lShape, _p(1, 2)), isFalse,
          reason: 'inside the bounding box, outside the drawn shape');
    });

    test('polygon: fewer than three vertices is refused, never guessed', () {
      expect(
        () => polygonContains([_p(0, 0), _p(0, 0.001)], _p(0, 0.0005)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('distance to the nearest edge is what the band is measured against', () {
      // 10 m north of the bottom edge, and the nearest edge is that one.
      final near = GeoPoint(_baseLat + 10 / 111132.0, _baseLon + 0.0005);

      expect(distanceToPolygonEdgeMeters(_square(), near), closeTo(10, 1));
    });
  });

  group('bounding circle', () {
    test('covers every vertex', () {
      final square = _square(side: 0.002);
      final box = boundingCircleOf(square);

      // A 0.002° box is ~222 m by ~202 m, so its half-diagonal is ~150 m.
      expect(box.radiusM, greaterThan(100));
      expect(box.radiusM, lessThan(200));
      for (final v in square) {
        expect(haversineMeters(box.center, v), lessThanOrEqualTo(box.radiusM + 0.5));
      }
    });

    test('the radius handed to the OS never drops below its own floor', () {
      expect(osRegistrationRadiusM(20), kOsMinRadiusM);
      expect(osRegistrationRadiusM(400), 400);
    });

    test('an empty point list is refused', () {
      expect(() => boundingCircleOf(const []), throwsA(isA<ArgumentError>()));
    });
  });

  group('transitions', () {
    const engine = GeofenceEngine();
    final home = CircleShape(center: _p(0, 0), radiusM: 200);

    test('the first fix only establishes state — it never fires an ENTER', () {
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 50),
          accuracyM: 10,
          wasInside: null,
        ),
        isNull,
      );
    });

    test('clearly inside after being outside is an ENTER', () {
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 100),
          accuracyM: 10,
          wasInside: false,
        ),
        GeofenceTransition.enter,
      );
    });

    test('clearly outside after being inside is an EXIT', () {
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 400),
          accuracyM: 10,
          wasInside: true,
        ),
        GeofenceTransition.exit,
      );
    });

    test('the hysteresis band keeps the previous state — no flap on the line', () {
      // 190 m of a 200 m radius: 10 m inside, so inside the 30 m band.
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 190),
          accuracyM: 10,
          wasInside: false,
        ),
        isNull,
      );
      // And 10 m outside the line gets the same answer, from the other side.
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 210),
          accuracyM: 10,
          wasInside: true,
        ),
        isNull,
      );
    });

    test('a fix too poor to trust produces no decision at all', () {
      expect(
        engine.transition(
          shape: home,
          fix: _north(home.center, 400),
          accuracyM: 500,
          wasInside: true,
        ),
        isNull,
        reason: 'better silence than a false EXIT',
      );
    });

    test('a polygon fence is judged by its drawn edge, not its bounding box', () {
      final yard = PolygonShape(_lShape);

      expect(engine.signedInsideDistance(yard, _p(1, 2)), lessThan(0));
      expect(
        engine.transition(
          shape: yard,
          fix: _p(1, 2),
          accuracyM: 5,
          wasInside: true,
        ),
        GeofenceTransition.exit,
        reason: 'in the notch of the L is out of the yard',
      );
    });
  });

  group('schedule', () {
    final monday = DateTime(2026, 9, 21);
    const school = ScheduleWindow(
      weekday: 1,
      startMinute: 7 * 60,
      endMinute: 14 * 60,
      expectBy: 8 * 60,
    );

    test('no schedule means always active', () {
      expect(fenceActiveAt(const [], DateTime(2026, 9, 21, 3)), isTrue);
    });

    test('a window is open inside its hours, on its day only', () {
      expect(school.isOpenAt(DateTime(2026, 9, 21, 9)), isTrue);
      expect(school.isOpenAt(DateTime(2026, 9, 21, 6, 59)), isFalse);
      expect(school.isOpenAt(DateTime(2026, 9, 21, 14)), isFalse,
          reason: 'the end is exclusive — 14:00 is out');
      expect(school.isOpenAt(DateTime(2026, 9, 22, 9)), isFalse);
    });

    test('a window that crosses midnight belongs to its start day', () {
      const night = ScheduleWindow(
        weekday: 1,
        startMinute: 22 * 60,
        endMinute: 6 * 60,
      );

      expect(night.crossesMidnight, isTrue);
      expect(night.isOpenAt(DateTime(2026, 9, 21, 23)), isTrue);
      expect(night.isOpenAt(DateTime(2026, 9, 22, 2)), isTrue,
          reason: 'Tuesday 02:00 is still Monday night');
      expect(night.isOpenAt(DateTime(2026, 9, 22, 12)), isFalse);
      expect(night.isOpenAt(DateTime(2026, 9, 21, 12)), isFalse);
    });

    test('the opening instant is found on the right day', () {
      expect(
        school.windowOpenedAt(DateTime(2026, 9, 21, 9)),
        DateTime(2026, 9, 21, 7),
      );
      expect(
        school.windowOpenedAt(DateTime(2026, 9, 22, 9)),
        DateTime(2026, 9, 21, 7),
        reason: 'the most recent opening is still last Monday',
      );
      expect(
        school.windowOpenedAt(DateTime(2026, 9, 21, 6)),
        DateTime(2026, 9, 14, 7),
        reason: 'before today opening, so last week',
      );
    });

    test('NO_SHOW is due only after the expected minute, and only if unseen', () {
      expect(
        noShowDueAt(
          windows: const [school],
          local: DateTime(2026, 9, 21, 9),
          arrivedWithinWindow: false,
        ),
        DateTime(2026, 9, 21, 8),
      );
      expect(
        noShowDueAt(
          windows: const [school],
          local: DateTime(2026, 9, 21, 7, 30),
          arrivedWithinWindow: false,
        ),
        isNull,
        reason: 'still before the expected minute',
      );
      expect(
        noShowDueAt(
          windows: const [school],
          local: DateTime(2026, 9, 21, 9),
          arrivedWithinWindow: true,
        ),
        isNull,
        reason: 'the child is inside — there is nothing to raise',
      );
      expect(
        noShowDueAt(
          windows: const [school],
          local: DateTime(2026, 9, 21, 20),
          arrivedWithinWindow: false,
        ),
        isNull,
        reason: 'the window is closed',
      );
    });

    test('a window without an expectation never raises NO_SHOW', () {
      const alwaysHome = ScheduleWindow(
        weekday: 1,
        startMinute: 0,
        endMinute: 1439,
      );

      expect(
        noShowDueAt(
          windows: const [alwaysHome],
          local: monday.add(const Duration(hours: 23, minutes: 59)),
          arrivedWithinWindow: false,
        ),
        isNull,
      );
    });
  });
}
