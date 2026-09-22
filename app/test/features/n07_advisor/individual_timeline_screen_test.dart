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
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelineEmptyFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(IndividualTimelineKeys.empty), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one stop loads body + row', (tester) async {
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelineOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(IndividualTimelineKeys.body), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.todayThread), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.stop('stop-school')), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.empty), findsNothing);
    expect(find.textContaining('Child one'), findsWidgets);
  });

  testWidgets('prototype insight card + four stops', (tester) async {
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelinePrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(IndividualTimelineKeys.body), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.insightCard), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.todayHeading), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.stop('stop-school')), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.stop('stop-fractions')), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.stop('stop-arrived')), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.stop('stop-sleep')), findsOneWidget);
    expect(find.text('Cross-domain link'), findsOneWidget);
    expect(find.text('Discuss with advisor'), findsOneWidget);
    expect(find.textContaining('School mode active'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelineOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(IndividualTimelineKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(IndividualTimelineKeys.body), findsOneWidget);
  });

  testWidgets('mother partner may view list', (tester) async {
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelinePrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(IndividualTimelineKeys.body), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.observerHint), findsNothing);
    expect(find.byKey(IndividualTimelineKeys.discussCta), findsOneWidget);
  });

  testWidgets('mother observer view-only hint', (tester) async {
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelinePrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(IndividualTimelineKeys.body), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(IndividualTimelineKeys.discussCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(IndividualTimelineKeys.discussCta));
    await tester.pump();
    expect(
      find.textContaining('Partner or Full permission'),
      findsOneWidget,
    );
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = 0;
    final repo = InMemoryIndividualTimelineRepository(
      seed: individualTimelinePrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.child,
      onSos: () => sos++,
    );

    expect(find.byKey(IndividualTimelineKeys.childLean), findsOneWidget);
    expect(find.byKey(IndividualTimelineKeys.body), findsNothing);

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required IndividualTimelineRepository repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId)? onNavigate,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: RoleController(role),
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
        home: IndividualTimelineScreen(
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
