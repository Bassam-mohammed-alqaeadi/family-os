import 'package:drift/drift.dart';

import 'family_database.dart';
import 'geofence_engine.dart';

/// Rule 25 seam — location history, fences and their events as real rows.
///
/// The engine decides, this store only records. Keeping the two apart is what
/// lets every decision rule be unit-tested without a database.
abstract class LocationRepository {
  /// Appends one fix. Returns the stored row id.
  Future<int> recordPing(LocationPingsCompanion ping);

  Future<List<LocationPing>> pingsFor(
    String childId, {
    DateTime? since,
    int limit = 500,
  });

  Future<LocationPing?> latestPing(String childId);

  /// The contract's `prune_locations()`: "تُقلَّم تلقائيًا بعد ٩٠ يومًا".
  Future<int> prunePings({DateTime? now});

  /// Writes a fence and its geometry in one transaction. [shape] carries the
  /// geometry, so a circle without a radius or a two-vertex polygon cannot even
  /// be expressed — and [saveFence] returns the **stored** row.
  Future<Geofence> saveFence({
    required String id,
    required String familyId,
    required String name,
    required FenceShape shape,
    required String createdBy,
    String? childId,
    String icon = 'home',
    double? altitudeM,
    String? floorLabel,
    List<ScheduleWindow> schedule = const [],
    DateTime? at,
  });

  Future<Geofence?> fenceById(String id);

  Future<List<Geofence>> fencesForFamily(String familyId, {String? childId});

  Future<List<GeoPoint>> verticesOf(String geofenceId);

  Future<List<ScheduleWindow>> scheduleOf(String geofenceId);

  /// The fence's geometry as the engine's own value type.
  Future<FenceShape> shapeOf(String geofenceId);

  /// Removes the fence and everything hanging off it, as the contract's
  /// `ON DELETE CASCADE` does.
  Future<int> deleteFence(String id);

  Future<int> appendEvent(GeofenceEventsCompanion event);

  Future<List<GeofenceEvent>> eventsFor(
    String geofenceId, {
    String? childId,
    int limit = 100,
  });

  /// Whether the child was seen inside since [since] — the fact a NO_SHOW is
  /// decided against, read from rows rather than remembered in a field.
  Future<bool> hasEnteredSince(String geofenceId, String childId, DateTime since);
}

final class DriftLocationRepository implements LocationRepository {
  DriftLocationRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<int> recordPing(LocationPingsCompanion ping) {
    return _db.into(_db.locationPings).insert(ping);
  }

  @override
  Future<List<LocationPing>> pingsFor(
    String childId, {
    DateTime? since,
    int limit = 500,
  }) {
    final query = _db.select(_db.locationPings)
      ..where((t) => t.childId.equals(childId))
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(limit);
    if (since != null) {
      query.where((t) => t.recordedAt.isBiggerOrEqualValue(since));
    }
    return query.get();
  }

