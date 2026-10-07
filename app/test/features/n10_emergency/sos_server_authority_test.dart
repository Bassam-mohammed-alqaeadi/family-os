import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/features/n10_emergency/sos_server_authority.dart';
import 'package:family_os/foundation_gate/family_sos_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../foundation_gate/foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '33333333-3333-4333-8333-333333333333';
const alertId = '44444444-4444-4444-8444-444444444444';
const membershipId = '66666666-6666-4666-8666-666666666666';
const contactId = '77777777-7777-4777-8777-777777777777';

/// One incident with a stored position and two recipients, as the server publishes it.
const locatedAlertBody =
    '{"id":"$alertId","familyId":"$familyId","childId":"$childId",'
    '"raisedByKind":"guardian","raisedByMembershipId":"$membershipId",'
    '"status":"active","open":true,"pressedAt":"2026-10-07T09:00:00.000Z",'
    '"receivedAt":"2026-10-07T09:00:01.000Z","acknowledgedAt":null,"escalatedAt":null,'
    '"resolvedAt":null,"terminalReason":null,"resolvedByKind":null,'
    '"picture":{"locationClass":"ready","latitude":15.3694,"longitude":44.191,'
    '"accuracyMeters":18,"connectionClass":"online","batteryPercent":42,'
    '"placeLabel":"البيت","panicQuiet":false,"fixId":null},'
    '"deliveries":['
    '{"recipientKind":"guardian","recipientMembershipId":"$membershipId",'
    '"recipientContactId":null,"channel":"in_app","deliveryState":"recorded",'
    '"reasonCode":null,"createdAt":"2026-10-07T09:00:01.000Z"},'
    '{"recipientKind":"backup","recipientMembershipId":null,'
    '"recipientContactId":"$contactId","channel":"sms","deliveryState":"not_configured",'
    '"reasonCode":"transport_not_configured","createdAt":"2026-10-07T09:00:01.000Z"}],'
    '"version":1}';

/// The same incident when the handset never managed to look: no coordinates, no readings.
const unlocatedAlertBody =
    '{"id":"$alertId","familyId":"$familyId","childId":"$childId",'
    '"raisedByKind":"child_device","raisedByMembershipId":null,'
    '"status":"active","open":true,"pressedAt":"2026-10-07T09:00:00.000Z",'
    '"receivedAt":"2026-10-07T09:00:01.000Z","acknowledgedAt":null,"escalatedAt":null,'
    '"resolvedAt":null,"terminalReason":null,"resolvedByKind":null,'
    '"picture":{"locationClass":"acquiring","latitude":null,"longitude":null,'
    '"accuracyMeters":null,"connectionClass":"degraded","batteryPercent":null,'
    '"placeLabel":null,"panicQuiet":false,"fixId":null},'
    '"deliveries":[],"version":1}';

FamilySosApiClient clientFor(FakeTransport transport) => FamilySosApiClient(
  configuration: FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://staging.example.test'),
  ),
  transport: transport,
);

SosServerAuthority authorityFor(
  FakeTransport transport, {
  Future<Map<String, String>> Function()? memberLabelSource,
  Map<String, String> Function()? memberLabels,
  String? Function() familyIdOf = _family,
  String Function(String childId)? childNameOf,
}) {
  return SosServerAuthority(
    api: clientFor(transport),
    idToken: () async => 'synthetic-token',
    familyId: familyIdOf,
    memberLabels: memberLabels,
    memberLabelSource: memberLabelSource,
    childNameOf: childNameOf,
  );
}

String? _family() => familyId;

