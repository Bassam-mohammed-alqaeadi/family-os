import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n06_notifications/alert_event.dart';
import 'package:family_os/features/n06_notifications/family_alert_catalog.dart';

void main() {
  test('catalog has live core kinds and wire-later hooks', () {
    expect(
      kFamilyAlertCatalog.any((e) => e.kind == FamilyAlertKinds.sos),
      isTrue,
    );
    expect(
      kFamilyAlertCatalog.any(
        (e) => e.kind == FamilyAlertKinds.timeRequest && e.status == 'live',
      ),
      isTrue,
    );
    expect(
      kFamilyAlertCatalog.any(
        (e) => e.kind == FamilyAlertKinds.strangerContact && e.status == 'hook',
      ),
      isTrue,
    );
    expect(
      kFamilyAlertCatalog.any(
        (e) => e.kind == FamilyAlertKinds.arriveSafe && e.status == 'live',
      ),
      isTrue,
    );
    expect(
      kFamilyAlertCatalog.any(
        (e) => e.kind == FamilyAlertKinds.leaveZone && e.status == 'live',
      ),
      isTrue,
    );
    expect(
      kFamilyAlertCatalog.where((e) => e.lane == FamilyAlertLane.critical),
      isNotEmpty,
    );
  });

  test('AlertEvent.fromCatalog carries lane + kind', () {
    final spec = kFamilyAlertCatalog.firstWhere(
      (e) => e.kind == FamilyAlertKinds.sos,
    );
    final event = AlertEvent.fromCatalog(
      id: 'e1',
      spec: spec,
      at: DateTime.utc(2026, 9, 27),
      childId: 'child_a',
    );
    expect(event.kind, FamilyAlertKinds.sos);
    expect(event.lane, FamilyAlertLane.critical);
    expect(event.childId, 'child_a');
  });
}
