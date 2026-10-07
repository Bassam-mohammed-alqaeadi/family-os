import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// W7 — family tasks and points, from the guardian's side of the family.
///
/// The client answers the question the wave is built on - "who says so?" - by what it refuses
/// to accept. A status this build cannot name is `invalidResponse` rather than a silently
/// dropped row, and there is no method here that awards points: points are the consequence of
/// a decision the server took, and this class only carries that decision to a screen.
///
/// The device's own routes are deliberately absent, exactly as they were in wave 6: the
/// child's handset reads its tasks and claims them with the credential issued at pairing, and
/// that credential is not kept in this layer. Those routes are declared in the contract and
/// covered by the real-PostgreSQL journey; a screen that showed a phone a locally-invented
/// task list would be the lie this wave exists to prevent.

/// What a task is waiting for, as the server states it.
enum FoundationGateTaskClaimStatus {
  pending('pending'),
  confirmed('confirmed'),
  declined('declined');

  const FoundationGateTaskClaimStatus(this.wire);

  final String wire;

  static FoundationGateTaskClaimStatus? parse(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

enum FoundationGateTaskStatus {
  open('open'),
  archived('archived');

  const FoundationGateTaskStatus(this.wire);

  final String wire;

  static FoundationGateTaskStatus? parse(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Why an entry exists. A closed vocabulary, because a point that cannot say where it came
/// from is a number with no author.
enum FoundationGatePointReason {
  taskConfirmed('task_confirmed');

  const FoundationGatePointReason(this.wire);

  final String wire;

  static FoundationGatePointReason? parse(Object? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

/// One cycle on a task: what the child said, and what a guardian answered.
class FoundationGateTaskClaim {
  const FoundationGateTaskClaim({
    required this.id,
    required this.taskId,
    required this.status,
    required this.note,
    required this.claimedByDeviceId,
    required this.claimedByMembershipId,
    required this.decidedByMembershipId,
    required this.decidedAt,
    required this.decisionNote,
    required this.pointsAwarded,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final FoundationGateTaskClaimStatus status;
  final String note;

  /// One of these is set, never both: the child's own handset spoke, or a guardian spoke for
  /// them. Which one it was is part of what the claim means.
  final String? claimedByDeviceId;
  final String? claimedByMembershipId;

  final String? decidedByMembershipId;
  final DateTime? decidedAt;
  final String decisionNote;

  /// The number copied from the task at the moment of confirmation, and null on a decline -
  /// which is a fact, not a missing value: a refusal awards nothing.
  final int? pointsAwarded;
  final DateTime createdAt;
}

/// A task a guardian stated, with the cycle currently open on it.
class FoundationGateTask {
  const FoundationGateTask({
    required this.id,
    required this.childId,
    required this.title,
    required this.note,
    required this.points,
    required this.status,
    required this.createdAt,
    required this.claim,
  });

  final String id;
  final String childId;
  final String title;
  final String note;
  final int points;
  final FoundationGateTaskStatus status;
  final DateTime createdAt;

  /// Null when nobody has said anything about this task yet. That is different from
  /// "claimed", and the screen says so rather than filling the gap.
  final FoundationGateTaskClaim? claim;
}

/// One row of the ledger: points, and where they came from.
class FoundationGatePointEntry {
  const FoundationGatePointEntry({
    required this.id,
    required this.points,
    required this.reason,
    required this.claimId,
    required this.awardedByMembershipId,
    required this.createdAt,
  });

  final String id;
  final int points;
  final FoundationGatePointReason reason;
  final String? claimId;
  final String awardedByMembershipId;
  final DateTime createdAt;
}

/// A balance and the entries that produced it. The number never travels alone.
class FoundationGateChildPoints {
  const FoundationGateChildPoints({required this.points, required this.entries});

  final int points;
  final List<FoundationGatePointEntry> entries;
}

/// The answer to a decision: the task as it now stands, and the balance afterwards.
class FoundationGateTaskDecision {
  const FoundationGateTaskDecision({
    required this.task,
    required this.points,
    required this.awarded,
  });

  final FoundationGateTask task;
  final FoundationGateChildPoints points;

  /// The entry this confirmation wrote, or null on a decline. A screen can say "15 points
  /// were awarded" without asking for the ledger again.
  final FoundationGatePointEntry? awarded;
}

/// The tasks and points of one child, as the family's screens read them.
class FamilyTasksApiClient {
  FamilyTasksApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<List<FoundationGateTask>> listTasks({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildTasksUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseTaskList(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// A guardian states a task. The points are stated here and only here - the confirmation
  /// that follows copies them, so no later request can name a different number.
  Future<FoundationGateTask> createTask({
    required String familyId,
    required String childId,
    required String title,
    required int points,
    required String idempotencyKey,
    required String idToken,
    String note = '',
  }) async {
    final body = <String, Object>{
      'title': title,
      'points': points,
      if (note.isNotEmpty) 'note': note,
    };
    final response = await _post(
      _configuration.familyChildTasksUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      201 => _parseTask(_decode(response.body)['task']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      422 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// "I did it" for a child who spoke to a guardian. This call awards nothing: the claim
  /// waits, and the screen must not draw points for a thing nobody has confirmed.
  Future<FoundationGateTaskClaim> claimTask({
    required String familyId,
    required String childId,
    required String taskId,
    required String idempotencyKey,
    required String idToken,
    String note = '',
  }) async {
    final body = <String, Object>{if (note.isNotEmpty) 'note': note};
    final response = await _post(
      _configuration.familyChildTaskClaimUri(familyId, childId, taskId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      201 => _parseClaim(_decode(response.body)['claim']),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// The guardian's word. Note what is not a parameter: a number of points. The task says
  /// what the work is worth, and this call cannot restate it.
  Future<FoundationGateTaskDecision> decideTask({
    required String familyId,
    required String childId,
    required String taskId,
    required bool confirm,
    required String idempotencyKey,
    required String idToken,
    String note = '',
  }) async {
    final body = <String, Object>{
      'decision': confirm ? 'confirm' : 'decline',
      if (note.isNotEmpty) 'note': note,
    };
    final response = await _post(
      _configuration.familyChildTaskDecisionUri(familyId, childId, taskId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseDecision(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  Future<FoundationGateChildPoints> readPoints({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildPointsUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parsePoints(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      404 => throw const FoundationGateApiException(
        FoundationGateApiFailure.notFound,
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  // ── parsing ──────────────────────────────────────────────────────────────────────────

  static List<FoundationGateTask> _parseTaskList(String body) {
    final raw = _decode(body)['tasks'];
    if (raw is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return raw
        .map((entry) => _parseTask(entry))
        .toList(growable: false);
  }

  static FoundationGateTask _parseTask(Object? value) {
    final task = _object(value, 'task');
    final status = FoundationGateTaskStatus.parse(task['status']);
    if (status == null) {
      // A status this build cannot name is refused rather than drawn. A screen that muted an
      // unknown task state would show a family a chore that looks ordinary and is not.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawClaim = task['claim'];
    return FoundationGateTask(
      id: _string(task['id'], 'id'),
      childId: _string(task['childId'], 'childId'),
      title: _string(task['title'], 'title'),
      note: task['note'] is String ? task['note']! as String : '',
      points: _integer(task['points'], 'points'),
      status: status,
      createdAt: _instant(task['createdAt'], 'createdAt'),
      claim: rawClaim == null ? null : _parseClaim(rawClaim),
    );
  }

  static FoundationGateTaskClaim _parseClaim(Object? value) {
    final claim = _object(value, 'claim');
    final status = FoundationGateTaskClaimStatus.parse(claim['status']);
    if (status == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawPoints = claim['pointsAwarded'];
    return FoundationGateTaskClaim(
      id: _string(claim['id'], 'id'),
      taskId: _string(claim['taskId'], 'taskId'),
      status: status,
      note: claim['note'] is String ? claim['note']! as String : '',
      claimedByDeviceId: claim['claimedByDeviceId'] as String?,
      claimedByMembershipId: claim['claimedByMembershipId'] as String?,
      decidedByMembershipId: claim['decidedByMembershipId'] as String?,
      decidedAt: claim['decidedAt'] == null
          ? null
          : _instant(claim['decidedAt'], 'decidedAt'),
      decisionNote: claim['decisionNote'] is String
          ? claim['decisionNote']! as String
          : '',
      pointsAwarded: rawPoints == null ? null : _integer(rawPoints, 'pointsAwarded'),
      createdAt: _instant(claim['createdAt'], 'createdAt'),
    );
  }

  static FoundationGateChildPoints _parsePoints(String body) {
    final decoded = _decode(body);
    return FoundationGateChildPoints(
      points: _integer(decoded['points'], 'points'),
      entries: _parseEntries(decoded['entries']),
    );
  }

  static FoundationGateTaskDecision _parseDecision(String body) {
    final decoded = _decode(body);
    final balance = _object(decoded['points'], 'points');
    final rawAwarded = decoded['awarded'];
    return FoundationGateTaskDecision(
      task: _parseTask(decoded['task']),
      points: FoundationGateChildPoints(
        points: _integer(balance['points'], 'points'),
        entries: _parseEntries(balance['entries']),
      ),
      awarded: rawAwarded == null ? null : _parseEntry(rawAwarded),
    );
  }

  static List<FoundationGatePointEntry> _parseEntries(Object? value) {
    if (value is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return value.map((entry) => _parseEntry(entry)).toList(growable: false);
  }

  static FoundationGatePointEntry _parseEntry(Object? value) {
    final entry = _object(value, 'entry');
    final reason = FoundationGatePointReason.parse(entry['reason']);
    if (reason == null) {
      // An entry with a reason this build cannot name would be a number a family cannot
      // account for, which is the one thing a ledger exists to prevent.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGatePointEntry(
      id: _string(entry['id'], 'id'),
      points: _integer(entry['points'], 'points'),
      reason: reason,
      claimId: entry['claimId'] as String?,
      awardedByMembershipId: _string(
        entry['awardedByMembershipId'],
        'awardedByMembershipId',
      ),
      createdAt: _instant(entry['createdAt'], 'createdAt'),
    );
  }

  // ── transport ────────────────────────────────────────────────────────────────────────

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _post(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.post(
        uri,
        headers: _headers(idToken, idempotencyKey: idempotencyKey),
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Map<String, String> _headers(String idToken, {String? idempotencyKey}) {
    final headers = <String, String>{
      'authorization': 'Bearer $idToken',
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['idempotency-key'] = idempotencyKey;
    }
    return headers;
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  static Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value;
  }

  static int _integer(Object? value, String field) {
    if (value is! num) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value.toInt();
  }

  static DateTime _instant(Object? value, String field) {
    if (value is! String) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return parsed;
  }
}
