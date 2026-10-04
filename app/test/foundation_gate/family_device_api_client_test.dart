import 'dart:convert';

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
const deviceBody =
    '{"id":"$deviceId","childId":"$childId","deviceLabel":"Amani Android","batteryLevel":78,"batteryStatus":"unplugged","locationLat":38.8646,"locationLng":-77.2749,"locationLabel":"Soccer Practice","lastSeenAt":"2026-10-04T12:00:00.000Z","linkedAt":"2026-10-04T11:00:00.000Z","version":2}';

void main() {
  FamilyDeviceApiClient clientFor(FakeTransport transport) => FamilyDeviceApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    ),
    transport: transport,
  );

  test('device list reads the narrow family endpoint and accepts nullable latest telemetry', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"devices":[$deviceBody]}'),
    );
    final devices = await clientFor(transport).list(familyId: familyId, idToken: 'synthetic-token');

    expect(transport.requestedUri.toString(), 'https://staging.example.test/v1/families/$familyId/devices');
    expect(transport.requestedHeaders, {'accept': 'application/json', 'authorization': 'Bearer synthetic-token'});
    expect(devices.single.locationLabel, 'Soccer Practice');
    expect(devices.single.batteryLevel, 78);
    expect(devices.single.lastSeenAt, DateTime.utc(2026, 10, 4, 12));
  });

  test('guardian registration and telemetry use the two real endpoint shapes', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 201, body: '{"device":$deviceBody}'),
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
    expect(jsonDecode(transport.postedBody!), {'deviceLabel': 'Amani Android'});

    transport.postResponse = const FoundationGateHttpResponse(statusCode: 200, body: '{"device":$deviceBody}');
    await client.ingestTelemetry(
      deviceId: deviceId,
      batteryLevel: 78,
      batteryStatus: 'unplugged',
      locationLat: 38.8646,
      locationLng: -77.2749,
      locationLabel: 'Soccer Practice',
      idToken: 'synthetic-token',
    );
    expect(transport.postedUri.toString(), 'https://staging.example.test/v1/devices/$deviceId/telemetry');
    expect(jsonDecode(transport.postedBody!), {
      'batteryLevel': 78,
      'batteryStatus': 'unplugged',
      'locationLat': 38.8646,
      'locationLng': -77.2749,
      'locationLabel': 'Soccer Practice',
    });
    expect(transport.postedHeaders?['idempotency-key'], isNull);
  });

  test('native child pairing creates a guardian capability then claims a device credential once', () async {
    const pairingBody =
        '{"pairing":{"id":"$deviceId","childId":"$childId","deviceLabel":"Amani Android","pairingCode":"abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-","expiresAt":"2026-10-04T12:10:00.000Z"}}';
    final transport = FakeTransport(const FoundationGateHttpResponse(statusCode: 201, body: pairingBody));
    final client = clientFor(transport);
    final pairing = await client.createPairing(
      familyId: familyId,
      childId: childId,
      deviceLabel: 'Amani Android',
      idempotencyKey: idempotencyKey,
      idToken: 'synthetic-token',
    );
    expect(transport.postedUri.toString(), 'https://staging.example.test/v1/families/$familyId/children/$childId/device-pairings');
    expect(pairing.childId, childId);
    expect(pairing.deviceLabel, 'Amani Android');

    transport.postResponse = const FoundationGateHttpResponse(
      statusCode: 201,
      body: '{"device":$deviceBody,"deviceCredential":"abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-"}',
    );
    final claim = await client.claimPairing(pairingCode: pairing.pairingCode);
    expect(transport.postedUri.toString(), 'https://staging.example.test/v1/device-pairings/claim');
    expect(transport.postedHeaders?['authorization'], isNull);
    expect(claim.device.id, deviceId);
    expect(claim.deviceCredential, hasLength(44));
  });

  test('device client rejects out-of-range telemetry before HTTP', () async {
    final transport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"device":$deviceBody}'));
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
      throwsA(isA<FoundationGateApiException>().having(
        (error) => error.failure,
        'failure',
        FoundationGateApiFailure.invalidInput,
      )),
    );
    expect(transport.postedUri, isNull);
  });
}
