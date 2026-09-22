import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/child_apps_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';
import 'package:family_os/features/n03_screen_time/new_app_approval_screen.dart';

void main() {
  tearDown(() {
    AppToast.dismiss();
  });

  testWidgets('empty when no pending installs', (tester) async {
    final repo = InMemoryChildAppsRepository(seed: {
      'demo-child': childAppsOneFixture(),
    });
    await _pump(tester, repository: repo);

    expect(find.byKey(NewAppApprovalKeys.empty), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.body), findsNothing);
    expect(find.byKey(NewAppApprovalKeys.approve), findsNothing);
  });

  testWidgets('pending snapchat shows approve/deny', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(tester, repository: repo, appId: 'snapchat');

    expect(find.byKey(NewAppApprovalKeys.body), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.hero), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.infoCard), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.approve), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.deny), findsOneWidget);
    expect(find.text('Snapchat'), findsOneWidget);
  });

  testWidgets('approve sets allowed + done banner', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(tester, repository: repo, appId: 'snapchat');

    await tester.tap(find.byKey(NewAppApprovalKeys.approve));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(
      repo.appsFor(ChildId('demo-child')).firstWhere((a) => a.id == 'snapchat').status,
      ChildAppStatus.allowed,
    );
    expect(find.byKey(NewAppApprovalKeys.doneBanner), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.backToApps), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.approve), findsNothing);
  });

  testWidgets('deny sets blocked + done banner', (tester) async {
    final repo = InMemoryChildAppsRepository();
    var backApps = false;
    await _pump(
      tester,
      repository: repo,
      appId: 'snapchat',
      onBackToApps: () => backApps = true,
    );

    await tester.tap(find.byKey(NewAppApprovalKeys.deny));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(
      repo.appsFor(ChildId('demo-child')).firstWhere((a) => a.id == 'snapchat').status,
      ChildAppStatus.blocked,
    );
    expect(find.byKey(NewAppApprovalKeys.doneBanner), findsOneWidget);

    await tester.tap(find.byKey(NewAppApprovalKeys.backToApps));
    await tester.pumpAndSettle();
    expect(backApps, isTrue);
  });

  testWidgets('mother partner can decide', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );
    expect(find.byKey(NewAppApprovalKeys.approve), findsOneWidget);
  });

  testWidgets('mother observer is view-only', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    expect(find.byKey(NewAppApprovalKeys.observerHint), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.approve), findsNothing);
    expect(find.byKey(NewAppApprovalKeys.deny), findsNothing);
  });

  testWidgets('child RoleGuard lean', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(tester, repository: repo, role: AppRole.child);

    expect(find.byKey(NewAppApprovalKeys.childLean), findsOneWidget);
    expect(find.byKey(NewAppApprovalKeys.body), findsNothing);
    expect(find.byKey(NewAppApprovalKeys.sosIconCta), findsOneWidget);
  });

  testWidgets('parametric childId empty pending', (tester) async {
    final repo = InMemoryChildAppsRepository(seed: {
      'k2': const <ChildAppEntry>[],
    });
    await _pump(tester, repository: repo, childId: 'k2');
    expect(find.byKey(NewAppApprovalKeys.empty), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ChildAppsRepository repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  String? childId,
  String? appId,
  VoidCallback? onBackToApps,
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
        home: NewAppApprovalScreen(
          childId: childId,
          appId: appId,
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onBackToApps: onBackToApps,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
