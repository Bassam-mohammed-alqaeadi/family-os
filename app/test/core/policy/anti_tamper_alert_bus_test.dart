import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';

void main() {
  final child = ChildId('alert-bus-child');

  tearDown(() {
    // Fresh bus per test via local instances — nothing global to clear.
  });

  group('AntiTamperAlertBus', () {
    test('bypassAlert ON → simulateBypassAttempt delivers father alert', () {
      final bus = AntiTamperAlertBus();
      const policy = AntiTamperPolicy(bypassAlert: true);

      final emitted = bus.simulateBypassAttempt(child, policy);

      expect(emitted, isTrue);
      expect(bus.delivered, hasLength(1));
      expect(bus.delivered.single.kind, AntiTamperAlertKind.bypassAttempt);
      expect(bus.delivered.single.childId, child);
      bus.dispose();
    });

    test('bypassAlert OFF → no father alert', () {
      final bus = AntiTamperAlertBus();
      const policy = AntiTamperPolicy(bypassAlert: false);

      expect(bus.simulateBypassAttempt(child, policy), isFalse);
      expect(bus.delivered, isEmpty);
      bus.dispose();
    });

    test('simAlert ON → simulateSimChange delivers father alert', () {
      final bus = AntiTamperAlertBus();
      const policy = AntiTamperPolicy(simAlert: true);

      final emitted = bus.simulateSimChange(child, policy);

      expect(emitted, isTrue);
      expect(bus.delivered.single.kind, AntiTamperAlertKind.simChange);
      bus.dispose();
    });

    test('simAlert OFF → no SIM alert', () {
      final bus = AntiTamperAlertBus();
      expect(
        bus.simulateSimChange(child, const AntiTamperPolicy()),
        isFalse,
      );
      expect(bus.delivered, isEmpty);
      bus.dispose();
    });

    test('fatherAlerts stream receives bypass event', () async {
      final bus = AntiTamperAlertBus();
      final events = <AntiTamperFatherAlert>[];
      final sub = bus.fatherAlerts.listen(events.add);

      bus.simulateBypassAttempt(
        child,
        const AntiTamperPolicy(bypassAlert: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.kind, AntiTamperAlertKind.bypassAttempt);
      await sub.cancel();
      bus.dispose();
    });
  });
}
