/// PERS-2c — the geometry and the decision rules behind every geofence event.
///
/// Deliberately pure Dart: no drift, no platform channel, no clock of its own.
/// Every rule here is testable in isolation, which is the only way to trust a
/// decision that will later read as "your child arrived" on a parent's phone.
///
/// Two platform facts shape all of it (ADR-051, researched 2026-09-24):
///  · **The OS only accepts a circle.** `Geofence.Builder` on Android and
///    `CLCircularRegion` on iOS both describe circular regions, and Google
///    recommends a radius of at least 100–150 m. So our own containment check
///    is not a convenience — it is the only way to honour a boundary a parent
///    actually drew.
///  · **Altitude is a label, not a rule.** Vertical GPS accuracy is far worse
///    than horizontal and unstable indoors, so altitude never decides whether a
///    child is inside. It is shown, and that is all.
library;

import 'dart:math' as math;

/// WGS-84 mean radius.
const double kEarthRadiusM = 6371008.8;

/// The OS's own floor: Google asks for "the minimum radius of the geofence
/// should be set between 100-150 meters". Applied only when a fence is handed
/// to the OS — never to what we store or evaluate ourselves.
const double kOsMinRadiusM = 150;

/// A polygon fence needs three vertices. The contract states the minimum; only
/// the store can check it, since SQL has no cross-row CHECK for this.
const int kMinPolygonVertices = 3;

/// The contract's own bounds for `geofence.radius_m`
/// (`CHECK (radius_m BETWEEN 10 AND 5000)`) — enforced at write time too,
/// because that CHECK only guards the server copy.
const int kMinFenceRadiusM = 10;
const int kMaxFenceRadiusM = 5000;

/// A point on the ground, WGS-84 degrees.
class GeoPoint {
  const GeoPoint(this.lat, this.lon);

  final double lat;
  final double lon;

  @override
  String toString() => 'GeoPoint($lat, $lon)';
}

/// The circle an arbitrary shape is registered with the OS as, and the cheap
/// pre-filter that lets us skip the polygon test for far-away fixes.
class BoundingCircle {
  const BoundingCircle({required this.center, required this.radiusM});

  final GeoPoint center;
  final double radiusM;
}

double _radians(double degrees) => degrees * math.pi / 180;

/// Metres per degree of latitude — effectively constant over a fence's span.
const double _metersPerDegreeLat = 111132.0;

/// Metres per degree of longitude at a given latitude.
double _metersPerDegreeLon(double lat) => 111320.0 * math.cos(_radians(lat));

/// Great-circle distance in metres (haversine).
double haversineMeters(GeoPoint a, GeoPoint b) {
  final dLat = _radians(b.lat - a.lat);
  final dLon = _radians(b.lon - a.lon);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(a.lat)) *
          math.cos(_radians(b.lat)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * kEarthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}

