// W6 — the web-filter panel, rendered and wired.
//
// This is the acceptance test the wave is judged by, so it renders the real widget over a
// real `WebFilterServerAuthority` talking to a routed transport, and it asserts what a family
// would see. Every test here is a way this screen could lie:
//
//   * with no session bound it shows no policy, only the sentence that says so;
//   * the categories it draws are the server's policy, not the screen's;
//   * flipping a switch sends the write with the version it read, and what appears
//     afterwards is the policy the SERVER returned - so a refusal cannot look like a change;
//   * the preview shows the decision the server made, with the source of denial;
//   * and the protection state never shows "protected" for a device that stopped reporting:
//     it shows unverified WITH the length of the silence, and what the handset observed.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/features/n04_web_filter/web_filter_server_panel.dart';
import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _requestId = '55555555-5555-4555-8555-555555555555';
const _deviceId = '88888888-8888-4888-8888-888888888888';

/// A transport that answers per path and remembers every request it was handed.
final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.responses, {this.patchResponses = const <String, FoundationGateHttpResponse>{}});

  final Map<String, FoundationGateHttpResponse> responses;

  /// Answers for PATCH only, because a real server says different things about the same URL
  /// depending on the verb - a read succeeds while a write is refused, and a test that could
  /// not express that could not test a refusal at all.
  final Map<String, FoundationGateHttpResponse> patchResponses;
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
    return _match(uri, extra: patchResponses);
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

  /// The most specific registered path wins, so `/web-filter/temp-allows` is never answered
  /// by the `/web-filter` entry.
  FoundationGateHttpResponse _match(
    Uri uri, {
    Map<String, FoundationGateHttpResponse> extra = const <String, FoundationGateHttpResponse>{},
  }) {
    final keys = <String>[...extra.keys, ...responses.keys].toList()
      ..sort((left, right) => right.length.compareTo(left.length));
    for (final key in keys) {
      if (uri.path.endsWith(key)) return (extra[key] ?? responses[key])!;
    }
    throw StateError('no response registered for ${uri.path}');
  }
}

String _policyJson({
  List<String> categories = const ['adults', 'gambling', 'violence'],
  List<String> activeAllows = const [],
  int version = 3,
}) => jsonEncode(<String, Object?>{
  'policy': <String, Object?>{
    'level': 'balanced',
    'enabledCategories': categories,
    'allowHosts': <String>['school.example.com'],
    'blockHosts': <String>['blocked.example.com'],
    'dictionaryKeywords': <String>['casino'],
    'activeTempAllows': activeAllows,
    'version': version,
  },
});

String _questionJson({
  String state = 'pending',
  String status = 'pending',
  int? grantedMinutes,
}) => jsonEncode(<String, Object?>{
  'requests': <Object?>[
    <String, Object?>{
      'id': _requestId,
      'host': 'games.example.com',
      'status': status,
      'state': state,
      'requestedMinutes': 15,
      'grantedMinutes': grantedMinutes,
      'reason': 'واجب المدرسة',
      'requestedByMembershipId': null,
      'requestedByDeviceId': _deviceId,
      'decidedByMembershipId': null,
      'decidedAt': null,
      'expiresAt': null,
      'createdAt': '2026-10-08T08:55:00.000Z',
    },
  ],
});

String _protectionJson({
  required String state,
  required String reason,
  int? ageMinutes,
  List<String> signals = const [],
  String since = '2026-10-08T06:00:00.000Z',
}) => jsonEncode(<String, Object?>{
  'devices': <Object?>[
    <String, Object?>{
      'deviceId': _deviceId,
      'deviceLabel': 'Amani Android',
      'childId': _childId,
      'state': state,
      'reason': reason,
      'since': since,
      'ageMinutes': ageMinutes,
      'detail': '',
      'signals': signals,
    },
  ],
  'counts': <String, Object?>{
    'protected': state == 'protected' ? 1 : 0,
    'at_risk': state == 'at_risk' ? 1 : 0,
    'unverified': state == 'unverified' ? 1 : 0,
    'unsupported': state == 'unsupported' ? 1 : 0,
  },
  'freshnessMinutes': 90,
});

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

