import 'dart:convert';

import 'package:family_os/foundation_gate/device_lifecycle.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';
const deviceId = '33333333-3333-4333-8333-333333333333';
const idempotencyKey = '44444444-4444-4444-8444-444444444444';
/// The device payload as the server now declares it, lifecycle included.
///
/// The previous fixture carried eleven keys and the client demanded exactly eleven, so an
/// additive server change read as a corrupt device. The count is gone and this fixture
/// carries the contract: the stored facts plus the condition the server decided.
const deviceBody =
    '{"id":"$deviceId","childId":"$childId","deviceLabel":"Amani Android",'
    '"batteryLevel":78,"batteryStatus":"unplugged","locationLat":38.8646,'
    '"locationLng":-77.2749,"locationLabel":"Soccer Practice",'
    '"lastSeenAt":"2026-10-04T12:00:00.000Z","linkedAt":"2026-10-04T11:00:00.000Z",'
    '"version":2,"credentialState":"active","capabilities":['
    '{"id":"telemetry","state":"available","reasonCode":"reporting_now",'
    '"since":"2026-10-04T12:00:00.000Z"},'
    '{"id":"location","state":"available","reasonCode":"location_reported",'
    '"since":"2026-10-04T12:00:00.000Z"},'
    '{"id":"background_service","state":"available","reasonCode":"reporting_now",'
    '"since":"2026-10-04T12:00:00.000Z"}],'
    '"health":{"state":"active","reasonCode":"reporting_now",'
    '"since":"2026-10-04T12:00:00.000Z","needsAttention":false}}';

void main() {
  FamilyDeviceApiClient clientFor(FakeTransport transport) =>
      FamilyDeviceApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      );

  test(
    'device list reads the narrow family endpoint and accepts nullable latest telemetry',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"devices":[$deviceBody]}',
        ),
      );
      final devices = await clientFor(
        transport,
      ).list(familyId: familyId, idToken: 'synthetic-token');

      expect(
        transport.requestedUri.toString(),
        'https://staging.example.test/v1/families/$familyId/devices',
      );
      expect(transport.requestedHeaders, {
        'accept': 'application/json',
        'authorization': 'Bearer synthetic-token',
      });
      expect(devices.single.locationLabel, 'Soccer Practice');
      expect(devices.single.batteryLevel, 78);
      expect(devices.single.lastSeenAt, DateTime.utc(2026, 10, 4, 12));
      // The server's condition arrives as data the client renders, not as something the
      // client works out for itself.
      expect(
        devices.single.credentialState,
        FoundationGateDeviceCredentialState.active,
      );
      expect(
        devices.single.health.state,
        FoundationGateDeviceHealthState.active,
      );
      expect(devices.single.health.reasonCode, 'reporting_now');
      expect(devices.single.health.needsAttention, isFalse);
      expect(devices.single.capabilities, hasLength(3));
      expect(
        devices.single.capabilities
            .firstWhere((capability) => capability.id == 'location')
            .reasonCode,
        'location_reported',
      );
    },
  );

  test(
    'guardian registration and telemetry use the two real endpoint shapes',
    () async {
      final transport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 201,
          body: '{"device":$deviceBody}',
        ),
      );
      final client = clientFor(transport);
      await client.register(
        familyId: familyId,
        childId: childId,
        deviceLabel: 'Amani Android',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      );
      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/families/$familyId/children/$childId/devices',
      );
      expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
      expect(jsonDecode(transport.postedBody!), {
        'deviceLabel': 'Amani Android',
      });

      transport.postResponse = const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"device":$deviceBody}',
      );
      await client.ingestTelemetry(
        deviceId: deviceId,
        batteryLevel: 78,
        batteryStatus: 'unplugged',
        locationLat: 38.8646,
        locationLng: -77.2749,
        locationLabel: 'Soccer Practice',
        idToken: 'synthetic-token',
      );
      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/devices/$deviceId/telemetry',
      );
      expect(jsonDecode(transport.postedBody!), {
        'batteryLevel': 78,
        'batteryStatus': 'unplugged',
        'locationLat': 38.8646,
        'locationLng': -77.2749,
        'locationLabel': 'Soccer Practice',
      });
      expect(transport.postedHeaders?['idempotency-key'], isNull);
    },
  );

  test(
    'native child pairing creates a guardian capability then claims a device credential once',
    () async {
      const pairingBody =
          '{"pairing":{"id":"$deviceId","childId":"$childId","deviceLabel":"Amani Android","pairingCode":"abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-","expiresAt":"2026-10-04T12:10:00.000Z"}}';
      final transport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 201, body: pairingBody),
      );
      final client = clientFor(transport);
      final pairing = await client.createPairing(
        familyId: familyId,
        childId: childId,
        deviceLabel: 'Amani Android',
        idempotencyKey: idempotencyKey,
        idToken: 'synthetic-token',
      );
      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/families/$familyId/children/$childId/device-pairings',
      );
      expect(pairing.childId, childId);
      expect(pairing.deviceLabel, 'Amani Android');

      transport.postResponse = const FoundationGateHttpResponse(
        statusCode: 201,
        body:
            '{"device":$deviceBody,"deviceCredential":"abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-"}',
      );
      final claim = await client.claimPairing(pairingCode: pairing.pairingCode);
      expect(
        transport.postedUri.toString(),
        'https://staging.example.test/v1/device-pairings/claim',
      );
      expect(transport.postedHeaders?['authorization'], isNull);
      expect(claim.device.id, deviceId);
      expect(claim.deviceCredential, hasLength(44));
    },
  );

  test('device client rejects out-of-range telemetry before HTTP', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"device":$deviceBody}',
      ),
    );
    await expectLater(
      clientFor(transport).ingestTelemetry(
        deviceId: deviceId,
        batteryLevel: 101,
        batteryStatus: 'unplugged',
        locationLat: 38,
        locationLng: -77,
        locationLabel: 'Soccer Practice',
        idToken: 'synthetic-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(transport.postedUri, isNull);
  });

  test('a device whose condition the client cannot understand is dropped, not guessed', () async {
    // The one failure this client must never have: rendering a state it did not receive.
    // A guardian told "active" about a device the server cut off is a guardian who stops
    // looking.
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"devices":[{"id":"$deviceId","childId":"$childId",'
            '"deviceLabel":"Amani Android","credentialState":"active",'
            '"capabilities":[{"id":"telemetry","state":"available",'
            '"reasonCode":"reporting_now","since":null}],'
            '"health":{"state":"repaired_itself","reasonCode":"unknown",'
            '"since":null,"needsAttention":false}}]}',
      ),
    );
    await expectLater(
      clientFor(transport).list(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('a field the client does not know is ignored rather than fatal', () async {
    // Forward compatibility is the point of dropping the exact key count. The server must
    // be able to add a fact without an older client calling the device broken.
    // The added field is spliced in as text so the fixture above stays one readable
    // const, and so the test proves the client ignores exactly one unknown key.
    final withExtra =
        '${deviceBody.substring(0, deviceBody.length - 1)},'
        '"aFieldFromALaterRelease":"whatever"}';
    final transport = FakeTransport(
      FoundationGateHttpResponse(statusCode: 200, body: '{"devices":[$withExtra]}'),
    );
    final devices = await clientFor(
      transport,
    ).list(familyId: familyId, idToken: 'synthetic-token');
    expect(devices.single.deviceLabel, 'Amani Android');
    expect(
      devices.single.health.state,
      FoundationGateDeviceHealthState.active,
    );
  });
}
