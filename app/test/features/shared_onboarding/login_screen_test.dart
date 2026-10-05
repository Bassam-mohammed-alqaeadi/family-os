import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

import 'onboarding_test_host.dart';

List<GoRoute> _routes({String? initialEmail}) => [
  GoRoute(
    path: '/scr-shr-003',
    builder: (context, state) => LoginScreen(
      initialEmail: initialEmail ?? state.uri.queryParameters['email'],
    ),
  ),
  placeholderRoute('/scr-fat-012', 'SCR-FAT-012'),
  placeholderRoute('/scr-shr-007', 'SCR-SHR-007'),
  placeholderRoute('/scr-shr-002', 'SCR-SHR-002'),
];

void main() {
  testWidgets('unconfigured build: honest notice, submit disabled, no mock', (
    tester,
  ) async {
    final router = await pumpWithRouter(
      tester,
      runtime: null,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );

    expect(find.byKey(LoginKeys.notice), findsOneWidget);
    expect(find.textContaining('FAMILY_OS_API_ORIGIN'), findsOneWidget);

    await tester.tap(find.byKey(LoginKeys.submit), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-003');
    expect(find.byType(PlaceholderScreen), findsNothing);
  });

  testWidgets('empty submit shows inline errors under both fields', (
    tester,
  ) async {
    final host = OnboardingHost(identity: FakeIdentity());
    addTearDown(host.dispose);
    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );

    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(find.text('أدخل بريدك الإلكتروني.'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور.'), findsOneWidget);
    expect(host.identity.signInCalls, 0);

    await tester.enterText(find.byKey(LoginKeys.email), 'not-an-email');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();
    expect(find.textContaining('صيغة البريد غير صحيحة'), findsOneWidget);
    expect(host.identity.signInCalls, 0);
  });

  testWidgets('wrong password: persistent error notice with reset shortcut', (
    tester,
  ) async {
    final identity = FakeIdentity(
      failure: const FoundationGateIdentityException(
        FoundationGateIdentityFailure.invalidCredentials,
      ),
    );
    final host = OnboardingHost(identity: identity);
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );

    await tester.enterText(find.byKey(LoginKeys.email), 'parent@example.com');
    await tester.enterText(find.byKey(LoginKeys.password), 'wrong-pass');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(identity.signInCalls, 1);
    expect(router.state.uri.path, '/scr-shr-003');
    expect(find.byKey(LoginKeys.notice), findsOneWidget);
    expect(
      find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة.'),
      findsOneWidget,
    );
    expect(find.byKey(LoginKeys.noticeAction), findsOneWidget);

    // The shortcut opens the real reset sheet with the e-mail pre-filled.
    identity.failure = null;
    await tester.tap(find.byKey(LoginKeys.noticeAction));
    await tester.pumpAndSettle();
    expect(find.byKey(LoginKeys.resetSheet), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(LoginKeys.resetEmail))
          .controller!
          .text,
      'parent@example.com',
    );
  });

  testWidgets('existing family → children list; no family → device mode', (
    tester,
  ) async {
    final withFamily = OnboardingHost(identity: FakeIdentity());
    addTearDown(withFamily.dispose);
    var router = await pumpWithRouter(
      tester,
      runtime: withFamily.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(LoginKeys.email), 'parent@example.com');
    await tester.enterText(find.byKey(LoginKeys.password), 'secret-123');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-012');

    final noFamily = OnboardingHost(
      identity: FakeIdentity(),
      discoveryBody: kNoFamiliesBody,
    );
    addTearDown(noFamily.dispose);
    router = await pumpWithRouter(
      tester,
      runtime: noFamily.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(LoginKeys.email), 'parent@example.com');
    await tester.enterText(find.byKey(LoginKeys.password), 'secret-123');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-007');
  });

  testWidgets('signed in but discovery down: warning with real retry', (
    tester,
  ) async {
    final host = OnboardingHost(
      identity: FakeIdentity(),
      discoveryStatus: 503,
      discoveryBody: '{}',
    );
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(LoginKeys.email), 'parent@example.com');
    await tester.enterText(find.byKey(LoginKeys.password), 'secret-123');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-shr-003');
    expect(find.textContaining('تعذر الوصول إلى خادم العائلة'), findsOneWidget);
    expect(find.byKey(LoginKeys.noticeAction), findsOneWidget);

    host.discovery.response = const FoundationGateHttpResponse(
      statusCode: 200,
      body: kFamiliesBody,
    );
    await tester.tap(find.byKey(LoginKeys.noticeAction));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-012');
  });

  testWidgets('forgot password sends a real reset e-mail and confirms', (
    tester,
  ) async {
    final host = OnboardingHost(identity: FakeIdentity());
    addTearDown(host.dispose);
    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(),
    );

    await tester.tap(find.byKey(LoginKeys.forgot));
    await tester.pumpAndSettle();
    expect(find.byKey(LoginKeys.resetSheet), findsOneWidget);

    // Validation inside the sheet.
    await tester.tap(find.byKey(LoginKeys.resetSend));
    await tester.pump();
    expect(find.text('أدخل بريدك الإلكتروني.'), findsOneWidget);
    expect(host.identity.passwordResetEmails, isEmpty);

    await tester.enterText(
      find.byKey(LoginKeys.resetEmail),
      ' Parent@Example.com ',
    );
    await tester.tap(find.byKey(LoginKeys.resetSend));
    await tester.pumpAndSettle();

    expect(host.identity.passwordResetEmails, ['Parent@Example.com']);
    expect(find.text('تحقق من بريدك'), findsOneWidget);
    expect(find.byKey(LoginKeys.resetDone), findsOneWidget);

    await tester.tap(find.byKey(LoginKeys.resetDone));
    await tester.pumpAndSettle();
    expect(find.byKey(LoginKeys.resetSheet), findsNothing);
  });

  testWidgets('reset failure stays in the sheet with a reason', (tester) async {
    final identity = FakeIdentity();
    final host = OnboardingHost(identity: identity);
    addTearDown(host.dispose);
    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003',
      routes: _routes(initialEmail: 'parent@example.com'),
    );

    await tester.tap(find.byKey(LoginKeys.forgot));
    await tester.pumpAndSettle();
    identity.failure = const FoundationGateIdentityException(
      FoundationGateIdentityFailure.tooManyAttempts,
    );
    await tester.tap(find.byKey(LoginKeys.resetSend));
    await tester.pumpAndSettle();

    expect(find.byKey(LoginKeys.resetSheet), findsOneWidget);
    expect(find.textContaining('محاولات كثيرة'), findsOneWidget);
    expect(find.byKey(LoginKeys.resetDone), findsNothing);
  });

  testWidgets('initial e-mail is pre-filled; create-account link routes', (
    tester,
  ) async {
    final host = OnboardingHost(identity: FakeIdentity());
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-003?email=someone%40example.com',
      routes: _routes(),
    );
    expect(
      tester.widget<TextField>(find.byKey(LoginKeys.email)).controller!.text,
      'someone@example.com',
    );

    await tester.ensureVisible(find.byKey(LoginKeys.createAccount));
    await tester.tap(find.byKey(LoginKeys.createAccount));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-002');
  });
}
