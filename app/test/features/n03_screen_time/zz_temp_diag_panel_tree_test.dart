// TEMP-DIAG (WILL BE REVERTED): ask the tree, not the imagination.
//
// Six panel tests and two board tests report "Found 0 widgets with key" for keys that exist in
// `lib/`, and CI clips the exception text that would say why. Guessing changed nothing, so this
// file pumps both screens exactly as the failing tests do, captures every FlutterError with its
// widget context, and hands the facts back inside a failing expectation - because the only thing
// CI shows a stranger is the `Expected / Actual / Which` block. Deleted once it has spoken.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

String _clip(String s, int at) {
  final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return one.length <= at ? one : one.substring(0, at);
}

void _capture(List<String> into) {
  FlutterError.onError = (FlutterErrorDetails details) {
    final context = details.informationCollector?.call().join(' | ') ?? '';
    into.add('${_clip('${details.exception}', 260)} ## ${_clip(context, 420)}');
  };
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('DIAG panel tree', (tester) async {
    final facts = <String>[];
    final previous = FlutterError.onError;
    _capture(facts);
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
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
        home: Scaffold(
          body: ScreenTimeServerPanel(
            childId: ChildId(screenTimeChildId),
            authority: screenTimeAuthorityFor(transport),
            canEdit: true,
            idempotencyKey: () => 'diag-key',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    FlutterError.onError = previous;

    final keys = <String>[
      'state',
      'lock_card',
      'cap_save',
      'quick_grant_card',
      'insights_card',
      'earned_minutes_card',
      'earned_minutes_toggle',
      'week_card',
      'apps_card',
    ].map((suffix) => 'screen_time_server_$suffix');
    final found = keys
        .map((k) => '${k.substring(18)}=${find.byKey(Key(k)).evaluate().length}')
        .join(',');
    expect(
      _clip(
        'E${facts.length} ${facts.join(' // ')} || $found',
        1000,
      ),
      isEmpty,
      reason: 'DIAG panel facts',
    );
  });

  testWidgets('DIAG child board tree at textScale 2.0', (tester) async {
    final facts = <String>[];
    final previous = FlutterError.onError;
    _capture(facts);
    final child = ChildId('diag-child');
    final syncBus = PolicySyncBus();
    addTearDown(syncBus.dispose);
    final activationBus = SmartModeActivationBus();
    final policy = ScreenTimePolicy(dailyCapMinutes: 90, usedMinutesToday: 10);
    syncBus.hydrate(child, policy: policy);
    activationBus.publish(
      SmartModeActivation(
        childId: child.value,
        active: true,
        modeId: BuiltInModeId.school,
        updatedAt: DateTime.utc(2026, 9, 21),
      ),
    );

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
        builder: (context, nested) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: nested!,
          );
        },
        home: ChildDayBoardScreen(
          childId: child,
          syncBus: syncBus,
          activationBus: activationBus,
          initialPolicy: policy,
          showModeNotices: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    FlutterError.onError = previous;

    final found = <String>[
      'child_day_board_hero_card',
      'child_day_board_hero_ring',
      'child_day_board_status_card',
      'child_day_board_active_mode',
      'child_day_board_routine_card',
      'child_day_board_tasks_card',
      'child_day_board_safety_card',
      'child_day_board_touchpoints_card',
    ].map((k) => '${k.substring(16)}=${find.byKey(Key(k)).evaluate().length}').join(',');
    expect(
      _clip(
        'E${facts.length} ${facts.join(' // ')} || $found',
        1000,
      ),
      isEmpty,
      reason: 'DIAG board facts',
    );
  });
}
