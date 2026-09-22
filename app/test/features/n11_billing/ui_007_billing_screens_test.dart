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
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/entitlement_service.dart';
import 'package:family_os/features/n11_billing/manage_subscription_screen.dart';
import 'package:family_os/features/n11_billing/plans_screen.dart';

void main() {
  group('UI-007 RoleGuard billing father-owner only', () {
    test('canOpenBilling only father', () {
      expect(canOpenBilling(AppRole.father), isTrue);
      expect(canOpenBilling(AppRole.mother), isFalse);
      expect(canOpenBilling(AppRole.child), isFalse);
    });

    test('mother redirected from FAT-056/057', () {
      for (final id in ['SCR-FAT-056', 'SCR-FAT-057']) {
        expect(
          roleGuardRedirectForPath(screenPath(id), AppRole.mother),
          roleGuardSafeLocation,
          reason: id,
        );
      }
    });

    test('child redirected from FAT-056/057', () {
      for (final id in ['SCR-FAT-056', 'SCR-FAT-057']) {
        expect(
          roleGuardRedirectForPath(screenPath(id), AppRole.child),
          roleGuardSafeLocation,
          reason: id,
        );
      }
    });

    test('father allowed on FAT-056/057', () {
      for (final id in ['SCR-FAT-056', 'SCR-FAT-057']) {
        expect(
          roleGuardRedirectForPath(screenPath(id), AppRole.father),
          isNull,
          reason: id,
        );
      }
    });
  });

  testWidgets('mother navigating to plans lands on gallery', (tester) async {
    final role = RoleController(AppRole.mother);
    final router = createAppRouter(roleListenable: role);
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(_RouterApp(router: router, role: role));
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-056'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
    expect(find.byType(PlansScreen), findsNothing);
  });

  testWidgets('child navigating to manage lands on gallery', (tester) async {
    final role = RoleController(AppRole.child);
    final router = createAppRouter(roleListenable: role);
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(_RouterApp(router: router, role: role));
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-057'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
    expect(find.byType(ManageSubscriptionScreen), findsNothing);
  });

  testWidgets('father opens plans with safety banner', (tester) async {
    final entitlement = MockEntitlementService(Entitlement.expired());
    await tester.pumpWidget(
      _ScreenApp(
        child: PlansScreen(
          entitlement: entitlement,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PlansScreenKeys.screen), findsOneWidget);
    expect(find.byKey(PlansScreenKeys.safetyBanner), findsOneWidget);
    expect(find.byKey(PlansScreenKeys.denyPanel), findsNothing);
    expect(find.byKey(PlansScreenKeys.planBasic), findsOneWidget);
  });

  testWidgets('mother deny panel on PlansScreen (composition)', (tester) async {
    await tester.pumpWidget(
      _ScreenApp(
        child: PlansScreen(roleOverride: AppRole.mother),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PlansScreenKeys.denyPanel), findsOneWidget);
    expect(find.byKey(PlansScreenKeys.planFamily), findsNothing);
  });

  testWidgets('cancel renewal keeps safety copy; status expired', (
    tester,
  ) async {
    final entitlement = MockEntitlementService(Entitlement.trial());
    addTearDown(AppToast.dismiss);
    await tester.pumpWidget(
      _ScreenApp(
        child: ManageSubscriptionScreen(
          entitlement: entitlement,
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ManageSubscriptionKeys.safetyBanner), findsOneWidget);
    await tester.tap(find.byKey(ManageSubscriptionKeys.cancelRenewal));
    await tester.pump(); // show toast
    AppToast.dismiss();
    await tester.pumpAndSettle();

    expect(entitlement.current.isExpired, isTrue);
    expect(find.byKey(ManageSubscriptionKeys.safetyBanner), findsOneWidget);
  });
}

class _RouterApp extends StatelessWidget {
  const _RouterApp({required this.router, required this.role});

  final GoRouter router;
  final RoleController role;

  @override
  Widget build(BuildContext context) {
    return CurrentRole(
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
      ),
    );
  }
}

class _ScreenApp extends StatelessWidget {
  const _ScreenApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }
}
