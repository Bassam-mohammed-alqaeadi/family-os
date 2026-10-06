import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/family_shell.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/components/tabs_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

void main() {
  test('screenIdFromPath maps registry paths', () {
    expect(screenIdFromPath('/scr-fat-010'), 'SCR-FAT-010');
    expect(screenIdFromPath('/scr-chd-004'), 'SCR-CHD-004');
    expect(screenIdFromPath('/gallery'), isNull);
  });

  test('hubTilesForTab excludes roots, noHub, and PERCHILD on kids', () {
    final today = hubTilesForTab('today');
    expect(today.map((e) => e.screenId), isNot(contains('SCR-FAT-010')));
    expect(today.map((e) => e.screenId), isNot(contains('SCR-FAT-074')));

    final kids = hubTilesForTab('kids');
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-032')));
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-013')));
    // VX-B4 · G-08
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-014')));
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-016')));
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-017')));
    expect(kids.map((e) => e.screenId), isNot(contains('SCR-FAT-085')));

    final settings = hubTilesForTab('settings');
    expect(settings.map((e) => e.screenId), isNot(contains('SCR-FAT-026')));
  });

  testWidgets('parent day board shows 5 tabs + hub + AI FAB', (tester) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-fat-010',
    );
    await _pump(tester, role: role, router: router);

    expect(find.byKey(FamilyShellKeys.tabs), findsOneWidget);
    expect(find.byType(TabsBar), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.aiFab), findsOneWidget);
    expect(find.text('اليوم'), findsWidgets);
  });

  testWidgets('welcome (bare) has no tabs', (tester) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-shr-001',
    );
    await _pump(tester, role: role, router: router);

    expect(find.byKey(FamilyShellKeys.tabs), findsNothing);
    expect(find.byKey(FamilyShellKeys.hub), findsNothing);
  });

  testWidgets('tab tap navigates to kids root with in-scroll more tools', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-fat-010',
    );
    await _pump(tester, role: role, router: router);

    await tester.tap(find.text('أبنائي').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-012');
    expect(find.byKey(FamilyShellKeys.tabs), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
    expect(find.textContaining('المزيد من الأدوات'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(FamilyShellKeys.hub),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
  });

  testWidgets('settings root scrolls more tools with page content', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-fat-025',
    );
    await _pump(tester, role: role, router: router);

    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(FamilyShellKeys.hub),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('المزيد من الأدوات'), findsOneWidget);
  });

  testWidgets('child myday shows 4 tabs + SOS FAB + in-scroll more tools', (
    tester,
  ) async {
    final role = RoleController(AppRole.child);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-chd-004',
    );
    await _pump(tester, role: role, router: router);

    expect(find.byKey(FamilyShellKeys.tabs), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.sosFab), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.aiFab), findsNothing);
    expect(find.text('يومي'), findsWidgets);
    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
  });

  testWidgets(
    'genuinely paired child mode suppresses guardian debug role chrome',
    (tester) async {
      final role = RoleController(AppRole.child);
      final router = createAppRouter(
        roleListenable: role,
        initialLocation: '/scr-chd-004',
      );
      await _pump(
        tester,
        role: role,
        router: router,
        showDebugRoleSwitch: false,
      );

      expect(find.byKey(FamilyShellKeys.devRoleSwitch), findsNothing);
      expect(find.byKey(FamilyShellKeys.tabs), findsOneWidget);
      expect(find.byKey(FamilyShellKeys.sosFab), findsOneWidget);
      expect(find.byKey(FamilyShellKeys.aiFab), findsNothing);
    },
  );

  testWidgets('login go() rebuilds shell tabs on day board', (tester) async {
    final role = RoleController(AppRole.father);
    final router = createAppRouter(
      roleListenable: role,
      initialLocation: '/scr-shr-003',
    );
    await _pump(tester, role: role, router: router);

    expect(find.byKey(FamilyShellKeys.tabs), findsNothing);

    router.go('/scr-fat-010');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-010');
    expect(find.byKey(FamilyShellKeys.tabs), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.hub), findsOneWidget);
    expect(find.byKey(FamilyShellKeys.aiFab), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required RoleController role,
  required GoRouter router,
  bool showDebugRoleSwitch = true,
}) async {
  await tester.pumpWidget(
    CurrentRole(
      notifier: role,
      child: MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
        builder: (context, child) => FamilyShellHost(
          router: router,
          showDebugRoleSwitch: showDebugRoleSwitch,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
