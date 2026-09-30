import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_app.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

void main() {
  testWidgets('tracked Foundation Gate entry starts unconfigured without network or legacy mock data', (tester) async {
    await tester.pumpWidget(const FoundationGateApp());

    expect(find.text('Foundation Gate is not configured.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('configured gate clears local form fields before discovery', (tester) async {
    final identity = FakeIdentity();
    final controller = FoundationGateSessionController(
      identity: identity,
      discoveryApi: FamilyDiscoveryApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: FakeTransport(const FoundationGateHttpResponse(statusCode: 200, body: '{"families":[]}')),
      ),
    );

    await tester.pumpWidget(FoundationGateApp(controller: controller));
    await tester.enterText(find.byType(TextField).at(0), 'synthetic@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'synthetic-password');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(identity.signInCalls, 1);
    expect(find.text('No active family is available.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
