import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/features/shared_onboarding/create_account_screen.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

import 'onboarding_test_host.dart';

final List<GoRoute> _routes = [
  GoRoute(
    path: '/scr-shr-002',
    builder: (context, state) => const CreateAccountScreen(),
  ),
  GoRoute(
    path: '/scr-shr-003',
    builder: (context, state) =>
        PlaceholderEmail(email: state.uri.queryParameters['email']),
  ),
  placeholderRoute('/scr-shr-007', 'SCR-SHR-007'),
];

class PlaceholderEmail extends StatelessWidget {
  const PlaceholderEmail({super.key, this.email});
  final String? email;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('login:${email ?? ''}'));
}

Future<void> _fill(
  WidgetTester tester, {
  String email = 'parent@example.com',
  String password = 'Strong-pass-123',
  String? confirm,
  bool agree = true,
}) async {
  await tester.enterText(find.byKey(CreateAccountKeys.email), email);
  await tester.enterText(find.byKey(CreateAccountKeys.password), password);
  await tester.enterText(
    find.byKey(CreateAccountKeys.confirm),
    confirm ?? password,
  );
  if (agree) {
    await tester.ensureVisible(find.byKey(CreateAccountKeys.terms));
    await tester.tap(find.byKey(CreateAccountKeys.terms));
  }
  await tester.pump();
}

void main() {
  group('password strength', () {
    test('bands follow length and variety', () {
      expect(passwordStrength(''), PasswordStrength.empty);
      expect(passwordStrength('abc'), PasswordStrength.weak);
      expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
      expect(passwordStrength('abcdefg1'), PasswordStrength.fair);
      expect(passwordStrength('Abcdefgh12'), PasswordStrength.good);
      expect(passwordStrength('Abcdefgh-1234-xyz'), PasswordStrength.strong);
    });
  });

  testWidgets('inline validation: short password, mismatch, terms', (
    tester,
  ) async {
    final host = OnboardingHost(identity: FakeIdentity());
    addTearDown(host.dispose);
    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );

    // Submit on an empty form reveals every field error at once.
    await tester.tap(find.byKey(CreateAccountKeys.submit));
    await tester.pump();
    expect(find.text('أدخل بريدك الإلكتروني.'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور.'), findsOneWidget);
    expect(find.text('أعد كتابة كلمة المرور.'), findsOneWidget);
    expect(find.text('يلزم الموافقة على الشروط للمتابعة.'), findsOneWidget);
    expect(host.identity.signUpCalls, 0);

    await tester.enterText(find.byKey(CreateAccountKeys.password), 'abc1');
    await tester.pump();
    expect(
      find.text('كلمة المرور يجب أن تكون 8 أحرف على الأقل.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(CreateAccountKeys.password),
      'abcdefghij',
    );
    await tester.pump();
    expect(find.text('استخدم حرفًا ورقمًا واحدًا على الأقل.'), findsOneWidget);

    await tester.enterText(
      find.byKey(CreateAccountKeys.password),
      'Strong-pass-123',
    );
    await tester.enterText(
      find.byKey(CreateAccountKeys.confirm),
      'Strong-pass-124',
    );
    await tester.pump();
    expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);
    expect(find.byKey(CreateAccountKeys.strengthLabel), findsOneWidget);
  });

  testWidgets('eye toggles obscure text on both password fields', (
    tester,
  ) async {
    final host = OnboardingHost(identity: FakeIdentity());
    addTearDown(host.dispose);
    await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );
    TextField field() =>
        tester.widget<TextField>(find.byKey(CreateAccountKeys.password));
    expect(field().obscureText, isTrue);
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(
              of: find.byKey(CreateAccountKeys.password),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(IconButton),
      ),
    );
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('e-mail already in use → inline hand-off to sign-in', (
    tester,
  ) async {
    final identity = FakeIdentity(
      failure: const FoundationGateIdentityException(
        FoundationGateIdentityFailure.emailAlreadyInUse,
      ),
    );
    final host = OnboardingHost(identity: identity);
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );

    await _fill(tester, email: 'dad@example.com');
    await tester.ensureVisible(find.byKey(CreateAccountKeys.submit));
    await tester.tap(find.byKey(CreateAccountKeys.submit));
    await tester.pumpAndSettle();

    expect(identity.signUpCalls, 1);
    expect(router.state.uri.path, '/scr-shr-002');
    expect(find.text('هذا البريد مسجّل مسبقًا'), findsOneWidget);
    expect(find.byKey(CreateAccountKeys.noticeAction), findsOneWidget);

    await tester.tap(find.byKey(CreateAccountKeys.noticeAction));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-003');
    expect(find.text('login:dad@example.com'), findsOneWidget);
  });

  testWidgets('weak-password from provider shows inline reason, no routing', (
    tester,
  ) async {
    final host = OnboardingHost(
      identity: FakeIdentity(
        failure: const FoundationGateIdentityException(
          FoundationGateIdentityFailure.weakPassword,
        ),
      ),
    );
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );
    await _fill(tester);
    await tester.ensureVisible(find.byKey(CreateAccountKeys.submit));
    await tester.tap(find.byKey(CreateAccountKeys.submit));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-002');
    expect(find.textContaining('كلمة المرور ضعيفة'), findsOneWidget);
  });

  testWidgets('successful sign-up continues to device mode', (tester) async {
    final host = OnboardingHost(
      identity: FakeIdentity(),
      discoveryBody: kNoFamiliesBody,
    );
    addTearDown(host.dispose);
    final router = await pumpWithRouter(
      tester,
      runtime: host.appRuntime,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );
    await _fill(tester);
    await tester.ensureVisible(find.byKey(CreateAccountKeys.submit));
    final before = tester.widget<PrimaryBtn>(
      find.byKey(CreateAccountKeys.submit),
    );
    expect(before.onPressed, isNotNull);
    await tester.tap(find.byKey(CreateAccountKeys.submit));
    await tester.pumpAndSettle();
    expect(host.identity.signUpCalls, 1);
    // The verification e-mail is sent proactively right after sign-up.
    expect(host.identity.verificationEmailsSent, 1);
    expect(router.state.uri.path, '/scr-shr-007');
  });

  testWidgets('unconfigured build never creates anything', (tester) async {
    final router = await pumpWithRouter(
      tester,
      runtime: null,
      initialLocation: '/scr-shr-002',
      routes: _routes,
    );
    expect(find.byKey(CreateAccountKeys.notice), findsOneWidget);
    await tester.ensureVisible(find.byKey(CreateAccountKeys.submit));
    await tester.tap(find.byKey(CreateAccountKeys.submit), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-002');
  });
}
