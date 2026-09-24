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
import 'package:family_os/features/n03_screen_time/child_apps_screen.dart';

void main() {
  tearDown(() {
    AppToast.dismiss();
  });

  testWidgets('empty inventory shows empty state', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': const <ChildAppEntry>[]},
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(ChildAppsKeys.empty), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.list), findsNothing);
    expect(find.byKey(ChildAppsKeys.sosCta), findsNothing);
  });

  testWidgets('one app shows single tile + categories', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(tester, repository: repo);

    expect(find.byKey(ChildAppsKeys.list), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.appTile('minecraft')), findsOneWidget);
    expect(
      find.byKey(ChildAppsKeys.category(ChildAppCategory.games)),
      findsOneWidget,
    );
    expect(find.byKey(ChildAppsKeys.pendingCta), findsNothing);
  });

  testWidgets('many apps + pending CTA fires FAT-035 seam', (tester) async {
    final repo = InMemoryChildAppsRepository();
    String? openedChild;
    String? openedApp;
    await _pump(
      tester,
      repository: repo,
      onOpenNewAppApprove: (childId, appId) {
        openedChild = childId;
        openedApp = appId;
      },
    );

    expect(find.byKey(ChildAppsKeys.list), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.pendingCta), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.honestyBanner), findsOneWidget);

    await tester.tap(find.byKey(ChildAppsKeys.pendingCta));
    await tester.pumpAndSettle();
    expect(openedChild, 'demo-child');
    expect(openedApp, 'snapchat');

    await tester.scrollUntilVisible(
      find.byKey(ChildAppsKeys.appTile('snapchat')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ChildAppsKeys.appTile('snapchat')), findsOneWidget);
  });

  testWidgets('pending tile tap opens FAT-035 seam', (tester) async {
    final repo = InMemoryChildAppsRepository();
    String? openedApp;
    await _pump(
      tester,
      repository: repo,
      onOpenNewAppApprove: (_, appId) => openedApp = appId,
    );

    final tile = find.byKey(ChildAppsKeys.appTile('snapchat'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(openedApp, 'snapchat');
  });

  testWidgets('father allow/block via sheet updates mock', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(ChildAppsKeys.appTile('minecraft')));
    await tester.pumpAndSettle();
    expect(find.byKey(ChildAppsKeys.controlSheet), findsOneWidget);

    await tester.tap(find.byKey(ChildAppsKeys.block('minecraft')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(
      repo.appsFor(ChildId('demo-child')).first.status,
      ChildAppStatus.blocked,
    );
  });

  testWidgets('toggle seam blocks allowed app', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(tester, repository: repo);

    await tester.tap(find.byKey(ChildAppsKeys.statusToggle('minecraft')));
    await tester.pump();
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(
      repo.appsFor(ChildId('demo-child')).first.status,
      ChildAppStatus.blocked,
    );
  });

  testWidgets('mother partner sees tickets hint — no permanent configure', (
    tester,
  ) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
    );
    expect(find.byKey(ChildAppsKeys.partnerHint), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.statusToggle('minecraft')), findsNothing);
  });

  testWidgets('mother full can configure access', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
    );
    expect(find.byKey(ChildAppsKeys.statusToggle('minecraft')), findsOneWidget);
  });

  testWidgets('mother observer is view-only', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {'demo-child': childAppsOneFixture()},
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    expect(find.byKey(ChildAppsKeys.observerHint), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.statusToggle('minecraft')), findsNothing);
  });

  testWidgets('child RoleGuard lean — no list controls', (tester) async {
    final repo = InMemoryChildAppsRepository();
    await _pump(tester, repository: repo, role: AppRole.child);

    expect(find.byKey(ChildAppsKeys.childLean), findsOneWidget);
    expect(find.byKey(ChildAppsKeys.list), findsNothing);
    expect(find.byKey(ChildAppsKeys.sosIconCta), findsOneWidget);
  });

  testWidgets('parametric childId empty inventory', (tester) async {
    final repo = InMemoryChildAppsRepository(
      seed: {
        'demo-child': childAppsOneFixture(),
        'k2': const <ChildAppEntry>[],
      },
    );
    await _pump(tester, repository: repo, childId: 'k2');
    expect(find.byKey(ChildAppsKeys.empty), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ChildAppsRepository repository,
  AppRole role = AppRole.father,
  MotherLevel motherLevel = MotherLevel.partner,
  String? childId,
  void Function(String childId, String? pendingAppId)? onOpenNewAppApprove,
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
        home: ChildAppsScreen(
          childId: childId,
          repository: repository,
          roleOverride: role,
          motherLevel: motherLevel,
          onOpenNewAppApprove: onOpenNewAppApprove,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
