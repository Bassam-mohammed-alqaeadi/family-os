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
import 'package:family_os/features/n16_tasks/create_task_repository.dart';
import 'package:family_os/features/n16_tasks/create_task_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateTaskRepository(seed: createTaskEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CreateTaskKeys.empty), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype form · submit → FAT-054 + toast', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CreateTaskKeys.body), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.rewardCard), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.courageSection), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.playtimeSection), findsOneWidget);
    expect(find.textContaining('15 minutes'), findsWidgets);

    await tester.enterText(
      find.byKey(CreateTaskKeys.titleField),
      'Tidy the playroom',
    );
    await _tapSubmit(tester);
    await tester.pump();
    expect(find.textContaining('assigned to Child one'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-054'));
  });

  testWidgets('one child fixture loads body', (tester) async {
    final repo = InMemoryCreateTaskRepository(seed: createTaskOneFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(CreateTaskKeys.body), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.assigneeSection), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.rewardCard), findsOneWidget);
  });

  testWidgets('empty title toast blocks nav', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.enterText(find.byKey(CreateTaskKeys.titleField), '   ');
    await _tapSubmit(tester);
    await tester.pump();
    expect(find.textContaining('Enter a task title'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryCreateTaskRepository(seed: createTaskOneFixture())
      ..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(CreateTaskKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(CreateTaskKeys.body), findsOneWidget);
  });

  testWidgets('mother assignee hides reward · shows help banner', (
    tester,
  ) async {
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(CreateTaskKeys.assigneeSection));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mother 🌸').last);
    await tester.pumpAndSettle();

    expect(find.byKey(CreateTaskKeys.motherHelpBanner), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.rewardCard), findsNothing);
    expect(find.byKey(CreateTaskKeys.courageSection), findsNothing);
    expect(find.byKey(CreateTaskKeys.playtimeSection), findsNothing);
  });

  testWidgets('mother observer view-only — submit blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(CreateTaskKeys.observerHint), findsOneWidget);

    await tester.enterText(
      find.byKey(CreateTaskKeys.titleField),
      'Water the plants',
    );
    await _tapSubmit(tester);
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner submit → FAT-054', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(CreateTaskKeys.observerHint), findsNothing);
    await tester.enterText(
      find.byKey(CreateTaskKeys.titleField),
      'Fold laundry',
    );
    await _tapSubmit(tester);
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-054'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(CreateTaskKeys.childLean), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.body), findsNothing);
    expect(find.byKey(CreateTaskKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(CreateTaskKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('courage and playtime minute chips update selection', (
    tester,
  ) async {
    final repo = InMemoryCreateTaskRepository(
      seed: createTaskPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(CreateTaskKeys.courageChip(25)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateTaskKeys.playtimeChip(30)));
    await tester.pumpAndSettle();

    expect(find.byKey(CreateTaskKeys.courageChip(25)), findsOneWidget);
    expect(find.byKey(CreateTaskKeys.playtimeChip(30)), findsOneWidget);
  });
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(CreateTaskKeys.submitCta));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(CreateTaskKeys.submitCta));
}

Future<void> _pump(
  WidgetTester tester, {
  CreateTaskRepository? repository,
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
        home: CreateTaskScreen(
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
