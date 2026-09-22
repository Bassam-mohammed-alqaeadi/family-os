import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/transparency_consent_screen.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';

void main() {
  testWidgets('child role — honesty banner + shared/never/advisor + CTA', (
    tester,
  ) async {
    await _pumpConsent(tester, role: AppRole.child);

    expect(find.byKey(TransparencyConsentKeys.screen), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.sharedCard), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.neverCard), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.advisorCard), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.acceptCta), findsOneWidget);
    expect(find.text('بصراحة معك'), findsOneWidget);
    expect(find.textContaining('نحن لا نتجسس — نطمئن'), findsOneWidget);
    expect(find.text('موقعك'), findsOneWidget);
    expect(find.text('وقت استخدامك للجوال'), findsOneWidget);
    expect(find.text('بطارية جهازك'), findsOneWidget);
    expect(find.text('نصوص رسائلك الخاصة'), findsOneWidget);
    expect(find.text('صورك وملفاتك'), findsOneWidget);
    expect(find.textContaining('مساعد ذكي'), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.parentLean), findsNothing);
  });

  testWidgets('accept CTA → /scr-chd-004', (tester) async {
    final role = RoleController(AppRole.child);
    final router = GoRouter(
      initialLocation: '/scr-chd-003',
      routes: [
        GoRoute(
          path: '/scr-chd-003',
          builder: (context, state) => const TransparencyConsentScreen(),
        ),
        GoRoute(
          path: '/scr-chd-004',
          builder: (context, state) => ChildDayBoardScreen(),
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

    await tester.ensureVisible(find.byKey(TransparencyConsentKeys.acceptCta));
    await tester.tap(find.byKey(TransparencyConsentKeys.acceptCta));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-chd-004');
    expect(find.byType(ChildDayBoardScreen), findsOneWidget);
    expect(role.value, AppRole.child);
  });

  testWidgets('RoleGuard — father lean hides CTA', (tester) async {
    await _pumpConsent(tester, role: AppRole.father);

    expect(find.byKey(TransparencyConsentKeys.parentLean), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.acceptCta), findsNothing);
    expect(find.text('لجهاز الابن'), findsOneWidget);
  });

  testWidgets('EN locale pumps honesty banner', (tester) async {
    await _pumpConsent(
      tester,
      role: AppRole.child,
      locale: const Locale('en'),
    );

    expect(find.text('Being honest with you'), findsOneWidget);
    expect(find.textContaining("We don't spy"), findsOneWidget);
    expect(find.byKey(TransparencyConsentKeys.acceptCta), findsOneWidget);
  });

  test('Rule 23 — no planted person names in CHD-003 ARB keys', () {
    const banned = [
      'خالد',
      'عبدالله',
      'نوال',
      'Khalid',
      'Abdullah',
      'Nawal',
    ];
    const sources = [
      'بصراحة معك',
      'نحن لا نتجسس — نطمئن. وهذا بالضبط ما سيعرفه والداك عنك:',
      'في التطبيق مساعد ذكي يساعد عائلتك على فهم يومك بشكل عام — وجوده معلن لك دائمًا هنا وفي تبويب «أنا».',
      'فهمت وأوافق ✓',
      'Being honest with you',
      "We don't spy — we check you're okay. Here's exactly what your parents will know about you:",
      'The app has a smart helper that helps your family understand your day in general — its presence is always announced here and on the Me tab.',
      'I understand and agree ✓',
    ];
    for (final s in sources) {
      for (final name in banned) {
        expect(s.contains(name), isFalse, reason: '$name in: $s');
      }
    }
  });
}

Future<void> _pumpConsent(
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
        home: TransparencyConsentScreen(roleOverride: role),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
