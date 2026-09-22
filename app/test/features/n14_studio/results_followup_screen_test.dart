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
import 'package:family_os/features/n14_studio/results_followup_repository.dart';
import 'package:family_os/features/n14_studio/results_followup_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(ResultsFollowupKeys.empty), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('prototype body · mastery · gap · activity log', (tester) async {
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(ResultsFollowupKeys.body), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.masteryCard), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.masteryHero), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.masteryProgress), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.gapCard), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.gapCta), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.activityLog), findsOneWidget);
    expect(
      find.byKey(ResultsFollowupKeys.activityRow('act-hw-fractions')),
      findsOneWidget,
    );
    expect(
      find.byKey(ResultsFollowupKeys.activityRow('act-family-daily')),
      findsOneWidget,
    );
    expect(find.textContaining('82%'), findsWidgets);
    expect(find.textContaining('Dividing proper fractions'), findsOneWidget);
    expect(find.textContaining('+30 minutes'), findsOneWidget);
  });

  testWidgets('gap CTA → FAT-049', (tester) async {
    final nav = <String>[];
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));
  });

  testWidgets('focus CTA → FAT-051', (tester) async {
    final nav = <String>[];
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(ResultsFollowupKeys.focusCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ResultsFollowupKeys.focusCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-051'));
  });

  testWidgets('mother observer view-only — gap blocked', (tester) async {
    final nav = <String>[];
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(ResultsFollowupKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner gap → FAT-049', (tester) async {
    final nav = <String>[];
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(ResultsFollowupKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ResultsFollowupKeys.gapCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-049'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(ResultsFollowupKeys.childLean), findsOneWidget);
    expect(find.byKey(ResultsFollowupKeys.body), findsNothing);
    expect(find.byKey(ResultsFollowupKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(ResultsFollowupKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryResultsFollowupRepository(
      seed: resultsFollowupOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ResultsFollowupKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ResultsFollowupKeys.body), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ResultsFollowupRepository? repository,
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
        home: ResultsFollowupScreen(
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
