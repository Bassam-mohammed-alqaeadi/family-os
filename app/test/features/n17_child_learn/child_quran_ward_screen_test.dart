import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_models.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_screen.dart';
import 'package:family_os/features/quran/quran_recitation_repository.dart';
import 'package:family_os/features/quran/quran_ward_plan_repository.dart';

void main() {
  tearDown(AppToast.dismiss);

  InMemoryChildQuranWardRepository isolated({ChildQuranWardSnapshot? seed}) {
    final bus = InMemoryQuranRecitationRepository();
    final plans = InMemoryQuranWardPlanRepository();
    addTearDown(bus.dispose);
    addTearDown(plans.dispose);
    return InMemoryChildQuranWardRepository(
      seed: seed,
      recitations: bus,
      plans: plans,
    );
  }

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: isolated(seed: childQuranWardEmptyFixture()),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildQuranWardKeys.empty), findsOneWidget);
    await tester.tap(find.text('My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('body + gift + play/record toasts', (tester) async {
    await _pump(
      tester,
      repository: isolated(seed: childQuranWardPrototypeFixture()),
    );
    expect(find.byKey(ChildQuranWardKeys.body), findsOneWidget);
    expect(find.byKey(ChildQuranWardKeys.giftBanner), findsOneWidget);

    await tester.tap(find.byKey(ChildQuranWardKeys.playCta));
    await tester.pump();
    expect(find.textContaining('Playing sheikh'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildQuranWardKeys.recordCta));
    await tester.pump();
    expect(
      find.textContaining('Recording sent to your parents'),
      findsOneWidget,
    );
    AppToast.dismiss();
  });

  testWidgets('one fixture — no gift banner', (tester) async {
    await _pump(tester, repository: isolated(seed: childQuranWardOneFixture()));
    expect(find.byKey(ChildQuranWardKeys.body), findsOneWidget);
    expect(find.byKey(ChildQuranWardKeys.giftBanner), findsNothing);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = isolated(seed: childQuranWardOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildQuranWardKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildQuranWardKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildQuranWardKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: isolated(seed: childQuranWardOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildQuranWardKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildQuranWardRepository? repository,
  AppRole role = AppRole.child,
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
        home: ChildQuranWardScreen(
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
