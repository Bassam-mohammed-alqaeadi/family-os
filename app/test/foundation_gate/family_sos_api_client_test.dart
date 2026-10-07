import 'package:family_os/foundation_gate/family_sos_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '33333333-3333-4333-8333-333333333333';
const alertId = '44444444-4444-4444-8444-444444444444';
const otherAlertId = '55555555-5555-4555-8555-555555555555';
const membershipId = '66666666-6666-4666-8666-666666666666';
const contactId = '77777777-7777-4777-8777-777777777777';
const fixId = '88888888-8888-4888-8888-888888888888';
const idempotencyKey = '99999999-9999-4999-8999-999999999999';

/// One incident exactly as `backend/src/sos-emergency.js` publishes it: an honest
/// position with its accuracy, one guardian whose payload is durably recorded, and one
/// backup number whose transport is not configured - the only two delivery states that
/// exist.
const openAlertBody =
    '{"id":"$alertId","familyId":"$familyId","childId":"$childId",'
    '"raisedByKind":"guardian","raisedByMembershipId":"$membershipId",'
    '"status":"active","open":true,"pressedAt":"2026-10-07T09:00:00.000Z",'
    '"receivedAt":"2026-10-07T09:00:01.000Z","acknowledgedAt":null,"escalatedAt":null,'
    '"resolvedAt":null,"terminalReason":null,"resolvedByKind":null,'
    '"picture":{"locationClass":"ready","latitude":15.3694,"longitude":44.191,'
    '"accuracyMeters":18,"connectionClass":"online","batteryPercent":42,'
    '"placeLabel":"البيت","panicQuiet":false,"fixId":"$fixId"},'
    '"deliveries":['
    '{"recipientKind":"guardian","recipientMembershipId":"$membershipId",'
    '"recipientContactId":null,"channel":"in_app","deliveryState":"recorded",'
    '"reasonCode":null,"createdAt":"2026-10-07T09:00:01.000Z"},'
    '{"recipientKind":"backup","recipientMembershipId":null,'
    '"recipientContactId":"$contactId","channel":"sms","deliveryState":"not_configured",'
    '"reasonCode":"transport_not_configured","createdAt":"2026-10-07T09:00:01.000Z"}],'
    '"version":1}';

const contactBody =
    '{"id":"$contactId","name":"العمّ خالد","relation":"uncle",'
    '"phoneE164":"+967771234567","verification":"verified","enabled":true,'
    '"priority":1,"archivedAt":null,"createdAt":"2026-10-07T08:00:00.000Z",'
    '"updatedAt":"2026-10-07T08:00:00.000Z"}';

FoundationGateConfiguration configuration() =>
    FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );

FamilySosApiClient clientFor(FakeTransport transport) => FamilySosApiClient(
  configuration: configuration(),
  transport: transport,
);

Matcher throwsApiFailure(FoundationGateApiFailure failure) =>
    throwsA(isA<FoundationGateApiException>().having((e) => e.failure, 'failure', failure));

