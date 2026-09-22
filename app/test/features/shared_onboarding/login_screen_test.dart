import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/login_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('forgot password shows anti-enumeration toast', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login_forgot')));
    await tester.pump();

    expect(
      find.text('أرسلنا رابط الاستعادة إن كان البريد مسجّلًا لدينا'),
      findsOneWidget,
    );
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('login navigates to /scr-fat-010', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-003',
      routes: [
        GoRoute(
          path: '/scr-shr-003',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-010',
            title: 'لوحة اليوم',
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

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-010');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-FAT-010'), findsWidgets);
  });

  testWidgets('invite link navigates to /scr-fat-009', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-003',
      routes: [
        GoRoute(
          path: '/scr-shr-003',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/scr-fat-009',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-009',
            title: 'قبول دعوة الأم',
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

    await tester.ensureVisible(find.byKey(const Key('login_invite_link')));
    await tester.tap(find.byKey(const Key('login_invite_link')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-009');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-FAT-009'), findsWidgets);
  });
}

Future<void> _pumpLogin(WidgetTester tester) async {
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
      home: const LoginScreen(),
    ),
  );
  await tester.pumpAndSettle();
}
