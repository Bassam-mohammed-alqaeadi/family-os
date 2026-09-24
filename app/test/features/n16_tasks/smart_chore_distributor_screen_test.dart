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
import 'package:family_os/features/n16_tasks/smart_chore_distributor_repository.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemorySmartChoreDistributorRepository(
        seed: smartChoreDistributorEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(SmartChoreDistributorKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('approve → FAT-054 + shuffle toast', (tester) async {
    final nav = <String>[];
    final repo = InMemorySmartChoreDistributorRepository(
      seed: smartChoreDistributorPrototypeFixture(),
    );
    await _pump(tester, repository: repo, onNavigate: nav.add);
    expect(find.byKey(SmartChoreDistributorKeys.proposal), findsOneWidget);

    await tester.tap(find.byKey(SmartChoreDistributorKeys.shuffleCta));
    await tester.pump();
    expect(find.textContaining('Alternate'), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SmartChoreDistributorKeys.approveCta));
    await tester.pump();
    expect(
      find.text('Approved — each child got their tasks with set minutes'),
      findsOneWidget,
    );
    AppToast.dismiss();
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-054'));
  });

  testWidgets('observer cannot approve', (tester) async {
    await _pump(
      tester,
      repository: InMemorySmartChoreDistributorRepository(
        seed: smartChoreDistributorPrototypeFixture(),
      ),
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    expect(find.byKey(SmartChoreDistributorKeys.observerHint), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemorySmartChoreDistributorRepository(
      seed: smartChoreDistributorOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(SmartChoreDistributorKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(SmartChoreDistributorKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(SmartChoreDistributorKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(SmartChoreDistributorKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  SmartChoreDistributorRepository? repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
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
        home: SmartChoreDistributorScreen(
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
