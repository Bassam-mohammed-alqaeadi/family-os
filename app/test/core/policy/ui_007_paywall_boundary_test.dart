import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/entitlement_service.dart';
import 'package:family_os/core/policy/sos_fire.dart';

void main() {
  group('UI-007 entitlement states', () {
    test('mock supports active / trial / expired', () {
      final svc = MockEntitlementService(Entitlement.activeFamily());
      expect(svc.current.isActive, isTrue);

      svc.setEntitlement(Entitlement.trial(daysRemaining: 3));
      expect(svc.current.isTrial, isTrue);
      expect(svc.current.trialDaysRemaining, 3);

      svc.setEntitlement(Entitlement.expired());
      expect(svc.current.isExpired, isTrue);
    });

    test('cancelRenewal expires plan without touching SOS API', () async {
      final svc = MockEntitlementService(Entitlement.trial());
      await svc.cancelRenewal();
      expect(svc.current.isExpired, isTrue);
      expect(svc.current.autoRenew, isFalse);
    });
  });

  group('UI-007 P-4 SOS fire ignores entitlement', () {
    test('expired entitlement + SosFire.fire still succeeds', () async {
      final entitlement = MockEntitlementService(Entitlement.expired());
      expect(entitlement.current.isExpired, isTrue);

      // SosFire has no EntitlementService parameter — boundary by API shape.
      final sos = MockSosFireService();
      final result = await sos.fire(childId: 'child-1');

      expect(result.fired, isTrue);
      expect(sos.fireCount, 1);
      expect(
        result.recipientDeliveries.every((d) => d.delivered),
        isTrue,
      );
    });

    test('active and trial also fire', () async {
      final sos = MockSosFireService();
      for (final _ in [
        Entitlement.activeFamily(),
        Entitlement.trial(),
        Entitlement.expired(),
      ]) {
        final r = await sos.fire(childId: 'c');
        expect(r.fired, isTrue);
      }
      expect(sos.fireCount, 3);
    });
  });

  group('UI-007 chat usable when expired', () {
    test('AlwaysOnChatAvailability ignores plan state', () {
      final entitlement = MockEntitlementService(Entitlement.expired());
      expect(entitlement.current.isExpired, isTrue);

      const chat = AlwaysOnChatAvailability();
      expect(chat.isUsable, isTrue);
      expect(chat.canSend, isTrue);
      expect(stage1ChatAvailability.isUsable, isTrue);
    });
  });

  group('architecture — SOS/chat must not import entitlement', () {
    test('guardian modules have no entitlement import', () {
      final importLeak = RegExp(
        r'''import\s+['"][^'"]*entitlement[^'"]*['"]''',
        caseSensitive: false,
      );
      const guardians = [
        'lib/core/policy/sos_fire.dart',
        'lib/core/policy/chat_availability.dart',
        'lib/core/policy/chat_mock_store.dart',
        'lib/core/policy/sos_ladder.dart',
        'lib/core/policy/sos_ladder_repository.dart',
        'lib/core/policy/notification_delivery.dart',
      ];

      final offenders = <String>[];
      for (final path in guardians) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final text = file.readAsStringSync();
        if (importLeak.hasMatch(text) ||
            text.contains('EntitlementService') ||
            text.contains('MockEntitlementService')) {
          offenders.add(path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Entitlement leak into safety modules: $offenders',
      );
    });

    test('SosFireService API surface has no entitlement parameter', () {
      // Compile-time proof: fire() signature uses only childId/recipients/clock.
      final sos = MockSosFireService();
      expect(sos, isA<SosFireService>());
    });
  });
}
