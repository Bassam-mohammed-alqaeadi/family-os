import 'package:family_os/foundation_gate/device_screen_time_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const deviceId = '44444444-4444-4444-8444-444444444444';
const deviceCredential = 'device-credential-sample-token-abc12345';

const fullScreenTimeResponseBody = '''
{
  "childId": "22222222-2222-4222-8222-222222222222",
  "date": "2026-10-23",
  "policy": {
    "childId": "22222222-2222-4222-8222-222222222222",
    "configured": true,
    "dailyLimitMinutes": 120,
    "schoolMode": {
      "enabled": false,
      "days": [1, 2, 3, 4, 5],
      "startMinute": 480,
      "endMinute": 900
    },
    "bedtime": {
      "startMinute": 1260,
      "endMinute": 360
    },
    "timezoneOffsetMinutes": 0,
    "earnedMinutesExtendLimit": true,
    "version": 1,
    "updatedAt": "2026-10-22T20:00:00.000Z"
  },
  "state": {
    "kind": "limited",
    "reasonCode": "daily_limit",
    "since": null,
    "date": "2026-10-23",
    "minuteOfDay": 600,
    "weekday": 5,
    "capMinutes": 120,
    "grantedMinutes": 30,
    "countableUsedMinutes": 45,
    "remainingMinutes": 105,
    "lock": null
  },
  "lock": null,
  "usage": {
    "minutes": 45,
    "apps": []
  },
  "openRequest": null,
  "apps": [],
  "reportedRequest": null
}
''';

const noLimitScreenTimeResponseBody = '''
{
  "childId": "22222222-2222-4222-8222-222222222222",
  "date": "2026-10-23",
  "policy": {
    "childId": "22222222-2222-4222-8222-222222222222",
    "configured": true,
    "dailyLimitMinutes": 0,
    "schoolMode": {
      "enabled": false,
      "days": [1, 2, 3, 4, 5],
      "startMinute": 480,
      "endMinute": 900
    },
    "bedtime": {
      "startMinute": 1260,
      "endMinute": 360
    },
    "timezoneOffsetMinutes": 0,
    "earnedMinutesExtendLimit": false,
    "version": 1,
    "updatedAt": "2026-10-22T20:00:00.000Z"
  },
  "state": {
    "kind": "free",
    "reasonCode": null,
    "since": null,
    "date": "2026-10-23",
    "minuteOfDay": 600,
    "weekday": 5,
    "capMinutes": null,
    "grantedMinutes": 0,
    "countableUsedMinutes": 15,
    "remainingMinutes": null,
    "lock": null
  },
  "lock": null,
  "usage": {
    "minutes": 15,
    "apps": []
  },
  "openRequest": null,
  "apps": [],
  "reportedRequest": null
}
''';

void main() {
  final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://staging.example.test'),
  );

  test(
    'read proves GET path and Device authorization header literally and parses full response',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: fullScreenTimeResponseBody,
        ),
      );
      final client = DeviceScreenTimeClient(
        configuration: configuration,
        transport: transport,
      );

      final reading = await client.read(
        deviceId: deviceId,
        deviceCredential: deviceCredential,
      );

      expect(
        transport.requestedUri.toString(),
        'https://staging.example.test/v1/devices/$deviceId/screen-time',
      );
      expect(transport.requestedHeaders, {
        'accept': 'application/json',
        'authorization': 'Device $deviceCredential',
      });
      expect(reading.remainingMinutes, 105);
      expect(reading.countableUsedMinutes, 45);
      expect(reading.grantedMinutes, 30);
      expect(reading.capMinutes, 120);
      expect(reading.kind, 'limited');
      expect(reading.reasonCode, 'daily_limit');
      expect(reading.earnedMinutesExtendLimit, isTrue);
      expect(reading.serverDate, '2026-10-23');
    },
  );

  test(
    'read preserves null remainingMinutes when there is no limit and never converts to zero',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: noLimitScreenTimeResponseBody,
        ),
      );
      final client = DeviceScreenTimeClient(
        configuration: configuration,
        transport: transport,
      );

      final reading = await client.read(
        deviceId: deviceId,
        deviceCredential: deviceCredential,
      );

      expect(reading.remainingMinutes, isNull);
      expect(reading.capMinutes, isNull);
      expect(reading.kind, 'free');
      expect(reading.reasonCode, isNull);
      expect(reading.earnedMinutesExtendLimit, isFalse);
      expect(reading.serverDate, '2026-10-23');
    },
  );

  test(
    'read throws accessDenied FoundationGateApiException on 403 status code',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 403,
          body: '{"error":"device_credential_rejected"}',
        ),
      );
      final client = DeviceScreenTimeClient(
        configuration: configuration,
        transport: transport,
      );

      expect(
        () => client.read(
          deviceId: deviceId,
          deviceCredential: deviceCredential,
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (e) => e.failure,
            'failure',
            FoundationGateApiFailure.accessDenied,
          ),
        ),
      );
    },
  );
}
