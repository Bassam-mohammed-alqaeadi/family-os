import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n10_emergency/child_sos_button_screen.dart';

void main() {
  testWidgets('child — hint, hold button, always-on banner', (tester) async {
    await _pumpSos(tester, role: AppRole.child);

    expect(find.byKey(ChildSosButtonKeys.screen), findsOneWidget);
    expect(find.byKey(ChildSosButtonKeys.holdButton), findsOneWidget);
    expect(find.byKey(ChildSosButtonKeys.alwaysOnBanner), findsOneWidget);
    expect(find.textContaining('اضغط مطوّلًا'), findsOneWidget);
    expect(find.textContaining('يعمل هذا الزر'), findsOneWidget);
    expect(find.byKey(ChildSosButtonKeys.parentLean), findsNothing);
  });

  testWidgets('early release — cancels without fire', (tester) async {
    final fire = MockSosFireService();
    await _pumpSos(
      tester,
      role: AppRole.child,
      sosFire: fire,
      holdDuration: const Duration(seconds: 3),
    );

    final center = tester.getCenter(find.byKey(ChildSosButtonKeys.holdButton));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pump();

    expect(fire.fireCount, 0);
    expect(find.textContaining('توقفت قبل'), findsOneWidget);
  });

  testWidgets('hold completes → fire + onFired', (tester) async {
    final fire = MockSosFireService();
    var firedNav = false;
    await _pumpSos(
      tester,
      role: AppRole.child,
      sosFire: fire,
      childId: 'child_test_a',
      holdDuration: const Duration(milliseconds: 200),
      holdTick: const Duration(milliseconds: 50),
      onFired: () => firedNav = true,
    );

    final center = tester.getCenter(find.byKey(ChildSosButtonKeys.holdButton));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fire.fireCount, 1);
    expect(firedNav, isTrue);
  });

  testWidgets('hold completes → route /scr-chd-006 with handoff params',
      (tester) async {
    final fire = MockSosFireService();
    final alerts = InMemorySosAlertRepository();
    final role = RoleController(AppRole.child);
    final router = GoRouter(
      initialLocation: '/scr-chd-005',
      routes: [
        GoRoute(
          path: '/scr-chd-005',
          builder: (context, state) => ChildSosButtonScreen(
            childId: 'child_test_a',
            sosFire: fire,
            alerts: alerts,
            holdDuration: const Duration(milliseconds: 150),
            holdTick: const Duration(milliseconds: 50),
          ),
        ),
        GoRoute(
          path: '/scr-chd-006',
          builder: (context, state) => Scaffold(
            body: Text(
              'sos_active '
              'alert=${state.uri.queryParameters['alertId']} '
              'child=${state.uri.queryParameters['childId']}',
            ),
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
    await tester.pump();

    final center = tester.getCenter(find.byKey(ChildSosButtonKeys.holdButton));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fire.fireCount, 1);
    expect(await alerts.loadActive(), isNotNull);
    expect(router.state.uri.path, '/scr-chd-006');
    expect(router.state.uri.queryParameters['childId'], 'child_test_a');
    expect(router.state.uri.queryParameters['alertId'], isNotNull);
    expect(find.textContaining('child=child_test_a'), findsOneWidget);
  });

  testWidgets('father role — parent lean, no hold button', (tester) async {
    await _pumpSos(tester, role: AppRole.father);

    expect(find.byKey(ChildSosButtonKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildSosButtonKeys.holdButton), findsNothing);
  });
}

Future<void> _pumpSos(
  WidgetTester tester, {
  required AppRole role,
  SosFireService? sosFire,
  String childId = 'child_local',
  Duration holdDuration = kChildSosHoldDuration,
  Duration holdTick = kChildSosHoldTick,
  VoidCallback? onFired,
}) async {
  final controller = RoleController(role);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    CurrentRole(
      notifier: controller,
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
        home: ChildSosButtonScreen(
          childId: childId,
          roleOverride: role,
          sosFire: sosFire,
          holdDuration: holdDuration,
          holdTick: holdTick,
          onFired: onFired,
        ),
      ),
    ),
  );
  await tester.pump();
}
