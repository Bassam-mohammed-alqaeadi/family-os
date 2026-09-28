import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/features/n02_day/alert_detail_local_projection.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';

void main() {
  test('projects active SOS into FAT-020 detail', () async {
    final sos = InMemorySosAlertRepository(
      initialActive: InMemorySosAlertRepository.demoActive(),
    );
    final repo = ProjectingAlertDetailRepository(sos: sos);
    final detail = await repo.load(alertId: 'sos-active', alertKind: 'sos');
    expect(detail, isNotNull);
    expect(detail!.kind, AlertDetailKind.sos);
    expect(detail.urgency.name, 'critical');
  });

  test('projects tamper bus into FAT-020 detail', () async {
    final bus = AntiTamperAlertBus();
    bus.simulateBypassAttempt(
      ChildId('child_b'),
      const AntiTamperPolicy(bypassAlert: true),
      at: DateTime.utc(2026, 9, 27, 12),
    );
    final repo = ProjectingAlertDetailRepository(tamperBus: bus);
    final detail = await repo.load(alertKind: 'tamper');
    expect(detail, isNotNull);
    expect(detail!.kind, AlertDetailKind.tamper);
    expect(detail.childId, 'child_b');
  });
}
