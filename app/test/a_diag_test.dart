// TEMP-DIAG (WILL BE REVERTED, do not build on it): ask the tree, not the imagination.
//
// Six panel tests report "Found 0 widgets with key" for keys that are wired in `lib/`, with no
// exception in the log. CI clips everything a stranger could read except the Expected/Actual
// block of a failed expectation - so the facts ride inside one. This file sorts first so its
// event survives the workflow's 12-event window. Deleted the moment it has spoken.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'features/n03_screen_time/support/screen_time_fake_server.dart';

const _panelKey = Key('screen_time_server_panel');
const _probe = <String>[
  'screen_time_server_state_card',
  'screen_time_server_lock_card',
  'screen_time_server_quick_grant_card',
  'screen_time_server_insights_card',
  'screen_time_server_earned_minutes_card',
  'screen_time_server_earned_minutes_toggle',
  'screen_time_server_week_card',
  'screen_time_server_apps_card',
  'screen_time_server_policy_card',
];

Future<String> _pumpAndRead(
  WidgetTester tester, {
  required String kind,
  String? reason,
  required int usedMinutes,
  required int cap,
  required int remaining,
}) async {
  final facts = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    facts.add('${details.exception}'.replaceAll(RegExp(r'\s+'), ' '));
  };
  final transport = ScreenTimeFakeTransport({
    '/screen-time': FoundationGateHttpResponse(
      statusCode: 200,
      body: screenTimeSnapshotJson(
        kind: kind,
        reason: reason,
        usedMinutes: usedMinutes,
        cap: cap,
        remaining: remaining,
      ),
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

  final list = tester.widget<ListView>(find.byKey(_panelKey));
  final count = <String>[
    'e${facts.length}',
    'b${find.byType(AppCard).evaluate().length}',
    't${find.byType(Text).evaluate().length}',
    for (final key in _probe) '${find.byKey(Key(key)).evaluate().length}',
  ];
  var line =
      'cache=${list.scrollCacheExtent} sz='
      '${MediaQuery.sizeOf(tester.element(find.byKey(_panelKey)))} '
      '${count.join(',')}';
  if (facts.isNotEmpty) {
    line = '${line} !! ${facts.first}';
  }
  return line.length <= 300 ? line : line.substring(0, 300);
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('DIAG a day with usage', (tester) async {
    expect(
      await _pumpAndRead(
        tester,
        kind: 'limited',
        usedMinutes: 30,
        cap: 60,
        remaining: 30,
      ),
      isEmpty,
      reason: 'DIAG',
    );
  });

  testWidgets('DIAG a day with no usage', (tester) async {
    expect(
      await _pumpAndRead(
        tester,
        kind: 'limited',
        usedMinutes: 0,
        cap: 60,
        remaining: 60,
      ),
      isEmpty,
      reason: 'DIAG',
    );
  });
}