  @override
  Future<LocationPing?> latestPing(String childId) {
    return (_db.select(_db.locationPings)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<int> prunePings({DateTime? now}) {
    final cutoff =
        (now ?? DateTime.now()).subtract(const Duration(days: kLocationRetentionDays));
    return (_db.delete(_db.locationPings)
          ..where((t) => t.recordedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  @override
  Future<Geofence> saveFence({
    required String id,
    required String familyId,
    required String name,
    required FenceShape shape,
    required String createdBy,
    String? childId,
    String icon = 'home',
    double? altitudeM,
    String? floorLabel,
    List<ScheduleWindow> schedule = const [],
    DateTime? at,
  }) async {
    // A polygon's stored centre is its bounding circle's centre — the same
    // circle the OS is given, so the row and the registration cannot disagree.
    final center = switch (shape) {
      CircleShape(:final center) => center,
      PolygonShape(:final vertices) => boundingCircleOf(vertices).center,
    };
    final int? storedRadiusM;
    switch (shape) {
      case CircleShape(:final radiusM):
        storedRadiusM = _checkCircleRadius(radiusM);
      case PolygonShape(:final vertices):
        _requirePolygon(vertices);
        storedRadiusM = null;
    }
    final windows = schedule.map(_checkWindow).toList(growable: false);

    return _db.transaction(() async {
      await _db.into(_db.geofences).insertOnConflictUpdate(
            GeofencesCompanion.insert(
              id: id,
              familyId: familyId,
              childId: Value(childId),
              name: name,
              shape: shape is PolygonShape
                  ? GeofenceShape.polygon
                  : GeofenceShape.circle,
              lat: center.lat,
              lon: center.lon,
              radiusM: Value(storedRadiusM),
              icon: Value(icon),
              altitudeM: Value(altitudeM),
              floorLabel: Value(floorLabel),
              createdBy: createdBy,
              createdAt: Value(at ?? DateTime.now()),
            ),
          );

      // Geometry is replaced wholesale: a fence re-drawn on the map is a new
      // boundary, and leaving stale vertices behind would silently widen it.
      await (_db.delete(_db.geofenceVertices)
            ..where((t) => t.geofenceId.equals(id)))
          .go();
      await (_db.delete(_db.geofenceSchedules)
            ..where((t) => t.geofenceId.equals(id)))
          .go();

      if (shape is PolygonShape) {
        for (var i = 0; i < shape.vertices.length; i++) {
          await _db.into(_db.geofenceVertices).insert(
                GeofenceVerticesCompanion.insert(
                  geofenceId: id,
                  seq: i,
                  lat: shape.vertices[i].lat,
                  lon: shape.vertices[i].lon,
                ),
              );
        }
      }

      for (final w in windows) {
        await _db.into(_db.geofenceSchedules).insert(
              GeofenceSchedulesCompanion.insert(
                id: '${id}_${w.weekday}_${w.startMinute}',
                geofenceId: id,
                weekday: w.weekday,
                startMinute: w.startMinute,
                endMinute: w.endMinute,
                expectBy: Value(w.expectBy),
              ),
            );
      }

      return (await fenceById(id))!;
    });
  }

  @override
  Future<Geofence?> fenceById(String id) {
    return (_db.select(_db.geofences)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<Geofence>> fencesForFamily(String familyId, {String? childId}) {
    final query = _db.select(_db.geofences)
      ..where((t) => t.familyId.equals(familyId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (childId != null) {
      // A fence aimed at one child and the family-wide ones both apply to them.
      query.where((t) => t.childId.equals(childId) | t.childId.isNull());
    }
    return query.get();
  }

  @override
  Future<List<GeoPoint>> verticesOf(String geofenceId) async {
    final rows = await (_db.select(_db.geofenceVertices)
          ..where((t) => t.geofenceId.equals(geofenceId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return rows.map((r) => GeoPoint(r.lat, r.lon)).toList(growable: false);
  }

  @override
  Future<List<ScheduleWindow>> scheduleOf(String geofenceId) async {
    final rows = await (_db.select(_db.geofenceSchedules)
          ..where((t) => t.geofenceId.equals(geofenceId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.weekday),
            (t) => OrderingTerm.asc(t.startMinute),
          ]))
        .get();
    return rows
        .map((r) => ScheduleWindow(
              weekday: r.weekday,
              startMinute: r.startMinute,
              endMinute: r.endMinute,
              expectBy: r.expectBy,
            ))
        .toList(growable: false);
  }

  @override
  Future<FenceShape> shapeOf(String geofenceId) async {
    final fence = await fenceById(geofenceId);
    if (fence == null) {
      throw ArgumentError.value(
        geofenceId,
        'geofenceId',
        'لا يوجد سياج بهذا المعرّف',
      );
    }
    return switch (fence.shape) {
      GeofenceShape.circle => CircleShape(
          center: GeoPoint(fence.lat, fence.lon),
          radiusM: (fence.radiusM ?? kMinFenceRadiusM).toDouble(),
        ),
      GeofenceShape.polygon => PolygonShape(await verticesOf(geofenceId)),
    };
  }

  @override
  Future<int> deleteFence(String id) {
    return _db.transaction(() async {
      // Deleted explicitly rather than leaning on FK cascade: the device copy
      // must not depend on a pragma the platform build might not set.
      await (_db.delete(_db.geofenceEvents)
            ..where((t) => t.geofenceId.equals(id)))
          .go();
      await (_db.delete(_db.geofenceVertices)
            ..where((t) => t.geofenceId.equals(id)))
          .go();
      await (_db.delete(_db.geofenceSchedules)
            ..where((t) => t.geofenceId.equals(id)))
          .go();
      return (_db.delete(_db.geofences)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<int> appendEvent(GeofenceEventsCompanion event) {
    return _db.into(_db.geofenceEvents).insert(event);
  }

  @override
  Future<List<GeofenceEvent>> eventsFor(
    String geofenceId, {
    String? childId,
    int limit = 100,
  }) {
    final query = _db.select(_db.geofenceEvents)
      ..where((t) => t.geofenceId.equals(geofenceId))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    if (childId != null) {
      query.where((t) => t.childId.equals(childId));
    }
    return query.get();
  }

  @override
  Future<bool> hasEnteredSince(
    String geofenceId,
    String childId,
    DateTime since,
  ) async {
    final row = await (_db.select(_db.geofenceEvents)
          ..where((t) =>
              t.geofenceId.equals(geofenceId) &
              t.childId.equals(childId) &
              t.occurredAt.isBiggerOrEqualValue(since) &
              t.kind.equalsValue(GeofenceEventKind.enter))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}

int _checkCircleRadius(double radiusM) {
  final rounded = radiusM.round();
  if (rounded < kMinFenceRadiusM || rounded > kMaxFenceRadiusM) {
    throw ArgumentError.value(
      radiusM,
      'radiusM',
      'المدى المسموح $kMinFenceRadiusM..$kMaxFenceRadiusM م',
    );
  }
  return rounded;
}

void _requirePolygon(List<GeoPoint> vertices) {
  if (vertices.length < kMinPolygonVertices) {
    throw ArgumentError.value(
      vertices.length,
      'vertices',
      'المضلّع يحتاج $kMinPolygonVertices رؤوس على الأقل',
    );
  }
}

ScheduleWindow _checkWindow(ScheduleWindow w) {
  if (w.weekday < 1 || w.weekday > 7) {
    throw ArgumentError.value(w.weekday, 'weekday', '1..7 (ISO-8601)');
  }
  for (final minute in [w.startMinute, w.endMinute]) {
    if (minute < 0 || minute > 1439) {
      throw ArgumentError.value(minute, 'minute', '0..1439');
    }
  }
  if (w.endMinute == w.startMinute) {
    throw ArgumentError.value(
      w.startMinute,
      'endMinute',
      'نافذة فارغة — البداية والنهاية متساويتان',
    );
  }
  final expectBy = w.expectBy;
  if (expectBy != null && (expectBy < w.startMinute || expectBy > 1439)) {
    throw ArgumentError.value(
      expectBy,
      'expectBy',
      'لا يسبق بداية النافذة ولا يتجاوز ١٤٣٩',
    );
  }
  return w;
}
