import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_screen.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quiz_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  test('LearningResultRepository submit lists for father', () async {
    final bus = InMemoryLearningResultRepository();
    addTearDown(bus.dispose);

    final row = await bus.submit(
      LearningResultSubmitRequest(
        childId: ChildId('child_a'),
        kind: LearningResultKind.quiz,
        titleKey: 'quizSubmitted',
        rewardMinutes: Minutes(20),
        scoreCorrect: 1,
        scoreTotal: 1,
      ),
    );
    expect(row.id, isNotEmpty);
    final listed = await bus.listRecent();
    expect(listed, hasLength(1));
    expect(listed.first.titleKey, 'quizSubmitted');
  });

  test('ResultsFollowup merges live submissions into activity log', () async {
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
    final followup = InMemoryResultsFollowupRepository(
      seed: resultsFollowupOneFixture(),
      results: bus,
    );
    final snap = await followup.load();
    expect(snap.activities, isNotEmpty);
    expect(snap.activities.first.titleKey, 'quizSubmitted');
    expect(snap.activities.first.minutes, 20);
  });

  testWidgets('P12: child quiz correct → FAT-050 shows live activity', (
    tester,
  ) async {
    final bus = InMemoryLearningResultRepository();
    addTearDown(bus.dispose);
    final nav = <String>[];

    await _pumpQuiz(
      tester,
      repository: InMemoryChildQuizRepository(seed: childQuizOneFixture()),
      results: bus,
      onNavigate: nav.add,
    );

    await tester.tap(find.byKey(ChildQuizKeys.option('a')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-016'));

    final listed = await bus.listRecent();
    expect(listed, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpFollowup(
      tester,
      repository: InMemoryResultsFollowupRepository(
        seed: resultsFollowupEmptyFixture(),
        results: bus,
      ),
    );
    expect(find.byKey(ResultsFollowupKeys.body), findsOneWidget);
    expect(find.text('Child quiz submitted'), findsOneWidget);
    expect(find.textContaining('+20 minutes'), findsOneWidget);
  });
}

Future<void> _pumpQuiz(
  WidgetTester tester, {
  required ChildQuizRepository repository,
  required LearningResultRepository results,
  void Function(String screenId)? onNavigate,
}) async {
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
          repository: repository,
          results: results,
          childId: ChildId('child_a'),
          roleOverride: AppRole.child,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpFollowup(
  WidgetTester tester, {
  required ResultsFollowupRepository repository,
}) async {
  final roleCtrl = RoleController(AppRole.father);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
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
        home: ResultsFollowupScreen(
          repository: repository,
          roleOverride: AppRole.father,
          motherLevel: MotherLevel.partner,
          onNavigate: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
