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
import 'package:family_os/features/n15_calendar/add_event_repository.dart';
import 'package:family_os/features/n15_calendar/add_event_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAddEventRepository(seed: addEventEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(AddEventKeys.empty), findsOneWidget);
    expect(find.byKey(AddEventKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype form · save → FAT-052', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(AddEventKeys.body), findsOneWidget);
    expect(find.byKey(AddEventKeys.categorySection), findsOneWidget);
    expect(find.byKey(AddEventKeys.categoryDin), findsOneWidget);
    expect(find.byKey(AddEventKeys.calendarSection), findsOneWidget);
    expect(find.byKey(AddEventKeys.weeklySwitch), findsOneWidget);

    await _tapSave(tester);
    await tester.pump();
    expect(find.textContaining('Saved'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-052'));
  });

  testWidgets('one child fixture loads body', (tester) async {
    final repo = InMemoryAddEventRepository(seed: addEventOneFixture());
    await _pump(tester, repository: repo);

    expect(find.byKey(AddEventKeys.body), findsOneWidget);
    expect(find.textContaining('Memorization review'), findsOneWidget);
    expect(find.byKey(AddEventKeys.categorySch), findsOneWidget);
  });

  testWidgets('empty title toast blocks nav', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture().copyWith(
        draft: addEventPrototypeFixture().draft.copyWith(title: ''),
      ),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.enterText(find.byKey(AddEventKeys.titleField), '');
    await tester.enterText(find.byKey(AddEventKeys.titleField), '   ');
    await _tapSave(tester);
    await tester.pump();
    expect(find.textContaining('Enter an event title'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryAddEventRepository(seed: addEventOneFixture())
      ..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(AddEventKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(AddEventKeys.body), findsOneWidget);
  });

  testWidgets('calendar toggle shows toast', (tester) async {
    final repo = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(AddEventKeys.calendarGregorian));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddEventKeys.calendarGregorian));
    await tester.pump();
    expect(find.textContaining('Stage 1 mock'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('mother observer view-only — save blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(AddEventKeys.observerHint), findsOneWidget);

    await _tapSave(tester);
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner save → FAT-052', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(AddEventKeys.observerHint), findsNothing);
    await _tapSave(tester);
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-052'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(AddEventKeys.childLean), findsOneWidget);
    expect(find.byKey(AddEventKeys.body), findsNothing);
    expect(find.byKey(AddEventKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(AddEventKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(AddEventKeys.saveCta));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(AddEventKeys.saveCta));
}

Future<void> _pump(
  WidgetTester tester, {
  AddEventRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
  bool settle = true,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
        home: AddEventScreen(
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
