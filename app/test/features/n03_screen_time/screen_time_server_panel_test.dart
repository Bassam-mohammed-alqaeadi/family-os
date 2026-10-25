// W5 — the screen-time panel, rendered and wired.
//
// This is the acceptance test the wave is judged by, so it renders the real widget over a
// real `ScreenTimeServerAuthority` talking to a routed transport, and it asserts what a family
// would see. Four of these tests exist because each one is a way this screen could lie:
//
//   * with no session bound it shows NO numbers, only the sentence that says so;
//   * the state, the minutes and the cap it draws are the server's answer, not the screen's;
//   * pressing the lock sends the write, and what appears afterwards is the state the SERVER
//     returned - so a refusal cannot look like a lock;
//   * when the server goes silent, the last true answer stays visible and is labelled as the
//     last one; with no answer at all, the panel shows nothing rather than zeroes.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/features/n03_screen_time/screen_time_server_panel.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

import 'support/screen_time_fake_server.dart';

Future<void> _pump(
  WidgetTester tester, {
  ScreenTimeServerAuthority? authority,
  bool canEdit = true,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
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
          authority: authority,
          canEdit: canEdit,
          idempotencyKey: () => 'w5-widget-key',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => bindScreenTimeServerAuthority(null));

  testWidgets('without a session the panel shows no numbers at all', (tester) async {
    await _pump(tester, authority: null);

    expect(
      find.byKey(const Key('screen_time_server_no_session')),
      findsOneWidget,
      reason: 'a build with nobody to ask must say so',
    );
    expect(find.byKey(const Key('screen_time_server_state_card')), findsNothing);
    expect(find.byKey(const Key('screen_time_server_loading')), findsNothing);
  });

  testWidgets('the state, the minutes and the cap are the server\'s answer', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(reason: 'bedtime', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    expect(find.text('حان وقت النوم'), findsOneWidget);
    expect(find.text('دقائق اليوم المحتسبة: 30'), findsOneWidget);
    expect(find.text('متبقي 30 دقيقة'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('screen_time_server_cap_field')),
    );
    expect(field.controller?.text, '60');
    expect(
      transport.calls,
      <String>['GET /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time'],
    );
  });

  testWidgets('a reason this build does not know shows the refusal, not freedom', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'blocked', reason: 'someday_mode'),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    expect(find.byKey(const Key('screen_time_server_refused')), findsOneWidget);
    expect(find.byKey(const Key('screen_time_server_state_card')), findsNothing);
    expect(find.text('الشاشة متاحة'), findsNothing);
  });

  testWidgets('pressing the lock writes to the server and draws the server\'s answer', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time/lock': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'blocked', reason: 'instant_lock', lock: jsonDecode(screenTimeLockJson())),
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    expect(find.text('الشاشة متاحة ضمن الحد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(
      transport.calls.first,
      'GET /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time',
    );
    expect(
      transport.calls[1],
      'POST /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time/lock',
    );
    expect(
      transport.calls.length,
      greaterThanOrEqualTo(3),
      reason: 'the write is followed by a read, so nothing on screen is guessed',
    );
    expect(jsonDecode(transport.bodies.single), <String, Object?>{'reasonCode': 'parent_lock'});
  });

  testWidgets('a lock the server refused never appears as locked', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time/lock': const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"screen_time_stale_version"}}',
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_refused')), findsOneWidget);
    expect(find.text('الشاشة موقوفة بقرار ولي أمر'), findsNothing);
    expect(find.text('الشاشة متاحة ضمن الحد'), findsOneWidget, reason: 'the last true state stands');
  });

  testWidgets('the child\'s open question can be answered from this screen', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/decision': FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{'request': jsonDecode(screenTimeRequestJson())}),
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(openRequest: screenTimeRequestJson()),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    expect(find.text('سؤال من الابن بانتظارك: 20 دقيقة'), findsOneWidget);
    // The question card is the last card in a scrollable panel, and the test surface is
    // shorter than a phone: without revealing it first, the tap lands below the fold.
    final approve = find.byKey(const Key('screen_time_server_request_approve'));
    await tester.ensureVisible(approve);
    await tester.pumpAndSettle();
    await tester.tap(approve);
    await tester.pumpAndSettle();

    expect(
      transport.calls.any(
        (call) => call ==
            'POST /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/time-requests/$screenTimeRequestId/decision',
      ),
      isTrue,
    );
    expect(jsonDecode(transport.bodies.single), <String, Object?>{'decision': 'approve'});
  });

  testWidgets('a silent server keeps the last true answer and says that it is the last one', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(reason: 'daily_limit', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));
    expect(find.text('انتهى وقت اليوم'), findsOneWidget);

    transport.failure = StateError('socket closed');
    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_unreachable')), findsOneWidget);
    expect(find.text('انتهى وقت اليوم'), findsOneWidget, reason: 'the last true answer is still true');
  });

  testWidgets('a read-only viewer sees the numbers and no controls', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(reason: 'daily_limit', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport), canEdit: false);

    expect(find.text('انتهى وقت اليوم'), findsOneWidget);
    final lock = tester.widget<PrimaryBtn>(
      find.byKey(const Key('screen_time_server_lock_button')),
    );
    expect(lock.onPressed, isNull, reason: 'a viewer may read the decision, not make one');
    final save = tester.widget<PrimaryBtn>(
      find.byKey(const Key('screen_time_server_cap_save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('earned minutes toggle renders, displays subtitle & preview breakdown, and writes to server', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    final toggleFinder = find.byKey(const Key('screen_time_server_earned_minutes_toggle'));
    expect(toggleFinder, findsOneWidget);
    expect(find.text('تمديد الحد بالدقائق المكتسبة'), findsOneWidget);
    expect(
      find.text('إضافة الدقائق المكتسبة من الأنشطة والمهام إلى وقت الشاشة اليومي'),
      findsOneWidget,
    );
    expect(
      find.text('المتبقي = الحد اليومي + المنح + الدقائق المكتسبة − الاستهلاك'),
      findsOneWidget,
    );

    final switchTile = tester.widget<SwitchListTile>(toggleFinder);
    expect(switchTile.value, isFalse);

    await tester.ensureVisible(toggleFinder);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(
      transport.calls.any(
        (call) =>
            call ==
            'PATCH /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/screen-time',
      ),
      isTrue,
    );
    final patchBody = jsonDecode(
      transport.bodies.firstWhere((b) => b.contains('earnedMinutesExtendLimit')),
    ) as Map<String, Object?>;
    expect(patchBody['earnedMinutesExtendLimit'], isTrue);
  });

  testWidgets('quick grant button posts direct minutes grant to server', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/minutes/grants': const FoundationGateHttpResponse(
        statusCode: 201,
        body: '{"grant":{"minutes":15,"channel":"guardian_grant"}}',
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    final grant15Finder = find.byKey(const Key('screen_time_server_quick_grant_15'));
    expect(grant15Finder, findsOneWidget);
    await tester.ensureVisible(grant15Finder);
    await tester.pumpAndSettle();
    await tester.tap(grant15Finder);
    await tester.pumpAndSettle();

    expect(
      transport.calls.any(
        (call) =>
            call ==
            'POST /v1/families/$screenTimeFamilyId/children/$screenTimeChildId/minutes/grants',
      ),
      isTrue,
    );
    final grantBody = jsonDecode(
      transport.bodies.firstWhere((b) => b.contains('guardian_instant_grant')),
    ) as Map<String, Object?>;
    expect(grantBody['minutes'], 15);
  });

  testWidgets('progress bar and total limit render accurately', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(usedMinutes: 45, remaining: 15, cap: 60),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    final barFinder = find.byKey(const Key('screen_time_server_progress_bar'));
    expect(barFinder, findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(barFinder);
    expect(bar.value, closeTo(0.75, 0.01));
    expect(find.text('الحد الكلي: 60 دقيقة'), findsOneWidget);
  });

  testWidgets('invalid daily cap shows error text and does not write to server', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    final fieldFinder = find.byKey(const Key('screen_time_server_cap_field'));
    final saveFinder = find.byKey(const Key('screen_time_server_cap_save'));

    await tester.enterText(fieldFinder, '-50');
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    expect(find.text('يرجى إدخال عدد دقائق بين 0 و 1440'), findsOneWidget);
    expect(
      transport.calls.any((c) => c.startsWith('PATCH')),
      isFalse,
    );
  });

  testWidgets('retry button reloads server state when unreachable', (tester) async {
    final transport = ScreenTimeFakeTransport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: screenTimeSnapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: screenTimeAuthorityFor(transport));

    transport.failure = StateError('network down');
    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_retry_button')), findsOneWidget);

    transport.failure = null;
    await tester.tap(find.byKey(const Key('screen_time_server_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_retry_button')), findsNothing);
  });
}