/// The box-centre circle that covers every vertex.
///
/// This is what gets registered with the OS, and it is meant to be generous:
/// the OS circle only has to *wake us up* near the fence. The precise answer
/// comes from [polygonContains] on the fix we take afterwards.
BoundingCircle boundingCircleOf(List<GeoPoint> points) {
  if (points.isEmpty) {
    throw ArgumentError.value(points, 'points', 'لا يمكن حصر نقاط فارغة');
  }
  var minLat = points.first.lat;
  var maxLat = points.first.lat;
  var minLon = points.first.lon;
  var maxLon = points.first.lon;
  for (final p in points) {
    minLat = math.min(minLat, p.lat);
    maxLat = math.max(maxLat, p.lat);
    minLon = math.min(minLon, p.lon);
    maxLon = math.max(maxLon, p.lon);
  }
  final center = GeoPoint((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  var radius = 0.0;
  for (final p in points) {
    radius = math.max(radius, haversineMeters(center, p));
  }
  return BoundingCircle(center: center, radiusM: radius);
}

/// The radius to hand the OS: never below its own documented floor.
double osRegistrationRadiusM(double radiusM) => math.max(radiusM, kOsMinRadiusM);

/// Containment in a circle, measured on the sphere rather than on a flat map.
bool circleContains({
  required GeoPoint center,
  required double radiusM,
  required GeoPoint point,
}) =>
    haversineMeters(center, point) <= radiusM;

/// Point-in-polygon by the even-odd (ray casting) rule.
///
/// Chosen because it handles concave outlines — the L-shaped school yard, the
/// street that bends — which is exactly what a finger draws on a map. The
/// polygon is treated as closed: the last vertex joins the first.
bool polygonContains(List<GeoPoint> vertices, GeoPoint point) {
  if (vertices.length < kMinPolygonVertices) {
    throw ArgumentError.value(
      vertices.length,
      'vertices',
      'المضلّع يحتاج $kMinPolygonVertices رؤوس على الأقل',
    );
  }
  var inside = false;
  for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    final yi = vertices[i].lat;
    final yj = vertices[j].lat;
    if ((yi > point.lat) == (yj > point.lat)) continue;
    final xCross = (vertices[j].lon - vertices[i].lon) *
            (point.lat - yi) /
            (yj - yi) +
        vertices[i].lon;
    if (point.lon < xCross) inside = !inside;
  }
  return inside;
}

/// Distance from [point] to the nearest polygon edge, in metres — the quantity
/// the hysteresis band is measured against.
double distanceToPolygonEdgeMeters(List<GeoPoint> vertices, GeoPoint point) {
  var best = double.infinity;
  for (var i = 0; i < vertices.length; i++) {
    final a = vertices[i];
    final b = vertices[(i + 1) % vertices.length];
    best = math.min(best, _distanceToSegmentMeters(point, a, b));
  }
  return best;
}

/// Local flat-earth projection: safe at fence scale, where the curvature error
/// is orders of magnitude below the GPS error we are already living with.
double _distanceToSegmentMeters(GeoPoint p, GeoPoint a, GeoPoint b) {
  final scaleX = _metersPerDegreeLon(p.lat);
  final ax = (a.lon - p.lon) * scaleX;
  final ay = (a.lat - p.lat) * _metersPerDegreeLat;
  final bx = (b.lon - p.lon) * scaleX;
  final by = (b.lat - p.lat) * _metersPerDegreeLat;
  final dx = bx - ax;
  final dy = by - ay;
  final lengthSq = dx * dx + dy * dy;
  final t = lengthSq == 0
      ? 0.0
      : (-(ax * dx + ay * dy) / lengthSq).clamp(0.0, 1.0);
  final cx = ax + t * dx;
  final cy = ay + t * dy;
  return math.sqrt(cx * cx + cy * cy);
}

/// The shape the engine evaluates — a plain value, not a database row.
sealed class FenceShape {
  const FenceShape();
}

final class CircleShape extends FenceShape {
  const CircleShape({required this.center, required this.radiusM});

  final GeoPoint center;
  final double radiusM;

  BoundingCircle get boundingCircle =>
      BoundingCircle(center: center, radiusM: radiusM);
}

/// Vertex count is validated on the write path ([DriftLocationRepository]'s
/// `saveFence`) and on the evaluate path ([polygonContains]) rather than in the
/// constructor — so an invalid shape fails where it is actually used, with a
/// message that says what is missing, instead of vanishing inside an assert
/// that a release build drops.
final class PolygonShape extends FenceShape {
  const PolygonShape(this.vertices);

  final List<GeoPoint> vertices;

  /// The circle this shape is registered with the OS as.
  BoundingCircle get boundingCircle => boundingCircleOf(vertices);
}

/// What a fix means relative to a fence.
enum GeofenceTransition { enter, exit }

/// The decision layer: turns a stream of fixes into (at most) one event.
///
/// Two guards exist because GPS is not a ruler:
///  · **Accuracy gate** — a fix worse than [maxAccuracyMeters] produces no
///    decision at all. Not "inside", not "outside" — nothing. An event built on
///    a 500 m fix would be a false alarm about a child who never moved.
///  · **Hysteresis band** — a fix within [hysteresisMeters] of the boundary
///    keeps the previous state, so waiting at the school gate does not emit an
///    enter/exit storm every few seconds.
class GeofenceEngine {
  const GeofenceEngine({
    this.hysteresisMeters = 30,
    this.maxAccuracyMeters = 100,
  });

  final double hysteresisMeters;
  final double maxAccuracyMeters;

  /// Signed distance to the boundary in metres: positive inside, negative out.
  double signedInsideDistance(FenceShape shape, GeoPoint fix) {
    switch (shape) {
      case CircleShape(:final center, :final radiusM):
        return radiusM - haversineMeters(center, fix);
      case PolygonShape(:final vertices):
        final edge = distanceToPolygonEdgeMeters(vertices, fix);
        return polygonContains(vertices, fix) ? edge : -edge;
    }
  }

  /// The transition this fix implies, or null when there is nothing to say —
  /// because the fix is too poor, because it sits in the hysteresis band, or
  /// because the state did not actually change.
  ///
  /// [wasInside] is the previously known state; null means this is the first fix
  /// we have ever had, and a first fix only *establishes* state. Opening the app
  /// inside a fence must not fire an ENTER.
  GeofenceTransition? transition({
    required FenceShape shape,
    required GeoPoint fix,
    required double accuracyM,
    required bool? wasInside,
  }) {
    if (accuracyM > maxAccuracyMeters) return null;

    final margin = signedInsideDistance(shape, fix);
    final bool nowInside;
    if (margin >= hysteresisMeters) {
      nowInside = true;
    } else if (margin <= -hysteresisMeters) {
      nowInside = false;
    } else {
      return null; // dead band — too close to the line to call it
    }

    if (wasInside == null || wasInside == nowInside) return null;
    return nowInside ? GeofenceTransition.enter : GeofenceTransition.exit;
  }
}

/// One weekly window of a fence. Absence of windows means "always active".
class ScheduleWindow {
  const ScheduleWindow({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    this.expectBy,
  });

  /// 1 = Monday … 7 = Sunday, the contract's numbering (ISO-8601).
  final int weekday;

  /// Minutes from midnight, 0..1439.
  final int startMinute;
  final int endMinute;

  /// The minute by which the child is expected inside. Null = no NO_SHOW.
  final int? expectBy;

  /// An end at or before the start means the window crosses midnight — the
  /// "home at night" fence from 22:00 to 06:00.
  bool get crossesMidnight => endMinute <= startMinute;

  bool isOpenAt(DateTime local) {
    final minute = local.hour * 60 + local.minute;
    if (!crossesMidnight) {
      return local.weekday == weekday &&
          minute >= startMinute &&
          minute < endMinute;
    }
    if (local.weekday == weekday) return minute >= startMinute;
    final previousDay =
        local.weekday == DateTime.monday ? DateTime.sunday : local.weekday - 1;
    return previousDay == weekday && minute < endMinute;
  }

  /// The instant this window most recently opened at or before [local].
  ///
  /// Plain local-time arithmetic, so a DST shift inside the window moves the
  /// opening by an hour — accepted: this is a schedule, not a measurement.
  DateTime windowOpenedAt(DateTime local) {
    var dayDelta = (local.weekday - weekday) % 7;
    if (dayDelta < 0) dayDelta += 7;
    var open = DateTime(local.year, local.month, local.day)
        .subtract(Duration(days: dayDelta))
        .add(Duration(minutes: startMinute));
    if (open.isAfter(local)) {
      open = open.subtract(const Duration(days: 7));
    }
    return open;
  }

  /// The instant the child was expected inside, for this window's current run.
  DateTime expectationAt(DateTime local) {
    final open = windowOpenedAt(local);
    return DateTime(open.year, open.month, open.day)
        .add(Duration(minutes: expectBy ?? startMinute));
  }
}

/// A fence with no schedule is always active.
bool fenceActiveAt(List<ScheduleWindow> windows, DateTime local) =>
    windows.isEmpty || windows.any((w) => w.isOpenAt(local));

/// The NO_SHOW moment when it is due, or null when there is nothing to raise.
///
/// Due means: a scheduled window is open now, it declared an expectation, that
/// moment has passed, and no arrival was recorded for this run.
/// [arrivedWithinWindow] is the caller's answer to that last part — it comes
/// from the `geofence_event` rows, never from memory.
DateTime? noShowDueAt({
  required List<ScheduleWindow> windows,
  required DateTime local,
  required bool arrivedWithinWindow,
}) {
  if (arrivedWithinWindow) return null;
  for (final w in windows) {
    if (w.expectBy == null || !w.isOpenAt(local)) continue;
    final due = w.expectationAt(local);
    if (!local.isBefore(due)) return due;
  }
  return null;
}
