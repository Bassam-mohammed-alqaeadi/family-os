// W7 — the tasks client, verified against the contract it speaks.
//
// Waves 5 and 6 each gave their contract a file of its own, and this one follows them because
// the reason is not tidiness: the client is the only place where a wire answer becomes something
// a family reads, and every claim in this wave is decided there.
//
// What is pinned here, in the order the file reads:
//
//   * the URL and the verb, including the identifier checks the configuration layer performs
//     (a path built from a value the server never issued is refused before a socket is opened);
//   * the idempotency header on every write, because a retried tap must be the same request;
//   * what a 201 without a body is, and what a body with a status this build cannot name is:
//     both are refusals, and the second one is the reason a points screen cannot be trusted to
//     skip a row it does not understand;
//   * the balance is the entries' sum as reported, and a decision returns the balance and the
//     awarded entry alongside the task - three facts the panel draws separately;
//   * the failure mapping (400 / 401 / 403 / 404 / 409 / 429 / anything else) for every verb.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _taskId = '44444444-4444-4444-8444-444444444444';
const _claimId = '66666666-6666-4666-8666-666666666666';
const _membershipId = '77777777-7777-4777-8777-777777777777';
const _entryId = '88888888-8888-4888-8888-888888888888';

final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.answer);

  FoundationGateHttpResponse Function(Uri uri, String? body) answer;
  final List<String> calls = <String>[];
  final List<Map<String, String>> headers = <String, String>[];
  final List<String> bodies = <String>[];

  FoundationGateHttpResponse _reply(Uri uri, String? body) {
    calls.add('${body == null ? 'GET' : 'POST'} ${uri.path}');
    if (body != null) bodies.add(body);
    return answer(uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    this.headers.add(headers);
    return _reply(uri, null);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply(uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply(uri, body);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    this.headers.add(headers);
    return _reply(uri, body);
  }
}

FamilyTasksApiClient _client(_Transport transport) => FamilyTasksApiClient(
  configuration: FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://staging.example.test'),
  ),
  transport: transport,
);

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

FoundationGateHttpResponse _created(String body) =>
    FoundationGateHttpResponse(statusCode: 201, body: body);

Map<String, Object?> _taskJson({Object? claim, String status = 'open'}) =>
    <String, Object?>{
      'id': _taskId,
      'childId': _childId,
      'title': 'ترتيب الغرفة',
      'note': 'الملابس في الخزانة',
      'points': 15,
      'status': status,
      'createdByMembershipId': _membershipId,
      'createdAt': '2026-10-08T06:00:00.000Z',
      'updatedAt': '2026-10-08T06:00:00.000Z',
      'claim': claim,
    };

Map<String, Object?> _claimJson({String status = 'pending'}) => <String, Object?>{
  'id': _claimId,
  'taskId': _taskId,
  'status': status,
  'note': 'خلصت',
  'claimedByDeviceId': null,
  'claimedByMembershipId': _membershipId,
  'decidedByMembershipId': status == 'pending' ? null : _membershipId,
  'decidedAt': status == 'pending' ? null : '2026-10-08T08:00:00.000Z',
  'decisionNote': '',
  'pointsAwarded': status == 'confirmed' ? 15 : null,
  'createdAt': '2026-10-08T07:00:00.000Z',
};

Map<String, Object?> _entryJson() => <String, Object?>{
  'id': _entryId,
  'points': 15,
  'reason': 'task_confirmed',
  'claimId': _claimId,
  'awardedByMembershipId': _membershipId,
  'createdAt': '2026-10-08T08:00:00.000Z',
};

/// Runs [call] and returns the refusal it must produce. A call that succeeds is a failure
/// here: every one of these cases is a server answer this client exists to reject.
Future<FoundationGateApiException> _refusal(
  Future<Object?> Function() call,
) async {
  try {
    await call();
  } on FoundationGateApiException catch (exception) {
    return exception;
  }
  fail('the client accepted an answer it should have refused');
}

