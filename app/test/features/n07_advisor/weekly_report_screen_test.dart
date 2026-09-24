import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/weekly_report_repository.dart';
import 'package:family_os/features/n07_advisor/weekly_report_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryWeeklyReportRepository(
        seed: weeklyReportEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(WeeklyReportKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype apply tip toast', (tester) async {
    final repo = InMemoryWeeklyReportRepository(
      seed: weeklyReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(WeeklyReportKeys.body), findsOneWidget);
    expect(find.byKey(WeeklyReportKeys.recommendCard), findsOneWidget);
    await tester.ensureVisible(find.byKey(WeeklyReportKeys.applyCta));
    await tester.tap(find.byKey(WeeklyReportKeys.applyCta));
    await tester.pump();
    expect(find.textContaining('Sleep schedule adjusted'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(find.textContaining('Suggestion applied'), findsOneWidget);
  });

  testWidgets('toggle include hides section', (tester) async {
    final repo = InMemoryWeeklyReportRepository(
      seed: weeklyReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    expect(find.byKey(WeeklyReportKeys.section('screen')), findsOneWidget);
    await tester.tap(find.byKey(WeeklyReportKeys.includeChip('screen')));
    await tester.pumpAndSettle();
    expect(find.byKey(WeeklyReportKeys.section('screen')), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryWeeklyReportRepository(seed: weeklyReportOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(WeeklyReportKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(WeeklyReportKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(WeeklyReportKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(WeeklyReportKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  WeeklyReportRepository? repository,
  AppRole role = AppRole.father,
  VoidCallback? onSos,
  void Function(String)? onNavigate,
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
        home: WeeklyReportScreen(
          repository: repository,
          roleOverride: role,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