WebFilterServerAuthority _authority(_Transport transport) =>
    WebFilterServerAuthority(
      api: FamilyWebFilterApiClient(
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
  WebFilterServerAuthority? authority,
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
        body: SingleChildScrollView(
          child: WebFilterServerPanel(
            childId: ChildId(_childId),
            authority: authority,
            canEdit: canEdit,
            idempotencyKey: () => 'w6-widget-key',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

_Transport _healthyTransport({
  List<String> categories = const ['adults', 'gambling', 'violence'],
  String protectionState = 'protected',
  String protectionReason = 'reported_healthy',
  int? ageMinutes = 2,
  List<String> signals = const [],
  String questionState = 'pending',
  String questionStatus = 'pending',
  int? grantedMinutes,
}) => _Transport(<String, FoundationGateHttpResponse>{
  '/decision': _ok(jsonEncode(<String, Object?>{
    'request': <String, Object?>{
      'id': _requestId,
      'host': 'games.example.com',
      'status': 'approved',
      'state': 'active',
      'requestedMinutes': 15,
      'grantedMinutes': 15,
      'reason': '',
      'requestedByMembershipId': null,
      'requestedByDeviceId': _deviceId,
      'decidedByMembershipId': '99999999-9999-4999-8999-999999999999',
      'decidedAt': '2026-10-08T09:00:00.000Z',
      'expiresAt': '2026-10-08T09:15:00.000Z',
      'createdAt': '2026-10-08T08:55:00.000Z',
    },
  })),
  '/web-filter/temp-allows': _ok(_questionJson(
    state: questionState,
    status: questionStatus,
    grantedMinutes: grantedMinutes,
  )),
  '/web-filter': _ok(_policyJson(categories: categories)),
  '/protection': _ok(_protectionJson(
    state: protectionState,
    reason: protectionReason,
    ageMinutes: ageMinutes,
    signals: signals,
  )),
});

void main() {
  tearDown(() => bindWebFilterServerAuthority(null));

  testWidgets('without a session the panel shows no policy at all', (tester) async {
    await _pump(tester, authority: null);

    expect(
      find.byKey(const Key('web_filter_server_notConfigured')),
      findsOneWidget,
      reason: 'a build with nobody to ask must say so',
    );
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsNothing);
    expect(find.byKey(const Key('web_filter_server_protection_card')), findsNothing);
  });

  testWidgets('the filter drawn is the server\'s policy', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: _authority(transport));

    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);
    expect(find.text('محتوى للبالغين'), findsOneWidget);
    expect(find.text('مقامرة'), findsOneWidget);
    // A category the family has not switched on is present as a switch and off.
    final social = tester.widget<SwitchListTile>(
      find.byKey(const Key('web_filter_server_category_social')),
    );
    expect(social.value, isFalse);
    expect(
      find.textContaining('blocked.example.com'),
      findsOneWidget,
      reason: 'the block list the server holds is shown as it is',
    );
    expect(transport.calls, contains('GET /v1/families/$_familyId/children/$_childId/web-filter'));
  });

  testWidgets('flipping a switch sends the field that changed with the version it read', (tester) async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/web-filter/temp-allows': _ok(_questionJson()),
      '/web-filter': _ok(_policyJson()),
      '/protection': _ok(_protectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
    });
    await _pump(tester, authority: _authority(transport));

    await tester.tap(find.byKey(const Key('web_filter_server_category_social')));
    await tester.pumpAndSettle();

    final sent = jsonDecode(transport.bodies.last) as Map<String, Object?>;
    expect(sent['categories'], containsAll(<String>['adults', 'gambling', 'violence', 'social']));
    expect(
      sent['expectedVersion'],
      3,
      reason: 'the version this screen read is the version it sends, so a stale screen is refused',
    );
    expect(
      sent.keys,
      isNot(contains('allowHosts')),
      reason: 'flipping one switch must not resend - and so must not rewrite - the other lists',
    );
  });

  testWidgets('a refused write keeps the last true policy on screen and says so', (tester) async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{
        '/web-filter/temp-allows': _ok(_questionJson()),
        '/web-filter': _ok(_policyJson()),
        '/protection': _ok(_protectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
      },
      patchResponses: <String, FoundationGateHttpResponse>{
        '/web-filter': FoundationGateHttpResponse(statusCode: 409, body: '{}'),
      },
    );
    await _pump(tester, authority: _authority(transport));

    await tester.tap(find.byKey(const Key('web_filter_server_category_social')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_filter_server_refused')), findsOneWidget);
    expect(
      find.byKey(const Key('web_filter_server_policy_card')),
      findsOneWidget,
      reason: 'a refusal must not empty the screen into something that looks like no filter',
    );
  });

  testWidgets('an unreachable server moves nothing, and a silent one claims nothing', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: _authority(transport));
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);

    transport.failure = StateError('socket closed');
    await tester.tap(find.byKey(const Key('web_filter_server_category_social')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_filter_server_unreachable')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_server_policy_card')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('web_filter_server_category_social')),
          )
          .value,
      isFalse,
      reason: 'the switch shows the server\'s last answer, not the tap',
    );
  });

  testWidgets('the preview shows the server\'s decision and the source of denial', (tester) async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/web-filter/temp-allows': _ok(_questionJson()),
      '/web-filter/evaluate': _ok(jsonEncode(<String, Object?>{
        'allowed': false,
        'denySource': 'category',
        'categoryKey': 'games',
        'policyVersion': 3,
        'normalizedHost': 'games.example.com',
      })),
      '/web-filter': _ok(_policyJson()),
      '/protection': _ok(_protectionJson(state: 'protected', reason: 'reported_healthy', ageMinutes: 1)),
    });
    await _pump(tester, authority: _authority(transport));

    await tester.tap(find.byKey(const Key('web_filter_server_preview_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('web_filter_server_preview_verdict')), findsOneWidget);
    expect(find.textContaining('ألعاب الإنترنت محجوبة'), findsOneWidget);
  });

  testWidgets('a device that stopped reporting is unverified, with the silence measured', (tester) async {
    final transport = _healthyTransport(
      protectionState: 'unverified',
      protectionReason: 'stale_report',
      ageMinutes: 180,
    );
    await _pump(tester, authority: _authority(transport));

    expect(
      find.text('لا ندّعي حماية: لا بلاغ حديث من هذا الجهاز.'),
      findsOneWidget,
      reason: 'silence is not health, and this screen is where that law is kept',
    );
    expect(
      find.text('صمت الجهاز منذ 180 دقيقة.'),
      findsOneWidget,
      reason: 'unverified with a number is a fact a parent can act on',
    );
    expect(
      find.text('آخر بلاغ حديث من الجهاز يقول إن الحماية تعمل.'),
      findsNothing,
      reason: 'nothing recently said so, so nothing claims it',
    );
  });

  testWidgets('what the handset observed is named, in the family\'s own words', (tester) async {
    final transport = _healthyTransport(
      protectionState: 'at_risk',
      protectionReason: 'vpn_active',
      ageMinutes: 1,
      signals: const ['vpn_active'],
    );
    await _pump(tester, authority: _authority(transport));

    expect(find.text('الحماية ليست كما ينبغي — راجع ما رصده الجهاز.'), findsOneWidget);
    expect(
      find.text('تطبيق VPN على جهاز الابن'),
      findsOneWidget,
      reason: 'a family can act on "a VPN is running"; it cannot act on "at risk"',
    );
  });

  testWidgets('the child\'s question is answered through the server, and the answer shown is the server\'s', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: _authority(transport));

    expect(find.byKey(const Key('web_filter_server_questions_card')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('web_filter_server_approve_$_requestId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('web_filter_server_approve_$_requestId')));
    await tester.pumpAndSettle();

    expect(
      transport.calls.any((call) => call.startsWith('POST /v1/families/$_familyId/children/$_childId/web-filter/temp-allows/$_requestId/decision')),
      isTrue,
      reason: 'the answer is a server command, not a local flag',
    );
  });

  testWidgets('an expired door reads expired because the clock said so', (tester) async {
    final transport = _healthyTransport(
      questionState: 'expired',
      questionStatus: 'approved',
      grantedMinutes: 10,
    );
    await _pump(tester, authority: _authority(transport));

    expect(
      find.byKey(const Key('web_filter_server_question_state_$_requestId')),
      findsOneWidget,
      reason: 'an answered question shows its state instead of two buttons',
    );
    expect(find.byKey(const Key('web_filter_server_approve_$_requestId')), findsNothing);
  });

  testWidgets('a reader without edit rights is offered no switch to flip', (tester) async {
    final transport = _healthyTransport();
    await _pump(tester, authority: _authority(transport), canEdit: false);

    final social = tester.widget<SwitchListTile>(
      find.byKey(const Key('web_filter_server_category_social')),
    );
    expect(social.onChanged, isNull);
    expect(find.byKey(const Key('web_filter_server_approve_$_requestId')), findsNothing);
  });
}
