// W6 — the filter authority, and the answers it refuses to invent.
//
// The states are the point, exactly as they are for screen time. Any one of them could have
// been smoothed over with a local default, and every one of those defaults would be a lie a
// family acts on:
//
//   * no session          -> nothing is asked, because there is nobody to ask;
//   * access denied       -> refused, and not retried: this account may not see this child;
//   * unreachable         -> nothing on the screen may move, and no shield may be drawn;
//   * a refusal with a reason (a stale policy, a host already waiting, a grant larger than
//     the ask) arrives as a refusal, and the client does not clamp the guardian's number.
//
// The last test is the one this wave exists for: a device that stopped reporting must reach
// the screen as `unverified`, with the silence measured, so no screen in this app can show a
// green dot produced by absence.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n04_web_filter/web_filter_server_authority.dart';
import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _requestId = '55555555-5555-4555-8555-555555555555';

/// A transport that answers one canned response and records what it was asked.
final class _Transport implements FoundationGateHttpTransport {
  _Transport({this.response, this.failure});

  FoundationGateHttpResponse? response;
  Object? failure;
  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  final List<Uri> uris = <Uri>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    uris.add(uri);
    if (failure != null) throw failure!;
    return response!;
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    uris.add(uri);
    bodies.add(body);
    if (failure != null) throw failure!;
    return response!;
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    uris.add(uri);
    bodies.add(body);
    if (failure != null) throw failure!;
    return response!;
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    uris.add(uri);
    bodies.add(body);
    if (failure != null) throw failure!;
    return response!;
  }
}

WebFilterServerAuthority _authorityFor(
  _Transport transport, {
  String? familyId = _familyId,
  String token = 'test-token',
}) => WebFilterServerAuthority(
  api: FamilyWebFilterApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    ),
    transport: transport,
  ),
  idToken: () async => token,
  familyId: () => familyId,
);

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

FoundationGateHttpResponse _created(String body) =>
    FoundationGateHttpResponse(statusCode: 201, body: body);

String policyBody({
  String level = 'balanced',
  List<String> categories = const ['adults', 'gambling', 'violence'],
  List<String> active = const [],
  int version = 3,
}) => jsonEncode(<String, Object?>{
  'policy': <String, Object?>{
    'level': level,
    'enabledCategories': categories,
    'allowHosts': <String>['school.example.com'],
    'blockHosts': <String>['blocked.example.com'],
    'dictionaryKeywords': <String>['casino'],
    'activeTempAllows': active,
    'version': version,
  },
});

String tempAllowBody({
  String state = 'active',
  String status = 'approved',
  int? grantedMinutes = 10,
  String host = 'games.example.com',
}) => jsonEncode(<String, Object?>{
  'request': <String, Object?>{
    'id': _requestId,
    'host': host,
    'status': status,
    'state': state,
    'requestedMinutes': 15,
    'grantedMinutes': grantedMinutes,
    'reason': 'واجب المدرسة',
    'requestedByMembershipId': null,
    'requestedByDeviceId': '66666666-6666-4666-8666-666666666666',
    'decidedByMembershipId': '77777777-7777-4777-8777-777777777777',
    'decidedAt': '2026-10-08T09:00:00.000Z',
    'expiresAt': '2026-10-08T09:10:00.000Z',
    'createdAt': '2026-10-08T08:55:00.000Z',
  },
});

