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
import 'package:family_os/features/n14_studio/focus_report_repository.dart';
import 'package:family_os/features/n14_studio/focus_report_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFocusReportRepository(seed: focusReportEmptyFixture());
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(FocusReportKeys.empty), findsOneWidget);
    expect(find.byKey(FocusReportKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype weekly summary and schedule row', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FocusReportKeys.body), findsOneWidget);
    expect(find.byKey(FocusReportKeys.weeklyCard), findsOneWidget);
    expect(find.byKey(FocusReportKeys.advisorCard), findsOneWidget);
    expect(find.byKey(FocusReportKeys.scheduleCard), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('3h 40m'), findsOneWidget);
    expect(
      find.byKey(FocusReportKeys.scheduleRow('sched-1')),
      findsOneWidget,
    );
  });

  testWidgets('praise toast then sent quote state', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FocusReportKeys.praiseCta), findsOneWidget);
    expect(find.byKey(FocusReportKeys.praiseSent), findsNothing);

    await tester.ensureVisible(find.byKey(FocusReportKeys.praiseCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FocusReportKeys.praiseCta));
    await tester.pump();
    expect(find.textContaining('Encouragement sent'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(find.byKey(FocusReportKeys.praiseSent), findsOneWidget);
    expect(find.byKey(FocusReportKeys.praiseCta), findsNothing);
    expect(find.textContaining('resisted distraction'), findsOneWidget);
  });

  testWidgets('reward toast +15 minutes', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(FocusReportKeys.rewardCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FocusReportKeys.rewardCta));
    await tester.pump();
    expect(find.textContaining('+15 minutes'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('add schedule Stage-1 toast', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportOneFixture(),
    );
    await _pump(tester, repository: repo);

    await tester.ensureVisible(find.byKey(FocusReportKeys.addScheduleCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FocusReportKeys.addScheduleCta));
    await tester.pump();
    expect(find.textContaining('full editor'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('mother partner toggles schedule', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(FocusReportKeys.observerHint), findsNothing);
    final switchFinder = find.byKey(FocusReportKeys.scheduleSwitch('sched-1'));
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(switchFinder).value,
      isFalse,
    );
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFocusReportRepository(
      seed: focusReportOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FocusReportKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FocusReportKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — praise blocked', (tester) async {
    final repo = InMemoryFocusReportRepository(
      seed: focusReportPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(FocusReportKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(FocusReportKeys.praiseCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FocusReportKeys.praiseCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(FocusReportKeys.praiseSent), findsNothing);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(FocusReportKeys.childLean), findsOneWidget);
    expect(find.byKey(FocusReportKeys.body), findsNothing);
    expect(find.byKey(FocusReportKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(FocusReportKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FocusReportRepository? repository,
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
        home: FocusReportScreen(
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
