// W5 — the screen-time authority, and the four ways it refuses to guess.
//
// The states are the point. Any one of them could have been smoothed over with a local
// default, and each of those defaults would have been a lie a family acts on:
//
//   * no session          -> nothing is asked, because there is nobody to ask;
//   * access denied       -> refused, and not retried: this account may not see this child;
//   * unreachable         -> the numbers do not move; a screen keeps the last true answer or
//                            shows nothing, and never a freshly invented one;
//   * a question waiting  -> the refusal carries the open question's id, so a parent sees the
//                            question instead of an error they cannot act on.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _requestId = '55555555-5555-4555-8555-555555555555';

/// A transport that answers one canned response per path and remembers whether it was called.
final class _Transport implements FoundationGateHttpTransport {
  _Transport({this.response, this.failure});

  FoundationGateHttpResponse? response;
  Object? failure;
  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
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
    bodies.add(body);
    if (failure != null) throw failure!;
    return response!;
  }
}

ScreenTimeServerAuthority _authorityFor(
  _Transport transport, {
  String? familyId = _familyId,
  String token = 'test-token',
  Future<String> Function()? idToken,
}) => ScreenTimeServerAuthority(
  api: FamilyScreenTimeApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    ),
    transport: transport,
  ),
  idToken: idToken ?? () async => token,
  familyId: () => familyId,
);

String snapshotBody() => jsonEncode(<String, Object?>{
  'childId': _childId,
  'date': '2026-10-07',
  'policy': <String, Object?>{
    'childId': _childId,
    'configured': true,
    'dailyLimitMinutes': 60,
    'schoolMode': <String, Object?>{
      'enabled': false,
      'days': <int>[7, 1, 2, 3, 4],
      'startMinute': 420,
      'endMinute': 840,
    },
    'bedtime': <String, Object?>{'startMinute': 1260, 'endMinute': 360},
    'timezoneOffsetMinutes': 180,
    'version': 2,
    'updatedAt': '2026-10-07T09:00:00.000Z',
  },
  'state': <String, Object?>{
    'kind': 'blocked',
    'reasonCode': 'instant_lock',
    'since': '2026-10-07T12:00:00.000Z',
    'date': '2026-10-07',
    'minuteOfDay': 720,
    'weekday': 3,
    'capMinutes': 60,
    'grantedMinutes': 0,
    'countableUsedMinutes': 30,
    'remainingMinutes': 30,
    'lock': <String, Object?>{
      'id': '33333333-3333-4333-8333-333333333333',
      'reasonCode': 'check_in',
      'lockedAt': '2026-10-07T12:00:00.000Z',
      'lockedByMembershipId': '44444444-4444-4444-8444-444444444444',
      'releasedAt': null,
      'version': 1,
    },
  },
  'lock': <String, Object?>{
    'id': '33333333-3333-4333-8333-333333333333',
    'reasonCode': 'check_in',
    'lockedAt': '2026-10-07T12:00:00.000Z',
    'lockedByMembershipId': '44444444-4444-4444-8444-444444444444',
    'releasedAt': null,
    'version': 1,
  },
  'usage': <String, Object?>{
    'date': '2026-10-07',
    'countableUsedMinutes': 30,
    'grantedMinutes': 0,
    'remainingMinutes': 30,
    'byApp': <Object?>[
      <String, Object?>{'appId': 'com.example.puzzle', 'usedMinutes': 30},
    ],
  },
  'openRequest': null,
});

