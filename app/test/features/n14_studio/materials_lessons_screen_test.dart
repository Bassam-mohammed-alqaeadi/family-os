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
import 'package:family_os/features/n14_studio/materials_lessons_repository.dart';
import 'package:family_os/features/n14_studio/materials_lessons_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-041', (tester) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(MaterialsLessonsKeys.empty), findsOneWidget);
    expect(find.byKey(MaterialsLessonsKeys.body), findsNothing);

    await tester.tap(find.text('Add from any source'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('one subject; active path → FAT-047', (tester) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsOneFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(MaterialsLessonsKeys.body), findsOneWidget);
    expect(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-math')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(MaterialsLessonsKeys.subjectRow('subj-math')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-047'));
  });

  testWidgets('many subjects; assignment CTA → FAT-049; add lesson → FAT-041', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-math')),
      findsOneWidget,
    );
    expect(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-quran')),
      findsOneWidget,
    );
    expect(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-english')),
      findsOneWidget,
    );
    expect(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-science')),
      findsOneWidget,
    );
    expect(find.textContaining('8 lessons'), findsOneWidget);
    expect(find.textContaining('24 flashcards'), findsOneWidget);

    await tester.ensureVisible(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));

    nav.clear();
    await tester.tap(find.byKey(MaterialsLessonsKeys.addLessonCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('add subject toast', (tester) async {
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsOneFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(MaterialsLessonsKeys.addSubjectCta));
    await tester.pump();
    expect(find.textContaining('own color'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('non-path subject toast', (tester) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.tap(
      find.byKey(MaterialsLessonsKeys.subjectRow('subj-quran')),
    );
    await tester.pump();
    expect(find.textContaining('Open lessons'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(MaterialsLessonsKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(MaterialsLessonsKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — assignment blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(MaterialsLessonsKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner assignment → FAT-049', (tester) async {
    final nav = <String>[];
    final repo = InMemoryMaterialsLessonsRepository(
      seed: materialsLessonsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(MaterialsLessonsKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MaterialsLessonsKeys.assignmentCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(MaterialsLessonsKeys.childLean), findsOneWidget);
    expect(find.byKey(MaterialsLessonsKeys.body), findsNothing);
    expect(find.byKey(MaterialsLessonsKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(MaterialsLessonsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  MaterialsLessonsRepository? repository,
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
        home: MaterialsLessonsScreen(
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
