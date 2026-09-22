import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_repository.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_screen.dart';

void main() {
  testWidgets('empty shows empty state + settings for father', (tester) async {
    final repo = InMemoryTamperAlertsRepository(seed: {'demo-child': const []});
    var openedSettings = false;
    await _pump(
      tester,
      repository: repo,
      onOpenAntiTamperSettings: () => openedSettings = true,
    );

    expect(find.byKey(TamperAlertsKeys.empty), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.body), findsNothing);
    expect(find.byKey(TamperAlertsKeys.settingsCta), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.pedagogyBanner), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.honestyBanner), findsOneWidget);

    await tester.tap(find.byKey(TamperAlertsKeys.settingsCta).first);
    await tester.pumpAndSettle();
    expect(openedSettings, isTrue);
  });

  testWidgets('one active alert shows tip card', (tester) async {
    final repo = InMemoryTamperAlertsRepository(
      seed: {'demo-child': tamperAlertsOneFixture()},
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(TamperAlertsKeys.body), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.activeSection), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-vpn-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.tip('ta-vpn-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.historySection), findsNothing);
    expect(find.textContaining('TurboVPN'), findsOneWidget);
  });

  testWidgets('many shows active + history sections', (tester) async {
    final repo = InMemoryTamperAlertsRepository(
      seed: {'demo-child': tamperAlertsManyFixture()},
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(TamperAlertsKeys.activeSection), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.historySection), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-vpn-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-perm-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-clock-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-safe-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.row('ta-sim-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.tip('ta-clock-1')), findsNothing);
  });

  testWidgets('mother observer view-only hint, no settings CTA', (
    tester,
  ) async {
    final repo = InMemoryTamperAlertsRepository(
      seed: {'demo-child': tamperAlertsOneFixture()},
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );

    expect(find.byKey(TamperAlertsKeys.observerHint), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.settingsCta), findsNothing);
    expect(find.byKey(TamperAlertsKeys.body), findsOneWidget);
  });

  testWidgets('mother partner can view alerts without settings', (
    tester,
  ) async {
    final repo = InMemoryTamperAlertsRepository(
      seed: {'demo-child': tamperAlertsOneFixture()},
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );

    expect(find.byKey(TamperAlertsKeys.body), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.settingsCta), findsNothing);
    expect(find.byKey(TamperAlertsKeys.observerHint), findsNothing);
  });

  testWidgets('child RoleGuard lean + SOS', (tester) async {
    final repo = InMemoryTamperAlertsRepository(
      seed: {'demo-child': tamperAlertsOneFixture()},
    );
    var sos = false;
    await _pump(
      tester,
      repository: repo,
      role: AppRole.child,
      onSos: () => sos = true,
    );

    expect(find.byKey(TamperAlertsKeys.childLean), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.body), findsNothing);
    expect(find.byKey(TamperAlertsKeys.sosIconCta), findsOneWidget);

    await tester.tap(find.byKey(TamperAlertsKeys.sosIconCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('parametric childId loads that child only', (tester) async {
    final other = ChildId('other-child');
    final repo = InMemoryTamperAlertsRepository(
      seed: {
        'demo-child': const [],
        'other-child': tamperAlertsOneFixture(childId: other),
      },
    );
    await _pump(tester, repository: repo, childId: 'other-child');

    expect(find.byKey(TamperAlertsKeys.row('ta-vpn-1')), findsOneWidget);
    expect(find.byKey(TamperAlertsKeys.empty), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required TamperAlertsRepository repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  String? childId,
  VoidCallback? onSos,
  VoidCallback? onOpenAntiTamperSettings,
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
        home: TamperAlertsScreen(
          childId: childId,
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onSos: onSos,
          onOpenAntiTamperSettings: onOpenAntiTamperSettings,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
