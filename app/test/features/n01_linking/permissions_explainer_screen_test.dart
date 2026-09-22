import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/permissions_explainer_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('renders 3 permission titles + banner', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('لماذا هذه الأذونات؟'), findsOneWidget);
    expect(find.text('٣ من ٣'), findsOneWidget);
    expect(find.text('الموقع «طوال الوقت»'), findsOneWidget);
    expect(find.text('خدمة إمكانية الوصول'), findsOneWidget);
    expect(find.text('استثناء البطارية'), findsOneWidget);
    expect(find.byKey(const Key('permissions_explainer_banner')), findsOneWidget);
    expect(
      find.textContaining('إن رُفض أي إذن لن تُقفل أي شاشة'),
      findsOneWidget,
    );
    expect(find.textContaining('القاعدة ٣'), findsOneWidget);
  });

  testWidgets('video tap → toast', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const Key('permissions_explainer_video')));
    await tester.pump();

    expect(find.textContaining('الفيديو قريبًا'), findsOneWidget);

    await _settleTimers(tester);
  });

  testWidgets('primary → /scr-fat-006', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-005',
      routes: [
        GoRoute(
          path: '/scr-fat-005',
          builder: (context, state) => const PermissionsExplainerScreen(),
        ),
        GoRoute(
          path: '/scr-fat-006',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-006',
            title: 'نجاح الربط',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

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

    await tester.tap(find.byKey(const Key('permissions_explainer_continue')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-006');
    expect(find.text('SCR-FAT-006'), findsWidgets);
  });

  testWidgets('Rule 23 — no خالد in screen UI', (tester) async {
    await _pumpScreen(tester);

    expect(find.textContaining('خالد'), findsNothing);

    await _settleTimers(tester);
  });

  test('Rule 23 — no خالد in screen source or new ARB keys', () {
    final screen = File(
      'lib/features/n01_linking/permissions_explainer_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('خالد'), isFalse);

    final arArb = File('lib/core/i18n/app_ar.arb').readAsStringSync();
    final enArb = File('lib/core/i18n/app_en.arb').readAsStringSync();
    final arKeys = _permissionsExplainerValues(arArb);
    final enKeys = _permissionsExplainerValues(enArb);
    expect(arKeys, isNotEmpty);
    expect(enKeys, isNotEmpty);
    for (final value in [...arKeys, ...enKeys]) {
      expect(value.contains('خالد'), isFalse, reason: value);
    }
  });
}

List<String> _permissionsExplainerValues(String arb) {
  final re = RegExp(
    r'"permissionsExplainer[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"',
  );
  return re.allMatches(arb).map((m) => m.group(1)!).toList();
}

Future<void> _settleTimers(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _pumpScreen(WidgetTester tester) async {
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
      home: const PermissionsExplainerScreen(),
    ),
  );
  await tester.pump();
}
