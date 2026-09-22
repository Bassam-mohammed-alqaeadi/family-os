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
import 'package:family_os/features/n14_studio/create_assignment_repository.dart';
import 'package:family_os/features/n14_studio/create_assignment_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CreateAssignmentKeys.empty), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one child · no skill gap · results → FAT-050', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentOneFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CreateAssignmentKeys.body), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.skillEmpty), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.skillCta), findsNothing);
    expect(find.byKey(CreateAssignmentKeys.homeworkCta), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.familyCta), findsOneWidget);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.resultsCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.resultsCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('many paths · homework assign → FAT-050', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(CreateAssignmentKeys.homeworkCard), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.skillCard), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.familyCard), findsOneWidget);
    expect(find.textContaining('Dividing proper fractions'), findsOneWidget);
    expect(find.textContaining('+50'), findsWidgets);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('skill assign → FAT-050 minutes toast', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.skillCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.skillCta));
    await tester.pump();
    expect(find.textContaining('50 minutes'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('family assign → FAT-050', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.familyCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.familyCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('empty homework toast blocks nav', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture().copyWith(homeworkTitle: ''),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pump();
    expect(find.textContaining('homework title'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(CreateAssignmentKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(CreateAssignmentKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — assign blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(CreateAssignmentKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.homeworkCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner skill assign → FAT-050', (tester) async {
    final nav = <String>[];
    final repo = InMemoryCreateAssignmentRepository(
      seed: createAssignmentPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(CreateAssignmentKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(CreateAssignmentKeys.skillCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CreateAssignmentKeys.skillCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(CreateAssignmentKeys.childLean), findsOneWidget);
    expect(find.byKey(CreateAssignmentKeys.body), findsNothing);
    expect(find.byKey(CreateAssignmentKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(CreateAssignmentKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  CreateAssignmentRepository? repository,
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
        home: CreateAssignmentScreen(
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