void main() {
  test('a bound session reads the server state and reports it as ready', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(
        statusCode: 200,
        body: snapshotBody(),
      ),
    );
    final answer = await _authorityFor(transport).read(_childId);
    expect(answer.status, ScreenTimeAuthorityStatus.ready);
    expect(answer.isReady, isTrue);
    expect(answer.value?.state.reason, FoundationGateScreenReason.instantLock);
    expect(answer.value?.countableUsedMinutes, 30);
    expect(answer.value?.lock?.live, isTrue);
  });

  test('a build without a selected family asks nobody and says so', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 200, body: snapshotBody()),
    );
    final answer = await _authorityFor(transport, familyId: null).read(_childId);
    expect(answer.status, ScreenTimeAuthorityStatus.notConfigured);
    expect(answer.value, isNull);
    expect(
      transport.calls,
      isEmpty,
      reason: 'a screen with no session must not send a request to find that out',
    );
  });

  test('a token that cannot be obtained is the same honest answer', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 200, body: snapshotBody()),
    );
    final answer = await _authorityFor(
      transport,
      idToken: () async => throw StateError('signed out'),
    ).read(_childId);
    expect(answer.status, ScreenTimeAuthorityStatus.notConfigured);
    expect(transport.calls, isEmpty);
  });

  test('access denied is refused, not retried, and carries no invented state', () async {
    final transport = _Transport(
      response: const FoundationGateHttpResponse(
        statusCode: 403,
        body: '{"error":{"code":"screen_time_forbidden"}}',
      ),
    );
    final answer = await _authorityFor(transport).read(_childId);
    expect(answer.status, ScreenTimeAuthorityStatus.accessDenied);
    expect(answer.value, isNull);
    expect(transport.calls, hasLength(1));
  });

  test('a server that is configured but silent leaves the screen with no numbers', () async {
    final transport = _Transport(failure: StateError('socket closed'));
    final answer = await _authorityFor(transport).read(_childId);
    expect(answer.status, ScreenTimeAuthorityStatus.unreachable);
    expect(answer.value, isNull);
  });

  test('a refusal with a reason stays a refusal, and does not become a value', () async {
    final transport = _Transport(
      response: const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"screen_time_stale_version"}}',
      ),
    );
    final answer = await _authorityFor(transport).writePolicy(
      _childId,
      dailyLimitMinutes: 90,
      expectedVersion: 1,
      idempotencyKey: () => 'w5-policy',
    );
    expect(answer.status, ScreenTimeAuthorityStatus.refused);
    expect(answer.value, isNull);
    expect(transport.calls.single, 'PATCH /v1/families/$_familyId/children/$_childId/screen-time');
    expect(
      jsonDecode(transport.bodies.single),
      <String, Object?>{'dailyLimitMinutes': 90, 'expectedVersion': 1},
    );
  });

  test('a second question names the first through the authority as well', () async {
    final transport = _Transport(
      response: const FoundationGateHttpResponse(
        statusCode: 409,
        body:
            '{"error":{"code":"time_request_pending","details":{"requestId":"$_requestId"}}}',
      ),
    );
    final answer = await _authorityFor(transport).ask(
      _childId,
      requestedMinutes: 15,
      idempotencyKey: () => 'w5-ask',
    );
    expect(answer.status, ScreenTimeAuthorityStatus.refused);
    expect(answer.openRequestId, _requestId);
  });

  test('locking answers with the state the server computed, lock and all', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(statusCode: 200, body: snapshotBody()),
    );
    final answer = await _authorityFor(transport).lockNow(
      _childId,
      reasonCode: 'check_in',
      idempotencyKey: () => 'w5-lock',
    );
    expect(answer.status, ScreenTimeAuthorityStatus.ready);
    expect(answer.value?.state.reason, FoundationGateScreenReason.instantLock);
    expect(
      transport.calls.single,
      'POST /v1/families/$_familyId/children/$_childId/screen-time/lock',
    );
  });

  test('releasing a lock that was not locked is reported as exactly that', () async {
    final transport = _Transport(
      response: FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"released":false,${snapshotBody().substring(1)}',
      ),
    );
    final answer = await _authorityFor(transport).releaseLock(
      _childId,
      idempotencyKey: () => 'w5-unlock',
    );
    expect(answer.status, ScreenTimeAuthorityStatus.ready);
    expect(answer.value?.released, isFalse);
  });

  test('binding and unbinding moves every screen-time surface together', () {
    expect(activeScreenTimeServerAuthority, isNull);
    final authority = _authorityFor(_Transport());
    bindScreenTimeServerAuthority(authority);
    expect(activeScreenTimeServerAuthority, same(authority));
    bindScreenTimeServerAuthority(null);
    expect(activeScreenTimeServerAuthority, isNull);
  });
}
