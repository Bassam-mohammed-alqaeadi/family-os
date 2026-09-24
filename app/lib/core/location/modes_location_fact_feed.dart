import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'geofence_event.dart';

/// Location context facts published for Modes consumption (MODE-OD-09).
///
/// FS-001 owns geometry/truth; FS-005 owns Mode activation decisions.
/// This feed never activates a Mode.
enum LocationModeFactKind {
  /// Child ENTER zone.
  zoneEnter,

  /// Child EXIT zone.
  zoneExit,

  /// Explicit NO_SHOW fact.
  zoneNoShow,

  /// Presence snapshot (inside=true/false) for schedule context.
  presence,
}

extension LocationModeFactKindWire on LocationModeFactKind {
  String get wireName => switch (this) {
    LocationModeFactKind.zoneEnter => 'ZONE_ENTER',
    LocationModeFactKind.zoneExit => 'ZONE_EXIT',
    LocationModeFactKind.zoneNoShow => 'ZONE_NO_SHOW',
    LocationModeFactKind.presence => 'PRESENCE',
  };

  static LocationModeFactKind parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'ZONE_ENTER':
        return LocationModeFactKind.zoneEnter;
      case 'ZONE_EXIT':
        return LocationModeFactKind.zoneExit;
      case 'ZONE_NO_SHOW':
        return LocationModeFactKind.zoneNoShow;
      case 'PRESENCE':
        return LocationModeFactKind.presence;
      default:
        throw FormatException('Unknown LocationModeFactKind: $raw');
    }
  }
}

@immutable
final class LocationModeFact {
  const LocationModeFact({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.kind,
    required this.occurredAt,
    this.zoneId,
    this.inside,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final LocationModeFactKind kind;
  final DateTime occurredAt;
  final String? zoneId;

  /// Only for [LocationModeFactKind.presence].
  final bool? inside;
}

/// Read-only fact feed for Modes / Kernel — no Mode mutation APIs.
final class ModesLocationFactFeed {
  ModesLocationFactFeed(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final DateTime Function() _clock;

  static const _table = 'loc_mode_fact';

  /// Publish from a canonical geofence event (FS-001 → Modes context).
  Future<LocationModeFact> publishFromGeofenceEvent(GeofenceEvent event) async {
    final kind = switch (event.kind) {
      GeofenceEventKind.enter => LocationModeFactKind.zoneEnter,
      GeofenceEventKind.exit => LocationModeFactKind.zoneExit,
      GeofenceEventKind.noShow => LocationModeFactKind.zoneNoShow,
    };
    final fact = LocationModeFact(
      id: 'mf_${event.eventId}',
      familyId: event.familyId,
      childId: event.childId,
      kind: kind,
      zoneId: event.zoneId,
      occurredAt: event.occurredAt,
    );
    await _insert(fact);
    return fact;
  }

  Future<LocationModeFact> publishPresence({
    required FamilyId familyId,
    required ChildId childId,
    required String zoneId,
    required bool inside,
  }) async {
    final now = _clock().toUtc();
    // Include inside bit so ENTER then EXIT in the same ms never collide.
    final fact = LocationModeFact(
      id:
          'mf_pres_${zoneId}_${childId.value}_${inside ? 'in' : 'out'}_'
          '${now.millisecondsSinceEpoch}',
      familyId: familyId,
      childId: childId,
      kind: LocationModeFactKind.presence,
      zoneId: zoneId,
      inside: inside,
      occurredAt: now,
    );
    await _insert(fact);
    return fact;
  }

  Future<List<LocationModeFact>> listForChild(
    FamilyId familyId,
    ChildId childId, {
    int? limit,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<LocationModeFact>> listForZone(
    FamilyId familyId,
    String zoneId, {
    int? limit,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'family_id = ? AND zone_id = ?',
      whereArgs: [familyId.value, zoneId],
      orderBy: 'occurred_at DESC',
    );
    var facts = rows.map(_fromRow).toList();
    if (limit != null && facts.length > limit) {
      facts = facts.sublist(0, limit);
    }
    return facts;
  }

  Future<void> _insert(LocationModeFact fact) async {
    await _db.insert(_table, {
      'id': fact.id,
      'family_id': fact.familyId.value,
      'child_id': fact.childId.value,
      'kind': fact.kind.wireName,
      'zone_id': fact.zoneId,
      'inside': fact.inside == null ? null : (fact.inside! ? 1 : 0),
      'occurred_at': fact.occurredAt.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: LocalConflictAlgorithm.replace);
  }

  static LocationModeFact _fromRow(Map<String, Object?> row) {
    final insideRaw = row['inside'] as int?;
    return LocationModeFact(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      kind: LocationModeFactKindWire.parse(row['kind']! as String),
      zoneId: row['zone_id'] as String?,
      inside: insideRaw == null ? null : insideRaw == 1,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at']! as int,
        isUtc: true,
      ),
    );
  }
}
