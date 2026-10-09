// W6 — the web-filter test server: a transport that answers per path and per verb, and the
// payloads the server actually returns.
//
// It is shared by the panel tests and the screen-wiring test on purpose: two fakes would
// drift, and the one that drifted would be the one that stopped catching the bug. Two details
// are load-bearing and were learned from the real contract: PATCH says different things about
// the same URL than GET does - a read may succeed while a write is refused - and the most
// specific registered path wins, so `/web-filter/temp-allows` is never answered by the
// `/web-filter` entry.
import 'dart:convert';

import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const webFilterFamilyId = '11111111-1111-4111-8111-111111111111';
const webFilterChildId = '22222222-2222-4222-8222-222222222222';
const webFilterRequestId = '55555555-5555-4555-8555-555555555555';
const webFilterDeviceId = '88888888-8888-4888-8888-888888888888';

/// A transport that answers per path and remembers every request it was handed.
final class WebFilterFakeTransport implements FoundationGateHttpTransport {
  WebFilterFakeTransport(this.responses, {this.patchResponses = const <String, FoundationGateHttpResponse>{}});

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

String webFilterPolicyJson({
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

String webFilterQuestionJson({
  String state = 'pending',
  String status = 'pending',
  int? grantedMinutes,
}) => jsonEncode(<String, Object?>{
  'requests': <Object?>[
    <String, Object?>{
      'id': webFilterRequestId,
      'host': 'games.example.com',
      'status': status,
      'state': state,
      'requestedMinutes': 15,
      'grantedMinutes': grantedMinutes,
      'reason': 'واجب المدرسة',
      'requestedByMembershipId': null,
      'requestedByDeviceId': webFilterDeviceId,
      'decidedByMembershipId': null,
      'decidedAt': null,
      'expiresAt': null,
      'createdAt': '2026-10-08T08:55:00.000Z',
    },
  ],
});

String webFilterProtectionJson({
  required String state,
  required String reason,
  int? ageMinutes,
  List<String> signals = const [],
  String since = '2026-10-08T06:00:00.000Z',
}) => jsonEncode(<String, Object?>{
  'devices': <Object?>[
    <String, Object?>{
      'deviceId': webFilterDeviceId,
      'deviceLabel': 'Amani Android',
      'childId': webFilterChildId,
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

FoundationGateHttpResponse webFilterOk(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

WebFilterServerAuthority webFilterAuthorityFor(WebFilterFakeTransport transport) =>
    WebFilterServerAuthority(
      api: FamilyWebFilterApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'test-token',
      familyId: () => webFilterFamilyId,
    );
