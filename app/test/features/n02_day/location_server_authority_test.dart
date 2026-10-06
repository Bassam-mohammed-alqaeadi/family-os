import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/zone_geometry.dart';
import 'package:family_os/features/n02_day/location_map_repository.dart';
import 'package:family_os/features/n02_day/location_server_authority.dart';
import 'package:family_os/features/n02_day/safe_zones_repository.dart';
import 'package:family_os/foundation_gate/family_location_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const zoneId = '22222222-2222-4222-8222-222222222222';
const childId = '33333333-3333-4333-8333-333333333333';
const otherChildId = '34343434-3434-4434-8434-343434343434';
const deviceId = '44444444-4444-4444-8444-444444444444';
const otherDeviceId = '45454545-4545-4545-8545-454545454545';
const fixId = '55555555-5555-4555-8555-555555555555';

/// A transport that answers by path, because the location pack reads three endpoints to
/// draw one screen and a single canned answer cannot model which one answered.
final class _RoutedTransport implements FoundationGateHttpTransport {
  _RoutedTransport(this.responses);

  final Map<String, FoundationGateHttpResponse> responses;
  final List<Uri> requests = <Uri>[];
  final List<Map<String, String>> requestHeaders = <Map<String, String>>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    requests.add(uri);
    requestHeaders.add(Map.unmodifiable(headers));
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    requests.add(uri);
    requestHeaders.add(Map.unmodifiable(headers));
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    requests.add(uri);
    requestHeaders.add(Map.unmodifiable(headers));
    return _match(uri);
  }

  FoundationGateHttpResponse _match(Uri uri) {
    for (final entry in responses.entries) {
      if (uri.path.endsWith(entry.key)) return entry.value;
    }
    throw StateError('No canned answer for ${uri.path}');
  }
}

const _circleZone =
    '{"id":"$zoneId","name":"البيت","emoji":"🏠",'
    '"geometry":{"kind":"CIRCLE","version":1,'
    '"center":{"latitude":24.7136,"longitude":46.6753},"radiusMeters":222},'
    '"childIds":["$childId"],"alertEnter":true,"alertExit":true,"version":1,'
    '"archivedAt":null}';

const _polygonZone =
    '{"id":"77777777-7777-4777-8777-777777777777","name":"المدرسة","emoji":"🏫",'
    '"geometry":{"kind":"POLYGON","version":1,"vertices":['
    '{"latitude":24.72,"longitude":46.68},{"latitude":24.72,"longitude":46.69},'
    '{"latitude":24.73,"longitude":46.69}]},'
    '"childIds":["$childId"],"alertEnter":true,"alertExit":false,"version":1,'
    '"archivedAt":null}';

/// One child who reported a position, one who never did, and one child standing inside a
/// zone on a baseline sighting.
const _picture =
    '{"visibility":"family_members","observedAt":"2026-10-07T09:05:00.000Z",'
    '"children":['
    '{"childId":"$childId","displayName":"سارة","devices":['
    '{"deviceId":"$deviceId","deviceLabel":"هاتف سارة","state":"live","lastFix":{'
    '"id":"$fixId","acquisition":"located","latitude":24.7136,"longitude":46.6753,'
    '"accuracyMeters":18,"recordedAt":"2026-10-07T09:04:00.000Z"}}],'
    '"zones":[{"zoneId":"$zoneId","name":"البيت","inside":true,"observedCrossing":false}]},'
    '{"childId":"$otherChildId","displayName":"عبدالله","devices":['
    '{"deviceId":"$otherDeviceId","deviceLabel":"هاتف عبدالله","state":"never",'
    '"lastFix":null}],"zones":[]}]}';

const _feed =
    '{"visibility":"family_members","events":[{"id":"$fixId","zoneId":"$zoneId",'
    '"zoneName":"البيت","childId":"$childId","kind":"EXIT","baseline":false,'
    '"zoneVersion":1,"occurredAt":"2026-10-07T08:00:00.000Z"}]}';

