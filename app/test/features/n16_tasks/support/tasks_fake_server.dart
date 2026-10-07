// W7 — the tasks test server: one child, a list of open tasks, one claim at a time.
//
// A write mutates this object before answering, so a surface that re-reads after a write sees
// the decision it just took. The alternative - a transport with canned answers - would let a
// broken surface pass, because the only way to catch a stale points total is to ask twice.
//
// It is shared by the panel tests and the screen-wiring test on purpose: two fakes would drift,
// and the one that drifted would be the one that stopped catching the bug.
import 'dart:convert';

import 'package:family_os/features/n16_tasks/tasks_server_authority.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const familyId = '11111111-1111-4111-8111-111111111111';
const childId = '22222222-2222-4222-8222-222222222222';
const taskId = '44444444-4444-4444-8444-444444444444';
const newTaskId = '55555555-5555-4555-8555-555555555555';
const claimId = '66666666-6666-4666-8666-666666666666';
const membershipId = '77777777-7777-4777-8777-777777777777';
const entryId = '88888888-8888-4888-8888-888888888888';

/// An authority bound to [server], the way the app binds one at boot.
TasksServerAuthority tasksAuthorityFor(TasksFakeServer server) =>
    TasksServerAuthority(
      api: FamilyTasksApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: server,
      ),
      idToken: () async => 'test-token',
      familyId: () => familyId,
    );

/// The server, small enough to read: one child, a list of open tasks, one claim at a time.
final class TasksFakeServer implements FoundationGateHttpTransport {
  TasksFakeServer({this.claimStatus, this.points = 0, this.pointsAssigned = 15});

  /// null means nobody has said anything about the seeded task yet.
  String? claimStatus;
  int points;
  final int pointsAssigned;
  int? pointsAwarded;
  String decisionNote = '';

  /// When set, the decision request is refused instead of applied (a 409 from the server),
  /// and a refused write must leave the state alone.
  int? refuseDecisionWith;
  Object? networkFailure;

  /// Tasks the guardian stated after this server started, in the order they arrived.
  final List<Map<String, Object?>> stated = <Map<String, Object?>>[];

  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];

  Map<String, Object?> get _entry => <String, Object?>{
    'id': entryId,
    'points': pointsAwarded,
    'reason': 'task_confirmed',
    'claimId': claimId,
    'awardedByMembershipId': membershipId,
    'createdAt': '2026-10-08T08:00:00.000Z',
  };

  Map<String, Object?> get _claim => <String, Object?>{
    'id': claimId,
    'taskId': taskId,
    'status': claimStatus,
    'note': 'خلصت',
    // Recorded by a guardian on the child's behalf, which is the path this panel uses:
    // the family/child claim endpoint, so the membership is the one that spoke.
    'claimedByDeviceId': null,
    'claimedByMembershipId': membershipId,
    'decidedByMembershipId': claimStatus == 'pending' ? null : membershipId,
    'decidedAt': claimStatus == 'pending' ? null : '2026-10-08T08:00:00.000Z',
    'decisionNote': decisionNote,
    'pointsAwarded': pointsAwarded,
    'createdAt': '2026-10-08T07:00:00.000Z',
  };

  Map<String, Object?> get _task => <String, Object?>{
    'id': taskId,
    'childId': childId,
    'title': 'ترتيب الغرفة',
    'note': 'الملابس في الخزانة',
    'points': pointsAssigned,
    'status': 'open',
    'createdByMembershipId': membershipId,
    'createdAt': '2026-10-08T06:00:00.000Z',
    'updatedAt': '2026-10-08T06:00:00.000Z',
    'claim': claimStatus == null ? null : _claim,
  };

  List<Map<String, Object?>> get _tasks => <Map<String, Object?>>[_task, ...stated];

  Map<String, Object?> get _points => <String, Object?>{
    'points': points,
    'entries': pointsAwarded == null ? const <Object?>[] : <Object?>[_entry],
  };

  FoundationGateHttpResponse _answer(Uri uri, {Map<String, Object?>? post}) {
    if (networkFailure != null) throw networkFailure!;
    if (uri.path.endsWith('/tasks') && post == null) {
      return FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{'tasks': _tasks}),
      );
    }
    if (uri.path.endsWith('/tasks') && post != null) {
      final task = <String, Object?>{
        'id': newTaskId,
        'childId': childId,
        'title': post['title'],
        'note': post['note'] ?? '',
        'points': post['points'],
        'status': 'open',
        'createdByMembershipId': membershipId,
        'createdAt': '2026-10-08T09:00:00.000Z',
        'updatedAt': '2026-10-08T09:00:00.000Z',
        'claim': null,
      };
      stated.add(task);
      return FoundationGateHttpResponse(
        statusCode: 201,
        body: jsonEncode(<String, Object?>{'task': task}),
      );
    }
    if (uri.path.endsWith('/points')) {
      return FoundationGateHttpResponse(statusCode: 200, body: jsonEncode(_points));
    }
    if (uri.path.endsWith('/claim')) {
      claimStatus = claimStatus ?? 'pending';
      return FoundationGateHttpResponse(
        statusCode: 201,
        body: jsonEncode(<String, Object?>{'claim': _claim}),
      );
    }
    if (uri.path.endsWith('/decision')) {
      final refusal = refuseDecisionWith;
      if (refusal != null) {
        return FoundationGateHttpResponse(statusCode: refusal, body: '{}');
      }
      final confirm = post?['decision'] == 'confirm';
      decisionNote = post?['note'] as String? ?? '';
      claimStatus = confirm ? 'confirmed' : 'declined';
      pointsAwarded = confirm ? pointsAssigned : null;
      points = confirm ? pointsAssigned : points;
      return FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'task': _task,
          'points': _points,
          'awarded': pointsAwarded == null ? null : _entry,
        }),
      );
    }
    throw StateError('the fake server was asked for ${uri.path}');
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    return _answer(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    bodies.add(body);
    return _answer(uri, post: jsonDecode(body) as Map<String, Object?>);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    bodies.add(body);
    return _answer(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    bodies.add(body);
    return _answer(uri);
  }
}
