import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/link_success_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('celebration + map semantics + location card', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('تمّ الربط!'), findsOneWidget);
    expect(find.text('١ من ٣ أبناء'), findsOneWidget);
    expect(find.text('🎉'), findsOneWidget);
    // Legacy path (no IdentityRuntime enrollment): honest prototype, not managed success.
    expect(
      find.byKey(const Key('link_success_legacy_honesty')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('link_success_legacy_hero')), findsOneWidget);
    expect(find.text('جهاز ابنك متصل الآن'), findsNothing);
    expect(find.textContaining('أول ثمرة'), findsOneWidget);
    expect(find.byKey(const Key('link_success_mini_map')), findsOneWidget);
    expect(find.bySemanticsLabel('معاينة الموقع الحالي'), findsOneWidget);
    expect(find.textContaining('ثانوية النور'), findsOneWidget);
    expect(find.textContaining('البطارية ٨٤٪'), findsOneWidget);
  });

  testWidgets('apply template → banner; undo clears', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.byKey(const Key('link_success_template_applied')),
      findsNothing,
    );

    await _tapKey(tester, const Key('link_success_apply_template'));

    expect(
      find.byKey(const Key('link_success_template_applied')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('link_success_legacy_honesty')),
      findsOneWidget,
    );
    expect(find.textContaining('ضُبط على قالب'), findsOneWidget);

    await _tapKey(tester, const Key('link_success_template_undo'));

    expect(
      find.byKey(const Key('link_success_template_applied')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('link_success_apply_template')),
      findsOneWidget,
    );

    await _settleTimers(tester);
  });

  testWidgets('manual ghost → toast only', (tester) async {
    await _pumpScreen(tester);

    await _tapKey(tester, const Key('link_success_manual'));

    expect(find.textContaining('تمام — تضبط كل أداة'), findsOneWidget);
    expect(
      find.byKey(const Key('link_success_apply_template')),
      findsOneWidget,
    );

    await _settleTimers(tester);
  });

  testWidgets('add-next → /scr-fat-003', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-006',
      routes: [
        GoRoute(
          path: '/scr-fat-006',
          builder: (context, state) => const LinkSuccessScreen(),
        ),
        GoRoute(
          path: '/scr-fat-003',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-003',
            title: 'إضافة ابن',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    expect(find.byType(LinkSuccessScreen), findsOneWidget);

    await _tapKey(tester, const Key('link_success_add_next'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-003');
    expect(find.text('SCR-FAT-003'), findsWidgets);

    await _settleTimers(tester);
  });

  testWidgets('day-board mint CTA → /scr-fat-010', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-006',
      routes: [
        GoRoute(
          path: '/scr-fat-006',
          builder: (context, state) => const LinkSuccessScreen(),
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
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    expect(find.byType(LinkSuccessScreen), findsOneWidget);

    await _tapKey(tester, const Key('link_success_day_board'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-010');
    expect(find.text('SCR-FAT-010'), findsWidgets);
  });

  testWidgets('Rule 23 — no خالد in screen UI', (tester) async {
    await _pumpScreen(tester);

    expect(find.textContaining('خالد'), findsNothing);

    await _settleTimers(tester);
  });

  test('Rule 23 — no خالد in screen source or new ARB keys', () {
    final screen = File(
      'lib/features/n01_linking/link_success_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('خالد'), isFalse);

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final arKeys = _linkSuccessValues(arArb);
    final enKeys = _linkSuccessValues(enArb);
    expect(arKeys, isNotEmpty);
    expect(enKeys, isNotEmpty);
    for (final value in [...arKeys, ...enKeys]) {
      expect(value.contains('خالد'), isFalse, reason: value);
    }
  });
}

List<String> _linkSuccessValues(String arb) {
  final re = RegExp(r'"linkSuccess[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"');
  return re.allMatches(arb).map((m) => m.group(1)!).toList();
}

Future<void> _settleTimers(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
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
      home: const LinkSuccessScreen(),
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
