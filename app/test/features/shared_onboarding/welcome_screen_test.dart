import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/create_account_screen.dart';
import 'package:family_os/features/shared_onboarding/welcome_screen.dart';

void main() {
  testWidgets('welcome shows first slide and advances via dots', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    expect(find.text('عائلتي'), findsOneWidget);
    expect(find.textContaining('طمأنينة الوالد'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.text('لديّ حساب — تسجيل الدخول'), findsOneWidget);
    expect(
      find.text('بالمتابعة توافق على الشروط وسياسة الخصوصية'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('welcome_dots')));
    await tester.pumpAndSettle();

    expect(find.text('اطمئن بلمحة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome_dots')));
    await tester.pumpAndSettle();

    expect(find.text('يتعلمون ويحبونه'), findsOneWidget);
  });

  testWidgets('start CTA fires onStart / navigates toward SHR-002', (
    tester,
  ) async {
    var startTaps = 0;
    await _pumpWelcome(tester, onStart: () => startTaps++);

    await tester.tap(find.byKey(const Key('welcome_start')));
    await tester.pump();
    expect(startTaps, 1);
  });

  testWidgets('start CTA goes to /scr-shr-002 via GoRouter', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-001',
      routes: [
        GoRoute(
          path: '/scr-shr-001',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/scr-shr-002',
          builder: (context, state) => const CreateAccountScreen(),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('welcome_start')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-shr-002');
    expect(find.byType(CreateAccountScreen), findsOneWidget);
  });

  testWidgets('login CTA goes to /scr-shr-003 via GoRouter', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-001',
      routes: [
        GoRoute(
          path: '/scr-shr-001',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/scr-shr-003',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-SHR-003',
            title: 'تسجيل الدخول',
          ),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('welcome_login')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-shr-003');
  });
}

Future<void> _pumpWelcome(
  WidgetTester tester, {
  VoidCallback? onStart,
  VoidCallback? onLogin,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WelcomeScreen(onStart: onStart, onLogin: onLogin),
    ),
  );
  await tester.pumpAndSettle();
}
