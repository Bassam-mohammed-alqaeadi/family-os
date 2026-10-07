// W7 — the tasks authority, and the words it refuses to invent.
//
// The statuses are the same five waves 4, 5 and 6 settled on, and they matter more here than
// anywhere before, because a points balance is a promise to a child:
//
//   * no session        -> nothing is asked, because there is nobody to ask;
//   * access denied     -> refused, and not retried: this account may not see this child;
//   * unreachable       -> nothing on the screen may move, and no total may be drawn;
//   * a refusal with a   reason (a claim already waiting, a claim already answered, a task
//     that was withdrawn) arrives as a refusal the screen shows as it is;
//   * and a status, a reason or a category this build cannot name is refused rather than
//     dropped, because a silently-dropped row on a points screen is a number nobody can
//     account for.
//
// Two laws are asserted here rather than assumed: claiming returns a CLAIM (which has no
// points on it), and the decision request carries no number of points - the task does.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _taskId = '44444444-4444-4444-8444-444444444444';
const _claimId = '55555555-5555-4555-8555-555555555555';
const _membershipId = '66666666-6666-4666-8666-666666666666';

/// A transport that answers per path and verb, and records what it was asked.
final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.responses, {this.postResponses = const <String, FoundationGateHttpResponse>{}});

  final Map<String, FoundationGateHttpResponse> responses;

  /// Answers for POST only: a real server says different things about the same URL depending
  /// on the verb, and a test that could not express that could not test a refusal.
  final Map<String, FoundationGateHttpResponse> postResponses;
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
    return _match(uri, extra: postResponses);
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

  /// The most specific registered path wins, so `/tasks/{id}/claim` is never answered by
  /// the `/tasks` entry beside it.
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

FoundationGateHttpResponse _ok(String body) =>
    FoundationGateHttpResponse(statusCode: 200, body: body);

FoundationGateHttpResponse _created(String body) =>
    FoundationGateHttpResponse(statusCode: 201, body: body);

FoundationGateHttpResponse _status(int code) =>
    FoundationGateHttpResponse(statusCode: code, body: '{}');

TasksServerAuthority _authorityFor(
  _Transport transport, {
  String? familyId = _familyId,
  String token = 'test-token',
}) => TasksServerAuthority(
  api: FamilyTasksApiClient(
    configuration: FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    ),
    transport: transport,
  ),
  idToken: () async => token,
  familyId: () => familyId,
);

Map<String, Object?> taskJson({
  String status = 'open',
  Object? claim,
  int points = 15,
}) => <String, Object?>{
  'id': _taskId,
  'childId': _childId,
  'title': 'ترتيب الغرفة',
  'note': 'الملابس في الخزانة',
  'points': points,
  'status': status,
  'createdByMembershipId': _membershipId,
  'createdAt': '2026-10-08T06:00:00.000Z',
  'updatedAt': '2026-10-08T06:00:00.000Z',
  'claim': claim,
};

Map<String, Object?> claimJson({
  String status = 'pending',
  int? pointsAwarded,
  String decisionNote = '',
}) => <String, Object?>{
  'id': _claimId,
  'taskId': _taskId,
  'status': status,
  'note': 'خلصت',
  'claimedByDeviceId': '77777777-7777-4777-8777-777777777777',
  'claimedByMembershipId': null,
  'decidedByMembershipId': pointsAwarded == null ? null : _membershipId,
  'decidedAt': pointsAwarded == null ? null : '2026-10-08T08:00:00.000Z',
  'decisionNote': decisionNote,
  'pointsAwarded': pointsAwarded,
  'createdAt': '2026-10-08T07:00:00.000Z',
};

Map<String, Object?> entryJson({int points = 15}) => <String, Object?>{
  'id': '99999999-9999-4999-8999-999999999999',
  'points': points,
  'reason': 'task_confirmed',
  'claimId': _claimId,
  'awardedByMembershipId': _membershipId,
  'createdAt': '2026-10-08T08:00:00.000Z',
};

String taskListBody({Object? claim}) => jsonEncode(<String, Object?>{
  'tasks': <Object?>[taskJson(claim: claim)],
});

String pointsBody({int points = 0, List<Object?> entries = const []}) =>
    jsonEncode(<String, Object?>{'points': points, 'entries': entries});

