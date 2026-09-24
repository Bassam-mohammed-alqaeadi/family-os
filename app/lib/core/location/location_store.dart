import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'geo_point.dart';
import 'geofence_evaluator.dart';
import 'geofence_event.dart';
import 'location_fix.dart';
import 'location_repository.dart';
import 'modes_location_fact_feed.dart';
import 'safe_zone_definition.dart';
import 'zone_geometry.dart';

/// [FamilyLocalDatabase]-backed Location Domain store (SQLite or Memory).
final class LocalLocationStore implements LocationDomainRepository {
  LocalLocationStore(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _zones = 'loc_zone';
  static const _geometry = 'loc_zone_geometry';
  static const _assign = 'loc_zone_assignment';
  static const _trail = 'loc_trail_sample';
  static const _events = 'loc_geofence_event';
  static const _presence = 'loc_zone_presence';

  @override
  Future<void> saveZone(SafeZoneDefinition zone) async {
    if (!zone.hasAssignment) {
      throw const ZoneAssignmentRequiredException();
    }
    if (!zone.geometry.isValid) {
      throw const InvalidZoneGeometryException('geometry failed validation');
    }
    if (zone.name.trim().isEmpty) {
      throw const InvalidZoneGeometryException('name required');
    }

    final now = zone.updatedAt.toUtc();
    await _db.insert(_zones, {
      'id': zone.id,
      'family_id': zone.familyId.value,
      'name': zone.name.trim(),
      'emoji': zone.emoji,
      'active': zone.active ? 1 : 0,
      'archived': zone.archived ? 1 : 0,
      'alert_enter': zone.alertEnter ? 1 : 0,
      'alert_exit': zone.alertExit ? 1 : 0,
      'alert_no_show': zone.alertNoShow ? 1 : 0,
      'created_at': zone.createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);

    await _writeGeometry(zone.id, zone.geometry);

    await _db.delete(_assign, where: 'zone_id = ?', whereArgs: [zone.id]);
    for (final child in zone.assignedChildIds) {
      await _db.insert(_assign, {'zone_id': zone.id, 'child_id': child.value});
    }
  }

  Future<void> _writeGeometry(String zoneId, ZoneGeometry geometry) async {
    if (geometry is CircleGeometry) {
      await _db.insert(_geometry, {
        'zone_id': zoneId,
        'kind': geometry.kindWire,
        'version': geometry.version,
        'center_lat': geometry.center.latitude,
        'center_lng': geometry.center.longitude,
        'radius_m': geometry.radiusMeters,
        'polygon_json': null,
      }, conflictAlgorithm: LocalConflictAlgorithm.replace);
      return;
    }
    if (geometry is PolygonGeometry) {
      await _db.insert(_geometry, {
        'zone_id': zoneId,
        'kind': geometry.kindWire,
        'version': geometry.version,
        'center_lat': null,
        'center_lng': null,
        'radius_m': null,
        'polygon_json': PolygonGeometry.encodeVertices(geometry.vertices),
      }, conflictAlgorithm: LocalConflictAlgorithm.replace);
      return;
    }
    throw const InvalidZoneGeometryException('unsupported geometry type');
  }

  @override
  Future<SafeZoneDefinition?> getZone(String zoneId) async {
    final rows = await _db.query(
      _zones,
      where: 'id = ?',
      whereArgs: [zoneId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrateZone(rows.first);
  }

  @override
  Future<List<SafeZoneDefinition>> listZones(FamilyId familyId) async {
    final rows = await _db.query(
      _zones,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'updated_at DESC',
    );
    final out = <SafeZoneDefinition>[];
    for (final row in rows) {
      out.add(await _hydrateZone(row));
    }
    return out;
  }

  Future<SafeZoneDefinition> _hydrateZone(Map<String, Object?> row) async {
    final id = row['id']! as String;
    final geoRows = await _db.query(
      _geometry,
      where: 'zone_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (geoRows.isEmpty) {
      throw StateError('Zone $id missing geometry');
    }
    final geometry = _geometryFromRow(geoRows.first);

    final assignRows = await _db.query(
      _assign,
      where: 'zone_id = ?',
      whereArgs: [id],
    );
    final children = [
      for (final a in assignRows) ChildId(a['child_id']! as String),
    ];

    return SafeZoneDefinition(
      id: id,
      familyId: FamilyId(row['family_id']! as String),
      name: row['name']! as String,
      emoji: row['emoji'] as String? ?? '📍',
      geometry: geometry,
      assignedChildIds: children,
      active: (row['active'] as int? ?? 1) == 1,
      archived: (row['archived'] as int? ?? 0) == 1,
      alertEnter: (row['alert_enter'] as int? ?? 1) == 1,
      alertExit: (row['alert_exit'] as int? ?? 1) == 1,
      alertNoShow: (row['alert_no_show'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
        isUtc: true,
      ),
    );
  }

  ZoneGeometry _geometryFromRow(Map<String, Object?> row) {
    final kind = (row['kind']! as String).toUpperCase();
    final version = row['version'] as int? ?? 1;
    if (kind == 'CIRCLE') {
      return CircleGeometry(
        center: GeoPoint(
          latitude: (row['center_lat']! as num).toDouble(),
          longitude: (row['center_lng']! as num).toDouble(),
        ),
        radiusMeters: (row['radius_m']! as num).toDouble(),
        version: version,
      );
    }
    if (kind == 'POLYGON') {
      final raw = row['polygon_json'] as String? ?? '[]';
      return PolygonGeometry(
        vertices: PolygonGeometry.decodeVertices(raw),
        version: version,
      );
    }
    throw FormatException('Unknown geometry kind in store: $kind');
  }

  @override
  Future<void> archiveZone(String zoneId, {required DateTime now}) async {
    await _db.update(
      _zones,
      {
        'archived': 1,
        'active': 0,
        'updated_at': now.toUtc().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [zoneId],
    );
  }

  @override
  Future<void> appendFix(LocationFix fix) async {
    if (!fix.isHonest) {
      throw const DishonestLocationFixException(
        'located/stale require valid coordinates; never fake GPS success',
      );
    }

    await _db.insert(_trail, {
      'id': fix.id,
      'family_id': fix.familyId.value,
      'child_id': fix.childId.value,
      'device_id': fix.deviceId.value,
      'acquisition': fix.acquisition.wireName,
      'lat': fix.point?.latitude,
      'lng': fix.point?.longitude,
      'accuracy_m': fix.accuracyMeters,
      'integrity_soft': fix.integritySoftWarning ? 1 : 0,
      'recorded_at': fix.recordedAt.toUtc().millisecondsSinceEpoch,
    });

    // Retention prune (90-day floor) — filter in Dart for Memory DB safety.
    final cutoff = fix.recordedAt
        .toUtc()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;
    final stale = await _db.query(
      _trail,
      where: 'child_id = ?',
      whereArgs: [fix.childId.value],
    );
    for (final row in stale) {
      final at = row['recorded_at'] as int? ?? 0;
      if (at < cutoff) {
        await _db.delete(_trail, where: 'id = ?', whereArgs: [row['id']]);
      }
    }
  }

  @override
  Future<List<LocationFix>> listTrail(
    FamilyId familyId,
    ChildId childId, {
    int retainDays = 90,
    int? limit,
  }) async {
    final cutoff = _clock()
        .toUtc()
        .subtract(Duration(days: retainDays))
        .millisecondsSinceEpoch;
    final rows = await _db.query(
      _trail,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
      orderBy: 'recorded_at DESC',
    );
    var fixes = rows
        .where((r) => (r['recorded_at'] as int? ?? 0) >= cutoff)
        .map(_fixFromRow)
        .toList();
    if (limit != null && fixes.length > limit) {
      fixes = fixes.sublist(0, limit);
    }
    return fixes;
  }

  @override
  Future<LocationFix?> latestFix(FamilyId familyId, ChildId childId) async {
    final all = await _db.query(
      _trail,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
      orderBy: 'recorded_at DESC',
    );
    for (final row in all) {
      final acq = LocationAcquisitionStatusWire.parse(
        row['acquisition']! as String,
      );
      if (acq == LocationAcquisitionStatus.located ||
          acq == LocationAcquisitionStatus.staleLastKnown) {
        return _fixFromRow(row);
      }
    }
    return null;
  }

  LocationFix _fixFromRow(Map<String, Object?> row) {
    final lat = row['lat'] as num?;
    final lng = row['lng'] as num?;
    GeoPoint? point;
    if (lat != null && lng != null) {
      point = GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble());
    }
    return LocationFix(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      deviceId: DeviceId(row['device_id']! as String),
      acquisition: LocationAcquisitionStatusWire.parse(
        row['acquisition']! as String,
      ),
      point: point,
      accuracyMeters: (row['accuracy_m'] as num?)?.toDouble(),
      integritySoftWarning: (row['integrity_soft'] as int? ?? 0) == 1,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        row['recorded_at']! as int,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> appendGeofenceEvent(GeofenceEvent event) async {
    await _db.insert(_events, {
      'event_id': event.eventId,
      'family_id': event.familyId.value,
      'child_id': event.childId.value,
      'device_id': event.deviceId.value,
      'zone_id': event.zoneId,
      'kind': event.kind.wireName,
      'occurred_at': event.occurredAt.toUtc().millisecondsSinceEpoch,
      'geometry_version': event.geometryVersion,
    });
  }

  @override
  Future<List<GeofenceEvent>> listGeofenceEvents(
    FamilyId familyId, {
    String? zoneId,
    ChildId? childId,
    int? limit,
  }) async {
    final rows = await _db.query(
      _events,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'occurred_at DESC',
    );
    var events = rows.map(_eventFromRow).toList();
    if (zoneId != null) {
      events = events.where((e) => e.zoneId == zoneId).toList();
    }
    if (childId != null) {
      events = events.where((e) => e.childId == childId).toList();
    }
    if (limit != null && events.length > limit) {
      events = events.sublist(0, limit);
    }
    return events;
  }

  GeofenceEvent _eventFromRow(Map<String, Object?> row) {
    return GeofenceEvent(
      eventId: row['event_id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      deviceId: DeviceId(row['device_id']! as String),
      zoneId: row['zone_id']! as String,
      kind: GeofenceEventKindWire.parse(row['kind']! as String),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at']! as int,
        isUtc: true,
      ),
      geometryVersion: row['geometry_version'] as int?,
    );
  }

  @override
  Future<bool?> wasInside({
    required String zoneId,
    required ChildId childId,
  }) async {
    final rows = await _db.query(
      _presence,
      where: 'zone_id = ? AND child_id = ?',
      whereArgs: [zoneId, childId.value],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['inside'] as int? ?? 0) == 1;
  }

  @override
  Future<void> setInside({
    required String zoneId,
    required ChildId childId,
    required bool inside,
  }) async {
    await _db.insert(_presence, {
      'zone_id': zoneId,
      'child_id': childId.value,
      'inside': inside ? 1 : 0,
      'updated_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }
}

/// Convenience: evaluate fix → optional event + update presence + Modes feed.
extension LocationDomainEvaluate on LocationDomainRepository {
  Future<GeofenceEvent?> evaluateAndRecord({
    required SafeZoneDefinition zone,
    required LocationFix fix,
    required String eventId,
    ModesLocationFactFeed? modesFeed,
  }) async {
    if (fix.point == null || !fix.point!.isValid) return null;
    if (!zone.assignedChildIds.contains(fix.childId)) return null;

    final prior = await wasInside(zoneId: zone.id, childId: fix.childId);
    final was = prior ?? false;
    final kind = GeofenceEvaluator.evaluateFix(
      geometry: zone.geometry,
      point: fix.point!,
      wasInside: was,
    );
    final isInside = zone.geometry.contains(fix.point!);
    await setInside(zoneId: zone.id, childId: fix.childId, inside: isInside);

    if (modesFeed != null) {
      await modesFeed.publishPresence(
        familyId: fix.familyId,
        childId: fix.childId,
        zoneId: zone.id,
        inside: isInside,
      );
    }

    if (kind == null) return null;
    if (kind == GeofenceEventKind.enter && !zone.alertEnter) return null;
    if (kind == GeofenceEventKind.exit && !zone.alertExit) return null;

    final event = GeofenceEvent(
      eventId: eventId,
      familyId: fix.familyId,
      childId: fix.childId,
      deviceId: fix.deviceId,
      zoneId: zone.id,
      kind: kind,
      occurredAt: fix.recordedAt,
      geometryVersion: zone.geometry.version,
    );
    await appendGeofenceEvent(event);
    if (modesFeed != null) {
      await modesFeed.publishFromGeofenceEvent(event);
    }
    return event;
  }
}
