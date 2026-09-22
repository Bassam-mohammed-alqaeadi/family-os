import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/learning_path_repository.dart';
import 'package:family_os/features/n14_studio/learning_path_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-041', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLearningPathRepository(
      seed: learningPathEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(LearningPathKeys.empty), findsOneWidget);
    expect(find.byKey(LearningPathKeys.body), findsNothing);

    await tester.tap(find.text('Add from any source'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('one stop; materials CTA → FAT-048', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLearningPathRepository(seed: learningPathOneFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(LearningPathKeys.body), findsOneWidget);
    expect(find.byKey(LearningPathKeys.stopRow('stop_adding')), findsOneWidget);
    expect(find.byKey(LearningPathKeys.progress), findsOneWidget);

    await tester.ensureVisible(find.byKey(LearningPathKeys.materialsCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LearningPathKeys.materialsCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-048'));
  });

  testWidgets('many stops; current → FAT-048; locked toast', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLearningPathRepository(
      seed: learningPathPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(LearningPathKeys.thread), findsOneWidget);
    expect(find.byKey(LearningPathKeys.advisorBanner), findsOneWidget);
    expect(
      find.byKey(LearningPathKeys.stopRow('stop_concept')),
      findsOneWidget,
    );
    expect(find.byKey(LearningPathKeys.stopRow('stop_final')), findsOneWidget);
    expect(find.textContaining('45%'), findsOneWidget);
    expect(find.textContaining('Mastered 90%'), findsOneWidget);
    expect(find.textContaining('Big reward: 50 minutes'), findsOneWidget);

    await tester.tap(find.byKey(LearningPathKeys.stopRow('stop_adding')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-048'));

    nav.clear();
    await tester.ensureVisible(
      find.byKey(LearningPathKeys.stopRow('stop_subtract')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LearningPathKeys.stopRow('stop_subtract')));
    await tester.pump();
    expect(find.textContaining('opens after mastery'), findsWidgets);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryLearningPathRepository(
      seed: learningPathPrototypeFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(LearningPathKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(LearningPathKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — materials blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLearningPathRepository(
      seed: learningPathPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(LearningPathKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(LearningPathKeys.materialsCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LearningPathKeys.materialsCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner materials → FAT-048', (tester) async {
    final nav = <String>[];
    final repo = InMemoryLearningPathRepository(
      seed: learningPathPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(LearningPathKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(LearningPathKeys.materialsCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LearningPathKeys.materialsCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-048'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(LearningPathKeys.childLean), findsOneWidget);
    expect(find.byKey(LearningPathKeys.body), findsNothing);
    expect(find.byKey(LearningPathKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(LearningPathKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  LearningPathRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
  bool settle = true,
}) async {
  final roleCtrl = RoleController(role);
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
        home: LearningPathScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}
