import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/features/n01_linking/native_device_pairing_screens.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

import '../shared_onboarding/onboarding_test_host.dart';

const _childId = '22222222-2222-4222-8222-222222222222';

String _pairingBody() {
  final expires = DateTime.now().toUtc().add(const Duration(minutes: 10));
  return '{"pairing":{"id":"33333333-3333-4333-8333-333333333333","childId":"$_childId","deviceLabel":"هاتف الطفل","pairingCode":"482910","expiresAt":"${expires.toIso8601String()}"}}';
}

void main() {
  tearDown(AppToast.dismiss);

  testWidgets(
    'C1 magic: e-mail verified elsewhere → detected silently → code issued',
    (tester) async {
      final identity = FakeIdentity(token: 'stale-unverified-token')
        ..emailVerified = false
        ..tokenAfterVerificationReload = 'fresh-verified-token';
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
      expect(identity.verificationReloads.first, isTrue);

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
      expect(
        devices.postedHeaders?['authorization'],
        'Bearer fresh-verified-token',
      );
      expect(identity.verificationReloads.every((reload) => reload), isTrue);
      expect(find.textContaining('بانتظار تأكيدك'), findsNothing);
      expect(find.text('تم تأكيد الإيميل بنجاح'), findsOneWidget);
      // The six digits are shown verbatim (no grouping/spaces) in a large
      // bold style so the guardian can read them aloud.
      final digits = tester.widget<SelectableText>(
        find.byKey(const ValueKey('pairing-code-digits')),
      );
      expect(digits.data, '482910');
      expect(digits.style?.fontSize, greaterThanOrEqualTo(40));
      expect(digits.style?.fontWeight, FontWeight.w900);

      // Dismiss transient feedback before replacing the overlay, then stop the
      // countdown/device timers by disposing the screen.
      AppToast.dismiss();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'server verification rejection reopens the gate with actionable copy',
    (tester) async {
      final identity = FakeIdentity();
      final devices = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"devices":[]}',
        ),
        postResponse: const FoundationGateHttpResponse(
          statusCode: 403,
          body:
              '{"error":{"code":"email_verification_required","message":"must not be displayed"}}',
        ),
      );
      final host = OnboardingHost(identity: identity, deviceTransport: devices);
      addTearDown(host.dispose);
      await host.runtime.signIn(email: 'p@example.com', password: 'x1234567');

      await pumpWithRouter(
        tester,
        runtime: host.appRuntime,
        initialLocation: '/scr-fat-004?childId=$_childId',
        routes: [
          GoRoute(
            path: '/scr-fat-004',
            builder: (context, state) => NativeParentPairingScreen(
              childId: state.uri.queryParameters['childId'],
            ),
          ),
        ],
      );
      await tester.tap(find.text('إنشاء رمز الربط'));
      // The verification-recovery card intentionally contains an animated
      // progress indicator while its silent poll is active, so this state can
      // never be observed with pumpAndSettle.
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('لم يستلم الخادم تأكيد البريد'), findsWidgets);
      expect(find.textContaining('must not be displayed'), findsNothing);
      expect(find.text('تعذر على الخادم إنشاء رمز ربط.'), findsNothing);
      expect(find.textContaining('بانتظار تأكيدك'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('conflict retry rotates the non-replayable issuance key', (
    tester,
  ) async {
    final identity = FakeIdentity();
    final devices = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"devices":[]}',
      ),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"pairing_code_not_replayable"}}',
      ),
    );
    final host = OnboardingHost(identity: identity, deviceTransport: devices);
    addTearDown(host.dispose);
    await host.runtime.signIn(email: 'p@example.com', password: 'x1234567');

    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-fat-004?childId=$_childId',
      routes: [
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => NativeParentPairingScreen(
            childId: state.uri.queryParameters['childId'],
          ),
        ),
      ],
    );
    await tester.tap(find.text('إنشاء رمز الربط'));
    await tester.pumpAndSettle();

    expect(find.textContaining('المحاولة السابقة'), findsOneWidget);
    final firstKey = devices.postedHeadersHistory.single['idempotency-key'];

    devices.postResponse = FoundationGateHttpResponse(
      statusCode: 201,
      body: _pairingBody(),
    );
    await tester.tap(find.text('إنشاء رمز الربط'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(devices.postedHeadersHistory, hasLength(2));
    expect(
      devices.postedHeadersHistory.last['idempotency-key'],
      isNot(firstKey),
    );

    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('401 hides pairing state and returns to this step after sign-in', (
    tester,
  ) async {
    final identity = FakeIdentity();
    final devices = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"devices":[]}',
      ),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 401,
        body: '',
      ),
    );
    final host = OnboardingHost(identity: identity, deviceTransport: devices);
    addTearDown(host.dispose);
    await host.runtime.signIn(email: 'p@example.com', password: 'x1234567');

    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-fat-004?childId=$_childId&source=server',
      routes: [
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => NativeParentPairingScreen(
            childId: state.uri.queryParameters['childId'],
          ),
        ),
        GoRoute(
          path: '/scr-shr-003',
          builder: (context, state) => const Scaffold(
            body: Text('real sign-in route'),
          ),
        ),
      ],
    );

    await tester.tap(find.text('إنشاء رمز الربط'));
    await tester.pumpAndSettle();

    expect(host.runtime.phase, FoundationGatePhase.sessionInvalid);
    expect(host.appRuntime.identity.value.isRemoteAuthoritative, isFalse);
    expect(identity.signOutCalls, 1);
    expect(find.textContaining('انتهت جلسة ولي الأمر'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('parent-pairing-sign-in-again')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pairing-code-digits')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('parent-pairing-sign-in-again')),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-003');
    expect(
      router.state.uri.queryParameters['resume'],
      '/scr-fat-004?childId=$_childId&source=server',
    );
  });
}