void main() {
  LocationServerAuthority authorityFor(_RoutedTransport transport) =>
      LocationServerAuthority(
        api: FamilyLocationApiClient(
          configuration: FoundationGateConfiguration.fromStagingApiOrigin(
            Uri.parse('https://staging.example.test'),
          ),
          transport: transport,
        ),
        idToken: () async => 'synthetic-token',
        familyId: () => familyId,
      );

  tearDown(() {
    activeSafeZoneServerWriter = null;
  });

  test('the family zones arrive as list rows the screen already renders', () async {
    final transport = _RoutedTransport({
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone,$_polygonZone]}',
      ),
    });
    final repository = ServerSafeZonesRepository(authorityFor(transport));

    expect(repository.isRemoteAuthority, isTrue);
    expect(
      repository.storesNoShowAlert,
      isFalse,
      reason: 'the server records entering and leaving; a missed-deadline alert is neither',
    );

    final snapshot = await repository.load();
    expect(snapshot.zones, hasLength(2));
    expect(snapshot.zones.first.id, zoneId);
    expect(snapshot.zones.first.name, 'البيت');
    expect(snapshot.zones.first.emoji, '🏠');
    expect(snapshot.zones.first.alertEnter, isTrue);
    expect(snapshot.zones.first.assignedChildIds, [childId]);
    expect(snapshot.zones.first.description, 'assigned:1');
    expect(
      snapshot.zones.first.alertNoShow,
      isFalse,
      reason: 'the server never reports a flag it does not store',
    );
    expect(transport.requestHeaders.single['authorization'], 'Bearer synthetic-token');
  });

  test('the missed-deadline flag is refused instead of accepted and dropped', () async {
    final transport = _RoutedTransport({
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone]}',
      ),
    });
    final repository = ServerSafeZonesRepository(authorityFor(transport));

    await expectLater(
      repository.setAlertFlag(zoneId, alertNoShow: true),
      throwsA(isA<UnsupportedError>()),
    );
    await expectLater(
      repository.add(
        const SafeZone(
          id: zoneId,
          emoji: '🏠',
          name: 'البيت',
          description: 'x',
        ),
      ),
      throwsA(isA<UnsupportedError>()),
      reason: 'a boundary without a shape cannot reach the server',
    );
    expect(transport.requests, isEmpty);
  });

  test('the flags reach the server through the writer with the family in the path', () async {
    final transport = _RoutedTransport({
      '/safe-zones/$zoneId': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zone":$_circleZone}',
      ),
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"zone":$_circleZone}',
      ),
    });
    final authority = authorityFor(transport);
    final writer = LocationServerZoneWriter(authority);

    await writer.updateAlerts(zoneId, alertExit: false);
    expect(
      transport.requests.single.toString(),
      'https://staging.example.test/v1/families/$familyId/safe-zones/$zoneId',
    );
    expect(
      transport.requestHeaders.single['idempotency-key'],
      isNotNull,
      reason: 'a repeated tap must not become two rule changes',
    );

    await writer.createZone(
      const SafeZoneDraft(
        name: 'المدرسة',
        emoji: '🏫',
        geometry: CircleGeometry(
          center: GeoPoint(latitude: 24.72, longitude: 46.68),
          radiusMeters: 180,
        ),
        assignedChildIds: [childId],
        alertEnter: true,
        alertExit: true,
      ),
    );
    expect(
      transport.requests.last.toString(),
      'https://staging.example.test/v1/families/$familyId/safe-zones',
    );
  });

  test('binding the authority puts the server behind the pack, and clearing it lets go', () async {
    final transport = _RoutedTransport({
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone]}',
      ),
    });
    bindLocationServerAuthority(authorityFor(transport));

    expect(stage1SafeZonesRepository, isA<ServerSafeZonesRepository>());
    expect(stage1SafeZonesRepository.isRemoteAuthority, isTrue);
    expect(activeSafeZoneServerWriter, isNotNull);
    expect(stage1LocationMapRepository, isA<ServerLocationMapRepository>());

    bindLocationServerAuthority(null);
    expect(activeSafeZoneServerWriter, isNull);
    expect(
      stage1SafeZonesRepository,
      isA<ServerSafeZonesRepository>(),
      reason: 'clearing the server authority must not decide what the local fallback is',
    );
  });

  test('a pin exists only where a device reported a position', () async {
    final transport = _RoutedTransport({
      '/location': const FoundationGateHttpResponse(statusCode: 200, body: _picture),
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone,$_polygonZone]}',
      ),
      '/geofence-events': const FoundationGateHttpResponse(
        statusCode: 200,
        body: _feed,
      ),
    });
    final snapshot = await ServerLocationMapRepository(
      authorityFor(transport),
    ).load();

    expect(snapshot, isNotNull);
    expect(
      snapshot!.pins.map((pin) => pin.id),
      [childId],
      reason: 'a child whose device never reported has no location to draw',
    );
    final pin = snapshot.pins.single;
    expect(pin.displayName, 'سارة');
    expect(pin.safeZoneLabel, 'البيت');
    expect(pin.lastSeenLabel, 'LIVE');
    expect(pin.batteryLabel, '—');
    expect(pin.xFraction, closeTo(0.5, 0.001));
    expect(pin.yFraction, closeTo(0.5, 0.001));
    expect(snapshot.focusChildId, childId);

    // The decorative canvas draws circles. The polygon zone is a real boundary that this
    // canvas cannot draw, and it is left undrawn rather than drawn as a circle.
    expect(snapshot.zones, hasLength(1));
    expect(snapshot.zones.single.id, zoneId);
    expect(snapshot.zones.single.diameterFraction, closeTo(222 / 2200, 0.001));
  });

  test('the crossings become the day thread of the same screen', () async {
    final transport = _RoutedTransport({
      '/location': const FoundationGateHttpResponse(statusCode: 200, body: _picture),
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone]}',
      ),
      '/geofence-events': const FoundationGateHttpResponse(
        statusCode: 200,
        body: _feed,
      ),
    });
    final snapshot = await ServerLocationMapRepository(
      authorityFor(transport),
    ).load();

    expect(snapshot!.threadStops, hasLength(1));
    expect(snapshot.threadStops.single.title, 'البيت');
    expect(snapshot.threadStops.single.timeLabel, '07/10 08:00');
  });

  test('a child the family does not know is not found rather than shown', () async {
    final transport = _RoutedTransport({
      '/location': const FoundationGateHttpResponse(statusCode: 200, body: _picture),
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[$_circleZone]}',
      ),
      '/geofence-events': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"visibility":"family_members","events":[]}',
      ),
    });
    final snapshot = await ServerLocationMapRepository(
      authorityFor(transport),
    ).load(focusChildId: '99999999-9999-4999-8999-999999999999');

    expect(snapshot, isNull);
  });

  test('a family that has drawn nothing reads as a family with no boundaries', () async {
    final transport = _RoutedTransport({
      '/location': const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"visibility":"family_members","observedAt":"2026-10-07T09:05:00.000Z",'
            '"children":[]}',
      ),
      '/safe-zones': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"zones":[]}',
      ),
      '/geofence-events': const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"visibility":"family_members","events":[]}',
      ),
    });
    final snapshot = await ServerLocationMapRepository(
      authorityFor(transport),
    ).load();

    expect(snapshot, isNotNull);
    expect(snapshot!.pins, isEmpty);
    expect(snapshot.zones, isEmpty);
  });

  test('with no family selected the pack refuses instead of answering for another one', () async {
    final transport = _RoutedTransport(const {});
    final authority = LocationServerAuthority(
      api: FamilyLocationApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'synthetic-token',
      familyId: () => null,
    );

    expect(authority.isReady, isFalse);
    await expectLater(
      ServerSafeZonesRepository(authority).load(),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(transport.requests, isEmpty);
  });

  test('both geometry shapes cross the wire, and the version stays the server business', () async {
    const circle = CircleGeometry(
      center: GeoPoint(latitude: 24.7136, longitude: 46.6753),
      radiusMeters: 250,
    );
    const polygon = PolygonGeometry(
      vertices: [
        GeoPoint(latitude: 24.72, longitude: 46.68),
        GeoPoint(latitude: 24.72, longitude: 46.69),
        GeoPoint(latitude: 24.73, longitude: 46.69),
      ],
    );

    final wireCircle = serverGeometryOf(circle);
    expect(wireCircle, isA<FoundationGateCircleGeometry>());
    expect((wireCircle as FoundationGateCircleGeometry).radiusMeters, 250);
    expect(wireCircle.kind, 'CIRCLE');

    final wirePolygon = serverGeometryOf(polygon);
    expect(wirePolygon, isA<FoundationGatePolygonGeometry>());
    expect((wirePolygon as FoundationGatePolygonGeometry).vertices, hasLength(3));
    expect(wirePolygon.kind, 'POLYGON');
  });
}
