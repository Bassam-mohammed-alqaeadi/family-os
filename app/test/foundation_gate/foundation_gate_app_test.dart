import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_app.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';

void main() {
  FoundationGateSessionController controllerFor({
    required FoundationGateHttpResponse discovery,
    required FoundationGateHttpResponse roster,
  }) {
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse('https://staging.example.test'));
    return FoundationGateSessionController(
      identity: FakeIdentity(),
      discoveryApi: FamilyDiscoveryApiClient(
        configuration: configuration,
        transport: FakeTransport(discovery),
      ),
      rosterApi: ChildrenRosterApiClient(
        configuration: configuration,
        transport: FakeTransport(roster),
      ),
    );
  }

  testWidgets('tracked Foundation Gate entry starts unconfigured without network or legacy mock data', (tester) async {
    await tester.pumpWidget(const FoundationGateApp());

    expect(find.text('Foundation Gate is not configured.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('configured gate clears local form fields before discovery', (tester) async {
    final controller = controllerFor(
      discovery: const FoundationGateHttpResponse(statusCode: 200, body: '{"families":[]}'),
      roster: const FoundationGateHttpResponse(statusCode: 200, body: '{"children":[]}'),
    );

    await tester.pumpWidget(FoundationGateApp(controller: controller));
    await tester.enterText(find.byType(TextField).at(0), 'synthetic@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'synthetic-password');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No active family is available.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('guardian roster renders only server profile facts and no mutation action', (tester) async {
    final controller = controllerFor(
      discovery: const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"families":[{"id":"$familyId","displayName":"Synthetic family","role":"co_guardian"}]}',
      ),
      roster: const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"children":[{"id":"$childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"purple","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}]}',
      ),
    );

    await tester.pumpWidget(FoundationGateApp(controller: controller));
    await tester.enterText(find.byType(TextField).at(0), 'synthetic@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'synthetic-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Synthetic family'));
    await tester.pumpAndSettle();

    expect(find.text('Children control centre'), findsOneWidget);
    expect(find.text('Synthetic child'), findsOneWidget);
    expect(find.text('Age: 8'), findsOneWidget);
    expect(find.textContaining('Co-guardian read-only view'), findsOneWidget);
    expect(find.textContaining('Add child'), findsNothing);
  });
}
