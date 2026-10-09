// W5 — the screen-time client, verified against the server's published answers.
//
// These tests do not describe what the client feels like; they pin what it may and may not
// say. Four of them exist because the client could otherwise lie to a family:
//
//   * a state whose reason is a word this build does not know is REFUSED rather than shown
//     as "nothing is in the way" - a screen that renders the opposite of the server is worse
//     than a screen that admits it cannot read the answer;
//   * a body missing `state` or `usage` is refused rather than filled with zeroes, because
//     "0 minutes used" and "we could not read the answer" are different facts;
//   * an update with no fields is refused before a request is sent: it would be a write that
//     changes nothing and a version bump nobody asked for;
//   * unlocking what is not locked comes back as `released: false`, which is an answer, not
//     an error to retry.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _token = 'test-id-token';

/// A transport that answers by method and path, and remembers what it was asked.
///
/// One canned answer per endpoint is not enough here: this surface reads the state, writes a
/// policy and answers a question, and a test that could not tell those apart would be
/// checking the parser rather than the client.
final class _RoutedTransport implements FoundationGateHttpTransport {
  _RoutedTransport(this.responses);

  final Map<String, FoundationGateHttpResponse> responses;
  final List<String> calls = <String>[];
  final List<Map<String, String>> headers = <Map<String, String>>[];
  final List<String> bodies = <String>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}');
    this.headers.add(Map.unmodifiable(headers));
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    this.headers.add(Map.unmodifiable(headers));
    bodies.add(body);
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    this.headers.add(Map.unmodifiable(headers));
    bodies.add(body);
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    this.headers.add(Map.unmodifiable(headers));
    bodies.add(body);
    return _match(uri);
  }

  FoundationGateHttpResponse _match(Uri uri) {
    for (final entry in responses.entries) {
      if (uri.path.endsWith(entry.key)) return entry.value;
    }
    throw StateError('No canned answer for ${uri.path}');
  }
}

FoundationGateConfiguration configuration() =>
    FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );

FamilyScreenTimeApiClient _client(_RoutedTransport transport) =>
    FamilyScreenTimeApiClient(
      configuration: configuration(),
      transport: transport,
    );

/// One honest answer from the server, written the way the server writes it.
String _snapshotJson({
  String kind = 'limited',
  Object? reason = 'daily_limit',
  Object? lock,
  String? openRequest,
  int countableUsedMinutes = 42,
  int grantedMinutes = 0,
  int? remainingMinutes = 18,
  int? capMinutes = 60,
}) =>
    jsonEncode(<String, Object?>{
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
        'version': 3,
        'updatedAt': '2026-10-07T09:00:00.000Z',
      },
      'state': <String, Object?>{
        'kind': kind,
        'reasonCode': reason,
        'since': lock == null ? null : '2026-10-07T12:00:00.000Z',
        'date': '2026-10-07',
        'minuteOfDay': 720,
        'weekday': 3,
        'capMinutes': capMinutes,
        'grantedMinutes': grantedMinutes,
        'countableUsedMinutes': countableUsedMinutes,
        'remainingMinutes': remainingMinutes,
        'lock': lock,
      },
      'lock': lock,
      'usage': <String, Object?>{
        'date': '2026-10-07',
        'countableUsedMinutes': countableUsedMinutes,
        'grantedMinutes': grantedMinutes,
        'remainingMinutes': remainingMinutes,
        'byApp': <Object?>[
          <String, Object?>{'appId': 'com.example.puzzle', 'usedMinutes': 42},
        ],
      },
      'openRequest': openRequest == null ? null : _requestJson(),
    });

Map<String, Object?> _lockJson() => <String, Object?>{
  'id': '33333333-3333-4333-8333-333333333333',
  'reasonCode': 'check_in',
  'lockedAt': '2026-10-07T12:00:00.000Z',
  'lockedByMembershipId': '44444444-4444-4444-8444-444444444444',
  'releasedAt': null,
  'version': 1,
};

