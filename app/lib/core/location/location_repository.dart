import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'geofence_event.dart';
import 'location_fix.dart';
import 'safe_zone_definition.dart';

/// FS-001 Location Domain repository (Rule 25 seam).
///
/// Persists zones/trail/events locally. Remote sync is MockRemote only —
/// this interface never claims cloud ack.
abstract class LocationDomainRepository {
  /// Saves a zone. Requires ≥1 child assignment and valid geometry.
  Future<void> saveZone(SafeZoneDefinition zone);

  Future<SafeZoneDefinition?> getZone(String zoneId);

  Future<List<SafeZoneDefinition>> listZones(FamilyId familyId);

  Future<void> archiveZone(String zoneId, {required DateTime now});

  /// Appends a trail sample. Rejects dishonest located/stale without coords.
  Future<void> appendFix(LocationFix fix);

  /// Trail for [childId], newest first. Optionally prune beyond [retainDays]
  /// (default 90 — LOC-OD retention floor).
  Future<List<LocationFix>> listTrail(
    FamilyId familyId,
    ChildId childId, {
    int retainDays = 90,
    int? limit,
  });

  /// Latest usable fix (located or stale) for child, if any.
  Future<LocationFix?> latestFix(FamilyId familyId, ChildId childId);

  /// Append-only canonical event.
  Future<void> appendGeofenceEvent(GeofenceEvent event);

  Future<List<GeofenceEvent>> listGeofenceEvents(
    FamilyId familyId, {
    String? zoneId,
    ChildId? childId,
    int? limit,
  });

  /// Presence memory for dwell/transition (per child+zone).
  Future<bool?> wasInside({required String zoneId, required ChildId childId});

  Future<void> setInside({
    required String zoneId,
    required ChildId childId,
    required bool inside,
  });
}
