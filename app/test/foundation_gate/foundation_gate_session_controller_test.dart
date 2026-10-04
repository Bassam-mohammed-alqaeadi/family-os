import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';
const familyBody =
    '{"families":[{"id":"$familyId","displayName":"Synthetic family","role":"primary_guardian"}]}';
const rosterBody =
    '{"children":[{"id":"$childId","displayName":"Synthetic child","ageYears":8,"version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}]}';
const emptyRosterBody = '{"children":[]}';
const createdChildBody =
    '{"child":{"id":"$childId","displayName":"Synthetic child","ageYears":8,"version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}}';
const idempotencyKey = '33333333-3333-4333-8333-333333333333';

void main() {
  FoundationGateConfiguration configuration() {
    return FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse('https://staging.example.test'));
  }

  FoundationGateSessionController controllerFor({
    required FakeIdentity identity,
    required FakeTransport discoveryTransport,
    required FakeTransport rosterTransport,
  }) {
    final config = configuration();
    return FoundationGateSessionController(
      identity: identity,
      discoveryApi: FamilyDiscoveryApiClient(configuration: config, transport: discoveryTransport),
      rosterApi: ChildrenRosterApiClient(configuration: config, transport: rosterTransport),
    );
  }

  Future<FoundationGateSessionController> readyForCreate({
    required FakeIdentity identity,
    required FakeTransport rosterTransport,
  }) async {
    final controller = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: familyBody)),
      rosterTransport: rosterTransport,
    );
    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);
    return controller;
  }

  test('successful roster read remains volatile and sign-out clears family and roster state', () async {
    final identity = FakeIdentity();
    final controller = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: familyBody)),
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: rosterBody)),
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    expect(controller.phase, FoundationGatePhase.familiesAvailable);

    await controller.selectFamily(controller.families.single);

    expect(identity.currentTokenCalls, 1);
    expect(controller.phase, FoundationGatePhase.childrenAvailable);
    expect(controller.children, hasLength(1));
    expect(controller.children.single.displayName, 'Synthetic child');

    await controller.signOut();

    expect(identity.signOutCalls, 1);
    expect(controller.phase, FoundationGatePhase.signedOut);
    expect(controller.families, isEmpty);
    expect(controller.children, isEmpty);
    expect(controller.selectedFamily, isNull);
  });

  test('primary guardian child creation refreshes the server roster after a 201 response', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postResponse = const FoundationGateHttpResponse(statusCode: 201, body: createdChildBody);
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);

    // The setup read sees the initially empty roster. The POST is then followed
    // by another GET, which receives the authoritative updated collection.
    rosterTransport.response = const FoundationGateHttpResponse(statusCode: 200, body: rosterBody);
    final result = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(result, FoundationGateChildCreateResult.created);
    expect(identity.currentTokenCalls, 2);
    expect(rosterTransport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(controller.phase, FoundationGatePhase.childrenAvailable);
    expect(controller.children.single.displayName, 'Synthetic child');
  });

  test('create conflict preserves the existing server roster and returns a typed result', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postResponse = const FoundationGateHttpResponse(statusCode: 409, body: '')
      ..response = const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody);
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);

    final first = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );
    final second = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(first, FoundationGateChildCreateResult.conflict);
    expect(second, FoundationGateChildCreateResult.conflict);
    expect(rosterTransport.postedHeaders?['idempotency-key'], idempotencyKey);
    expect(controller.phase, FoundationGatePhase.noChildren);
    expect(controller.children, isEmpty);
  });

  test('ambiguous network outcome clears the roster and retries the same key safely', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postFailure = apiFailure(FoundationGateApiFailure.networkUnavailable);
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);

    final first = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );
    expect(first, FoundationGateChildCreateResult.networkUnavailable);
    expect(controller.phase, FoundationGatePhase.networkUnavailable);
    expect(controller.children, isEmpty);

    rosterTransport
      ..postFailure = null
      ..postResponse = const FoundationGateHttpResponse(statusCode: 201, body: createdChildBody)
      ..response = const FoundationGateHttpResponse(statusCode: 200, body: rosterBody);
    final second = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(second, FoundationGateChildCreateResult.created);
    expect(
      rosterTransport.postedHeadersHistory.map((headers) => headers['idempotency-key']),
      everyElement(equals(idempotencyKey)),
    );
    expect(controller.phase, FoundationGatePhase.childrenAvailable);
  });

  test('create 401 clears volatile authority and returns the sign-in recovery result', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postResponse = const FoundationGateHttpResponse(statusCode: 401, body: '');
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);

    final result = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(result, FoundationGateChildCreateResult.sessionInvalid);
    expect(identity.signOutCalls, 1);
    expect(controller.phase, FoundationGatePhase.sessionInvalid);
    expect(controller.families, isEmpty);
    expect(controller.children, isEmpty);
    expect(controller.selectedFamily, isNull);
  });

  test('server create denial overrides a primary-looking discovery role and reveals no roster', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postResponse = const FoundationGateHttpResponse(statusCode: 403, body: '');
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);

    final result = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(result, FoundationGateChildCreateResult.accessDenied);
    expect(controller.phase, FoundationGatePhase.rosterAccessDenied);
    expect(controller.children, isEmpty);
  });

  test('created profile never appears locally when the required roster refresh is unavailable', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody))
      ..postResponse = const FoundationGateHttpResponse(statusCode: 201, body: createdChildBody);
    final controller = await readyForCreate(identity: identity, rosterTransport: rosterTransport);
    rosterTransport.response = const FoundationGateHttpResponse(statusCode: 503, body: '');

    final result = await controller.createChild(
      displayName: 'Synthetic child',
      ageYears: 8,
      idempotencyKey: idempotencyKey,
    );

    expect(result, FoundationGateChildCreateResult.createdRosterRefreshUnavailable);
    expect(controller.phase, FoundationGatePhase.serviceUnavailable);
    expect(controller.children, isEmpty);
  });

  test('child or unrelated roster denial never creates parent roster state', () async {
    final identity = FakeIdentity();
    final controller = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: familyBody)),
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 403, body: '')),
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);

    expect(controller.phase, FoundationGatePhase.rosterAccessDenied);
    expect(controller.children, isEmpty);
    expect(controller.families, hasLength(1));
  });

  test('401 roster response clears all authority and signs the provider out', () async {
    final identity = FakeIdentity();
    final controller = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: familyBody)),
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 401, body: '')),
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);

    expect(identity.signOutCalls, 1);
    expect(controller.phase, FoundationGatePhase.sessionInvalid);
    expect(controller.families, isEmpty);
    expect(controller.children, isEmpty);
    expect(controller.selectedFamily, isNull);
  });

  test('unavailable roster clears only roster state and may be retried without a cache', () async {
    final identity = FakeIdentity();
    final rosterTransport = FakeTransport(const FoundationGateHttpResponse(statusCode: 503, body: ''));
    final controller = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: familyBody)),
      rosterTransport: rosterTransport,
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);

    expect(controller.phase, FoundationGatePhase.serviceUnavailable);
    expect(controller.children, isEmpty);
    expect(controller.selectedFamily, isNotNull);

    rosterTransport.response = const FoundationGateHttpResponse(statusCode: 200, body: rosterBody);
    await controller.retryRoster();

    expect(controller.phase, FoundationGatePhase.childrenAvailable);
    expect(controller.children, hasLength(1));
  });

  test('discovery 503 and network failures never provide cached family authority', () async {
    final identity = FakeIdentity();
    final unavailable = controllerFor(
      identity: identity,
      discoveryTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 503, body: '')),
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody)),
    );

    await unavailable.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(unavailable.phase, FoundationGatePhase.serviceUnavailable);
    expect(unavailable.families, isEmpty);

    final transport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"families":[]}'))
      ..failure = apiFailure(FoundationGateApiFailure.networkUnavailable);
    final networkFailure = controllerFor(
      identity: identity,
      discoveryTransport: transport,
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: emptyRosterBody)),
    );

    await networkFailure.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(networkFailure.phase, FoundationGatePhase.networkUnavailable);
    expect(networkFailure.families, isEmpty);
  });
}
