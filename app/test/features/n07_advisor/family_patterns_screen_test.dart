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
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';
import 'package:family_os/features/n07_advisor/family_patterns_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsEmptyFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      onNavigate: (id, {childId}) => nav.add(id),
    );

    expect(find.byKey(FamilyPatternsKeys.advisorBanner), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.empty), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.body), findsNothing);

    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('one child card + confidence seal', (tester) async {
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsOneFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FamilyPatternsKeys.body), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.childCard('child_card_a')), findsOneWidget);
    expect(
      find.byKey(FamilyPatternsKeys.confidenceSeal('child_card_a')),
      findsOneWidget,
    );
    expect(find.text('Trust 72%'), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.patternRow('pat-a1')), findsOneWidget);
  });

  testWidgets('prototype two children · pattern tags + footer', (tester) async {
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(FamilyPatternsKeys.body), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.advisorBanner), findsOneWidget);
    expect(find.textContaining('79%'), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.childCard('child_card_one')), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.childCard('child_card_two')), findsOneWidget);
    expect(find.text('Trust 85%'), findsOneWidget);
    expect(find.text('Trust 72%'), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.patternRow('pat-sleep-one')), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.patternRow('pat-comm-one')), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.patternRow('pat-edu-one')), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.patternRow('pat-morning-two')), findsOneWidget);
    expect(find.text('Anomaly'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.footerNote), findsOneWidget);
    expect(find.textContaining('14 days'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsOneFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FamilyPatternsKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyPatternsKeys.body), findsOneWidget);
  });

  testWidgets('mother observer timeline blocked toast', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: (id, {childId}) => nav.add(id),
    );

    expect(find.byKey(FamilyPatternsKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(FamilyPatternsKeys.timelineLink('child_card_one')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyPatternsKeys.timelineLink('child_card_one')));
    await tester.pump();
    expect(
      find.textContaining('ask the father or a partner mother to open the timeline'),
      findsOneWidget,
    );
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner opens timeline → FAT-063', (tester) async {
    final nav = <String>[];
    final repo = InMemoryFamilyPatternsRepository(
      seed: familyPatternsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: (id, {childId}) => nav.add(id),
    );

    expect(find.byKey(FamilyPatternsKeys.observerHint), findsNothing);

    await tester.ensureVisible(
      find.byKey(FamilyPatternsKeys.timelineLink('child_card_one')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FamilyPatternsKeys.timelineLink('child_card_one')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-063'));
  });

  testWidgets('child lean + SOS navigates FAT-018 seam', (tester) async {
    var sos = false;
    String? nav;
    await _pump(
      tester,
      role: AppRole.child,
      onSos: () => sos = true,
      onNavigate: (id, {childId}) => nav = id,
    );

    expect(find.byKey(FamilyPatternsKeys.childLean), findsOneWidget);
    expect(find.byKey(FamilyPatternsKeys.body), findsNothing);

    await tester.tap(find.byKey(FamilyPatternsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
    expect(nav, isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FamilyPatternsRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  VoidCallback? onSos,
  void Function(String screenId, {String? childId})? onNavigate,
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
        home: FamilyPatternsScreen(
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
