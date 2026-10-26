import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/features/n06_notifications/family_notification_router.dart';

const _child = '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb';
const _alert = 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b';
const _device = '6dbb6760-f609-4f3e-a29f-4c209dc1d53b';
const _zone = 'ef211c24-fce2-4bdc-a254-2bf1ad2396a1';

void main() {
  group('PendingAlert', () {
    test('SOS payload becomes a validated emergency route', () {
      final pending = PendingAlert.fromData(<String, dynamic>{
        'type': 'family.sos_alert_raised',
        'copyKey': 'sos.raised',
        'alertId': _alert,
        'childId': _child,
        'occurredAt': '2026-05-10T15:45:00Z',
      });

      expect(pending?.channelId, 'familyos_sos_alerts');
      expect(
        pending?.route,
        '/scr-fat-018?alertId=$_alert&childId=$_child',
      );
      expect(PendingAlert.validateRoute(pending?.route), pending?.route);
      expect(pending?.occurredAt, DateTime.utc(2026, 5, 10, 15, 45));
    });

    test('both geofence directions route to the selected child map and share one channel', () {
      for (final event in <(String, String)>[
        ('family.geofence_entered', 'geofence.entered'),
        ('family.geofence_exited', 'geofence.exited'),
      ]) {
        final pending = PendingAlert.fromData(<String, dynamic>{
          'type': event.$1,
          'copyKey': event.$2,
          'childId': _child,
          'zoneId': _zone,
        });
        expect(pending?.route, '/scr-fat-014?childId=$_child');
        expect(pending?.channelId, 'familyos_geofence_alerts');
      }
    });

    test('protection report routes to device health with its own channel', () {
      final pending = PendingAlert.fromData(<String, dynamic>{
        'type': 'family.device_protection_reported',
        'copyKey': 'protection.reported',
        'deviceId': _device,
        'childId': _child,
      });

      expect(pending?.channelId, 'familyos_protection_alerts');
      expect(pending?.route, '/scr-fat-026?deviceId=$_device');
    });

    test('a child task claim routes to the one screen that can answer it', () {
      final pending = PendingAlert.fromData(<String, dynamic>{
        'type': 'family.task_claimed',
        'copyKey': 'task.claimed',
        'childId': _child,
        'occurredAt': '2026-10-26T22:30:00Z',
      });

      expect(pending?.channelId, 'familyos_family_alerts');
      expect(pending?.route, '/scr-fat-054');
      expect(pending?.childId, _child);
      expect(PendingAlert.validateRoute(pending?.route), '/scr-fat-054');
      // An ordinary alert never chooses an emergency destination, whatever its payload carries.
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.task_claimed',
        'copyKey': 'task.claimed',
        'alertId': _alert,
      })?.route, '/scr-fat-054');
    });

    test('unknown or mismatched events fail closed and a route ignores coordinate fields', () {
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.task_claimed',
        'copyKey': 'sos.raised',
        'childId': _child,
      }), isNull);
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.chat_message_sent',
        'copyKey': 'chat.message',
      }), isNull);
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.sos_alert_raised',
        'copyKey': 'geofence.entered',
        'alertId': _alert,
        'childId': _child,
      }), isNull);
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.device_protection_reported',
        'copyKey': 'protection.reported',
        'deviceId': 'not-an-id',
      }), isNull);
      expect(PendingAlert.fromData(<String, dynamic>{
        'type': 'family.geofence_entered',
        'copyKey': 'geofence.entered',
        'childId': _child,
        'zoneId': _zone,
        'latitude': '15.35',
        'longitude': '44.20',
      })?.route, '/scr-fat-014?childId=$_child');
    });
  });

  group('notification route allow-list', () {
    test('accepts only the four internal alert routes with their pinned parameters', () {
      expect(PendingAlert.validateRoute('/scr-fat-054'), '/scr-fat-054');
      expect(PendingAlert.validateRoute('/scr-fat-018?alertId=$_alert&childId=$_child'),
          '/scr-fat-018?alertId=$_alert&childId=$_child');
      expect(PendingAlert.validateRoute('/scr-fat-014?childId=$_child'),
          '/scr-fat-014?childId=$_child');
      expect(PendingAlert.validateRoute('/scr-fat-026?deviceId=$_device'),
          '/scr-fat-026?deviceId=$_device');
    });

    test('rejects external URLs, arbitrary routes, extra parameters and invalid IDs', () {
      expect(PendingAlert.validateRoute('https://example.com/scr-fat-018?alertId=$_alert&childId=$_child'), isNull);
      expect(PendingAlert.validateRoute('/scr-fat-021'), isNull);
      expect(PendingAlert.validateRoute('/scr-fat-014?childId=$_child&next=https://example.com'), isNull);
      expect(PendingAlert.validateRoute('/scr-fat-018?alertId=bad&childId=$_child'), isNull);
      expect(PendingAlert.validateRoute('/scr-fat-018?alertId=$_alert&alertId=$_alert&childId=$_child'), isNull);
      expect(PendingAlert.validateRoute('/scr-fat-014?childId=$_child#fragment'), isNull);
      // The task board is reached empty or not at all: a parameter is a reason to refuse the tap.
      expect(PendingAlert.validateRoute('/scr-fat-054?childId=$_child'), isNull);
    });
  });
}
