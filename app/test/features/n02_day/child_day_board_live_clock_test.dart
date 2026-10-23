// S3 polish — the child's number is alive.
//
// A countdown that only moves when a network call finishes is a number that lies by
// standing still. These tests pin the three ways it is allowed to move: one minute at a
// time between reads, a pull that measures before it reads, and a day that ends while the
// child is still looking at the screen.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_mode_prefs.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/foundation_gate/child_screen_time_report_client.dart';
import 'package:family_os/foundation_gate/child_screen_time_state_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

final _child = ChildId(SmartModePrefs.defaultChildId);

/// The paired handset's own state, as a transport this test controls.
final class _StateTransport implements ChildScreenTimeStateTransport {
  int reads = 0;

  /// What the server says today. The test changes it between reads.
  int remaining = 30;

  @override
  Future<FoundationGateHttpResponse> readState() async {
    reads++;
    return FoundationGateHttpResponse(
      statusCode: 200,
      body: jsonEncode(<String, Object?>{
        'date': '2026-10-23',
        'policy': <String, Object?>{'earnedMinutesExtendLimit': false},
        'state': <String, Object?>{
          'kind': 'limited',
          'reasonCode': 'daily_limit',
          'remainingMinutes': remaining,
          'capMinutes': 60,
          'countableUsedMinutes': 60 - remaining,
          'grantedMinutes': 0,
        },
      }),
    );
  }
}

final class _CountingReporter implements ChildScreenTimeReportTransport {
  int reports = 0;

  @override
  Future<UsageSnapshot> snapshot() async {
    reports++;
    return const UsageSnapshot(
      permissionGranted: true,
      apps: <AppUsageSample>[],
    );
  }

  @override
  Future<bool> openUsageAccessSettings() async => true;

  @override
  Future<FoundationGateHttpResponse> postUsage({
    required String body,
    required String idempotencyKey,
  }) async => const FoundationGateHttpResponse(statusCode: 201, body: '{}');
}

Widget _wrap(Widget home) => MaterialApp(
  theme: buildFamilyTheme(),
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

Future<void> _pump(
  WidgetTester tester, {
  required _StateTransport state,
  required _CountingReporter reporter,
  required DateTime Function() clock,
}) async {
  await tester.pumpWidget(
    _wrap(
      ChildDayBoardScreen(
        childId: _child,
        syncBus: PolicySyncBus(),
        activationBus: SmartModeActivationBus(),
        serverScreenTime: ChildScreenTimeStateClient(transport: state),
        usageReporter: ChildScreenTimeReportClient(transport: reporter),
        clock: clock,
        showModeNotices: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _remainingText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ChildDayBoardKeys.remainingMinutes)).data!;

void main() {
  testWidgets('the countdown moves one minute at a time between reads',
      (tester) async {
    var now = DateTime(2026, 10, 23, 9, 0);
    final state = _StateTransport()..remaining = 30;
    await _pump(
      tester,
      state: state,
      reporter: _CountingReporter(),
      clock: () => now,
    );

    expect(_remainingText(tester), contains('30'));

    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(
      _remainingText(tester),
      contains('29'),
      reason: 'a minute passed in the child\'s hands, not only on the server',
    );

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(minutes: 1));
    expect(_remainingText(tester), contains('26'));
  });

  testWidgets('a stale count never goes below zero', (tester) async {
    var now = DateTime(2026, 10, 23, 9, 0);
    final state = _StateTransport()..remaining = 2;
    await _pump(
      tester,
      state: state,
      reporter: _CountingReporter(),
      clock: () => now,
    );

    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(minutes: 1));

    expect(_remainingText(tester), contains('0'));
    expect(_remainingText(tester), isNot(contains('-')));
  });

  testWidgets('pulling down measures first, then reads', (tester) async {
    final state = _StateTransport();
    final reporter = _CountingReporter();
    await _pump(
      tester,
      state: state,
      reporter: reporter,
      clock: () => DateTime(2026, 10, 23, 12, 0),
    );
    final reportsBefore = reporter.reports;
    final readsBefore = state.reads;

    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 320),
      1000,
    );
    await tester.pumpAndSettle();

    expect(reporter.reports, greaterThan(reportsBefore));
    expect(state.reads, greaterThan(readsBefore));
  });

  testWidgets('midnight under an open screen asks the server again',
      (tester) async {
    var now = DateTime(2026, 10, 23, 23, 59);
    final state = _StateTransport();
    await _pump(
      tester,
      state: state,
      reporter: _CountingReporter(),
      clock: () => now,
    );
    final readsBefore = state.reads;

    // The clock rolls over, and the tick a minute later is what notices.
    now = DateTime(2026, 10, 24, 0, 0);
    state.remaining = 60;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(
      state.reads,
      greaterThan(readsBefore),
      reason: 'a new day is the server\'s to declare, not the screen\'s to reset',
    );
    expect(_remainingText(tester), contains('60'));
  });
}
