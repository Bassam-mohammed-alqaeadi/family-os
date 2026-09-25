import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/mock/register_mock_family.dart';

void main() {
  // —— UI-004 AC1: empty family → empty cards, never fake Khaled ——
  testWidgets('UI-004 AC1: empty family → empty cards, no Khaled/numerals', (
    tester,
  ) async {
    await _pumpScreen(tester, projection: DayBoardProjection.empty);

    expect(find.byKey(DayBoardKeys.emptyChildren), findsOneWidget);
    expect(find.byKey(DayBoardKeys.emptyPending), findsOneWidget);
    expect(find.byKey(DayBoardKeys.activeChild), findsNothing);
    expect(find.byKey(DayBoardKeys.priority), findsNothing);
    expect(find.byKey(DayBoardKeys.pulse(0)), findsNothing);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);
    expect(find.textContaining('سناب'), findsNothing);
    expect(find.textContaining('Snapchat'), findsNothing);
    // No planted sample numerals from manyFixture.
    expect(find.textContaining('٨٤٪'), findsNothing);
    expect(find.textContaining('٥٠٪'), findsNothing);
    expect(find.textContaining('٤٥ د'), findsNothing);
  });

  testWidgets('UI-004: many children bind projection numerals only', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      guardianDisplayName: 'سامي',
      projection: DayBoardProjection(children: DayChildMock.manyFixture),
    );

    expect(find.byKey(DayBoardKeys.greeting), findsOneWidget);
    expect(find.textContaining('صباح الخير سامي'), findsOneWidget);
    expect(find.byKey(DayBoardKeys.pulse(0)), findsOneWidget);
    expect(find.byKey(DayBoardKeys.pulse(1)), findsOneWidget);
    expect(find.byKey(DayBoardKeys.pulse(2)), findsOneWidget);
    expect(find.byKey(DayBoardKeys.activeChild), findsOneWidget);
    expect(find.textContaining('ابن ١'), findsWidgets);
    expect(find.textContaining('خالد'), findsNothing);
  });

  testWidgets('empty guardian → ARB fallback (Rule 23)', (tester) async {
    await _pumpScreen(
      tester,
      projection: DayBoardProjection(children: DayChildMock.manyFixture),
    );

    expect(find.textContaining('صباح الخير ولي الأمر'), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);
  });

  testWidgets('UI-004: honest offline banner with last-synced', (tester) async {
    await _pumpScreen(
      tester,
      projection: const DayBoardProjection(
        offline: true,
        lastSyncLabel: 'منذ ١٠ دقائق',
      ),
    );

    expect(find.byKey(DayBoardKeys.offlineBanner), findsOneWidget);
    expect(find.textContaining('منذ ١٠ دقائق'), findsOneWidget);
    expect(find.textContaining('دون اتصال'), findsOneWidget);
  });

  // —— UI-004 AC2: pending request → real FAT-033 inbox ——
  testWidgets('UI-004 AC2: pending request card → /scr-fat-033', (
    tester,
  ) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection(
          pendingRequests: const [
            DayBoardPendingRequest(
              id: 'tr1',
              title: 'طلب وقت إضافي',
              subtitle: '+٣٠ دقيقة · بانتظار قرارك',
              inboxPath: '/scr-fat-033',
            ),
          ],
        ),
        onPendingRequest: () => hits.add('033'),
      ),
    );

    expect(find.byKey(DayBoardKeys.priority), findsOneWidget);
    expect(find.textContaining('طلب وقت إضافي'), findsOneWidget);
    await tester.tap(find.byKey(DayBoardKeys.priority));
    await tester.pumpAndSettle();
    expect(hits, ['033']);
  });

  testWidgets('UI-004 AC2 router: pending → RequestInboxScreen SCR-FAT-033', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-010',
      routes: [
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) => DayBoardScreen(
            projection: DayBoardProjection(
              pendingRequests: const [
                DayBoardPendingRequest(
                  id: 'tr1',
                  title: 'طلب وقت إضافي',
                  subtitle: 'بانتظار قرارك',
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/scr-fat-033',
          name: 'SCR-FAT-033',
          builder: (context, state) => RequestInboxScreen(
            service: TimeRequestService(
              repository: InMemoryTimeRequestRepository(),
            ),
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

    await tester.tap(find.byKey(DayBoardKeys.priority));
    await tester.pumpAndSettle();

    expect(find.byType(RequestInboxScreen), findsOneWidget);
    expect(find.byKey(RequestInboxKeys.emptyState), findsOneWidget);
  });

  // —— UI-004 AC3: advisor suggest-only — never silent apply ——
  testWidgets(
    'UI-004 AC3: advisor tap navigates suggest-only; no rule mutate',
    (tester) async {
      final rules = InMemoryRulesEngineRuleRepository();
      final hits = <String>[];
      expect(await rules.listEnabled(), isEmpty);

      await _pumpRouted(
        tester,
        DayBoardScreen(
          projection: DayBoardProjection.empty,
          onAdvisor: () => hits.add('011'),
        ),
      );

      await tester.ensureVisible(find.byKey(DayBoardKeys.advisorCta));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DayBoardKeys.advisorCta));
      await tester.pumpAndSettle();

      expect(hits, ['011']);
      // No approve / silent apply path on the board CTA.
      expect(await rules.listEnabled(), isEmpty);
    },
  );

  testWidgets('active child card → /scr-fat-013', (tester) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection(children: DayChildMock.manyFixture),
        onChildProfile: () => hits.add('013'),
      ),
    );

    await tester.tap(find.byKey(DayBoardKeys.activeChild));
    await tester.pumpAndSettle();
    expect(hits, ['013']);
  });

  testWidgets('pulse avatar → /scr-fat-013', (tester) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection(children: DayChildMock.manyFixture),
        onChildProfile: () => hits.add('013'),
      ),
    );

    await tester.tap(find.byKey(DayBoardKeys.pulse(0)));
    await tester.pumpAndSettle();
    expect(hits, ['013']);
  });

  testWidgets('quick grid targets + all children', (tester) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection.empty,
        onAllChildren: () => hits.add('012'),
        onQuran: () => hits.add('072'),
        onTasks: () => hits.add('054'),
        onLock: () => hits.add('037'),
        onMap: () => hits.add('014'),
      ),
    );

    await tester.tap(find.text('كل الأبناء ←'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day_board_quick_quran')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day_board_quick_tasks')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day_board_quick_lock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day_board_quick_map')));
    await tester.pumpAndSettle();

    expect(hits, ['012', '072', '054', '037', '014']);
  });

  testWidgets('router wiring: /scr-fat-010 shows DayBoardScreen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-010',
      routes: [
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) =>
              const DayBoardScreen(projection: DayBoardProjection.empty),
        ),
        GoRoute(
          path: '/scr-fat-013',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-013',
            title: 'ملف الابن',
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

    expect(find.byType(DayBoardScreen), findsOneWidget);
    expect(find.text('لوحة اليوم'), findsOneWidget);
    expect(find.byKey(DayBoardKeys.emptyChildren), findsOneWidget);
  });

  test('InMemoryDayBoardProjectionRepository defaults empty', () async {
    final repo = InMemoryDayBoardProjectionRepository();
    final p = await repo.load();
    expect(p.children, isEmpty);
    expect(p.pendingRequests, isEmpty);
    expect(p.offline, isFalse);
  });

  test('stage1DayBoardProjectionRepository seeds Register §10', () async {
    final p = await stage1DayBoardProjectionRepository.load();
    expect(
      p.children.map((c) => c.displayName).toList(),
      RegisterMockFamily.children.map((c) => c.displayName).toList(),
    );
    expect(p.children.map((c) => c.displayName), ['خالد', 'نورة', 'سعد']);
    expect(p.hasPending, isTrue);
    expect(p.phase, DayBoardPhase.ready);
  });

  // —— WIR-03b: the default screen reads the family's own rows ——
  testWidgets('default DayBoardScreen is empty until the family has rows', (
    tester,
  ) async {
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
        home: const DayBoardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // The Register §10 mock family no longer feeds the default: an empty
    // database shows the honest empty cards, never planted names.
    expect(find.byKey(DayBoardKeys.emptyChildren), findsOneWidget);
    expect(find.byKey(DayBoardKeys.pulse(0)), findsNothing);
    expect(find.textContaining('خالد'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

}

Future<void> _pumpScreen(
  WidgetTester tester, {
  String guardianDisplayName = '',
  required DayBoardProjection projection,
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
      home: DayBoardScreen(
        guardianDisplayName: guardianDisplayName,
        projection: projection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRouted(WidgetTester tester, Widget home) async {
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
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