void main() {
  test('a build with no session asks nothing and says why', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/tasks': _ok(taskListBody()),
    });
    final answer = await _authorityFor(transport, familyId: null).listTasks(_childId);
    expect(answer.status, TasksAuthorityStatus.notConfigured);
    expect(answer.value, isNull);
    expect(transport.calls, isEmpty, reason: 'there was nobody to ask');
  });

  test('the tasks the server states are the tasks the screen gets', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/tasks': _ok(taskListBody()),
    });
    final answer = await _authorityFor(transport).listTasks(_childId);
    expect(answer.status, TasksAuthorityStatus.ready);
    final task = answer.value!.single;
    expect(task.title, 'ترتيب الغرفة');
    expect(task.points, 15);
    expect(task.status, FoundationGateTaskStatus.open);
    expect(
      task.claim,
      isNull,
      reason: 'nobody has said anything yet - which is not the same as "claimed"',
    );
    expect(transport.calls.single, 'GET /v1/families/$_familyId/children/$_childId/tasks');
  });

  test('a task status this build cannot name is refused rather than drawn', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/tasks': _ok(jsonEncode(<String, Object?>{
        'tasks': <Object?>[taskJson(status: 'suspended')],
      })),
    });
    final answer = await _authorityFor(transport).listTasks(_childId);
    expect(answer.status, TasksAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('an entry reason this build cannot name is refused, because a number needs an author', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/points': _ok(pointsBody(
        points: 15,
        entries: <Object?>[
          <String, Object?>{...entryJson(), 'reason': 'mystery_bonus'},
        ],
      )),
    });
    final answer = await _authorityFor(transport).readPoints(_childId);
    expect(answer.status, TasksAuthorityStatus.refused);
  });

  test('a claim returns a claim, and a claim carries no points', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/tasks': _ok(taskListBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/claim': _created(jsonEncode(<String, Object?>{'claim': claimJson()})),
      },
    );
    final answer = await _authorityFor(transport).claimTask(
      _childId,
      taskId: _taskId,
      idempotencyKey: () => 'key-claim',
    );
    expect(answer.status, TasksAuthorityStatus.ready);
    expect(answer.value!.status, FoundationGateTaskClaimStatus.pending);
    expect(
      answer.value!.pointsAwarded,
      isNull,
      reason: 'pressing the button awards nothing - that is the whole law of this wave',
    );
  });

  test('the decision that is sent names no number, because the task names it', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/tasks': _ok(taskListBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/decision': _ok(jsonEncode(<String, Object?>{
          'task': taskJson(claim: claimJson(status: 'confirmed', pointsAwarded: 15)),
          'points': <String, Object?>{'points': 15, 'entries': <Object?>[entryJson()]},
          'awarded': entryJson(),
        })),
      },
    );
    final answer = await _authorityFor(transport).decideTask(
      _childId,
      taskId: _taskId,
      confirm: true,
      idempotencyKey: () => 'key-decide',
    );
    expect(answer.status, TasksAuthorityStatus.ready);
    final sent = jsonDecode(transport.bodies.single) as Map<String, Object?>;
    expect(sent['decision'], 'confirm');
    expect(
      sent.containsKey('points'),
      isFalse,
      reason: 'the reward is a property of the task; this request cannot restate it',
    );
    expect(answer.value!.awarded!.points, 15);
    expect(answer.value!.points.points, 15, 'the balance travels with the decision');
  });

  test('a declined claim reports no award, and the balance does not move', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/tasks': _ok(taskListBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/decision': _ok(jsonEncode(<String, Object?>{
          'task': taskJson(
            claim: claimJson(status: 'declined', decisionNote: 'الملابس ما زالت على الأرض'),
          ),
          'points': <String, Object?>{'points': 15, 'entries': <Object?>[entryJson()]},
          'awarded': null,
        })),
      },
    );
    final answer = await _authorityFor(transport).decideTask(
      _childId,
      taskId: _taskId,
      confirm: false,
      note: 'الملابس ما زالت على الأرض',
      idempotencyKey: () => 'key-decline',
    );
    expect(answer.status, TasksAuthorityStatus.ready);
    expect(answer.value!.awarded, isNull);
    expect(answer.value!.task.claim!.status, FoundationGateTaskClaimStatus.declined);
    expect(answer.value!.task.claim!.pointsAwarded, isNull);
    expect(answer.value!.points.points, 15, 'a refusal awards nothing and takes nothing');
  });

  test('a refusal with a reason arrives as a refusal, and nothing is invented', () async {
    final transport = _Transport(
      <String, FoundationGateHttpResponse>{'/tasks': _ok(taskListBody())},
      postResponses: <String, FoundationGateHttpResponse>{
        '/claim': _status(409),
      },
    );
    final answer = await _authorityFor(transport).claimTask(
      _childId,
      taskId: _taskId,
      idempotencyKey: () => 'key-claim-2',
    );
    expect(answer.status, TasksAuthorityStatus.refused);
    expect(answer.value, isNull);
  });

  test('an unreachable server moves nothing at all', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/tasks': _ok(taskListBody()),
    })
      ..failure = StateError('socket closed');
    final answer = await _authorityFor(transport).listTasks(_childId);
    expect(answer.status, TasksAuthorityStatus.unreachable);
    expect(answer.value, isNull);
  });

  test('an access refusal is not retried and not softened', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/points': _status(403),
    });
    final answer = await _authorityFor(transport).readPoints(_childId);
    expect(answer.status, TasksAuthorityStatus.accessDenied);
    expect(transport.calls.length, 1, reason: 'a refusal is an answer, not a retry hint');
  });

  test('a balance is the sum over the entries that travelled with it', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/points': _ok(pointsBody(
        points: 20,
        entries: <Object?>[entryJson(points: 15), <String, Object?>{...entryJson(points: 5)}],
      )),
    });
    final answer = await _authorityFor(transport).readPoints(_childId);
    expect(answer.status, TasksAuthorityStatus.ready);
    expect(answer.value!.points, 20);
    expect(answer.value!.entries.length, 2);
    expect(answer.value!.entries.first.reason, FoundationGatePointReason.taskConfirmed);
  });

  test('a server that answers with a shape this build cannot read is refused', () async {
    final transport = _Transport(<String, FoundationGateHttpResponse>{
      '/tasks': _ok(jsonEncode(<String, Object?>{'items': <Object?>[]})),
    });
    final answer = await _authorityFor(transport).listTasks(_childId);
    expect(answer.status, TasksAuthorityStatus.refused);
  });
}
