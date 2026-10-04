import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/features/n02_day/alerts_hub_local_projection.dart';
import 'package:family_os/features/n06_notifications/family_alert_catalog.dart';

void main() {
  test(
    'geofence ENTER → reassurance arrive; EXIT → critical leaveZone',
    () async {
      final now = DateTime.utc(2026, 9, 27, 12);
      final events = [
        GeofenceEvent(
          eventId: 'e_enter',
          familyId: FamilyId('fam_t'),
          childId: ChildId('kid_a'),
          deviceId: DeviceId('dev_a'),
          zoneId: 'z1',
          kind: GeofenceEventKind.enter,
          occurredAt: now,
        ),
        GeofenceEvent(
          eventId: 'e_exit',
          familyId: FamilyId('fam_t'),
          childId: ChildId('kid_a'),
          deviceId: DeviceId('dev_a'),
          zoneId: 'z1',
          kind: GeofenceEventKind.exit,
          occurredAt: now.add(const Duration(minutes: 5)),
        ),
      ];

      final hub = ProjectingAlertsHubRepository(
        familyId: () => FamilyId('fam_t'),
        listGeofenceEvents: () async => events,
        listTimePending: () async => const [],
        listAppPending: (_) async => const [],
      );

      final snap = await hub.load();
      expect(
        snap.critical.any((a) => a.alertKind == FamilyAlertKinds.leaveZone),
        isTrue,
      );
      expect(
        snap.reassurance.any((a) => a.alertKind == FamilyAlertKinds.arriveSafe),
        isTrue,
      );
    },
  );
}