void main() {
  tearDown(() => bindSosServerAuthority(null));

  test('a press admits it has not looked, and is reported as reached only then', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"alert":$locatedAlertBody}',
      ),
    );

    final result = await ServerSosFireService(
      authorityFor(transport),
    ).fire(childId: childId, actorId: membershipId);

    expect(result.fired, isTrue);
    expect(result.reachedServer, isTrue);
    expect(result.duplicate, isFalse);
    expect(result.alertId, alertId);
    expect(result.childId, childId);
    expect(transport.postedBody, contains('"locationClass":"acquiring"'));
    expect(transport.postedBody, isNot(contains('"latitude"')));
    expect(transport.postedBody, contains('"panicQuiet":false'));
    // Every recipient row is a queued payload, and none of them is a handset that has it.
    expect(result.recipientDeliveries, hasLength(2));
    expect(result.recipientDeliveries.every((d) => d.delivered), isFalse);
  });

  test('a refusal is not turned into a success', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 201, body: '{"alert":$locatedAlertBody}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 403,
        body: '{"error":{"code":"forbidden","message":"ممنوع"}}',
      ),
    );

    final result = await ServerSosFireService(
      authorityFor(transport),
    ).fire(childId: childId, actorId: membershipId);

    expect(result.fired, isFalse);
    expect(result.reachedServer, isFalse);
    expect(result.alertId, isNull);
    expect(result.recipientDeliveries, isEmpty);
  });

  test('a build with no server says the press reached nobody', () async {
    bindSosServerAuthority(null);

    final result = await activeSosFireService.fire(childId: childId);

    expect(sosFireIsWired, isFalse);
    expect(result.fired, isFalse);
    expect(result.reachedServer, isFalse);
    expect(result.recipientDeliveries, isEmpty);
  });

  test('a build with a server answers with the server incident', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"alert":$locatedAlertBody}',
      ),
    );
    bindSosServerAuthority(authorityFor(transport));

    final result = await activeSosFireService.fire(childId: childId);

    expect(sosFireIsWired, isTrue);
    expect(result.fired, isTrue);
    expect(result.alertId, alertId);
  });

  test('a second press leads to the incident that already exists', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 409,
        body:
            '{"error":{"code":"sos_alert_exists","message":"حادث مفتوح",'
            '"details":{"alertId":"$alertId"}}}',
      ),
    );

    final result = await ServerSosFireService(
      authorityFor(transport),
    ).fire(childId: childId, actorId: membershipId);

    expect(result.fired, isTrue);
    expect(result.duplicate, isTrue);
    expect(result.alertId, alertId);
    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-alerts/$alertId',
    );
  });

  test('the board never reports a delivery nobody made', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
    );

    final alert = (await authorityFor(transport).openAlerts()).single;
    final board = authorityFor(transport).toAlert(alert);

    expect(board.status, SosAlertStatus.active);
    expect(board.deliveries.first.status, SosDeliveryClass.pending);
    expect(board.deliveries.last.status, SosDeliveryClass.notConfigured);
    expect(board.batteryPercent, 42);
    expect(board.accuracyMeters, 18);
    expect(board.locationLabel, 'البيت');
    expect(board.locationClass, SosLocationClass.ready);
  });

  test('a pin exists only where the server stored a position', () async {
    final located = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
    );
    final locatedBoard = authorityFor(
      located,
    ).toAlert((await authorityFor(located).openAlerts()).single);

    expect(locatedBoard.pinFracX, isNotNull);
    expect(locatedBoard.pinFracY, isNotNull);
    expect(locatedBoard.pinFracX, inInclusiveRange(0, 1));
    expect(locatedBoard.pinFracY, inInclusiveRange(0, 1));

    final unlocated = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$unlocatedAlertBody}'),
    );
    final board = authorityFor(
      unlocated,
    ).toAlert((await authorityFor(unlocated).openAlerts()).single);

    // A handset that could not look has no reading to show and no door to pin - not a
    // zero, and not the middle of the map.
    expect(board.pinFracX, isNull);
    expect(board.pinFracY, isNull);
    expect(board.batteryPercent, isNull);
    expect(board.accuracyMeters, isNull);
    expect(board.locationLabel, isEmpty);
    expect(board.locationClass, SosLocationClass.acquiring);
  });

  test('the footer names the members the roster named, and invents nobody', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
    );
    final authority = authorityFor(
      transport,
      memberLabelSource: () async => {membershipId: 'الأب'},
    );

    final board = authority.toAlert((await authority.openAlerts()).single);

    expect(board.recipientLabels, ['الأب']);
    expect(board.deliveries.first.recipientId, 'الأب');

    final unknown = authorityFor(
      transport,
      memberLabels: () => const {'00000000-0000-4000-8000-000000000000': 'غير معروف'},
    );
    final unnamed = unknown.toAlert((await unknown.openAlerts()).single);

    // Nobody was named, so the summary says nothing rather than printing a uuid.
    expect(unnamed.recipientLabels, isEmpty);
  });

  test('a roster read that fails does not blank the recipients', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
    );
    var reads = 0;
    final authority = authorityFor(
      transport,
      memberLabels: () => const {membershipId: 'الأب'},
      memberLabelSource: () async {
        reads += 1;
        throw Exception('roster unavailable');
      },
    );

    final board = authority.toAlert((await authority.openAlerts()).single);

    // The refresh was attempted and failed; the names the authority already had survive,
    // because an emergency board must not lose its labels to a failed roster read.
    expect(reads, greaterThan(0));
    expect(board.recipientLabels, ['الأب']);
  });

  test('the child cannot close their own incident from this build', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alert":$locatedAlertBody}'),
    );
    final repository = ServerSosAlertRepository(authorityFor(transport));

    await expectLater(
      repository.resolve(
        alertId,
        actor: SosActor.child(),
        reason: SosTerminalReason.falseAlarm,
      ),
      throwsA(isA<SosFireUnavailable>()),
    );
    expect(transport.postedUri, isNull);

    // Acknowledge is not a child's act either, and it is refused before any request.
    await expectLater(
      repository.acknowledge(alertId, actor: SosActor.child()),
      throwsA(isA<StateError>()),
    );
    expect(transport.postedUri, isNull);
  });

  test('a guardian closes the incident on the server', () async {
    final resolvedBody =
        '{"alert":${locatedAlertBody.replaceFirst('"status":"active"', '"status":"resolved"').replaceFirst('"resolvedAt":null', '"resolvedAt":"2026-10-07T09:10:00.000Z"').replaceFirst('"terminalReason":null', '"terminalReason":"false_alarm"').replaceFirst('"resolvedByKind":null', '"resolvedByKind":"guardian"')}}';
    final transport = FakeTransport(
      FoundationGateHttpResponse(statusCode: 200, body: resolvedBody),
    );
    final repository = ServerSosAlertRepository(
      authorityFor(transport, memberLabels: () => const {membershipId: 'الأب'}),
    );

    final board = await repository.resolve(
      alertId,
      actor: const SosActor(role: AppRole.father),
      reason: SosTerminalReason.falseAlarm,
    );

    expect(board.status, SosAlertStatus.resolved);
    expect(board.terminalReason, SosTerminalReason.falseAlarm);
    expect(transport.postedBody, contains('"terminalReason":"false_alarm"'));
  });
}
