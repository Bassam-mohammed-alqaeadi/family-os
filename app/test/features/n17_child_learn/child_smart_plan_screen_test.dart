import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_repository.dart';
import 'package:family_os/features/n17_child_learn/child_smart_plan_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildSmartPlanRepository(
        seed: childSmartPlanEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildSmartPlanKeys.empty), findsOneWidget);
    await tester.tap(find.text('My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('body + gap + start toast', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildSmartPlanRepository(
        seed: childSmartPlanPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildSmartPlanKeys.body), findsOneWidget);
    expect(find.byKey(ChildSmartPlanKeys.gapCard), findsOneWidget);

    await tester.tap(find.byKey(ChildSmartPlanKeys.startCta));
    await tester.pump();
    expect(find.textContaining('3-day plan'), findsOneWidget);
    AppToast.dismiss();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildSmartPlanRepository(
      seed: childSmartPlanOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildSmartPlanKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildSmartPlanKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildSmartPlanKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildSmartPlanRepository(
        seed: childSmartPlanOneFixture(),
      ),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildSmartPlanKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildSmartPlanRepository? repository,
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
        home: ChildSmartPlanScreen(
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
