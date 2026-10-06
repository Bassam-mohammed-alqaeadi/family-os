import 'package:family_os/foundation_gate/family_location_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const zoneId = '22222222-2222-4222-8222-222222222222';
const childId = '33333333-3333-4333-8333-333333333333';
const deviceId = '44444444-4444-4444-8444-444444444444';
const fixId = '55555555-5555-4555-8555-555555555555';
const idempotencyKey = '66666666-6666-4666-8666-666666666666';
const deviceCredential = 'device-credential-0123456789abcdefghij';

/// One zone exactly as `backend/src/safe-zones.js` publishes it, geometry included.
const circleZoneBody =
    '{"id":"$zoneId","name":"البيت","emoji":"🏠",'
    '"geometry":{"kind":"CIRCLE","version":1,'
    '"center":{"latitude":15.3694,"longitude":44.191},"radiusMeters":150},'
    '"childIds":["$childId"],"alertEnter":true,"alertExit":true,"version":1,'
    '"archivedAt":null,"createdAt":"2026-10-07T09:00:00.000Z",'
    '"updatedAt":"2026-10-07T09:00:00.000Z"}';

/// One polygon zone, as the same endpoint publishes it.
const polygonZoneBody =
    '{"id":"77777777-7777-4777-8777-777777777777","name":"المدرسة","emoji":"🏫",'
    '"geometry":{"kind":"POLYGON","version":2,"vertices":['
    '{"latitude":15.4,"longitude":44.2},{"latitude":15.4,"longitude":44.21},'
    '{"latitude":15.41,"longitude":44.21}]},'
    '"childIds":["$childId"],"alertEnter":false,"alertExit":true,"version":2,'
    '"archivedAt":null,"createdAt":"2026-10-07T09:00:00.000Z",'
    '"updatedAt":"2026-10-07T09:00:00.000Z"}';

const familyLocationBody =
    '{"visibility":"family_members","observedAt":"2026-10-07T09:05:00.000Z",'
    '"children":[{"childId":"$childId","displayName":"سارة","devices":['
    '{"deviceId":"$deviceId","deviceLabel":"هاتف سارة","state":"live",'
    '"lastFix":{"id":"$fixId","acquisition":"located","latitude":15.3694,'
    '"longitude":44.191,"accuracyMeters":18,"recordedAt":"2026-10-07T09:04:00.000Z",'
    '"receivedAt":"2026-10-07T09:04:01.000Z"}}],'
    '"zones":[{"zoneId":"$zoneId","name":"البيت","inside":true,"observedCrossing":false}]}]}';

const crossingFeedBody =
    '{"visibility":"family_members","events":[{"id":"$fixId","zoneId":"$zoneId",'
    '"zoneName":"البيت","childId":"$childId","kind":"EXIT","baseline":false,'
    '"zoneVersion":2,"occurredAt":"2026-10-07T08:00:00.000Z"}]}';

const historyBody =
    '{"visibility":"family_members","childId":"$childId","displayName":"سارة",'
    '"retentionDays":30,"fixes":['
    '{"id":"$fixId","acquisition":"located","latitude":15.3694,"longitude":44.191,'
    '"accuracyMeters":18,"integritySoftWarning":false,'
    '"recordedAt":"2026-10-07T09:04:00.000Z","receivedAt":"2026-10-07T09:04:01.000Z"},'
    '{"id":"99999999-9999-4999-8999-999999999999","acquisition":"acquiring",'
    '"latitude":null,"longitude":null,"accuracyMeters":null,"integritySoftWarning":false,'
    '"recordedAt":"2026-10-07T09:00:00.000Z","receivedAt":"2026-10-07T09:00:01.000Z"}]}';

const fixReceiptBody =
    '{"fix":{"id":"$fixId","acquisition":"located","latitude":15.3694,'
    '"longitude":44.191,"accuracyMeters":18,"recordedAt":"2026-10-07T09:04:00.000Z",'
    '"receivedAt":"2026-10-07T09:04:01.000Z"},"evaluated":true,"reason":"evaluated",'
    '"crossings":[{"zoneId":"$zoneId","kind":"EXIT","baseline":false,"notified":true,'
    '"zoneVersion":2}],"replayed":false,"pruned":0}';

