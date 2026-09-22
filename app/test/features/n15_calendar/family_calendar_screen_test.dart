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
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FamilyCalendarKeys.empty), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one event · header and grid', (tester) async {
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FamilyCalendarKeys.body), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.headerCard), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.monthGrid), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-1')), findsOneWidget);
    expect(find.textContaining('Memorization review'), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.dayCell(14)), findsOneWidget);
  });

  testWidgets('prototype events · add event → FAT-053', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-1')), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-2')), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-3')), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-4')), findsOneWidget);
    expect(find.textContaining('Swim practice'), findsOneWidget);
    expect(find.textContaining('Grandparents dinner'), findsOneWidget);

    await tester.ensureVisible(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-053'));
  });

  testWidgets('category filter · study shows one event', (tester) async {
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(
      find.byKey(FamilyCalendarKeys.filterChip('sch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.filterChip('sch')));
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-4')), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-1')), findsNothing);
    expect(find.byKey(FamilyCalendarKeys.filterEmpty), findsNothing);
  });

  testWidgets('category filter empty message', (tester) async {
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarOneFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(
      find.byKey(FamilyCalendarKeys.filterChip('sch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.filterChip('sch')));
    await tester.pumpAndSettle();

    expect(find.byKey(FamilyCalendarKeys.filterEmpty), findsOneWidget);
    expect(find.textContaining('No events in this category'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FamilyCalendarKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyCalendarKeys.body), findsOneWidget);
  });

  testWidgets('mother observer — view filters · add blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(FamilyCalendarKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(FamilyCalendarKeys.filterChip('sch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.filterChip('sch')));
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-4')), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.eventRow('ev-1')), findsNothing);

    await tester.ensureVisible(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner add event → FAT-053', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyCalendarRepository(
      seed: familyCalendarPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(FamilyCalendarKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyCalendarKeys.addEventCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-053'));
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(FamilyCalendarKeys.childLean), findsOneWidget);
    expect(find.byKey(FamilyCalendarKeys.body), findsNothing);
    expect(find.byKey(FamilyCalendarKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(FamilyCalendarKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FamilyCalendarRepository? repository,
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
        home: FamilyCalendarScreen(
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
