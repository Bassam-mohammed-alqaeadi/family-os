import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/zone_geometry.dart';

/// Explicit local-only sample zones used by the mock-first Stage-1 experience.
///
/// They are definitions only: no device trail, GPS sample or live location is
/// implied by this fixture.
List<SafeZoneDefinition> realLocalSafeZoneSeedMock({
  required FamilyId familyId,
  required List<ChildId> assignedChildIds,
  required DateTime now,
}) {
  return [
    SafeZoneDefinition(
      id: 'zone_home_real_local',
      familyId: familyId,
      name: 'المنزل',
      emoji: '📍',
      geometry: const CircleGeometry(
        center: GeoPoint(latitude: 24.7136, longitude: 46.6753),
        radiusMeters: 250,
      ),
      assignedChildIds: assignedChildIds,
      createdAt: now,
      updatedAt: now,
    ),
    SafeZoneDefinition(
      id: 'zone_school_real_local',
      familyId: familyId,
      name: 'المدرسة',
      emoji: '📍',
      geometry: const CircleGeometry(
        center: GeoPoint(latitude: 24.7250, longitude: 46.6900),
        radiusMeters: 180,
      ),
      assignedChildIds: assignedChildIds,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
