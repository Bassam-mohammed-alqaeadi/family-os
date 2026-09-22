import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/device_mode_screen.dart';

void main() {
  testWidgets('exactly two mode cards; no mother third card', (tester) async {
    await _pumpDeviceMode(tester);

    expect(find.byKey(const Key('device_mode_guardian')), findsOneWidget);
    expect(find.byKey(const Key('device_mode_child')), findsOneWidget);
    expect(find.byKey(const Key('device_mode_mother')), findsNothing);
    expect(find.text('أنا — وليّ الأمر'), findsOneWidget);
    expect(find.text('ابني'), findsOneWidget);
    // Banner may mention mother; must not appear as a third selectable title.
    expect(find.text('أم'), findsNothing);
    expect(find.textContaining('لا يوجد خيار «أم» هنا'), findsOneWidget);
  });

  testWidgets('guardian card → /scr-fat-001 and role not child', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-007',
      routes: [
        GoRoute(
          path: '/scr-shr-007',
          builder: (context, state) => const DeviceModeScreen(),
        ),
        GoRoute(
          path: '/scr-fat-001',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-001',
            title: 'إنشاء العائلة',
          ),
        ),
      ],
    );
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

    await tester.tap(find.byKey(const Key('device_mode_guardian')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-001');
    expect(role.value, isNot(AppRole.child));
    expect(role.value, AppRole.father);
    expect(find.byType(PlaceholderScreen), findsOneWidget);
  });

  testWidgets('child card → role=child and /scr-chd-001', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-007',
      routes: [
        GoRoute(
          path: '/scr-shr-007',
          builder: (context, state) => const DeviceModeScreen(),
        ),
        GoRoute(
          path: '/scr-chd-001',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-CHD-001',
            title: 'ترحيب الابن',
          ),
        ),
      ],
    );
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

    expect(role.value, AppRole.father);

    await tester.tap(find.byKey(const Key('device_mode_child')));
    await tester.pumpAndSettle();

    expect(role.value, AppRole.child);
    expect(router.state.uri.path, '/scr-chd-001');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
  });
}

Future<void> _pumpDeviceMode(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DeviceModeScreen(),
    ),
  );
  await tester.pumpAndSettle();
}
