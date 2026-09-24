import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_repository.dart';
import 'package:family_os/features/n07_advisor/family_advisor_hub_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty → FAT-003', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryFamilyAdvisorHubRepository(
        seed: familyAdvisorHubEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(FamilyAdvisorHubKeys.empty), findsOneWidget);
    await tester.tap(find.text('Add a child'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-003'));
  });

  testWidgets('weekly chip → FAT-073 + honesty', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryFamilyAdvisorHubRepository(
        seed: familyAdvisorHubPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(FamilyAdvisorHubKeys.body), findsOneWidget);
    expect(find.byKey(FamilyAdvisorHubKeys.honesty), findsOneWidget);
    await tester.tap(find.byKey(FamilyAdvisorHubKeys.chip('weekly')));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-FAT-073'));
  });

  testWidgets('ask free text toast', (tester) async {
    final repo = InMemoryFamilyAdvisorHubRepository(
      seed: familyAdvisorHubPrototypeFixture(),
    );
    await _pump(tester, repository: repo);
    await tester.ensureVisible(find.byKey(FamilyAdvisorHubKeys.askField));
    await tester.enterText(
      find.byKey(FamilyAdvisorHubKeys.askField),
      'How is sleep?',
    );
    await tester.ensureVisible(find.byKey(FamilyAdvisorHubKeys.askSend));
    await tester.tap(find.byKey(FamilyAdvisorHubKeys.askSend));
    await tester.pump();
    expect(repo.asks, contains('How is sleep?'));
    expect(find.textContaining("honest «I don't know»"), findsOneWidget);
    AppToast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryFamilyAdvisorHubRepository(
      seed: familyAdvisorHubOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(FamilyAdvisorHubKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(FamilyAdvisorHubKeys.body), findsOneWidget);
  });

  testWidgets('child lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.child, onSos: () => sos = true);
    expect(find.byKey(FamilyAdvisorHubKeys.childLean), findsOneWidget);
    await tester.tap(find.byKey(FamilyAdvisorHubKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FamilyAdvisorHubRepository? repository,
  AppRole role = AppRole.father,
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
        home: FamilyAdvisorHubScreen(
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
