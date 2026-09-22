import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/app/router.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_advisor/brain_control_screen.dart';
import 'package:family_os/features/n07_privacy/audit_log_screen.dart';

void main() {
  group('roleGuardRedirectForPath', () {
    test('father allowed on all owner-only paths', () {
      for (final id in ownerOnlyScreenIds) {
        final path = screenPath(id);
        expect(
          roleGuardRedirectForPath(path, AppRole.father),
          isNull,
          reason: path,
        );
      }
    });

    test('mother allowed on owner-only paths (privacy/audit; billing is father-only)', () {
      for (final id in ownerOnlyScreenIds) {
        final path = screenPath(id);
        expect(
          roleGuardRedirectForPath(path, AppRole.mother),
          isNull,
          reason: path,
        );
      }
    });

    test('child redirected from owner-only paths to /gallery', () {
      for (final id in ownerOnlyScreenIds) {
        final path = screenPath(id);
        expect(
          roleGuardRedirectForPath(path, AppRole.child),
          roleGuardSafeLocation,
          reason: path,
        );
      }
    });

    test('child allowed on SOS, location, chat, gallery', () {
      const allowed = [
        '/gallery',
        '/scr-chd-005', // SOS
        '/scr-fat-014', // location map
        '/scr-fat-021', // chat list
        '/scr-chd-007', // child chats
        '/scr-chd-008', // child conversation
      ];
      for (final path in allowed) {
        expect(
          roleGuardRedirectForPath(path, AppRole.child),
          isNull,
          reason: path,
        );
      }
    });

    test('owner-only IDs are privacy/audit (billing moved to father-only)', () {
      expect(ownerOnlyScreenIds, {
        'SCR-FAT-059',
        'SCR-FAT-060',
      });
    });

    test('SET-015 father allowed on brain control path', () {
      expect(
        roleGuardRedirectForPath(screenPath('SCR-FAT-029'), AppRole.father),
        isNull,
      );
      expect(canOpenBrainControl(AppRole.father), isTrue);
    });

    test('SET-015 mother FULL redirected from brain control', () {
      expect(
        roleGuardRedirectForPath(screenPath('SCR-FAT-029'), AppRole.mother),
        roleGuardSafeLocation,
      );
      expect(
        fatherOnlyRedirect(screenPath('SCR-FAT-029'), AppRole.mother),
        roleGuardSafeLocation,
      );
      expect(canOpenBrainControl(AppRole.mother), isFalse);
    });

    test('SET-015 child redirected from brain control', () {
      expect(
        roleGuardRedirectForPath(screenPath('SCR-FAT-029'), AppRole.child),
        roleGuardSafeLocation,
      );
      expect(canOpenBrainControl(AppRole.child), isFalse);
    });

    test('UI-007 father-only IDs include brain + mother level + billing', () {
      expect(fatherOnlyScreenIds, {
        'SCR-FAT-029',
        'SCR-FAT-031',
        'SCR-FAT-056',
        'SCR-FAT-057',
      });
      expect(fatherOnlyPaths, {
        '/scr-fat-029',
        '/scr-fat-031',
        '/scr-fat-056',
        '/scr-fat-057',
      });
    });

    test('UI-007 mother redirected from billing paths', () {
      expect(
        roleGuardRedirectForPath(screenPath('SCR-FAT-056'), AppRole.mother),
        roleGuardSafeLocation,
      );
      expect(
        roleGuardRedirectForPath(screenPath('SCR-FAT-057'), AppRole.mother),
        roleGuardSafeLocation,
      );
      expect(canOpenBilling(AppRole.mother), isFalse);
      expect(canOpenBilling(AppRole.father), isTrue);
    });

    test('SET-022 only father may approve advisor rules', () {
      expect(canApproveAdvisorRules(AppRole.father), isTrue);
      expect(canApproveAdvisorRules(AppRole.mother), isFalse);
      expect(canApproveAdvisorRules(AppRole.child), isFalse);
    });

    test('SET-021 no role may show SOS mute control', () {
      expect(canShowSosMuteControl(AppRole.father), isFalse);
      expect(canShowSosMuteControl(AppRole.mother), isFalse);
      expect(canShowSosMuteControl(AppRole.child), isFalse);
    });
  });

  testWidgets('child navigating to subscription lands on gallery', (
    tester,
  ) async {
    final role = RoleController(AppRole.child);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-056'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
  });

  testWidgets('UI-007 mother navigating to subscription lands on gallery', (
    tester,
  ) async {
    final role = RoleController(AppRole.mother);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-057'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
  });

  testWidgets('father can open audit route', (tester) async {
    final role = RoleController(AppRole.father);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-060'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, screenPath('SCR-FAT-060'));
    expect(find.byType(AuditLogScreen), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
  });

  testWidgets('SET-015 mother navigating to brain lands on gallery', (
    tester,
  ) async {
    final role = RoleController(AppRole.mother);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-029'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
    expect(find.byType(BrainControlScreen), findsNothing);
  });

  testWidgets('SET-015 child navigating to brain lands on gallery', (
    tester,
  ) async {
    final role = RoleController(AppRole.child);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-029'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/gallery');
    expect(find.byType(BrainControlScreen), findsNothing);
  });

  testWidgets('SET-015 father can open brain control route', (tester) async {
    final role = RoleController(AppRole.father);
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
      ),
    );
    await tester.pumpAndSettle();

    router.go(screenPath('SCR-FAT-029'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, screenPath('SCR-FAT-029'));
    expect(find.byType(BrainControlScreen), findsOneWidget);
    expect(find.byKey(BrainControlKeys.denyPanel), findsNothing);
  });
}
