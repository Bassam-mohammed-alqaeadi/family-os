import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/design/components/status_pulse_avatar.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/rules_engine_rule_repository.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';

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
    expect(find.textContaining('84٪'), findsNothing);
    expect(find.textContaining('50٪'), findsNothing);
    expect(find.textContaining('45 د'), findsNothing);
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
    expect(find.textContaining('ابن 1'), findsWidgets);
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
        lastSyncLabel: 'منذ 10 دقائق',
      ),
    );

    expect(find.byKey(DayBoardKeys.offlineBanner), findsOneWidget);
    expect(find.textContaining('منذ 10 دقائق'), findsOneWidget);
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
              subtitle: '+30 دقيقة · بانتظار قرارك',
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

  testWidgets('active child card → /scr-fat-013 with childId', (tester) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection(children: DayChildMock.manyFixture),
        onChildProfile: (id) => hits.add(id),
      ),
    );

    await tester.tap(find.byKey(DayBoardKeys.activeChild));
    await tester.pumpAndSettle();
    expect(hits, ['child_a']);
  });

  testWidgets('pulse avatar → profile with that childId', (tester) async {
    final hits = <String>[];
    await _pumpRouted(
      tester,
      DayBoardScreen(
        projection: DayBoardProjection(children: DayChildMock.manyFixture),
        onChildProfile: (id) => hits.add(id),
      ),
    );

    await tester.tap(find.byKey(DayBoardKeys.pulse(1)));
    await tester.pumpAndSettle();
    expect(hits, ['child_b']);
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

  test(
    'stage1DayBoardProjectionRepository binds Identity roster (no Register §10)',
    () async {
      resetStage1ChildrenListRepositoryForTest();
      final memory = InMemoryChildrenListRepository(
        byFamily: {
          ChildrenListLocalSeed.famStage1.value:
              ChildrenListLocalSeed.famStage1Children,
        },
        provenance: kChildrenListLocalDemoProvenance,
      );
      rebindStage1ChildrenListRepository(memory);

      final p = await stage1DayBoardProjectionRepository.load();
      expect(p.children.map((c) => c.id).toList(), ['demo-child', 'child_b']);
      expect(p.children.map((c) => c.displayName).toList(), ['ابن 1', 'ابن 2']);
      expect(p.children.any((c) => c.displayName.contains('خالد')), isFalse);
      expect(p.hasPending, isFalse);
      expect(p.lastSyncLabel, isNull);
      expect(p.localDemoSeeded, isTrue);
      expect(p.phase, DayBoardPhase.ready);

      resetStage1ChildrenListRepositoryForTest();
    },
  );

  testWidgets('LOCAL_DEMO roster → day board honesty BannerNote', (
    tester,
  ) async {
    resetStage1ChildrenListRepositoryForTest();
    rebindStage1ChildrenListRepository(
      InMemoryChildrenListRepository(
        byFamily: {
          ChildrenListLocalSeed.famStage1.value:
              ChildrenListLocalSeed.famStage1Children,
        },
        provenance: kChildrenListLocalDemoProvenance,
      ),
    );

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

    expect(find.byKey(DayBoardKeys.localDemoBanner), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);

    resetStage1ChildrenListRepositoryForTest();
  });

  testWidgets(
    'default DayBoardScreen shows Identity roster ids, never Khaled',
    (tester) async {
      resetStage1ChildrenListRepositoryForTest();
      rebindStage1ChildrenListRepository(
        InMemoryChildrenListRepository(
          byFamily: {
            ChildrenListLocalSeed.famStage1.value:
                ChildrenListLocalSeed.famStage1Children,
          },
          provenance: kChildrenListLocalDemoProvenance,
        ),
      );

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

      expect(find.byKey(DayBoardKeys.emptyChildren), findsNothing);
      expect(find.byKey(DayBoardKeys.pulse(0)), findsOneWidget);
      expect(find.byKey(DayBoardKeys.pulse(1)), findsOneWidget);
      expect(find.byKey(DayBoardKeys.pulse(2)), findsNothing);
      expect(find.textContaining('ابن 1'), findsWidgets);
      expect(find.textContaining('خالد'), findsNothing);
      expect(find.textContaining('نورة'), findsNothing);
      expect(find.textContaining('سعد'), findsNothing);
      expect(find.text('🦁'), findsWidgets);
      expect(find.text('🐱'), findsWidgets);

      resetStage1ChildrenListRepositoryForTest();
    },
  );

  testWidgets('FAT-010: importance ladder shows multiple live pending rows', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      projection: const DayBoardProjection(
        children: DayChildMock.manyFixture,
        pendingRequests: [
          DayBoardPendingRequest(
            id: 'athkar-0',
            titleKey: 'athkarBlessing',
            subtitleKey: 'athkarDone',
            kind: DayBoardPendingKind.athkar,
            inboxPath: '/scr-fat-072',
          ),
          DayBoardPendingRequest(
            id: 'tr-1',
            titleKey: 'timeRequest',
            subtitleKey: 'timeRequestWaiting',
            minutes: 30,
            kind: DayBoardPendingKind.time,
          ),
          DayBoardPendingRequest(
            id: 'friend-1',
            titleKey: 'friendRequest',
            subtitleKey: 'friendRequestWaiting',
            kind: DayBoardPendingKind.friend,
            inboxPath: '/scr-fat-071',
          ),
        ],
      ),
    );

    expect(find.byKey(DayBoardKeys.priorityLadder), findsOneWidget);
    expect(find.byKey(DayBoardKeys.priority), findsOneWidget);
    expect(find.byKey(DayBoardKeys.priorityAt(1)), findsOneWidget);
    expect(find.byKey(DayBoardKeys.priorityAt(2)), findsOneWidget);
    // Friend ranks above time above athkar.
    expect(find.textContaining('صداقة'), findsOneWidget);
  });

  testWidgets('FAT-010: mint bar only when timeLeftRatio is bound', (
    tester,
  ) async {
    final withRatio = DayChildMock(
      id: 'child_a',
      displayName: 'ابن 1',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      batteryLabel: '84٪',
      timeLeftLabel: '1 س 20 د',
      quranLabel: '50٪',
      walletLabel: '45 د',
      timeLeftRatio: 0.55,
      pulseStatus: DayChildPulseStatus.attention,
    );

    await _pumpScreen(
      tester,
      projection: DayBoardProjection(children: [withRatio]),
    );
    expect(find.byKey(DayBoardKeys.mintProgress), findsOneWidget);
    expect(find.byType(StatusPulseAvatar), findsOneWidget);

    await _pumpScreen(
      tester,
      projection: DayBoardProjection(children: DayChildMock.manyFixture),
    );
    expect(find.byKey(DayBoardKeys.mintProgress), findsNothing);
  });

  testWidgets('FAT-010: More tools hub scrolls inside the board', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      projection: DayBoardProjection(children: DayChildMock.manyFixture),
    );

    expect(find.byKey(DayBoardKeys.moreTools), findsOneWidget);
    expect(find.textContaining('المزيد'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(DayBoardKeys.moreTools), findsOneWidget);
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
