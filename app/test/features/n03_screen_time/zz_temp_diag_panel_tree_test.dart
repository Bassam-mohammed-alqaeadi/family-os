// TEMP-DIAG (WILL BE REVERTED): ask the tree, not the imagination.
//
// Six panel tests fail on CI and the annotations clip the exception text, which is the only
// thing that can say *why* a card with a key that exists in `lib/` is not in the element tree.
// This file pumps the panel exactly the way `screen_time_server_panel_test.dart` does, then
// prints one short line per fact: every captured error, and whether each card is present.
// Every line is prefixed so the CI summary's keyword filter keeps it.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

const List<String> _diagPrefix = <String>['Warning: DIAG'];

void _say(String line) {
  for (final piece in line.split('\n')) {
    debugPrint('${_diagPrefix.first} $piece');
  }
}

Future<void> _pumpDiag(WidgetTester tester, ScreenTimeServerAuthority authority) async {
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
          authority: authority,
          canEdit: true,
          idempotencyKey: () => 'diag-key',
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('DIAG panel tree', (tester) async {
    final seen = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      seen.add(
        '${details.exception}\n'
        '${details.informationCollector?.call().join('\n') ?? ''}',
      );
    };
    try {
      final transport = ScreenTimeFakeTransport({
        '/screen-time': FoundationGateHttpResponse(
          statusCode: 200,
          body: screenTimeSnapshotJson(kind: 'limited', reason: null),
        ),
      });
      await _pumpDiag(tester, screenTimeAuthorityFor(transport));
      FlutterError.onError = previous;

      _say('errors=${seen.length}');
      for (var i = 0; i < seen.length; i++) {
        final text = seen[i].replaceAll('\n', ' | ');
        _say('exc[$i]=${text.length > 900 ? text.substring(0, 900) : text}');
      }
      for (final key in <String>[
        'screen_time_server_panel',
        'screen_time_server_state_card',
        'screen_time_server_lock_card',
        'screen_time_server_cap_card',
        'screen_time_server_quick_grant_card',
        'screen_time_server_insights_card',
        'screen_time_server_earned_minutes_card',
        'screen_time_server_earned_minutes_toggle',
        'screen_time_server_week_card',
        'screen_time_server_apps_card',
        'screen_time_server_cap_save',
      ]) {
        final found = find.byKey(Key(key)).evaluate().length;
        _say('key=$key found=$found');
      }
      _say('appcards=${find.byType(AppCard).evaluate().length}');
      final list = find.byType(ListView);
      if (list.evaluate().isNotEmpty) {
        final view = tester.widget<ListView>(list);
        _say(
          'listview children=${view.children?.length} '
          'scrollCacheExtent=${view.scrollCacheExtent}',
        );
      }
      _say('calls=${transport.calls.join(",")}');
    } finally {
      FlutterError.onError = previous;
    }
  });

  testWidgets('DIAG child board tree at textScale 2.0', (tester) async {
    final seen = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      seen.add(
        '${details.exception}\n'
        '${details.informationCollector?.call().join('\n') ?? ''}',
      );
    };
    try {
      final child = ChildId('diag-child');
      final syncBus = PolicySyncBus();
      addTearDown(syncBus.dispose);
      final activationBus = SmartModeActivationBus();
      syncBus.hydrate(
        child,
        policy: ScreenTimePolicy(dailyCapMinutes: 90, usedMinutesToday: 10),
      );
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
            initialPolicy: ScreenTimePolicy(
              dailyCapMinutes: 90,
              usedMinutesToday: 10,
            ),
            showModeNotices: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      FlutterError.onError = previous;

      _say('board errors=${seen.length}');
      for (var i = 0; i < seen.length; i++) {
        final text = seen[i].replaceAll('\n', ' | ');
        _say('board exc[$i]=${text.length > 900 ? text.substring(0, 900) : text}');
      }
      for (final key in <String>[
        'child_day_board_hero_card',
        'child_day_board_hero_ring',
        'child_day_board_status_card',
        'child_day_board_active_mode',
        'child_day_board_routine_card',
        'child_day_board_tasks_card',
        'child_day_board_safety_card',
        'child_day_board_touchpoints_card',
        'child_day_board_remaining',
      ]) {
        _say('board key=$key found=${find.byKey(Key(key)).evaluate().length}');
      }
    } finally {
      FlutterError.onError = previous;
    }
  });
}