void main() {
  test('a task list is read from the child path, with the claim the server reports', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'tasks': <Object?>[_taskJson(claim: _claimJson())],
        }),
      ),
    );

    final tasks = await _client(transport).listTasks(
      familyId: _familyId,
      childId: _childId,
      idToken: 'token',
    );

    expect(transport.calls.single, 'GET /v1/families/$_familyId/children/$_childId/tasks');
    expect(transport.headers.single['authorization'], 'Bearer token');
    expect(tasks.single.claim!.status, FoundationGateTaskClaimStatus.pending);
    expect(
      tasks.single.claim!.pointsAwarded,
      isNull,
      reason: 'a claim that is waiting has no number, and zero would be a number',
    );
  });

  test('a task nobody has touched carries no claim - not a claim in disguise', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'tasks': <Object?>[_taskJson()],
        }),
      ),
    );

    final tasks = await _client(transport).listTasks(
      familyId: _familyId,
      childId: _childId,
      idToken: 'token',
    );

    expect(tasks.single.claim, isNull);
    expect(tasks.single.status, FoundationGateTaskStatus.open);
  });

  test('a task status or a claim status this build cannot name is refused', () async {
    final unknownTask = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'tasks': <Object?>[_taskJson(status: 'suspended')],
        }),
      ),
    );
    await _refusal(
      () => _client(unknownTask).listTasks(
        familyId: _familyId,
        childId: _childId,
        idToken: 'token',
      ),
    );

    final unknownClaim = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'tasks': <Object?>[_taskJson(claim: _claimJson(status: 'appealed'))],
        }),
      ),
    );
    final failure = await _refusal(
      () => _client(unknownClaim).listTasks(
        familyId: _familyId,
        childId: _childId,
        idToken: 'token',
      ),
    );
    expect(failure.failure, FoundationGateApiFailure.invalidResponse);
  });

  test('a body that is not a JSON object, and one without the list, are both refused', () async {
    final arrayBody = _Transport(
      (uri, body) => _ok(jsonEncode(<Object?>[_taskJson()])),
    );
    expect(
      (await _refusal(
        () => _client(arrayBody).listTasks(
          familyId: _familyId,
          childId: _childId,
          idToken: 'token',
        ),
      )).failure,
      FoundationGateApiFailure.invalidResponse,
    );

    final wrongKey = _Transport(
      (uri, body) => _ok(jsonEncode(<String, Object?>{'items': <Object?>[]})),
    );
    expect(
      (await _refusal(
        () => _client(wrongKey).listTasks(
          familyId: _familyId,
          childId: _childId,
          idToken: 'token',
        ),
      )).failure,
      FoundationGateApiFailure.invalidResponse,
    );
  });

  test('a task stated by a guardian carries its number and an idempotency key', () async {
    final transport = _Transport(
      (uri, body) => _created(jsonEncode(<String, Object?>{'task': _taskJson()})),
    );

    await _client(transport).createTask(
      familyId: _familyId,
      childId: _childId,
      title: 'ترتيب الغرفة',
      note: 'الملابس في الخزانة',
      points: 15,
      idempotencyKey: 'key-create',
      idToken: 'token',
    );

    expect(transport.calls.single, 'POST /v1/families/$_familyId/children/$_childId/tasks');
    expect(transport.headers.single['idempotency-key'], 'key-create');
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['title'], 'ترتيب الغرفة');
    expect(sent['points'], 15);
    expect(sent['note'], 'الملابس في الخزانة');
    expect(
      sent.containsKey('status'),
      isFalse,
      reason: 'a task is born open; the client does not get to state its own lifecycle',
    );
  });

  test('a 201 without a task, and a task missing a field, are refused', () async {
    final empty = _Transport((uri, body) => _created('{}'));
    expect(
      (await _refusal(
        () => _client(empty).createTask(
          familyId: _familyId,
          childId: _childId,
          title: 'مهمة',
          points: 5,
          idempotencyKey: 'k',
          idToken: 'token',
        ),
      )).failure,
      FoundationGateApiFailure.invalidResponse,
    );

    final noId = _Transport((uri, body) {
      final task = _taskJson()..['id'] = '';
      return _created(jsonEncode(<String, Object?>{'task': task}));
    });
    expect(
      (await _refusal(
        () => _client(noId).createTask(
          familyId: _familyId,
          childId: _childId,
          title: 'مهمة',
          points: 5,
          idempotencyKey: 'k',
          idToken: 'token',
        ),
      )).failure,
      FoundationGateApiFailure.invalidResponse,
    );
  });

  test('recording a claim sends no number of points, and returns the waiting claim', () async {
    final transport = _Transport(
      (uri, body) => _created(jsonEncode(<String, Object?>{'claim': _claimJson()})),
    );

    final claim = await _client(transport).claimTask(
      familyId: _familyId,
      childId: _childId,
      taskId: _taskId,
      note: 'قال لي إنه أنجزها',
      idempotencyKey: 'key-claim',
      idToken: 'token',
    );

    expect(transport.calls.single, 'POST /v1/families/$_familyId/children/$_childId/tasks/$_taskId/claim');
    expect(claim.status, FoundationGateTaskClaimStatus.pending);
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent.keys.toList(), <String>['note']);
    expect(
      sent.containsKey('points'),
      isFalse,
      reason: 'there is no request in this wave that can carry a number of points',
    );
  });

  test('a claim with no note sends an empty body rather than an empty string', () async {
    final transport = _Transport(
      (uri, body) => _created(jsonEncode(<String, Object?>{'claim': _claimJson()})),
    );

    await _client(transport).claimTask(
      familyId: _familyId,
      childId: _childId,
      taskId: _taskId,
      idempotencyKey: 'key-claim',
      idToken: 'token',
    );

    expect(jsonDecode(transport.bodies.single), isEmpty);
  });

  test('the decision names the answer and the note, and never a number', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'task': _taskJson(claim: _claimJson(status: 'confirmed')),
          'points': <String, Object?>{
            'points': 15,
            'entries': <Object?>[_entryJson()],
          },
          'awarded': _entryJson(),
        }),
      ),
    );

    final decision = await _client(transport).decideTask(
      familyId: _familyId,
      childId: _childId,
      taskId: _taskId,
      confirm: true,
      note: 'أحسنت',
      idempotencyKey: 'key-decision',
      idToken: 'token',
    );

    expect(
      transport.calls.single,
      'POST /v1/families/$_familyId/children/$_childId/tasks/$_taskId/decision',
    );
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['decision'], 'confirm');
    expect(sent['note'], 'أحسنت');
    expect(sent.containsKey('points'), isFalse);
    expect(decision.task.claim!.status, FoundationGateTaskClaimStatus.confirmed);
    expect(decision.points.points, 15);
    expect(decision.awarded!.points, 15);
    expect(decision.awarded!.reason, FoundationGatePointReason.taskConfirmed);
  });

  test('a decline returns no award, and the balance it returns is the one the server holds', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'task': _taskJson(claim: _claimJson(status: 'declined')),
          'points': <String, Object?>{
            'points': 15,
            'entries': <Object?>[_entryJson()],
          },
          'awarded': null,
        }),
      ),
    );

    final decision = await _client(transport).decideTask(
      familyId: _familyId,
      childId: _childId,
      taskId: _taskId,
      confirm: false,
      idempotencyKey: 'key-decision',
      idToken: 'token',
    );

    expect(jsonDecode(transport.bodies.single)['decision'], 'decline');
    expect(decision.awarded, isNull);
    expect(decision.task.claim!.pointsAwarded, isNull);
    expect(decision.points.points, 15, reason: 'a refusal takes nothing away either');
  });

  test('the balance and its entries are read together, and an unknown reason is refused', () async {
    final transport = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'points': 15,
          'entries': <Object?>[_entryJson()],
        }),
      ),
    );
    final points = await _client(transport).readPoints(
      familyId: _familyId,
      childId: _childId,
      idToken: 'token',
    );
    expect(transport.calls.single, 'GET /v1/families/$_familyId/children/$_childId/points');
    expect(points.points, 15);
    expect(points.entries.single.reason, FoundationGatePointReason.taskConfirmed);

    final unknown = _Transport(
      (uri, body) => _ok(
        jsonEncode(<String, Object?>{
          'points': 15,
          'entries': <Object?>[
            <String, Object?>{..._entryJson(), 'reason': 'mystery_bonus'},
          ],
        }),
      ),
    );
    expect(
      (await _refusal(
        () => _client(unknown).readPoints(
          familyId: _familyId,
          childId: _childId,
          idToken: 'token',
        ),
      )).failure,
      FoundationGateApiFailure.invalidResponse,
    );
  });

  test('every refusal the server can send is mapped to the failure a screen can act on', () async {
    final cases = <int, FoundationGateApiFailure>{
      400: FoundationGateApiFailure.invalidInput,
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      404: FoundationGateApiFailure.notFound,
      409: FoundationGateApiFailure.conflict,
      429: FoundationGateApiFailure.serviceUnavailable,
      503: FoundationGateApiFailure.serviceUnavailable,
      500: FoundationGateApiFailure.invalidResponse,
    };

    for (final entry in cases.entries) {
      final transport = _Transport(
        (uri, body) => FoundationGateHttpResponse(
          statusCode: entry.key,
          body: '{}',
        ),
      );
      final failure = await _refusal(
        () => _client(transport).decideTask(
          familyId: _familyId,
          childId: _childId,
          taskId: _taskId,
          confirm: true,
          idempotencyKey: 'k',
          idToken: 'token',
        ),
      );
      expect(failure.failure, entry.value, reason: 'HTTP ${entry.key}');
    }
  });

  test('an identifier the server never issued is refused before a request is made', () async {
    final transport = _Transport(
      (uri, body) => _ok(jsonEncode(<String, Object?>{'tasks': <Object?>[]})),
    );

    await expectLater(
      _client(transport).listTasks(
        familyId: _familyId,
        childId: 'k1',
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    await expectLater(
      _client(transport).claimTask(
        familyId: _familyId,
        childId: _childId,
        taskId: 'not-a-uuid',
        idempotencyKey: 'k',
        idToken: 'token',
      ),
      throwsArgumentError,
    );
    expect(transport.calls, isEmpty, reason: 'nothing was asked, because nothing could be');
  });
}
