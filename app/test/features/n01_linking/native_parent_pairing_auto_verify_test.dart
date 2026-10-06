import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/features/n01_linking/native_device_pairing_screens.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import '../shared_onboarding/onboarding_test_host.dart';

const _childId = '22222222-2222-4222-8222-222222222222';

String _pairingBody() {
  final expires = DateTime.now().toUtc().add(const Duration(minutes: 10));
  return '{"pairing":{"id":"33333333-3333-4333-8333-333333333333","childId":"$_childId","deviceLabel":"هاتف الطفل","pairingCode":"abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-","expiresAt":"${expires.toIso8601String()}"}}';
}

void main() {
  testWidgets(
    'C1 magic: e-mail verified elsewhere → detected silently → code issued',
    (tester) async {
      final identity = FakeIdentity()..emailVerified = false;
      final devices = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"devices":[]}',
        ),
        postResponse: FoundationGateHttpResponse(
          statusCode: 201,
          body: _pairingBody(),
        ),
      );
      final host = OnboardingHost(identity: identity, deviceTransport: devices);
      addTearDown(host.dispose);
      await host.runtime.signIn(email: 'p@example.com', password: 'x1234567');

      await pumpWithRouter(
        tester,
        runtime: host.appRuntime,
        initialLocation: '/scr-fat-004?childId=$_childId',
        settle: false,
        routes: [
          GoRoute(
            path: '/scr-fat-004',
            builder: (context, state) => NativeParentPairingScreen(
              childId: state.uri.queryParameters['childId'],
            ),
          ),
        ],
      );

      // Gate closed: waiting copy visible, no manual "I verified" button,
      // nothing posted to the server.
      expect(find.textContaining('بانتظار تأكيدك'), findsOneWidget);
      expect(find.text('تحققت'), findsNothing);
      expect(devices.postedUri, isNull);

      // Two silent polls while still unverified.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      expect(devices.postedUri, isNull);

      // The guardian clicks the link on a laptop: the next poll sees it and
      // the screen continues hands-free.
      identity.emailVerified = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump();

      expect(devices.postedUri?.path, contains('/device-pairings'));
      expect(find.textContaining('بانتظار تأكيدك'), findsNothing);

      // Let the countdown/device timers settle, then stop them.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