void main() {
  test('the board reads open incidents by default, with the family session', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"alerts":[$openAlertBody]}',
      ),
    );

    final alerts = await clientFor(
      transport,
    ).listAlerts(familyId: familyId, idToken: 'synthetic-token');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-alerts',
    );
    expect(transport.requestedHeaders?['authorization'], 'Bearer synthetic-token');

    final alert = alerts.single;
    expect(alert.id, alertId);
    expect(alert.childId, childId);
    expect(alert.raisedByKind, 'guardian');
    expect(alert.status, FoundationGateSosAlertStatus.active);
    expect(alert.isOpen, isTrue);
    expect(alert.picture.locationClass, FoundationGateSosLocationClass.ready);
    expect(alert.picture.carriesCoordinates, isTrue);
    expect(alert.picture.latitude, 15.3694);
    expect(alert.picture.accuracyMeters, 18);
    expect(alert.picture.batteryPercent, 42);
    expect(alert.deliveries, hasLength(2));
    expect(
      alert.deliveries.first.deliveryState,
      FoundationGateSosDeliveryState.recorded,
    );
    expect(alert.deliveries.last.reasonCode, 'transport_not_configured');
  });

  test('closed incidents are asked for explicitly, never assumed', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alerts":[]}'),
    );

    await clientFor(
      transport,
    ).listAlerts(familyId: familyId, idToken: 'synthetic-token', status: 'all');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-alerts?status=all',
    );
  });

  test('a delivery that claims it was delivered is refused, not displayed', () async {
    final body =
        '{"alerts":[${openAlertBody.replaceFirst('"deliveryState":"recorded"', '"deliveryState":"delivered"')}]}';
    final transport = FakeTransport(
      FoundationGateHttpResponse(statusCode: 200, body: body),
    );

    await expectLater(
      clientFor(transport).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );
  });

  test('a reason exists exactly when the transport does not', () async {
    // A recorded payload that explains itself, and a missing transport that explains
    // nothing: the database forbids both, and the screen must not have to guess.
    final recordedWithReason = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"alerts":[${openAlertBody.replaceFirst('"deliveryState":"recorded","reasonCode":null', '"deliveryState":"recorded","reasonCode":"transport_not_configured"')}]}',
      ),
    );
    await expectLater(
      clientFor(recordedWithReason).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );

    final silentNotConfigured = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"alerts":[${openAlertBody.replaceFirst('"deliveryState":"not_configured","reasonCode":"transport_not_configured"', '"deliveryState":"not_configured","reasonCode":null')}]}',
      ),
    );
    await expectLater(
      clientFor(silentNotConfigured).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );
  });

  test('a position without precision, and precision without a position, are both refused', () async {
    final noAccuracy = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"alerts":[${openAlertBody.replaceFirst('"accuracyMeters":18', '"accuracyMeters":null')}]}',
      ),
    );
    await expectLater(
      clientFor(noAccuracy).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );

    final noPosition = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"alerts":[${openAlertBody.replaceFirst('"locationClass":"ready","latitude":15.3694,"longitude":44.191,', '"locationClass":"acquiring","latitude":null,"longitude":null,').replaceFirst('"accuracyMeters":18', '"accuracyMeters":null')}]}',
      ),
    );
    await expectLater(
      clientFor(noPosition).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );
  });

  test('a missing incident is notFound rather than an empty incident', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 404,
        body: '{"error":{"code":"not_found","message":"لا يوجد"}}',
      ),
    );

    await expectLater(
      clientFor(
        transport,
      ).readAlert(familyId: familyId, alertId: alertId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.notFound),
    );
  });

  test('a guardian press opens an incident and returns it', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 201, body: '{"alert":$openAlertBody}'),
    );

    final outcome = await clientFor(transport).raiseForChild(
      familyId: familyId,
      childId: childId,
      locationClass: FoundationGateSosLocationClass.ready,
      connectionClass: FoundationGateSosConnectionClass.online,
      latitude: 15.3694,
      longitude: 44.191,
      accuracyMeters: 18,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(outcome.opened, isTrue);
    expect(outcome.isDuplicate, isFalse);
    expect(outcome.alert?.id, alertId);
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/children/$childId/sos-alerts',
    );
    expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(transport.postedBody, contains('"locationClass":"ready"'));
    expect(transport.postedBody, contains('"accuracyMeters":18.0'));
  });

  test('a second press is the incident that already exists, not an error', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"alert":$openAlertBody}',
      ),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 409,
        body:
            '{"error":{"code":"sos_alert_exists","message":"حادث مفتوح",'
            '"details":{"alertId":"$otherAlertId"}}}',
      ),
    );

    final outcome = await clientFor(transport).raiseForChild(
      familyId: familyId,
      childId: childId,
      locationClass: FoundationGateSosLocationClass.acquiring,
      connectionClass: FoundationGateSosConnectionClass.degraded,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(outcome.opened, isFalse);
    expect(outcome.isDuplicate, isTrue);
    expect(outcome.existingAlertId, otherAlertId);
  });

  test('a conflict that does not name the incident is a conflict, not a guess', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 201, body: '{"alert":$openAlertBody}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"conflict","message":"تعارض"}}',
      ),
    );

    await expectLater(
      clientFor(transport).raiseForChild(
        familyId: familyId,
        childId: childId,
        locationClass: FoundationGateSosLocationClass.acquiring,
        connectionClass: FoundationGateSosConnectionClass.online,
        idempotencyKey: idempotencyKey,
        idToken: 't',
      ),
      throwsApiFailure(FoundationGateApiFailure.conflict),
    );
  });

  test('a press that claims a place it cannot measure never leaves the device', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 201, body: '{"alert":$openAlertBody}'),
    );

    await expectLater(
      clientFor(transport).raiseForChild(
        familyId: familyId,
        childId: childId,
        locationClass: FoundationGateSosLocationClass.acquiring,
        connectionClass: FoundationGateSosConnectionClass.online,
        accuracyMeters: 18,
        idempotencyKey: idempotencyKey,
        idToken: 't',
      ),
      throwsApiFailure(FoundationGateApiFailure.invalidInput),
    );
    expect(transport.postedUri, isNull);
  });

  test('acknowledging says "seen" with a key the server can replay', () async {
    final transport = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"alert":${openAlertBody.replaceFirst('"status":"active"', '"status":"acknowledged"').replaceFirst('"acknowledgedAt":null', '"acknowledgedAt":"2026-10-07T09:02:00.000Z"')}}',
      ),
    );

    final alert = await clientFor(transport).acknowledge(
      familyId: familyId,
      alertId: alertId,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(alert.status, FoundationGateSosAlertStatus.acknowledged);
    expect(alert.acknowledgedAt, DateTime.utc(2026, 10, 7, 9, 2));
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-alerts/$alertId/acknowledge',
    );
    expect(transport.postedHeaders?['idempotency-key'], idempotencyKey);
  });

  test('escalation reports the ladder it climbed, and the rungs it skipped', () async {
    final transport = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"alert":${openAlertBody.replaceFirst('"status":"active"', '"status":"escalating"')},'
            '"escalation":{"eligibleContacts":2,"skippedUnverified":1},"replayed":false}',
      ),
    );

    final receipt = await clientFor(transport).escalate(
      familyId: familyId,
      alertId: alertId,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(receipt.alert.status, FoundationGateSosAlertStatus.escalating);
    expect(receipt.escalation.eligibleContacts, 2);
    expect(receipt.escalation.skippedUnverified, 1);
    expect(receipt.replayed, isFalse);
  });

  test('closing an incident states the reason the guardian chose', () async {
    final resolvedBody =
        '{"alert":${openAlertBody.replaceFirst('"status":"active"', '"status":"resolved"').replaceFirst('"resolvedAt":null', '"resolvedAt":"2026-10-07T09:10:00.000Z"').replaceFirst('"terminalReason":null', '"terminalReason":"helped"').replaceFirst('"resolvedByKind":null', '"resolvedByKind":"guardian"')}}';
    final transport = FakeTransport(
      FoundationGateHttpResponse(statusCode: 200, body: resolvedBody),
    );

    final alert = await clientFor(transport).resolve(
      familyId: familyId,
      alertId: alertId,
      reason: FoundationGateSosTerminalReason.helped,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(alert.status, FoundationGateSosAlertStatus.resolved);
    expect(alert.isOpen, isFalse);
    expect(alert.terminalReason, FoundationGateSosTerminalReason.helped);
    expect(alert.resolvedByKind, 'guardian');
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-alerts/$alertId/resolve',
    );
    expect(transport.postedBody, contains('"terminalReason":"helped"'));
  });

  test('backup contacts carry the verification that decides whether they escalate', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"contacts":[$contactBody,'
            '{"id":"$otherAlertId","name":"الخالة","relation":"aunt",'
            '"phoneE164":"+967700000000","verification":"unverified","enabled":true,'
            '"priority":2,"archivedAt":null,"createdAt":"2026-10-07T08:00:00.000Z",'
            '"updatedAt":"2026-10-07T08:00:00.000Z"}]}',
      ),
    );

    final contacts = await clientFor(
      transport,
    ).listBackupContacts(familyId: familyId, idToken: 't');

    expect(
      transport.requestedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-backup-contacts',
    );
    expect(contacts.first.id, contactId);
    expect(contacts.first.phoneE164, '+967771234567');
    expect(contacts.first.verification, FoundationGateSosBackupVerification.verified);
    expect(contacts.first.escalates, isTrue);
    expect(contacts.last.escalates, isFalse);
  });

  test('a number that is not E.164 is refused rather than shown to a family', () async {
    final transport = FakeTransport(
      FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"contacts":[${contactBody.replaceFirst('"+967771234567"', '"0771234567"')}]}',
      ),
    );

    await expectLater(
      clientFor(transport).listBackupContacts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.invalidResponse),
    );
  });

  test('adding a rung posts it and returns the rung the server created', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"contact":$contactBody}',
      ),
    );

    final contact = await clientFor(transport).createBackupContact(
      familyId: familyId,
      name: 'العمّ خالد',
      phoneE164: '+967771234567',
      relation: 'uncle',
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(contact.id, contactId);
    expect(contact.priority, 1);
    expect(
      transport.postedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-backup-contacts',
    );
    expect(transport.postedBody, contains('"+967771234567"'));
    expect(transport.postedBody, isNot(contains('"verification"')));
  });

  test('an edit sends only what changed, and an empty edit is refused', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"contact":$contactBody}',
      ),
    );

    await clientFor(transport).updateBackupContact(
      familyId: familyId,
      contactId: contactId,
      enabled: false,
      idempotencyKey: idempotencyKey,
      idToken: 't',
    );

    expect(
      transport.patchedUri.toString(),
      'https://staging.example.test/v1/families/$familyId/sos-backup-contacts/$contactId',
    );
    expect(transport.patchedBody, '{"enabled":false}');

    await expectLater(
      clientFor(
        transport,
      ).updateBackupContact(
        familyId: familyId,
        contactId: contactId,
        idempotencyKey: idempotencyKey,
        idToken: 't',
      ),
      throwsApiFailure(FoundationGateApiFailure.invalidInput),
    );
  });

  test('a network that never answered is a network failure, not an empty board', () async {
    final transport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{"alerts":[]}'),
    )..failure = Exception('socket closed');

    await expectLater(
      clientFor(transport).listAlerts(familyId: familyId, idToken: 't'),
      throwsApiFailure(FoundationGateApiFailure.networkUnavailable),
    );
  });
}
