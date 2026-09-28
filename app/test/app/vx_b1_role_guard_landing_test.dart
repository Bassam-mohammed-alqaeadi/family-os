import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/road_safety_screen.dart';
import 'package:family_os/features/n07_privacy/privacy_data_screen.dart';
import 'package:family_os/features/n11_billing/plans_screen.dart';
import 'package:family_os/features/n13_coming_soon/coming_soon_screen.dart';

/// VX-B1 — Owner D4 (blocked role lands on its own home with a polite
/// message; never the developer gallery) and D11 (FAT-077 → FAT-075).
void main() {
  tearDown(AppToast.dismiss);

  group('D4 landing paths', () {
    test('every guarded path lands on the role home, never /gallery', () {
      final guarded = {...ownerOnlyPaths, ...fatherOnlyPaths};
      for (final role in AppRole.values) {
        for (final path in guarded) {
          final target = roleGuardRedirectForPath(path, role);
          if (target == null) continue;
          expect(target, isNot(contains('/gallery')), reason: '$role $path');
          final uri = Uri.parse(target);
          expect(uri.path, roleHomePath(role), reason: '$role $path');
          expect(isRoleGuardBlockedLanding(uri), isTrue, reason: target);
        }
      }
    });

    test('role homes: child → My Day, father/mother → Today', () {
      expect(roleHomePath(AppRole.child), '/scr-chd-004');
      expect(roleHomePath(AppRole.mother), '/scr-fat-010');
      expect(roleHomePath(AppRole.father), '/scr-fat-010');
    });

    test('normal home visits are not treated as blocked landings', () {
      expect(isRoleGuardBlockedLanding(Uri.parse('/scr-chd-004')), isFalse);
      expect(isRoleGuardBlockedLanding(Uri.parse('/scr-fat-010')), isFalse);
    });
  });

  testWidgets('child blocked from privacy lands on My Day with gentle toast', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, AppRole.child);

    router.go(screenPath('SCR-FAT-059'));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(router.state.uri.path, roleGuardChildHomePath);
    expect(find.byType(ChildDayBoardScreen), findsOneWidget);
    expect(find.byType(PrivacyDataScreen), findsNothing);
    expect(find.text(l10n.roleGuardBlockedChild), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('mother blocked from billing lands on Today (English copy)', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      AppRole.mother,
      locale: const Locale('en'),
    );

    router.go(screenPath('SCR-FAT-056'));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(router.state.uri.path, roleGuardParentHomePath);
    expect(find.byType(DayBoardScreen), findsOneWidget);
    expect(find.byType(PlansScreen), findsNothing);
    expect(find.text(l10n.roleGuardBlockedParent), findsOneWidget);
    AppToast.dismiss();
    await tester.pump();
  });

  testWidgets('opening Today normally shows no blocked toast', (tester) async {
    final router = await _pumpRouter(tester, AppRole.father);

    router.go(roleGuardParentHomePath);
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(find.byType(DayBoardScreen), findsOneWidget);
    expect(find.text(l10n.roleGuardBlockedParent), findsNothing);
  });

  testWidgets('D11 FAT-077 deep link redirects to FAT-075 Coming soon', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, AppRole.father);

    router.go('/scr-fat-077');
    await tester.pumpAndSettle();

    expect(legacyRedirectPaths['/scr-fat-077'], '/scr-fat-075');
    expect(router.state.uri.path, '/scr-fat-075');
    expect(find.byType(ComingSoonScreen), findsOneWidget);
    expect(find.byType(RoadSafetyScreen), findsNothing);
    expect(
      find.byKey(ComingSoonKeys.featureRow('road_safety')),
      findsOneWidget,
    );
  });
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  AppRole initialRole, {
  Locale locale = const Locale('ar'),
}) async {
  final role = RoleController(initialRole);
  final router = createAppRouter(roleListenable: role);
  addTearDown(() {
    router.dispose();
    role.dispose();
  });

  await tester.pumpWidget(
    CurrentRole(
      notifier: role,
      child: MaterialApp.router(
        theme: buildFamilyTheme(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
