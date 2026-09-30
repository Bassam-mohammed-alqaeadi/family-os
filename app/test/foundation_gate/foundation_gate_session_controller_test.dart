import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

void main() {
  FamilyDiscoveryApiClient clientFor(FakeTransport transport) {
    return FamilyDiscoveryApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
  }

  test('successful discovery remains volatile and sign-out clears it', () async {
    final identity = FakeIdentity();
    final controller = FoundationGateSessionController(
      identity: identity,
      discoveryApi: clientFor(
        FakeTransport(
          const FoundationGateHttpResponse(
            statusCode: 200,
            body: '{"families":[{"id":"family-a","displayName":"Synthetic family","role":"primary_guardian"}]}',
          ),
        ),
      ),
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(controller.phase, FoundationGatePhase.familiesAvailable);
    expect(controller.families, hasLength(1));
    controller.selectFamily(controller.families.single);
    expect(controller.selectedFamily?.id, 'family-a');

    await controller.signOut();

    expect(identity.signOutCalls, 1);
    expect(controller.phase, FoundationGatePhase.signedOut);
    expect(controller.families, isEmpty);
    expect(controller.selectedFamily, isNull);
  });

  test('401 clears state and signs out without retaining a family', () async {
    final identity = FakeIdentity();
    final controller = FoundationGateSessionController(
      identity: identity,
      discoveryApi: clientFor(FakeTransport(const FoundationGateHttpResponse(statusCode: 401, body: ''))),
    );

    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(identity.signOutCalls, 1);
    expect(controller.phase, FoundationGatePhase.sessionInvalid);
    expect(controller.families, isEmpty);
    expect(controller.selectedFamily, isNull);
  });

  test('503 and transport failures never supply cached authority', () async {
    final identity = FakeIdentity();
    final unavailable = FoundationGateSessionController(
      identity: identity,
      discoveryApi: clientFor(FakeTransport(const FoundationGateHttpResponse(statusCode: 503, body: ''))),
    );

    await unavailable.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(unavailable.phase, FoundationGatePhase.serviceUnavailable);
    expect(unavailable.families, isEmpty);

    final transport = FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"families":[]}'))
      ..failure = apiFailure(FoundationGateApiFailure.networkUnavailable);
    final networkFailure = FoundationGateSessionController(
      identity: identity,
      discoveryApi: clientFor(transport),
    );

    await networkFailure.signIn(email: 'synthetic@example.test', password: 'synthetic-password');

    expect(networkFailure.phase, FoundationGatePhase.networkUnavailable);
    expect(networkFailure.families, isEmpty);
  });
}
