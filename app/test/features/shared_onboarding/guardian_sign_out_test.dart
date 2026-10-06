import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/features/sys3_identity/sys3_identity_screens.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';

import 'onboarding_test_host.dart';

void main() {
  testWidgets(
    'A5: guardian logout ends the provider session and returns to welcome',
    (tester) async {
      final host = OnboardingHost(identity: FakeIdentity());
      addTearDown(host.dispose);
      await host.runtime.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );
      expect(host.runtime.phase, FoundationGatePhase.noChildren);

      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(host: host, router: router));
      await tester.pumpAndSettle();

      expect(find.byKey(Sys3Keys.logout), findsOneWidget);
      expect(find.byKey(Sys3Keys.mockBanner), findsNothing);

      await tester.tap(find.byKey(const Key('sys3_logout_action')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/scr-shr-001');
      expect(find.byKey(const Key('signed_out_welcome')), findsOneWidget);
      expect(host.identity.signOutCalls, 1);
      expect(host.runtime.phase, FoundationGatePhase.signedOut);
      expect(
        host.runtime.identityValue.authority,
        IdentityAuthority.unavailable,
      );
      expect(host.runtime.rosterValue.children, isEmpty);
      expect(host.runtime.deviceValue.children, isEmpty);
    },
  );

  testWidgets(
    'A5: failed provider logout keeps the session, explains it, and retries',
    (tester) async {
      final host = OnboardingHost(identity: FakeIdentity());
      addTearDown(host.dispose);
      await host.runtime.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );
      host.identity.signOutFailure = StateError('synthetic failure');

      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(host: host, router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sys3_logout_action')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/sys3-logout');
      expect(find.byKey(Sys3Keys.error), findsOneWidget);
      expect(find.textContaining('بقيت جلستك الحالية مفتوحة'), findsOneWidget);
      expect(host.runtime.phase, FoundationGatePhase.noChildren);
      expect(host.runtime.identityValue.isRemoteAuthoritative, isTrue);

      host.identity.signOutFailure = null;
      await tester.tap(find.byKey(const Key('sys3_logout_retry')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/scr-shr-001');
      expect(host.identity.signOutCalls, 2);
    },
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/sys3-logout',
  routes: [
    GoRoute(
      path: '/sys3-logout',
      builder: (_, __) => const LogoutConfirmScreen(),
    ),
    GoRoute(
      path: '/scr-shr-001',
      builder: (_, __) => const Scaffold(
        body: SizedBox(key: Key('signed_out_welcome')),
      ),
    ),
  ],
);

Widget _app({required OnboardingHost host, required GoRouter router}) {
  return AppScope(
    runtime: host.appRuntime,
    child: MaterialApp.router(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}
