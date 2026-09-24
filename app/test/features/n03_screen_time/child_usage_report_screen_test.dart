import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_repository.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_screen.dart';

void main() {
  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryChildUsageReportRepository(
      seed: childUsageReportEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(ChildUsageReportKeys.empty), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype week bars + categories + retention', (tester) async {
    final repo = InMemoryChildUsageReportRepository(
      seed: childUsageReportPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(ChildUsageReportKeys.body), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.weekCard), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.categoriesCard), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.retentionBanner), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.category('learn')), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.dayBar(0)), findsOneWidget);
    expect(find.textContaining('18h 40m'), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildUsageReportRepository(
      seed: childUsageReportOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildUsageReportKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildUsageReportKeys.body), findsOneWidget);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(ChildUsageReportKeys.childLean), findsOneWidget);
    expect(find.byKey(ChildUsageReportKeys.body), findsNothing);

    await tester.tap(find.byKey(ChildUsageReportKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildUsageReportRepository? repository,
  AppRole role = AppRole.father,
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
        home: ChildUsageReportScreen(
          repository: repository,
          roleOverride: role,
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