Map<String, Object?> _requestJson({
  String status = 'pending',
  int? grantedMinutes,
  String? decidedAt,
}) => <String, Object?>{
  'id': '55555555-5555-4555-8555-555555555555',
  'childId': _childId,
  'usageDate': '2026-10-07',
  'requestedMinutes': 20,
  'requestedByKind': 'child',
  'reasonCode': 'homework_done',
  'status': status,
  'grantedMinutes': grantedMinutes,
  'expiresAt': '2026-10-07T21:00:00.000Z',
  'decidedAt': decidedAt,
  'decidedByMembershipId': null,
  'version': 1,
  'createdAt': '2026-10-07T15:00:00.000Z',
};

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

void main() {
  test('a read carries the state, the policy and today\'s minutes from the server', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(_snapshotJson()),
    });
    final snapshot = await _client(transport).readSnapshot(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );

    expect(
      transport.calls.single,
      'GET /v1/families/$_familyId/children/$_childId/screen-time',
    );
    expect(snapshot.state.kind, FoundationGateScreenStateKind.limited);
    expect(snapshot.state.reason, FoundationGateScreenReason.dailyLimit);
    expect(snapshot.state.remainingMinutes, 18);
    expect(snapshot.countableUsedMinutes, 42);
    expect(snapshot.usageByApp.single.usedMinutes, 42);
    expect(snapshot.policy.configured, isTrue);
    expect(snapshot.policy.dailyLimitMinutes, 60);
    expect(snapshot.policy.schoolDays, <int>[7, 1, 2, 3, 4]);
    expect(snapshot.policy.timezoneOffsetMinutes, 180);
    expect(snapshot.lock, isNull);
    expect(snapshot.openRequest, isNull);
  });

  test('a read carries a bearer token and never an idempotency key', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(_snapshotJson()),
    });
    await _client(transport).readSnapshot(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );
    expect(transport.headers.single['authorization'], 'Bearer $_token');
    expect(transport.headers.single.containsKey('idempotency-key'), isFalse);
  });

  test('an instant lock is read with its author, its reason and the moment it began', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(
        _snapshotJson(
          kind: 'blocked',
          reason: 'instant_lock',
          lock: _lockJson(),
          remainingMinutes: 18,
        ),
      ),
    });
    final snapshot = await _client(transport).readSnapshot(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );
    expect(snapshot.state.kind, FoundationGateScreenStateKind.blocked);
    expect(snapshot.state.reason, FoundationGateScreenReason.instantLock);
    expect(snapshot.state.since, DateTime.utc(2026, 10, 7, 12));
    expect(snapshot.lock?.live, isTrue);
    expect(snapshot.lock?.reasonCode, 'check_in');
    expect(snapshot.state.lock?.lockedAt, snapshot.state.since);
  });

  test('a reason this build does not know is refused, never shown as freedom', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(_snapshotJson(kind: 'blocked', reason: 'someday_mode')),
    });
    await expectLater(
      _client(transport).readSnapshot(
        familyId: _familyId,
        childId: _childId,
        idToken: _token,
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (exception) => exception.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('"nothing is in the way" is the only thing a null reason may mean', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(
        _snapshotJson(kind: 'free', reason: null, remainingMinutes: null, capMinutes: null),
      ),
    });
    final snapshot = await _client(transport).readSnapshot(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );
    expect(snapshot.state.kind, FoundationGateScreenStateKind.free);
    expect(snapshot.state.reason, isNull);
    expect(snapshot.state.capMinutes, isNull);
  });

  test('an answer missing its state is refused rather than filled with zeroes', () async {
    final broken = jsonDecode(_snapshotJson()) as Map<String, Object?>;
    broken.remove('state');
    final transport = _RoutedTransport({
      '/screen-time': _ok(jsonEncode(broken)),
    });
    await expectLater(
      _client(transport).readSnapshot(
        familyId: _familyId,
        childId: _childId,
        idToken: _token,
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
  });

  test('a policy update sends only what changed, and asks for the version it read', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(
        jsonEncode(<String, Object?>{'policy': _policyJson()}),
      ),
    });
    final policy = await _client(transport).updatePolicy(
      familyId: _familyId,
      childId: _childId,
      idempotencyKey: 'w5-policy',
      idToken: _token,
      dailyLimitMinutes: 90,
      expectedVersion: 3,
    );
    expect(transport.calls.single, 'PATCH /v1/families/$_familyId/children/$_childId/screen-time');
    final body = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(body.keys.toSet(), <String>{'dailyLimitMinutes', 'expectedVersion'});
    expect(body['dailyLimitMinutes'], 90);
    expect(transport.headers.single['idempotency-key'], 'w5-policy');
    expect(policy.dailyLimitMinutes, 60);
  });

  test('a bedtime and a school week travel as the shapes the contract publishes', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(jsonEncode(<String, Object?>{'policy': _policyJson()})),
    });
    await _client(transport).updatePolicy(
      familyId: _familyId,
      childId: _childId,
      idempotencyKey: 'w5-bedtime',
      idToken: _token,
      bedtimeStartMinute: 1260,
      bedtimeEndMinute: 360,
      schoolModeEnabled: true,
      schoolDays: <int>[7, 1, 2, 3, 4],
      schoolStartMinute: 420,
      schoolEndMinute: 840,
    );
    final body = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(body.keys.toSet(), <String>{'schoolMode', 'bedtime'});
    expect(body['bedtime'], <String, Object?>{'startMinute': 1260, 'endMinute': 360});
    expect(
      body['schoolMode'],
      <String, Object?>{
        'enabled': true,
        'days': <int>[7, 1, 2, 3, 4],
        'startMinute': 420,
        'endMinute': 840,
      },
    );
  });

  test('an update with nothing in it is refused before a request is sent', () async {
    final transport = _RoutedTransport({
      '/screen-time': _ok(jsonEncode(<String, Object?>{'policy': _policyJson()})),
    });
    await expectLater(
      _client(transport).updatePolicy(
        familyId: _familyId,
        childId: _childId,
        idempotencyKey: 'w5-empty',
        idToken: _token,
      ),
      throwsA(isA<FoundationGateApiException>()),
    );
    expect(
      transport.calls,
      isEmpty,
      reason: 'a write that changes nothing must not reach the server and move a version',
    );
  });

  test('a stale policy is a conflict a screen can explain', () async {
    final transport = _RoutedTransport({
      '/screen-time': const FoundationGateHttpResponse(
        statusCode: 409,
        body: '{"error":{"code":"screen_time_stale_version"}}',
      ),
    });
    await expectLater(
      _client(transport).updatePolicy(
        familyId: _familyId,
        childId: _childId,
        idempotencyKey: 'w5-stale',
        idToken: _token,
        dailyLimitMinutes: 30,
        expectedVersion: 1,
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (exception) => exception.failure,
          'failure',
          FoundationGateApiFailure.conflict,
        ),
      ),
    );
  });

  test('an app rule is written with PUT, and pending is a decision a family can make', () async {
    final transport = _RoutedTransport({
      '/rule': _ok(
        jsonEncode(<String, Object?>{
          'appId': 'com.example.puzzle',
          'knownOnDevice': true,
          'category': 'games',
          'rule': <String, Object?>{
            'status': 'allowed',
            'limitMinutes': 30,
            'unlimited': false,
            'version': 2,
            'updatedAt': '2026-10-07T09:00:00.000Z',
          },
        }),
      ),
    });
    final rule = await _client(transport).setAppRule(
      familyId: _familyId,
      childId: _childId,
      appId: 'com.example.puzzle',
      status: FoundationGateAppRuleStatus.allowed,
      limitMinutes: 30,
      idempotencyKey: 'w5-rule',
      idToken: _token,
    );
    expect(
      transport.calls.single,
      'PUT /v1/families/$_familyId/children/$_childId/apps/com.example.puzzle/rule',
    );
    expect(
      jsonDecode(transport.bodies.single),
      <String, Object?>{'status': 'allowed', 'limitMinutes': 30},
    );
    expect(rule.limitMinutes, 30);
    expect(rule.status, FoundationGateAppRuleStatus.allowed);
  });

  test('the app inventory says what is undecided instead of leaving it blank', () async {
    final transport = _RoutedTransport({
      '/apps': _ok(
        jsonEncode(<String, Object?>{
          'childId': _childId,
          'date': '2026-10-07',
          'state': <String, Object?>{
            'kind': 'limited',
            'reasonCode': null,
            'since': null,
            'date': '2026-10-07',
            'minuteOfDay': 720,
            'weekday': 3,
            'capMinutes': 60,
            'grantedMinutes': 0,
            'countableUsedMinutes': 30,
            'remainingMinutes': 30,
            'lock': null,
          },
          'apps': <Object?>[
            <String, Object?>{
              'appId': 'com.example.puzzle',
              'displayName': 'Puzzle',
              'category': 'games',
              'ageRating': '',
              'knownOnDevice': true,
              'countable': true,
              'usedMinutes': 30,
              'remainingMinutes': null,
              'rule': null,
              'decision': <String, Object?>{'allowed': false, 'reasonCode': 'awaiting_decision'},
            },
            <String, Object?>{
              'appId': 'com.quran.tilawa',
              'displayName': 'تلاوة',
              'category': 'edu',
              'ageRating': '',
              'knownOnDevice': true,
              'countable': false,
              'usedMinutes': 25,
              'remainingMinutes': null,
              'rule': <String, Object?>{
                'status': 'allowed',
                'limitMinutes': null,
                'unlimited': false,
                'version': 1,
                'updatedAt': null,
              },
              'decision': <String, Object?>{'allowed': true, 'reasonCode': null},
            },
          ],
        }),
      ),
    });
    final apps = await _client(transport).listApps(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );
    final undecided = apps.first;
    expect(undecided.rule, isNull);
    expect(undecided.decision.allowed, isFalse);
    expect(undecided.decision.reason, FoundationGateScreenReason.awaitingDecision);
    final education = apps.last;
    expect(education.countable, isFalse);
    expect(education.decision.allowed, isTrue);
    expect(education.displayName, 'تلاوة');
  });

  test('locking returns the state the server computed, not the one that was asked for', () async {
    final transport = _RoutedTransport({
      '/lock': _ok(
        _snapshotJson(kind: 'blocked', reason: 'instant_lock', lock: _lockJson()),
      ),
    });
    final snapshot = await _client(transport).lock(
      familyId: _familyId,
      childId: _childId,
      idempotencyKey: 'w5-lock',
      idToken: _token,
      reasonCode: 'check_in',
    );
    expect(
      jsonDecode(transport.bodies.single),
      <String, Object?>{'reasonCode': 'check_in'},
    );
    expect(snapshot.state.reason, FoundationGateScreenReason.instantLock);
    expect(snapshot.lock?.live, isTrue);
  });

  test('unlocking nothing is an answer, not an error', () async {
    final transport = _RoutedTransport({
      '/unlock': _ok('{"released":false,${_snapshotJson().substring(1)}'),
    });
    final outcome = await _client(transport).unlock(
      familyId: _familyId,
      childId: _childId,
      idempotencyKey: 'w5-unlock',
      idToken: _token,
    );
    expect(outcome.released, isFalse);
    expect(outcome.snapshot.state.kind, FoundationGateScreenStateKind.limited);
  });

  test('a question is listed, asked and answered through the routes the contract names', () async {
    final transport = _RoutedTransport({
      '/time-requests': _ok(
        jsonEncode(<String, Object?>{
          'childId': _childId,
          'requests': <Object?>[_requestJson()],
        }),
      ),
      '/decision': _ok(
        jsonEncode(<String, Object?>{
          'request': _requestJson(
            status: 'approved',
            grantedMinutes: 20,
            decidedAt: '2026-10-07T15:30:00.000Z',
          ),
        }),
      ),
    });
    final client = _client(transport);
    final pending = await client.listTimeRequests(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
      status: 'pending',
    );
    expect(
      transport.calls.first,
      'GET /v1/families/$_familyId/children/$_childId/time-requests?status=pending',
    );
    expect(pending.single.status, FoundationGateTimeRequestStatus.pending);
    expect(pending.single.requestedByKind, 'child');
    expect(pending.single.grantedMinutes, isNull);

    final approved = await client.decideTimeRequest(
      familyId: _familyId,
      childId: _childId,
      requestId: pending.single.id,
      decision: FoundationGateTimeRequestDecision.approve,
      grantedMinutes: 20,
      idempotencyKey: 'w5-decide',
      idToken: _token,
    );
    expect(
      transport.calls.last,
      'POST /v1/families/$_familyId/children/$_childId/time-requests/'
      '${pending.single.id}/decision',
    );
    expect(approved.status, FoundationGateTimeRequestStatus.approved);
    expect(approved.grantedMinutes, 20);
    expect(approved.usageDate, '2026-10-07');
  });

  test('the whole list is asked for without a query parameter', () async {
    final transport = _RoutedTransport({
      '/time-requests': _ok('{"childId":"$_childId","requests":[]}'),
    });
    final requests = await _client(transport).listTimeRequests(
      familyId: _familyId,
      childId: _childId,
      idToken: _token,
    );
    expect(
      transport.calls.single,
      'GET /v1/families/$_familyId/children/$_childId/time-requests',
    );
    expect(requests, isEmpty);
  });

  test('a second question names the first, so a screen shows it instead of an error', () async {
    final transport = _RoutedTransport({
      '/time-requests': const FoundationGateHttpResponse(
        statusCode: 409,
        body:
            '{"error":{"code":"time_request_pending","details":'
            '{"requestId":"55555555-5555-4555-8555-555555555555"}}}',
      ),
    });
    try {
      await _client(transport).requestMinutes(
        familyId: _familyId,
        childId: _childId,
        requestedMinutes: 15,
        idempotencyKey: 'w5-ask',
        idToken: _token,
      );
      fail('a question that is already waiting must be a conflict');
    } on FoundationGateApiException catch (exception) {
      expect(exception.failure, FoundationGateApiFailure.conflict);
      expect(
        FamilyScreenTimeApiClient.openRequestIdFrom(exception),
        '55555555-5555-4555-8555-555555555555',
      );
    }
    // And a conflict without details is not dressed up as one that named a request.
    expect(
      FamilyScreenTimeApiClient.openRequestIdFrom(
        const FoundationGateApiException(FoundationGateApiFailure.conflict),
      ),
      isNull,
    );
    expect(
      FamilyScreenTimeApiClient.openRequestIdFrom(
        const FoundationGateApiException(
          FoundationGateApiFailure.conflict,
          details: <String, Object?>{'requestId': 'not-a-uuid'},
        ),
      ),
      isNull,
    );
  });

  test('the route refuses an app id that is not a package name, before sending anything', () {
    final transport = _RoutedTransport(const {});
    expect(
      () => _client(transport).setAppRule(
        familyId: _familyId,
        childId: _childId,
        appId: '../escape',
        status: FoundationGateAppRuleStatus.blocked,
        idempotencyKey: 'w5-escape',
        idToken: _token,
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty);
  });

  test('a 403 on this surface is access denied, not a retry', () async {
    final transport = _RoutedTransport({
      '/screen-time': const FoundationGateHttpResponse(
        statusCode: 403,
        body: '{"error":{"code":"screen_time_forbidden"}}',
      ),
    });
    await expectLater(
      _client(transport).readSnapshot(
        familyId: _familyId,
        childId: _childId,
        idToken: _token,
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (exception) => exception.failure,
          'failure',
          FoundationGateApiFailure.accessDenied,
        ),
      ),
    );
  });
}

Map<String, Object?> _policyJson() => <String, Object?>{
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
  'version': 4,
  'updatedAt': '2026-10-07T09:05:00.000Z',
};
