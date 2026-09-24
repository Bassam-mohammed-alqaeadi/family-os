import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_screen.dart';

void main() {
  testWidgets('empty → CHD-012', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(
        seed: childWalletEmptyFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildWalletKeys.empty), findsOneWidget);
    await tester.tap(find.text('Back to My learning'));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-012'));
  });

  testWidgets('prototype body + earn nav', (tester) async {
    final nav = <String>[];
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(
        seed: childWalletPrototypeFixture(),
      ),
      onNavigate: nav.add,
    );
    expect(find.byKey(ChildWalletKeys.body), findsOneWidget);
    expect(find.byKey(ChildWalletKeys.hero), findsOneWidget);
    expect(find.textContaining('minutes'), findsWidgets);
    expect(find.textContaining('pride'), findsOneWidget);

    await tester.ensureVisible(find.byKey(ChildWalletKeys.earnTasks));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChildWalletKeys.earnTasks));
    await tester.pumpAndSettle();
    expect(nav, contains('SCR-CHD-022'));
  });

  testWidgets('loading then body', (tester) async {
    final gate = Completer<void>();
    final repo = InMemoryChildWalletRepository(seed: childWalletOneFixture())
      ..loadGate = () => gate.future;
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(ChildWalletKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChildWalletKeys.body), findsOneWidget);
  });

  testWidgets('parent lean', (tester) async {
    await _pump(tester, role: AppRole.father);
    expect(find.byKey(ChildWalletKeys.parentLean), findsOneWidget);
  });

  testWidgets('SOS', (tester) async {
    var sos = 0;
    await _pump(
      tester,
      repository: InMemoryChildWalletRepository(seed: childWalletOneFixture()),
      onSos: () => sos++,
    );
    await tester.tap(find.byKey(ChildWalletKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, 1);
  });

  testWidgets('CHD-019 reflects policy wallet projection', (tester) async {
    final childId = ChildId('demo-child');
    final policyRepo = InMemoryScreenTimePolicyRepository({
      childId.value: ScreenTimePolicy(
        wallets: [
          AppWallet(appId: 'youtube', earnedMinutes: Minutes(25)),
          AppWallet(appId: 'games', earnedMinutes: Minutes(10)),
        ],
      ),
    });

    await _pump(
      tester,
      repository: PolicyChildWalletRepository(
        policyRepository: policyRepo,
        childId: childId,
      ),
    );

    expect(find.byKey(ChildWalletKeys.appRow('youtube')), findsOneWidget);
    expect(find.byKey(ChildWalletKeys.appRow('games')), findsOneWidget);
    expect(find.textContaining('35'), findsWidgets);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ChildWalletRepository? repository,
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
        home: ChildWalletScreen(
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