void main() {
  test('a build with no session asks nothing and says why', () async {
    final transport = _Transport(response: _ok(policyBody()));
    final answer = await _authorityFor(
      transport,
      familyId: null,
    ).readPolicy(_childId);
    expect(answer.status, WebFilterAuthorityStatus.notConfigured);
    expect(answer.value, isNull);
    expect(transport.calls, isEmpty, reason: 'there was nobody to ask');
  });

  test('the policy the server states is the policy the screen gets', () async {
    final transport = _Transport(response: _ok(policyBody(active: ['games.example.com'])));
    final answer = await _authorityFor(transport).readPolicy(_childId);
    expect(answer.status, WebFilterAuthorityStatus.ready);
    final policy = answer.value!;
    expect(policy.level, FoundationGateWebFilterLevel.balanced);
    expect(policy.enabledCategories, {
      FoundationGateWebFilterCategory.adults,
      FoundationGateWebFilterCategory.gambling,
      FoundationGateWebFilterCategory.violence,
    });
    expect(policy.blockHosts, ['blocked.example.com']);
    expect(
      policy.activeTempAllows,
      ['games.example.com'],
      reason: 'an open door travels with the policy, or the screen would deny what the '
          'phone is currently allowing',
    );
    expect(policy.version, 3);
    expect(transport.calls.single, 'GET /v1/families/$_familyId/children/$_childId/web-filter');
  });

  test('a category this build cannot name is refused rather than dropped', () async {
    // A screen that silently dropped an unknown key would show a family fewer switches than
    // the server is enforcing - the exact class of lie this wave deletes.
    final transport = _Transport(
      response: _ok(policyBody(categories: ['adults', 'crypto'])),
    );
    final answer = await _authorityFor(transport).readPolicy(_childId);
    expect(answer.status, WebFilterAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('a stale policy arrives as a refusal, not as a silent overwrite', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 409, body: '{}'),
    );
    final answer = await _authorityFor(
      transport,
    ).writePolicy(_childId, categories: {FoundationGateWebFilterCategory.games}, idempotencyKey: () => 'key-1');
    expect(answer.status, WebFilterAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('an empty change is refused here rather than sent as a request that means nothing', () async {
    final transport = _Transport(response: _ok(policyBody()));
    await expectLater(
      _authorityFor(transport).writePolicy(
        _childId,
        idempotencyKey: () => 'key-empty',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (exception) => exception.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(transport.calls, isEmpty);
  });

  test('the change that is sent carries exactly the field that was chosen', () async {
    final transport = _Transport(response: _ok(policyBody()));
    final answer = await _authorityFor(transport).writePolicy(
      _childId,
      categories: {FoundationGateWebFilterCategory.games, FoundationGateWebFilterCategory.streaming},
      expectedVersion: 3,
      idempotencyKey: () => 'key-2',
    );
    expect(answer.status, WebFilterAuthorityStatus.ready);
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent.keys, containsAll(<String>['categories', 'expectedVersion']));
    expect(sent.keys, isNot(contains('allowHosts')), reason: 'an untouched list is not resent');
    expect(sent['expectedVersion'], 3);
  });

  test('a guardian number is never clamped by the client', () async {
    // The server refuses a grant larger than the ask. This client must report that refusal
    // rather than quietly reducing the number a person typed: a screen that changes a
    // guardian's decision is worse than one that reports it.
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 409, body: '{}'),
    );
    final answer = await _authorityFor(transport).decideHost(
      _childId,
      requestId: _requestId,
      approve: true,
      grantedMinutes: 60,
      idempotencyKey: () => 'key-3',
    );
    expect(answer.status, WebFilterAuthorityStatus.refused);
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['grantedMinutes'], 60, reason: 'the number that was chosen is the number that is sent');
  });

  test('a refusal that is an unreachable server moves nothing', () async {
    final transport = _Transport(failure: StateError('socket closed'));
    final answer = await _authorityFor(transport).readPolicy(_childId);
    expect(answer.status, WebFilterAuthorityStatus.unreachable);
    expect(answer.value, isNull);
  });

  test('an access refusal is not retried and not softened', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 403, body: '{}'),
    );
    final answer = await _authorityFor(transport).openQuestions(_childId);
    expect(answer.status, WebFilterAuthorityStatus.accessDenied);
    expect(transport.calls.length, 1, reason: 'a refusal is an answer, not a retry hint');
  });

  test('silence reaches the screen as unverified, with the silence measured', () async {
    final transport = _Transport(
      response: _ok(
        jsonEncode(<String, Object?>{
          'devices': <Object?>[
            <String, Object?>{
              'deviceId': '88888888-8888-4888-8888-888888888888',
              'deviceLabel': 'Amani Android',
              'childId': _childId,
              'state': 'unverified',
              'reason': 'stale_report',
              'since': '2026-10-08T06:00:00.000Z',
              'ageMinutes': 180,
              'detail': '',
              'signals': <String>[],
            },
          ],
          'counts': <String, Object?>{
            'protected': 0,
            'at_risk': 0,
            'unverified': 1,
            'unsupported': 0,
          },
          'freshnessMinutes': 90,
        }),
      ),
    );
    final answer = await _authorityFor(transport).protection();
    expect(answer.status, WebFilterAuthorityStatus.ready);
    final protection = answer.value!;
    expect(protection.unverifiedCount, 1);
    expect(protection.protectedCount, 0, reason: 'nothing said so, so nothing claims it');
    expect(protection.freshnessMinutes, 90);
    final device = protection.devices.single;
    expect(device.state, FoundationGateProtectionState.unverified);
    expect(device.reason, FoundationGateProtectionReason.staleReport);
    expect(device.ageMinutes, 180);
  });

  test('what the handset saw is carried exactly as it said it', () async {
    final transport = _Transport(
      response: _ok(
        jsonEncode(<String, Object?>{
          'devices': <Object?>[
            <String, Object?>{
              'deviceId': '88888888-8888-4888-8888-888888888888',
              'deviceLabel': 'Amani Android',
              'childId': _childId,
              'state': 'at_risk',
              'reason': 'vpn_active',
              'since': '2026-10-08T08:59:00.000Z',
              'ageMinutes': 1,
              'detail': 'VPN v2',
              'signals': <String>['vpn_active', 'proxy_detected'],
            },
          ],
          'counts': <String, Object?>{
            'protected': 0,
            'at_risk': 1,
            'unverified': 0,
            'unsupported': 0,
          },
          'freshnessMinutes': 90,
        }),
      ),
    );
    final device = (await _authorityFor(transport).protection()).value!.devices.single;
    expect(device.state, FoundationGateProtectionState.atRisk);
    expect(device.reason, FoundationGateProtectionReason.vpnActive);
    expect(
      device.signals,
      ['vpn_active', 'proxy_detected'],
      reason: 'a family can act on "a VPN is running"; it cannot act on "at risk"',
    );
  });

  test('the preview asks the server about the host, and answers with the source of denial', () async {
    final transport = _Transport(
      response: _ok(
        jsonEncode(<String, Object?>{
          'allowed': false,
          'denySource': 'category',
          'categoryKey': 'games',
          'policyVersion': 4,
          'normalizedHost': 'games.example.com',
        }),
      ),
    );
    final answer = await _authorityFor(
      transport,
    ).evaluate(_childId, host: 'WWW.Games.example.com');
    expect(answer.status, WebFilterAuthorityStatus.ready);
    final decision = answer.value!;
    expect(decision.allowed, isFalse);
    expect(decision.denySource, FoundationGateWebDenySource.category);
    expect(decision.categoryKey, FoundationGateWebFilterCategory.games);
    expect(decision.policyVersion, 4);
    expect(
      decision.normalizedHost,
      'games.example.com',
      reason: 'the host the server read is the host the screen shows',
    );
    expect(transport.uris.single.queryParameters['host'], 'WWW.Games.example.com');
  });

  test('an open door is read as an allow, and an expired one as the stored approval', () async {
    final open = _Transport(response: _ok(tempAllowBody(state: 'active')));
    final openAnswer = await _authorityFor(open).decideHost(
      _childId,
      requestId: _requestId,
      approve: true,
      idempotencyKey: () => 'key-4',
    );
    expect(openAnswer.value!.state, FoundationGateTempAllowState.active);
    expect(openAnswer.value!.grantedMinutes, 10);

    final expired = _Transport(response: _ok(tempAllowBody(state: 'expired')));
    final expiredAnswer = await _authorityFor(expired).openQuestions(_childId);
    expect(expiredAnswer.value!.single.state, FoundationGateTempAllowState.expired);
    expect(
      expiredAnswer.value!.single.status,
      'approved',
      reason: 'what was stored is an approval; what a screen shows is the clock',
    );
  });

  test('a question asked on a child’s behalf lands on the family path', () async {
    final transport = _Transport(response: _created(tempAllowBody(state: 'pending', status: 'pending', grantedMinutes: null)));
    final answer = await _authorityFor(transport).requestHost(
      _childId,
      host: 'youtube.com',
      minutes: 20,
      reason: 'درس',
      idempotencyKey: () => 'key-5',
    );
    expect(answer.status, WebFilterAuthorityStatus.ready);
    expect(transport.calls.single, 'POST /v1/families/$_familyId/children/$_childId/web-filter/temp-allows');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['host'], 'youtube.com');
    expect(sent['minutes'], 20);
  });
}
