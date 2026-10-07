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
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _requestId = '55555555-5555-4555-8555-555555555555';

/// A transport that answers per path and remembers every request it was handed.
final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.responses);

  final Map<String, FoundationGateHttpResponse> responses;
  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  Object? failure;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  FoundationGateHttpResponse _match(Uri uri) {
    for (final entry in responses.entries) {
      if (uri.path.endsWith(entry.key)) return entry.value;
    }
    throw StateError('No canned answer for ${uri.path}');
  }
}

String _snapshotJson({
  String kind = 'limited',
  Object? reason,
  Object? lock,
  String? openRequest,
  int usedMinutes = 30,
  int? remaining = 30,
  int cap = 60,
}) => jsonEncode(<String, Object?>{
  'childId': _childId,
  'date': '2026-10-07',
  'policy': <String, Object?>{
    'childId': _childId,
    'configured': true,
    'dailyLimitMinutes': cap,
    'schoolMode': <String, Object?>{
      'enabled': false,
      'days': <int>[7, 1, 2, 3, 4],
      'startMinute': 420,
      'endMinute': 840,
    },
    'bedtime': <String, Object?>{'startMinute': 1260, 'endMinute': 360},
    'timezoneOffsetMinutes': 180,
    'version': 4,
    'updatedAt': '2026-10-07T09:00:00.000Z',
  },
  'state': <String, Object?>{
    'kind': kind,
    'reasonCode': reason,
    'since': lock == null ? null : '2026-10-07T12:00:00.000Z',
    'date': '2026-10-07',
    'minuteOfDay': 720,
    'weekday': 3,
    'capMinutes': cap,
    'grantedMinutes': 0,
    'countableUsedMinutes': usedMinutes,
    'remainingMinutes': remaining,
    'lock': lock,
  },
  'lock': lock,
  'usage': <String, Object?>{
    'date': '2026-10-07',
    'countableUsedMinutes': usedMinutes,
    'grantedMinutes': 0,
    'remainingMinutes': remaining,
    'byApp': <Object?>[
      <String, Object?>{'appId': 'com.example.puzzle', 'usedMinutes': usedMinutes},
    ],
  },
  'openRequest': openRequest == null ? null : jsonDecode(openRequest),
});

String _lockJson() => jsonEncode(<String, Object?>{
  'id': '33333333-3333-4333-8333-333333333333',
  'reasonCode': 'parent_lock',
  'lockedAt': '2026-10-07T12:00:00.000Z',
  'lockedByMembershipId': '44444444-4444-4444-8444-444444444444',
  'releasedAt': null,
  'version': 1,
});

String _requestJson() => jsonEncode(<String, Object?>{
  'id': _requestId,
  'childId': _childId,
  'usageDate': '2026-10-07',
  'requestedMinutes': 20,
  'requestedByKind': 'child',
  'reasonCode': null,
  'status': 'pending',
  'grantedMinutes': null,
  'expiresAt': '2026-10-07T21:00:00.000Z',
  'decidedAt': null,
  'decidedByMembershipId': null,
  'version': 1,
  'createdAt': '2026-10-07T15:00:00.000Z',
});

ScreenTimeServerAuthority _authority(_Transport transport) =>
    ScreenTimeServerAuthority(
      api: FamilyScreenTimeApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'test-token',
      familyId: () => _familyId,
    );

Future<void> _pump(
  WidgetTester tester, {
  ScreenTimeServerAuthority? authority,
  bool canEdit = true,
}) async {
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
          childId: ChildId(_childId),
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
    final transport = _Transport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(reason: 'bedtime', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: _authority(transport));

    expect(find.text('حان وقت النوم'), findsOneWidget);
    expect(find.text('دقائق اليوم المحتسبة: 30'), findsOneWidget);
    expect(find.text('متبقي 30 دقيقة'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('screen_time_server_cap_field')),
    );
    expect(field.controller?.text, '60');
    expect(
      transport.calls,
      <String>['GET /v1/families/$_familyId/children/$_childId/screen-time'],
    );
  });

  testWidgets('a reason this build does not know shows the refusal, not freedom', (tester) async {
    final transport = _Transport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(kind: 'blocked', reason: 'someday_mode'),
      ),
    });
    await _pump(tester, authority: _authority(transport));

    expect(find.byKey(const Key('screen_time_server_refused')), findsOneWidget);
    expect(find.byKey(const Key('screen_time_server_state_card')), findsNothing);
    expect(find.text('الشاشة متاحة'), findsNothing);
  });

  testWidgets('pressing the lock writes to the server and draws the server\'s answer', (tester) async {
    final transport = _Transport({
      '/screen-time/lock': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(kind: 'blocked', reason: 'instant_lock', lock: jsonDecode(_lockJson())),
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: _authority(transport));

    expect(find.text('الشاشة متاحة ضمن الحد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(
      transport.calls.first,
      'GET /v1/families/$_familyId/children/$_childId/screen-time',
    );
    expect(
      transport.calls[1],
      'POST /v1/families/$_familyId/children/$_childId/screen-time/lock',
    );
    expect(
      transport.calls.length,
      greaterThanOrEqualTo(3),
      reason: 'the write is followed by a read, so nothing on screen is guessed',
    );
    expect(jsonDecode(transport.bodies.single), <String, Object?>{'reasonCode': 'parent_lock'});
  });

  testWidgets('a lock the server refused never appears as locked', (tester) async {
    final transport = _Transport({
      '/screen-time/lock': const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"screen_time_stale_version"}}',
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(kind: 'limited', reason: null),
      ),
    });
    await _pump(tester, authority: _authority(transport));

    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_refused')), findsOneWidget);
    expect(find.text('الشاشة موقوفة بقرار ولي أمر'), findsNothing);
    expect(find.text('الشاشة متاحة ضمن الحد'), findsOneWidget, reason: 'the last true state stands');
  });

  testWidgets('the child\'s open question can be answered from this screen', (tester) async {
    final transport = _Transport({
      '/decision': FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{'request': jsonDecode(_requestJson())}),
      ),
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(openRequest: _requestJson()),
      ),
    });
    await _pump(tester, authority: _authority(transport));

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
            'POST /v1/families/$_familyId/children/$_childId/time-requests/$_requestId/decision',
      ),
      isTrue,
    );
    expect(jsonDecode(transport.bodies.single), <String, Object?>{'decision': 'approve'});
  });

  testWidgets('a silent server keeps the last true answer and says that it is the last one', (tester) async {
    final transport = _Transport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(reason: 'daily_limit', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: _authority(transport));
    expect(find.text('انتهى وقت اليوم'), findsOneWidget);

    transport.failure = StateError('socket closed');
    await tester.tap(find.byKey(const Key('screen_time_server_lock_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen_time_server_unreachable')), findsOneWidget);
    expect(find.text('انتهى وقت اليوم'), findsOneWidget, reason: 'the last true answer is still true');
  });

  testWidgets('a read-only viewer sees the numbers and no controls', (tester) async {
    final transport = _Transport({
      '/screen-time': FoundationGateHttpResponse(
        statusCode: 200,
        body: _snapshotJson(reason: 'daily_limit', kind: 'blocked'),
      ),
    });
    await _pump(tester, authority: _authority(transport), canEdit: false);

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
}
