import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/active_call_repository.dart';
import 'package:family_os/features/n02_day/child_active_call_mock.dart';
import 'package:family_os/features/n02_day/child_active_call_screen.dart';

void main() {
  testWidgets('SCR-CHD-009 body + mute/speaker/end', (tester) async {
    var ended = false;
    await _pump(
      tester,
      callId: 'call_father',
      repo: InMemoryActiveCallRepository(initial: ChildActiveCallMock.all),
      onEnd: () => ended = true,
    );
    await tester.pump();

    expect(find.byKey(ChildActiveCallKeys.body), findsOneWidget);
    expect(find.byKey(ChildActiveCallKeys.peerLabel), findsOneWidget);
    expect(find.text('أب ١'), findsOneWidget);

    await tester.tap(find.byKey(ChildActiveCallKeys.mute));
    await tester.pump();
    await tester.tap(find.byKey(ChildActiveCallKeys.speaker));
    await tester.pump();
    await tester.tap(find.byKey(ChildActiveCallKeys.end));
    await tester.pump();
    expect(ended, isTrue);
  });

  testWidgets('SCR-CHD-009 missing callId', (tester) async {
    await _pump(tester, callId: null, repo: InMemoryActiveCallRepository());
    await tester.pump();
    expect(find.byKey(ChildActiveCallKeys.missingId), findsOneWidget);
  });

  testWidgets('SCR-CHD-009 parent lean', (tester) async {
    await _pump(
      tester,
      callId: 'call_father',
      role: AppRole.father,
      repo: InMemoryActiveCallRepository(initial: ChildActiveCallMock.all),
    );
    await tester.pump();
    expect(find.byKey(ChildActiveCallKeys.parentLean), findsOneWidget);
  });

  test('SCR-CHD-009 mock has no planted names', () {
    for (final c in ChildActiveCallMock.all) {
      expect(c.peerLabel.contains('عبدالله'), isFalse);
      expect(c.peerLabel.contains('خالد'), isFalse);
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ActiveCallRepository repo,
  String? callId,
  AppRole role = AppRole.child,
  VoidCallback? onEnd,
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
        home: ChildActiveCallScreen(
          callId: callId,
          repository: repo,
          roleOverride: role,
          onEnd: onEnd,
        ),
      ),
    ),
  );
}
