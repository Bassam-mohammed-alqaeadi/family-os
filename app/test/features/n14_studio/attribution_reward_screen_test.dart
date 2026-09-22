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
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('father: child+schedule+rewards; assign → FAT-046', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    expect(find.byKey(AttributionRewardKeys.body), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.whoCard), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.scheduleField), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.rewardsCard), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.childChip('child_a')), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.rewardSwitch('wallet')), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.rewardSwitch('play')), findsOneWidget);
    expect(find.textContaining('20 minutes to their wallet'), findsOneWidget);
    expect(find.textContaining('+15 play minutes'), findsOneWidget);

    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));
  });

  testWidgets('library CTA → FAT-046', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.ensureVisible(find.byKey(AttributionRewardKeys.libraryCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.libraryCta));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));
  });

  testWidgets('select child_b then assign', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.tap(find.byKey(AttributionRewardKeys.childChip('child_b')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));
  });

  testWidgets('disabling all rewards blocks assign', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);

    await tester.tap(find.byKey(AttributionRewardKeys.rewardSwitch('wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.rewardSwitch('play')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('empty state when no children', (tester) async {
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardEmptyFixture(),
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(AttributionRewardKeys.empty), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.body), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    )..loadGate = () => gate.future;

    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(AttributionRewardKeys.loading), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(AttributionRewardKeys.body), findsOneWidget);
  });

  testWidgets('mother observer view-only — assign does not navigate', (
    tester,
  ) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      onNavigate: nav.add,
    );

    expect(find.byKey(AttributionRewardKeys.observerHint), findsOneWidget);

    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    expect(nav, isEmpty);
  });

  testWidgets('mother partner can assign → FAT-046', (tester) async {
    final nav = <String>[];
    final repo = InMemoryAttributionRewardRepository(
      seed: attributionRewardPrototypeFixture(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      onNavigate: nav.add,
    );

    expect(find.byKey(AttributionRewardKeys.observerHint), findsNothing);
    await tester.ensureVisible(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AttributionRewardKeys.assignCta));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-046'));
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    var sos = false;
    await _pump(
      tester,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(AttributionRewardKeys.childLean), findsOneWidget);
    expect(find.byKey(AttributionRewardKeys.body), findsNothing);
    expect(find.byKey(AttributionRewardKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(AttributionRewardKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  AttributionRewardRepository? repository,
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
        home: AttributionRewardScreen(
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
