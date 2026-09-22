import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/trial_mode_screen.dart';
import 'package:family_os/features/n02_day/location_map_screen.dart';
import 'package:family_os/features/n07_advisor/advisor_suggestions_screen.dart';

void main() {
  testWidgets('banner + demo child preview', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('وضع التجربة'), findsOneWidget);
    expect(find.text('بيانات تجريبية'), findsOneWidget);
    expect(find.byKey(const Key('trial_mode_banner')), findsOneWidget);
    expect(find.byType(BannerNote), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsWidgets);
    expect(find.textContaining('ابن افتراضي'), findsOneWidget);
    expect(find.byKey(const Key('trial_mode_preview_card')), findsOneWidget);
    expect(find.text('تجريبي — ١٢ سنة'), findsOneWidget);
    expect(find.textContaining('المدرسة الافتراضية'), findsOneWidget);
    expect(find.textContaining('٧٧٪'), findsOneWidget);
    expect(find.textContaining('٢ س ١٥ د'), findsOneWidget);
    expect(find.textContaining('١٨٠ دقيقة'), findsOneWidget);
  });

  testWidgets('map row → /scr-fat-014', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-007',
      routes: [
        GoRoute(
          path: '/scr-fat-007',
          builder: (context, state) => const TrialModeScreen(),
        ),
        GoRoute(
          path: '/scr-fat-014',
          builder: (context, state) => const LocationMapScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    expect(find.byType(TrialModeScreen), findsOneWidget);

    await _tapKey(tester, const Key('trial_mode_map_row'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-014');
    expect(find.byType(LocationMapScreen), findsOneWidget);
  });

  testWidgets('advisor row → /scr-fat-011', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-007',
      routes: [
        GoRoute(
          path: '/scr-fat-007',
          builder: (context, state) => const TrialModeScreen(),
        ),
        GoRoute(
          path: '/scr-fat-011',
          builder: (context, state) => AdvisorSuggestionsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    expect(find.byType(TrialModeScreen), findsOneWidget);

    await _tapKey(tester, const Key('trial_mode_advisor_row'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-011');
    expect(find.byType(AdvisorSuggestionsScreen), findsOneWidget);
  });

  testWidgets('link CTA → /scr-fat-004', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-007',
      routes: [
        GoRoute(
          path: '/scr-fat-007',
          builder: (context, state) => const TrialModeScreen(),
        ),
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-004',
            title: 'رمز الربط QR',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    expect(find.byType(TrialModeScreen), findsOneWidget);

    await _tapKey(tester, const Key('trial_mode_link_cta'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-004');
    expect(find.text('SCR-FAT-004'), findsWidgets);
  });

  testWidgets('Rule 23 — no خالد in screen UI', (tester) async {
    await _pumpScreen(tester);

    expect(find.textContaining('خالد'), findsNothing);
  });

  test('Rule 23 — no خالد in screen source or trialMode ARB keys', () {
    final screen = File(
      'lib/features/n01_linking/trial_mode_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('خالد'), isFalse);

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final arKeys = _trialModeValues(arArb);
    final enKeys = _trialModeValues(enArb);
    expect(arKeys, isNotEmpty);
    expect(enKeys, isNotEmpty);
    for (final value in [...arKeys, ...enKeys]) {
      expect(value.contains('خالد'), isFalse, reason: value);
    }
  });
}

List<String> _trialModeValues(String arb) {
  final re = RegExp(
    r'"trialMode[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"',
  );
  return re.allMatches(arb).map((m) => m.group(1)!).toList();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _setTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await _setTallSurface(tester);
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
      home: const TrialModeScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await _setTallSurface(tester);
  await tester.pumpWidget(
    MaterialApp.router(
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
  await tester.pumpAndSettle();
}
