import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_screen.dart';

void main() {
  tearDown(() {
    AppToast.dismiss();
    stage1MotherPermissionLevelRepository.resetForTests();
  });

  testWidgets('father sees three levels + fixed rights + empty audit',
      (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo);

    expect(find.byKey(MotherPermissionLevelKeys.screen), findsOneWidget);
    expect(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.observer)),
      findsOneWidget,
    );
    expect(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.partner)),
      findsOneWidget,
    );
    expect(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.full)),
      findsOneWidget,
    );
    expect(
      find.byKey(MotherPermissionLevelKeys.fixedRightsBanner),
      findsOneWidget,
    );
    expect(find.byKey(MotherPermissionLevelKeys.auditEmpty), findsOneWidget);
    expect(find.byKey(MotherPermissionLevelKeys.sosCta), findsOneWidget);
    expect(repo.level, MotherLevel.partner);
  });

  testWidgets('upgrade to full confirms then persists + audit', (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo);

    await tester.tap(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.full)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(MotherPermissionLevelKeys.upgradeDialog),
      findsOneWidget,
    );
    await tester.tap(find.byKey(MotherPermissionLevelKeys.upgradeConfirm));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(repo.level, MotherLevel.full);
    expect(repo.auditLog, hasLength(1));
    expect(repo.auditLog.first.from, MotherLevel.partner);
    expect(repo.auditLog.first.to, MotherLevel.full);
    expect(find.byKey(MotherPermissionLevelKeys.auditRow(0)), findsOneWidget);
  });

  testWidgets('downgrade requires confirm; cancel keeps level', (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo);

    await tester.tap(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.observer)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(MotherPermissionLevelKeys.downgradeDialog),
      findsOneWidget,
    );
    await tester.tap(find.byKey(MotherPermissionLevelKeys.dialogCancel));
    await tester.pumpAndSettle();

    expect(repo.level, MotherLevel.partner);
    expect(repo.auditLog, isEmpty);
  });

  testWidgets('downgrade confirm persists observer + audit', (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo);

    await tester.tap(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.observer)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MotherPermissionLevelKeys.downgradeConfirm));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(repo.level, MotherLevel.observer);
    expect(repo.auditLog.first.to, MotherLevel.observer);
  });

  testWidgets('mother sees owner-only banner — cannot change level',
      (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo, role: AppRole.mother);

    expect(
      find.byKey(MotherPermissionLevelKeys.ownerOnly),
      findsOneWidget,
    );
    expect(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.partner)),
      findsNothing,
    );
    expect(
      find.byKey(MotherPermissionLevelKeys.fixedRightsBanner),
      findsOneWidget,
    );
    expect(repo.level, MotherLevel.partner);
  });

  testWidgets('child RoleGuard lean — no level controls', (tester) async {
    final repo = InMemoryMotherPermissionLevelRepository();
    await _pump(tester, repository: repo, role: AppRole.child);

    expect(find.byKey(MotherPermissionLevelKeys.childLean), findsOneWidget);
    expect(
      find.byKey(MotherPermissionLevelKeys.levelRow(MotherLevel.partner)),
      findsNothing,
    );
    expect(find.byKey(MotherPermissionLevelKeys.sosIconCta), findsOneWidget);
  });

  test('isMotherLevelDowngrade / upgrade ranks', () {
    expect(
      isMotherLevelDowngrade(MotherLevel.full, MotherLevel.partner),
      isTrue,
    );
    expect(
      isMotherLevelUpgrade(MotherLevel.observer, MotherLevel.partner),
      isTrue,
    );
    expect(
      isMotherLevelDowngrade(MotherLevel.partner, MotherLevel.full),
      isFalse,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required MotherPermissionLevelRepository repository,
  AppRole role = AppRole.father,
}) async {
  final roleCtrl = RoleController(role);
  addTearDown(roleCtrl.dispose);
  await tester.pumpWidget(
    CurrentRole(
      notifier: roleCtrl,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MotherPermissionLevelScreen(
          repository: repository,
          roleOverride: role,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
