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
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"children":[]}')),
    );

    await unavailable.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(unavailable.phase, FoundationGatePhase.serviceUnavailable);
    expect(unavailable.families, isEmpty);

    final transport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"families":[]}'))
      ..failure = apiFailure(FoundationGateApiFailure.networkUnavailable);
    final networkFailure = controllerFor(
      identity: identity,
      discoveryTransport: transport,
      rosterTransport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"children":[]}')),
    );

    await networkFailure.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(networkFailure.phase, FoundationGatePhase.networkUnavailable);
    expect(networkFailure.families, isEmpty);
  });
}