void main() {
  FamilyLocationApiClient clientFor(FakeTransport transport) =>
      FamilyLocationApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      );

  test('the zones are read from the family endpoint and both shapes survive', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$circleZoneBody,$polygonZoneBody]}',
      ),
    );
    final zones = await clientFor(
      transport,
    ).listZones(familyId: familyId, idToken: 'synthetic-token');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/safe-zones',
    );
    expect(transport.requestedHeaders?['authorization'], 'Bearer synthetic-token');
    expect(zones, hasLength(2));

    final circle = zones.first.geometry;
    expect(circle, isA<FoundationGateCircleGeometry>());
    expect((circle as FoundationGateCircleGeometry).radiusMeters, 150);
    expect(circle.center.latitude, closeTo(15.3694, 0.00001));
    expect(zones.first.alertEnter, isTrue);
    expect(zones.first.childIds, [childId]);
    expect(zones.first.version, 1);

    final polygon = zones.last.geometry;
    expect(polygon, isA<FoundationGatePolygonGeometry>());
    expect((polygon as FoundationGatePolygonGeometry).vertices, hasLength(3));
    expect(polygon.version, 2);
    expect(zones.last.alertEnter, isFalse);
  });

  test('a zone is drawn with its geometry, children and flags, and a key', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"zone":$circleZoneBody}',
      ),
    );
    final zone = await clientFor(transport).createZone(
      familyId: familyId,
      idToken: 'synthetic-token',
      idempotencyKey: idempotencyKey,
      name: 'البيت',
      emoji: '🏠',
      geometry: const FoundationGateCircleGeometry(
        version: 1,
        center: FoundationGateGeoPoint(latitude: 15.3694, longitude: 44.191),
        radiusMeters: 150,
      ),
      childIds: const [childId],
      alertEnter: true,
      alertExit: true,
    );

    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/safe-zones',
    );
    expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(transport.postedHeaders?['authorization'], 'Bearer synthetic-token');
    expect(transport.postedBody, contains('"kind":"CIRCLE"'));
    expect(transport.postedBody, contains('"radiusMeters":150'));
    expect(transport.postedBody, contains('"childIds":["$childId"]'));
    expect(zone.id, zoneId);
    expect(zone.name, 'البيت');
  });

  test('a polygon is drawn as points, never as a circle with a radius', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"zone":$polygonZoneBody}',
      ),
    );
    await clientFor(transport).createZone(
      familyId: familyId,
      idToken: 'synthetic-token',
      idempotencyKey: idempotencyKey,
      name: 'المدرسة',
      emoji: '🏫',
      geometry: const FoundationGatePolygonGeometry(
        version: 1,
        vertices: [
          FoundationGateGeoPoint(latitude: 15.4, longitude: 44.2),
          FoundationGateGeoPoint(latitude: 15.4, longitude: 44.21),
          FoundationGateGeoPoint(latitude: 15.41, longitude: 44.21),
        ],
      ),
      childIds: const [childId],
      alertEnter: false,
      alertExit: true,
    );

    final body = transport.postedBody!;
    expect(body, contains('"kind":"POLYGON"'));
    expect(body, isNot(contains('radiusMeters')));
    expect(body, contains('"alertEnter":false'));
  });

  test('the alert flags move with PATCH and only the flags move', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      patchResponse: const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zone":$polygonZoneBody}',
      ),
    );
    final zone = await clientFor(transport).updateZoneAlerts(
      familyId: familyId,
      zoneId: zoneId,
      idToken: 'synthetic-token',
      idempotencyKey: idempotencyKey,
      alertEnter: false,
    );

    expect(
      transport.patchedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/safe-zones/$zoneId',
    );
    expect(transport.patchedHeaders?['idempotency-key'], idempotencyKey);
    expect(transport.patchedBody, '{"alertEnter":false}');
    // The version travelled with the shape, so a crossing judged later can name the rule
    // it was judged against.
    expect(zone.geometry.version, 2);
    expect(zone.version, 2);
  });

  test('a flag write with no flags, or with someone else identifiers, never leaves', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
    );
    final client = clientFor(transport);

    await expectLater(
      client.updateZoneAlerts(
        familyId: familyId,
        zoneId: zoneId,
        idToken: 'synthetic-token',
        idempotencyKey: idempotencyKey,
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    await expectLater(
      client.updateZoneAlerts(
        familyId: familyId,
        zoneId: 'not-a-uuid',
        idToken: 'synthetic-token',
        idempotencyKey: idempotencyKey,
        alertEnter: true,
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    expect(transport.patchedUri, isNull, reason: 'a refused request must not be sent');
  });

  test('the live picture is read as one answer for the whole family', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: familyLocationBody),
    );
    final picture = await clientFor(
      transport,
    ).familyLocation(familyId: familyId, idToken: 'synthetic-token');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/location',
    );
    expect(picture.visibility, 'family_members');
    expect(picture.children, hasLength(1));
    final child = picture.children.single;
    expect(child.childId, childId);
    expect(child.displayName, 'سارة');
    expect(child.devices.single.state, FoundationGateDeviceState.live);
    expect(child.devices.single.acquisition, FoundationGateAcquisition.located);
    expect(child.devices.single.hasPosition, isTrue);
    expect(child.zones.single.inside, isTrue);
    expect(
      child.zones.single.observedCrossing,
      isFalse,
      reason: 'a baseline state is known but was never watched happening',
    );
  });

  test('a device that never reported carries no position and no invented zero', () async {
    const body =
        '{"visibility":"family_members","observedAt":"2026-10-07T09:05:00.000Z",'
        '"children":[{"childId":"$childId","displayName":"سارة","devices":['
        '{"deviceId":"$deviceId","deviceLabel":"هاتف سارة","state":"never",'
        '"lastFix":null}],"zones":[]}]}';
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: body),
    );
    final picture = await clientFor(
      transport,
    ).familyLocation(familyId: familyId, idToken: 'synthetic-token');

    final reading = picture.children.single.devices.single;
    expect(reading.state, FoundationGateDeviceState.never);
    expect(reading.hasPosition, isFalse);
    expect(reading.latitude, isNull);
    expect(reading.longitude, isNull);
    expect(reading.recordedAt, isNull);
  });

  test('a fix without coordinates that claims coordinates is refused as a corrupt answer', () async {
    const body =
        '{"visibility":"family_members","observedAt":"2026-10-07T09:05:00.000Z",'
        '"children":[{"childId":"$childId","displayName":"سارة","devices":['
        '{"deviceId":"$deviceId","deviceLabel":"هاتف","state":"live","lastFix":'
        '{"id":"$fixId","acquisition":"unavailable","latitude":15.3,'
        '"longitude":44.1,"recordedAt":"2026-10-07T09:04:00.000Z"}}],"zones":[]}]}';
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: body),
    );
    await expectLater(
      clientFor(transport).familyLocation(
        familyId: familyId,
        idToken: 'synthetic-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('the trail is read back newest first, with the retention window published', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: historyBody),
    );
    final history = await clientFor(transport).locationHistory(
      familyId: familyId,
      childId: childId,
      idToken: 'synthetic-token',
    );

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/children/$childId/location-history',
    );
    expect(history.visibility, 'family_members');
    expect(history.retentionDays, 30);
    expect(history.displayName, 'سارة');
    expect(history.fixes, hasLength(2));
    expect(history.fixes.first.hasPosition, isTrue);
    expect(history.fixes.first.recordedAt?.isUtc, isTrue);
    expect(
      history.fixes.last.hasPosition,
      isFalse,
      reason: 'a device that answered without a position keeps its nulls',
    );
    expect(history.fixes.last.latitude, isNull);
    expect(history.fixes.last.acquisition, FoundationGateAcquisition.acquiring);
  });

  test('a trail row that claims coordinates without a position is refused', () async {
    const corrupt =
        '{"visibility":"family_members","childId":"$childId","displayName":"سارة",'
        '"retentionDays":30,"fixes":[{"id":"$fixId","acquisition":"unavailable",'
        '"latitude":15.3,"longitude":44.1,"recordedAt":"2026-10-07T09:04:00.000Z"}]}';
    await expectLater(
      clientFor(
        FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: corrupt),
        ),
      ).locationHistory(
        familyId: familyId,
        childId: childId,
        idToken: 'synthetic-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('a child the family does not know is not found', () async {
    await expectLater(
      clientFor(
        FakeTransport(const FoundationGateHttpResponse(statusCode: 404, body: '{}')),
      ).locationHistory(
        familyId: familyId,
        childId: childId,
        idToken: 'synthetic-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.notFound,
        ),
      ),
    );
  });

  test('the crossing feed is read newest first with its baselines marked', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: crossingFeedBody),
    );
    final events = await clientFor(
      transport,
    ).crossingFeed(familyId: familyId, idToken: 'synthetic-token');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/geofence-events',
    );
    expect(events, hasLength(1));
    expect(events.single.kind, 'EXIT');
    expect(events.single.baseline, isFalse);
    expect(events.single.zoneVersion, 2);
    expect(events.single.zoneName, 'البيت');
    expect(events.single.occurredAt.isUtc, isTrue);
  });

  test('a position is reported with the device own credential, never a bearer', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: fixReceiptBody,
      ),
    );
    final receipt = await clientFor(transport).reportLocationFix(
      deviceId: deviceId,
      deviceCredential: deviceCredential,
      idempotencyKey: idempotencyKey,
      fixId: fixId,
      acquisition: FoundationGateAcquisition.located,
      latitude: 15.3694,
      longitude: 44.191,
      accuracyMeters: 18,
      recordedAt: DateTime.now().toUtc(),
    );

    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/devices/$deviceId/location-fixes',
    );
    expect(transport.postedHeaders?['authorization'], 'Device $deviceCredential');
    expect(transport.postedBody, contains('"fixId":"$fixId"'));
    expect(receipt.evaluated, isTrue);
    expect(receipt.reason, FoundationGateFixEvaluation.evaluated);
    expect(receipt.replayed, isFalse);
    expect(receipt.crossings.single.kind, 'EXIT');
    expect(receipt.crossings.single.notified, isTrue);
    expect(receipt.pruned, 0);
  });

  test('an honest non-answer travels without coordinates, and a dishonest one is refused', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: fixReceiptBody,
      ),
    );
    final client = clientFor(transport);

    await client.reportLocationFix(
      deviceId: deviceId,
      deviceCredential: deviceCredential,
      idempotencyKey: idempotencyKey,
      fixId: fixId,
      acquisition: FoundationGateAcquisition.acquiring,
      recordedAt: DateTime.now().toUtc(),
    );
    expect(transport.postedBody, isNot(contains('latitude')));

    await expectLater(
      client.reportLocationFix(
        deviceId: deviceId,
        deviceCredential: deviceCredential,
        idempotencyKey: idempotencyKey,
        fixId: fixId,
        acquisition: FoundationGateAcquisition.unavailable,
        latitude: 15.3,
        longitude: 44.1,
        recordedAt: DateTime.now().toUtc(),
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    await expectLater(
      client.reportLocationFix(
        deviceId: deviceId,
        deviceCredential: deviceCredential,
        idempotencyKey: idempotencyKey,
        fixId: fixId,
        acquisition: FoundationGateAcquisition.located,
        latitude: 91,
        longitude: 44.1,
        recordedAt: DateTime.now().toUtc(),
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    await expectLater(
      client.reportLocationFix(
        deviceId: deviceId,
        deviceCredential: deviceCredential,
        idempotencyKey: idempotencyKey,
        fixId: fixId,
        acquisition: FoundationGateAcquisition.located,
        latitude: 15.3,
        longitude: 44.1,
        recordedAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
  });

  test('a device credential the wire shape cannot carry is refused before any request', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
    );
    await expectLater(
      clientFor(transport).reportLocationFix(
        deviceId: deviceId,
        deviceCredential: 'Bearer-like credential',
        idempotencyKey: idempotencyKey,
        fixId: fixId,
        acquisition: FoundationGateAcquisition.acquiring,
        recordedAt: DateTime.now().toUtc(),
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    expect(transport.postedUri, isNull);
  });

  test('the server answers map to failures a screen can explain', () async {
    final client = clientFor(
      FakeTransport(
        const FoundationGateHttpResponse(statusCode: 403, body: '{}'),
      ),
    );
    await expectLater(
      client.listZones(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.accessDenied,
        ),
      ),
    );

    final unavailable = clientFor(
      FakeTransport(
        const FoundationGateHttpResponse(statusCode: 503, body: '{}'),
      ),
    );
    await expectLater(
      unavailable.familyLocation(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.serviceUnavailable,
        ),
      ),
    );

    final offline = clientFor(
      FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{}'))
        ..failure = const SocketExceptionLike(),
    );
    await expectLater(
      offline.listZones(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.networkUnavailable,
        ),
      ),
    );
  });

  test('a zone with a malformed shape is refused rather than rendered with a guess', () async {
    const missingRadius =
        '{"zones":[{"id":"$zoneId","name":"البيت","emoji":"🏠",'
        '"geometry":{"kind":"CIRCLE","version":1,'
        '"center":{"latitude":15.3,"longitude":44.1}},"childIds":["$childId"],'
        '"alertEnter":true,"alertExit":true,"version":1}]}';
    await expectLater(
      clientFor(
        FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: missingRadius),
        ),
      ).listZones(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );

    const noChildren =
        '{"zones":[{"id":"$zoneId","name":"البيت","emoji":"🏠",'
        '"geometry":{"kind":"CIRCLE","version":1,'
        '"center":{"latitude":15.3,"longitude":44.1},"radiusMeters":150},'
        '"childIds":[],"alertEnter":true,"alertExit":true,"version":1}]}';
    await expectLater(
      clientFor(
        FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: noChildren),
        ),
      ).listZones(familyId: familyId, idToken: 'synthetic-token'),
      throwsA(isA<FoundationGateApiException>()),
    );
  });

  test('an unknown extra field on a zone is ignored, not fatal', () async {
    const withExtra =
        '{"zones":[{"id":"$zoneId","name":"البيت","emoji":"🏠",'
        '"geometry":{"kind":"CIRCLE","version":1,'
        '"center":{"latitude":15.3,"longitude":44.1},"radiusMeters":150},'
        '"childIds":["$childId"],"alertEnter":true,"alertExit":true,"version":1,'
        '"futureField":{"whatever":true},"another":"value"}]}';
    final zones = await clientFor(
      FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: withExtra),
      ),
    ).listZones(familyId: familyId, idToken: 'synthetic-token');

    expect(zones, hasLength(1));
    expect(zones.single.name, 'البيت');
  });
}

/// A stand-in for a transport that cannot reach anything: the client must classify it as
/// the network being unavailable rather than as a malformed answer.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
