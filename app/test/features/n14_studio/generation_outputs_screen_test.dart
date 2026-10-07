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
import 'package:family_os/features/n14_studio/generation_outputs_repository.dart';
import 'package:family_os/features/n14_studio/generation_outputs_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('father: six outputs + religious lock; generate → FAT-044', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(GenerationOutputsKeys.body), findsOneWidget);
    expect(find.byKey(GenerationOutputsKeys.sourceBanner), findsOneWidget);
    expect(find.byKey(GenerationOutputsKeys.religiousLock), findsOneWidget);
    expect(
      find.byKey(GenerationOutputsKeys.outputRow('out-lesson')),
      findsOneWidget,
    );
    expect(
      find.byKey(GenerationOutputsKeys.outputRow('out-review')),
      findsOneWidget,
    );
    expect(find.textContaining('Generate selected (5)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pump();
    expect(find.textContaining('upcoming update'), findsOneWidget);
    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-044'));
  });

  testWidgets('toggle off reduces selected count', (tester) async {
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.textContaining('Generate selected (5)'), findsOneWidget);

    await tester.tap(
      find.byKey(GenerationOutputsKeys.outputSwitch('out-quiz')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Generate selected (4)'), findsOneWidget);
  });

  testWidgets('phase-locked review game stays off', (tester) async {
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    );
    await _pump(tester, repository: repo);

    final review = find.byKey(GenerationOutputsKeys.outputSwitch('out-review'));
    final sw = tester.widget<Switch>(review);
    expect(sw.value, isFalse);

    // The review row is the last in a long page and the test surface is shorter than a
    // phone. Without revealing it first the tap lands below the fold and misses: the
    // switch would stay off because nothing was pressed, and this test would pass for the
    // wrong reason.
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pump();

    // The tap landed: the screen answered it with the reason the switch will not move.
    expect(
      find.textContaining('غير قابلة للتحديد'),
      findsOneWidget,
      reason: 'the phase lock answers the tap instead of silently ignoring it',
    );

    AppToast.dismiss();
    await tester.pumpAndSettle();

    final swAfter = tester.widget<Switch>(review);
    expect(swAfter.value, isFalse);
    expect(find.textContaining('Generate selected (5)'), findsOneWidget);
  });

  testWidgets('empty state when no outputs', (tester) async {
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsEmptyFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(GenerationOutputsKeys.empty), findsOneWidget);
    expect(find.byKey(GenerationOutputsKeys.body), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(GenerationOutputsKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(GenerationOutputsKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — generate does not navigate', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(GenerationOutputsKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);

    await tester.ensureVisible(
      find.byKey(GenerationOutputsKeys.outputSwitch('out-lesson')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(GenerationOutputsKeys.outputSwitch('out-lesson')),
    );
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    // Switch disabled for observer — count stays 5.
    expect(find.textContaining('Generate selected (5)'), findsOneWidget);
  });

  testWidgets('mother partner can generate → FAT-044', (tester) async {
    final nav = <String>[];
    final repo = InMemoryGenerationOutputsRepository(
      seed: generationOutputsPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(GenerationOutputsKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GenerationOutputsKeys.generateCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-044'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);

    expect(find.byKey(GenerationOutputsKeys.childLean), findsOneWidget);
    expect(find.byKey(GenerationOutputsKeys.body), findsNothing);
    expect(find.byKey(GenerationOutputsKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(GenerationOutputsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets(
    'NotebookLM studio: toggle audio overview + source grounding + depth chip',
    (tester) async {
      final repo = InMemoryGenerationOutputsRepository(
        seed: generationOutputsPrototypeFixture(),
      );
      await _pump(tester, repository: repo);

      expect(find.byKey(GenerationOutputsKeys.sourcesCard), findsOneWidget);
      expect(find.byKey(GenerationOutputsKeys.flexibilityCard), findsOneWidget);
      expect(
        find.byKey(GenerationOutputsKeys.outputRow('out-audio-overview')),
        findsOneWidget,
      );
      expect(
        find.byKey(GenerationOutputsKeys.outputRow('out-mind-map')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(GenerationOutputsKeys.outputSwitch('out-audio-overview')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(GenerationOutputsKeys.outputSwitch('out-audio-overview')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Generate selected (6)'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(GenerationOutputsKeys.sourceSwitch('src-voice-father')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(GenerationOutputsKeys.sourceSwitch('src-voice-father')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Active grounding sources: 2 of 3'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(GenerationOutputsKeys.depthChip('examCrunch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(GenerationOutputsKeys.depthChip('examCrunch')),
      );
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.byKey(GenerationOutputsKeys.depthChip('examCrunch')),
      );
      expect(chip.selected, isTrue);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  GenerationOutputsRepository? repository,
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
        home: GenerationOutputsScreen(
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
