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
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FamilyTasksKeys.empty), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one pending task · approve toast and status update', (
    tester,
  ) async {
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FamilyTasksKeys.body), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.pendingRow('t-pending')), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.activeRow('t-pending')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(FamilyTasksKeys.pendingApprove('t-pending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyTasksKeys.pendingApprove('t-pending')));
    await tester.pump();
    expect(find.textContaining('+15 minutes deposited'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyTasksKeys.pendingEmpty), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('prototype · cards and new task → FAT-055', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FamilyTasksKeys.pendingCard), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.motherHelpCard), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.activeCard), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.pendingRow('t1')), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.activeRow('t2')), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.activeRow('t3')), findsOneWidget);
    expect(find.textContaining('Wash dishes'), findsOneWidget);
    expect(find.textContaining('Mother help requests'), findsOneWidget);

    await tester.ensureVisible(find.byKey(FamilyTasksKeys.newTaskCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyTasksKeys.newTaskCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-055'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FamilyTasksKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyTasksKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — approve blocked', (tester) async {
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksOneFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(FamilyTasksKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(FamilyTasksKeys.pendingApprove('t-pending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyTasksKeys.pendingApprove('t-pending')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyTasksKeys.pendingRow('t-pending')), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.pendingEmpty), findsNothing);
  });

  testWidgets('mother observer view-only — new task blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    await tester.ensureVisible(find.byKey(FamilyTasksKeys.newTaskCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyTasksKeys.newTaskCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner can approve', (tester) async {
    final repo = InMemoryFamilyTasksRepository(
      seed: familyTasksOneFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(FamilyTasksKeys.observerHint), findsNothing);
    await tester.ensureVisible(
      find.byKey(FamilyTasksKeys.pendingApprove('t-pending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyTasksKeys.pendingApprove('t-pending')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyTasksKeys.pendingEmpty), findsOneWidget);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(FamilyTasksKeys.childLean), findsOneWidget);
    expect(find.byKey(FamilyTasksKeys.body), findsNothing);
    expect(find.byKey(FamilyTasksKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(FamilyTasksKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FamilyTasksRepository? repository,
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
        home: FamilyTasksScreen(
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
