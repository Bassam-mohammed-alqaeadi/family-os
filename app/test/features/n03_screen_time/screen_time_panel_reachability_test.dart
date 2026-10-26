// SCR-FAT-032 · reachability, which is the same thing as existence.
//
// The guardian panel is a fixed set of decisions — eight cards, in the order a parent works
// through them: what is true now, what to do about it now, then the rules. A list that builds
// only what fits its viewport is the reason this test exists: on a short surface the lower half
// of the panel was not scrolled-out-of-view, it was not built, and a card that is not built is
// invisible to a screen reader, unreachable by `ensureVisible`, and simply missing for the
// parent who arrived from a notification tapping "review the request".
//
// So the assertion is deliberately blunt: every card key must be in the tree, on a 390×844
// phone at textScale 2.0 and on a 320×480 surface at 1.3 — the smallest configurations this app
// claims to support. When it fails, the reason line carries the counts, because "Found 0 widgets"
// on its own has already cost this repo three wrong diagnoses.
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

import 'support/screen_time_fake_server.dart';

/// Every card and control the panel owes a guardian, in the order they are drawn.
const _owed = <String>[
  'screen_time_server_state_card',
  'screen_time_server_lock_card',
  'screen_time_server_lock_button',
  'screen_time_server_policy_card',
  'screen_time_server_cap_field',
  'screen_time_server_cap_save',
  'screen_time_server_quick_grant_card',
  'screen_time_server_custom_grant',
  'screen_time_server_insights_card',
  'screen_time_server_insights_open_apps',
  'screen_time_server_earned_minutes_card',
  'screen_time_server_earned_minutes_toggle',
  'screen_time_server_week_card',
  'screen_time_server_apps_card',
];

String _facts(WidgetTester tester) {
  final present = <String>[
    for (final key in _owed)
      if (find.byKey(Key(key)).evaluate().isEmpty) key,
  ];
  return 'cards built=${find.byType(AppCard).evaluate().length} '
      'missing=${present.isEmpty ? 'none' : present.join(',')}';
}

Future<void> _pumpOn(
  WidgetTester tester, {
  required Size surface,
  required double textScale,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final transport = ScreenTimeFakeTransport({
    '/screen-time': FoundationGateHttpResponse(
      statusCode: 200,
      body: screenTimeSnapshotJson(
        kind: 'limited',
        reason: null,
        usedMinutes: 30,
        cap: 60,
        remaining: 30,
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ScreenTimeServerPanel(
          childId: ChildId(screenTimeChildId),
          authority: screenTimeAuthorityFor(transport),
          canEdit: true,
          idempotencyKey: () => 'reachability-key',
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('a parent on a phone at large text is shown the whole panel', (
    tester,
  ) async {
    await _pumpOn(tester, surface: const Size(390, 844), textScale: 2.0);

    for (final key in _owed) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: _facts(tester));
    }
    // The scroll view itself is asserted too: a pull-to-refresh gesture finds it by key, and
    // a panel that is not scrollable on a 390-pt phone is a panel with unreachable decisions.
    expect(
      find.byKey(const Key('screen_time_server_panel')),
      findsOneWidget,
      reason: _facts(tester),
    );
  });

  testWidgets('the smallest supported surface still holds every decision', (
    tester,
  ) async {
    await _pumpOn(tester, surface: const Size(320, 480), textScale: 1.3);

    for (final key in _owed) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: _facts(tester));
    }
    // Nothing here may be scrolled into existence by the test: the point is that the widgets
    // exist without scrolling, which is what a screen reader and a notification deep-link need.
    expect(tester.takeException(), isNull, reason: _facts(tester));
  });
}
