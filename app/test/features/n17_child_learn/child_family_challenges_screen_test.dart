import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n17_child_learn/child_family_challenges_repository.dart';
import 'package:family_os/features/n17_child_learn/child_family_challenges_screen.dart';

void main() {
  testWidgets('empty → CHD-001', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildFamilyChallengesRepository(
        seed: childFamilyChallengesEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildFamilyChallengesKeys.empty), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-001'));
  });

  testWidgets('active + done lists', (tester) async {
    await _pump(
      tester,
      repository: InMemoryChildFamilyChallengesRepository(
        seed: childFamilyChallengesPrototypeFixture(),
      ),
    );
    expect(find.byKey(ChildFamilyChallengesKeys.active), findsOneWidget);
    expect(find.byKey(ChildFamilyChallengesKeys.done), findsOneWidget);
    expect(find.textContaining('review marathon'), findsOneWidget);
    expect(find.text('Sibling'), findsOneWidget);
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildFamilyChallengesRepository(
      seed: childFamilyChallengesOneFixture(),
    )..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildFamilyChallengesKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildFamilyChallengesKeys.body), findsOneWidget);
  });

  testWidgets('parent lean + SOS', (tester) async {
    var sos = false;
    await _pump(tester, role: AppRole.father, onSos: () => sos = true);
    expect(find.byKey(ChildFamilyChallengesKeys.parentLean), findsOneWidget);
    await tester.tap(find.byKey(ChildFamilyChallengesKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildFamilyChallengesRepository? repository,
  AppRole role = AppRole.child,
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
        home: ChildFamilyChallengesScreen(
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
