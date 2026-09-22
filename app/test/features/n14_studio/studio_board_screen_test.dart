import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';
import 'package:family_os/features/n14_studio/studio_board_screen.dart';

void main() {
  testWidgets('loading shows while load awaits', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryStudioBoardRepository();
    repo.loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(StudioBoardKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(StudioBoardKeys.loading), findsNothing);
    expect(find.byKey(StudioBoardKeys.empty), findsOneWidget);
  });

  testWidgets('empty shows create CTA + quick actions for father', (
    tester,
  ) async {
    final repo = InMemoryStudioBoardRepository();
    final nav = <String>[];
    await _pump(
      tester,
      repository: repo,
      onNavigate: nav.add,
    );

    expect(find.byKey(StudioBoardKeys.empty), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.body), findsNothing);
    expect(find.byKey(StudioBoardKeys.createCta), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.quickCamera), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.quickLibrary), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.quickResults), findsOneWidget);

    await tester.tap(find.byKey(StudioBoardKeys.createCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));

    await tester.tap(find.byKey(StudioBoardKeys.quickCamera));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-042'));
  });

  testWidgets('one shows suggestion + recent rows', (tester) async {
    final repo = InMemoryStudioBoardRepository(seed: studioBoardOneFixture());
    final nav = <String>[];
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(StudioBoardKeys.body), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.suggestionsSection), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.suggestionRow('sug-fractions')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.contentRow('cnt-quiz-1')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.empty), findsNothing);

    await tester.tap(find.byKey(StudioBoardKeys.suggestionRow('sug-fractions')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('many shows two suggestions + three recent', (tester) async {
    final repo = InMemoryStudioBoardRepository(seed: studioBoardManyFixture());
    final nav = <String>[];
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(StudioBoardKeys.suggestionRow('sug-fractions')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.suggestionRow('sug-wird')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.contentRow('cnt-quiz-1')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.contentRow('cnt-cards-1')), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.contentRow('cnt-wird-1')), findsOneWidget);

    await tester.tap(find.byKey(StudioBoardKeys.recentAllCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-048'));

    await tester.ensureVisible(find.byKey(StudioBoardKeys.quickLibrary));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StudioBoardKeys.quickLibrary));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));

    await tester.ensureVisible(find.byKey(StudioBoardKeys.quickResults));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StudioBoardKeys.quickResults));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-050'));
  });

  testWidgets('mother observer view-only — no create or camera', (
    tester,
  ) async {
    final repo = InMemoryStudioBoardRepository(seed: studioBoardOneFixture());
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(StudioBoardKeys.observerHint), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.createCta), findsNothing);
    expect(find.byKey(StudioBoardKeys.quickCamera), findsNothing);
    expect(find.byKey(StudioBoardKeys.body), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.quickLibrary), findsOneWidget);
  });

  testWidgets('mother partner can create', (tester) async {
    final repo = InMemoryStudioBoardRepository(seed: studioBoardOneFixture());
    final nav = <String>[];
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(StudioBoardKeys.createCta), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.observerHint), findsNothing);
    await tester.tap(find.byKey(StudioBoardKeys.createCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-041'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    final repo = InMemoryStudioBoardRepository(seed: studioBoardOneFixture());
    var sos = false;
    await _pump(
      tester,
      repository: repo,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(StudioBoardKeys.childLean), findsOneWidget);
    expect(find.byKey(StudioBoardKeys.body), findsNothing);
    expect(find.byKey(StudioBoardKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(StudioBoardKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required StudioBoardRepository repository,
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
        home: StudioBoardScreen(
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
