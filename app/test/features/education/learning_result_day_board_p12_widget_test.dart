import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  test('DayBoard merges LearningResult into pending', () async {
    final bus = InMemoryLearningResultRepository();
    addTearDown(bus.dispose);
    await bus.submit(
      LearningResultSubmitRequest(
        childId: ChildId('child_a'),
        kind: LearningResultKind.quiz,
        titleKey: 'quizSubmitted',
        rewardMinutes: Minutes(20),
      ),
    );
    final board = InMemoryDayBoardProjectionRepository(
      DayBoardProjection(children: DayChildMock.manyFixture),
      bus,
    );
    final snap = await board.load();
    expect(snap.pendingRequests, isNotEmpty);
    expect(snap.primaryPending!.titleKey, 'quizSubmitted');
    expect(snap.primaryPending!.inboxPath, '/scr-fat-050');
    expect(snap.primaryPending!.minutes, 20);
  });

  testWidgets('P12: child quiz → day-board priority → FAT-050', (tester) async {
    final bus = InMemoryLearningResultRepository();
    addTearDown(bus.dispose);
    final nav = <String>[];

    await tester.pumpWidget(
      CurrentRole(
        notifier: RoleController(AppRole.child),
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ChildQuizScreen(
            repository: InMemoryChildQuizRepository(
              seed: childQuizOneFixture(),
            ),
            results: bus,
            childId: ChildId('child_a'),
            roleOverride: AppRole.child,
            onNavigate: nav.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildQuizKeys.option('a')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-016'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final router = GoRouter(
      initialLocation: '/scr-fat-010',
      routes: [
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) => DayBoardScreen(
            guardianDisplayName: 'Parent',
            projectionRepository: InMemoryDayBoardProjectionRepository(
              DayBoardProjection(children: DayChildMock.manyFixture),
              bus,
            ),
          ),
        ),
        GoRoute(
          path: '/scr-fat-050',
          builder: (context, state) =>
              const Scaffold(body: Text('results-followup')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
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

    expect(find.byKey(DayBoardKeys.priority), findsOneWidget);
    expect(find.text('Child quiz submitted'), findsOneWidget);
    expect(find.textContaining('+20 minutes'), findsOneWidget);

    await tester.tap(find.byKey(DayBoardKeys.priority));
    await tester.pumpAndSettle();
    expect(find.text('results-followup'), findsOneWidget);
  });
}
