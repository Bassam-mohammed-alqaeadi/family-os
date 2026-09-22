import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/child_qr_scan_screen.dart';
import 'package:family_os/features/n01_linking/child_welcome_screen.dart';
import 'package:family_os/features/n01_linking/camera_permission_seam.dart';

void main() {
  testWidgets('child role — hero + CTA; no surveillance wording', (
    tester,
  ) async {
    await _pumpWelcome(tester, role: AppRole.child);

    expect(find.byKey(ChildWelcomeKeys.screen), findsOneWidget);
    expect(find.byKey(ChildWelcomeKeys.hero), findsOneWidget);
    expect(find.byKey(ChildWelcomeKeys.continueCta), findsOneWidget);
    expect(find.text('أهلًا بك يا بطل!'), findsOneWidget);
    expect(find.textContaining('هذا الجهاز سيرتبط بعائلتك'), findsOneWidget);
    expect(find.textContaining('مراقبة'), findsNothing);
    expect(find.textContaining('تجسس'), findsNothing);
    expect(find.byKey(ChildWelcomeKeys.parentLean), findsNothing);
  });

  testWidgets('CTA → /scr-chd-002', (tester) async {
    final role = RoleController(AppRole.child);
    final router = GoRouter(
      initialLocation: '/scr-chd-001',
      routes: [
        GoRoute(
          path: '/scr-chd-001',
          builder: (context, state) => const ChildWelcomeScreen(),
        ),
        GoRoute(
          path: '/scr-chd-002',
          builder: (context, state) => ChildQrScanScreen(
            permissionSeam: FakeCameraPermissionSeam(
              status: CameraPermissionStatus.granted,
            ),
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

    await tester.tap(find.byKey(ChildWelcomeKeys.continueCta));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-chd-002');
    expect(find.byType(ChildQrScanScreen), findsOneWidget);
    expect(role.value, AppRole.child);
  });

  testWidgets('RoleGuard — father lean hides CTA', (tester) async {
    await _pumpWelcome(tester, role: AppRole.father);

    expect(find.byKey(ChildWelcomeKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildWelcomeKeys.continueCta), findsNothing);
    expect(find.text('لجهاز الابن'), findsOneWidget);
  });

  testWidgets('EN locale pumps headline', (tester) async {
    await _pumpWelcome(tester, role: AppRole.child, locale: const Locale('en'));

    expect(find.text('Welcome, champ!'), findsOneWidget);
    expect(find.byKey(ChildWelcomeKeys.continueCta), findsOneWidget);
  });

  test('Rule 23 — no planted person names in CHD-001 ARB keys', () {
    const banned = [
      'خالد',
      'عبدالله',
      'نوال',
      'Khalid',
      'Abdullah',
      'Nawal',
    ];
    const sources = [
      'أهلًا بك يا بطل!',
      'هذا الجهاز سيرتبط بعائلتك — عشان يطمئنون عليك، وتلعب وتتعلم وتكسب دقائق لعب ⏱',
      'يلّا نبدأ 🚀',
      'Welcome, champ!',
      "This device will link to your family — so they know you're okay, and you can play, learn, and earn play minutes ⏱",
      "Let's go 🚀",
    ];
    for (final s in sources) {
      for (final name in banned) {
        expect(s.contains(name), isFalse, reason: '$name in: $s');
      }
    }
  });
}

Future<void> _pumpWelcome(
  WidgetTester tester, {
  required AppRole role,
  Locale locale = const Locale('ar'),
}) async {
  final controller = RoleController(role);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    CurrentRole(
      notifier: controller,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChildWelcomeScreen(roleOverride: role),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
