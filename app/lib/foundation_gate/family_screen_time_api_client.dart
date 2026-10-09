import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Why the answer is what it is. The vocabulary is closed and shared by the state and by
/// every app's own decision, so a screen never has to interpret a free-form string.
///
/// `instantLock` is the only one that stops everything. `bedtime` and `schoolMode` end the
/// entertainment and leave education working. `dailyLimit` means the day's countable budget
/// is spent. `appBlocked` and `appLimit` are the family's own decisions about one app, and
/// `awaitingDecision` means nobody has made one yet - which is a refusal, not a permission.
enum FoundationGateScreenReason {
  instantLock('instant_lock'),
  bedtime('bedtime'),
  schoolMode('school_mode'),
  dailyLimit('daily_limit'),
  appBlocked('app_blocked'),
  appLimit('app_limit'),
  awaitingDecision('awaiting_decision');

  const FoundationGateScreenReason(this.wire);

  final String wire;

  static FoundationGateScreenReason? parse(Object? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

/// What the phone may do right now.
enum FoundationGateScreenStateKind {
  free('free'),
  limited('limited'),
  blocked('blocked');

  const FoundationGateScreenStateKind(this.wire);

  final String wire;

  static FoundationGateScreenStateKind? parse(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// The family's decision about one app.
enum FoundationGateAppRuleStatus {
  allowed('allowed'),
  free('free'),
  blocked('blocked'),
  pending('pending');

  const FoundationGateAppRuleStatus(this.wire);

  final String wire;

  static FoundationGateAppRuleStatus? parse(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// What a question is now.
enum FoundationGateTimeRequestStatus {
  pending('pending'),
  approved('approved'),
  denied('denied'),
  expired('expired');

  const FoundationGateTimeRequestStatus(this.wire);

  final String wire;

  static FoundationGateTimeRequestStatus? parse(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// A guardian's answer. Two values, because "answer the question" has two shapes.
enum FoundationGateTimeRequestDecision {
  approve('approve'),
  deny('deny');

  const FoundationGateTimeRequestDecision(this.wire);

  final String wire;
}

/// The stored policy: what the family chose, or the published defaults when they have not
/// chosen yet - `configured` says which of the two this is, so a screen can label it.
class FoundationGateScreenPolicy {
  const FoundationGateScreenPolicy({
    required this.childId,
    required this.configured,
    required this.dailyLimitMinutes,
    required this.schoolModeEnabled,
    required this.schoolDays,
    required this.schoolStartMinute,
    required this.schoolEndMinute,
    required this.bedtimeStartMinute,
    required this.bedtimeEndMinute,
    required this.timezoneOffsetMinutes,
    required this.version,
    required this.updatedAt,
  });

  final String childId;
  final bool configured;

  /// 0 means no cap. It is a number rather than null so a screen shows one thing for
  /// "unset" and "unlimited", which is what the family means by both.
  final int dailyLimitMinutes;
  final bool schoolModeEnabled;
  final List<int> schoolDays;
  final int schoolStartMinute;
  final int schoolEndMinute;
  final int bedtimeStartMinute;
  final int bedtimeEndMinute;
  final int timezoneOffsetMinutes;

  /// Null until the family saves a policy for the first time.
  final int? version;
  final DateTime? updatedAt;
}

/// A lock episode: who pressed it, why, and whether it has been released.
class FoundationGateChildLock {
  const FoundationGateChildLock({
    required this.id,
    required this.reasonCode,
    required this.lockedAt,
    required this.lockedByMembershipId,
    required this.releasedAt,
    required this.version,
  });

  final String id;
  final String reasonCode;
  final DateTime lockedAt;
  final String lockedByMembershipId;
  final DateTime? releasedAt;
  final int version;

  bool get live => releasedAt == null;
}

/// The computed state of one child's device at the instant the server answered.
class FoundationGateScreenState {
  const FoundationGateScreenState({
    required this.kind,
    required this.reason,
    required this.since,
    required this.date,
    required this.minuteOfDay,
    required this.weekday,
    required this.capMinutes,
    required this.grantedMinutes,
    required this.countableUsedMinutes,
    required this.remainingMinutes,
    required this.lock,
  });

  final FoundationGateScreenStateKind kind;
  final FoundationGateScreenReason? reason;

  /// When a lock started. Null for every state that is not an instant lock: a bedtime is
  /// not a moment somebody pressed something.
  final DateTime? since;
  final String date;
  final int minuteOfDay;
  final int weekday;
  final int? capMinutes;
  final int grantedMinutes;
  final int countableUsedMinutes;
  final int? remainingMinutes;
  final FoundationGateChildLock? lock;
}

/// One app's measured minutes for the day.
class FoundationGateAppUsage {
  const FoundationGateAppUsage({required this.appId, required this.usedMinutes});

  final String appId;
  final int usedMinutes;
}

/// What the server decided about one app, and why.
class FoundationGateAppDecision {
  const FoundationGateAppDecision({
    required this.allowed,
    required this.reason,
  });

  final bool allowed;
  final FoundationGateScreenReason? reason;
}

/// A rule the family wrote. Null on an app means nobody has written one yet.
class FoundationGateAppRule {
  const FoundationGateAppRule({
    required this.status,
    required this.limitMinutes,
    required this.unlimited,
    required this.version,
    required this.updatedAt,
  });

  final FoundationGateAppRuleStatus status;
  final int? limitMinutes;
  final bool unlimited;
  final int version;
  final DateTime? updatedAt;
}

/// One app on the child's phone: what the handset reported, what the family decided, and
/// what today's minutes add up to.
class FoundationGateChildApp {
  const FoundationGateChildApp({
    required this.appId,
    required this.displayName,
    required this.category,
    required this.ageRating,
    required this.knownOnDevice,
    required this.countable,
    required this.usedMinutes,
    required this.remainingMinutes,
    required this.rule,
    required this.decision,
  });

  final String appId;
  final String displayName;
  final String category;
  final String ageRating;

  /// True when a handset reported it. A rule for an app nobody has is still this family's
  /// decision, and it says so rather than pretending the app was found.
  final bool knownOnDevice;
  final bool countable;
  final int usedMinutes;
  final int? remainingMinutes;
  final FoundationGateAppRule? rule;
  final FoundationGateAppDecision decision;
}

/// The minutes a child asked for, and the answer.
class FoundationGateTimeRequest {
  const FoundationGateTimeRequest({
    required this.id,
    required this.childId,
    required this.usageDate,
    required this.requestedMinutes,
    required this.requestedByKind,
    required this.reasonCode,
    required this.status,
    required this.grantedMinutes,
    required this.expiresAt,
    required this.decidedAt,
    required this.decidedByMembershipId,
    required this.version,
    required this.createdAt,
  });

  final String id;
  final String childId;

  /// The day the granted minutes belong to. There is no wallet: a day's extension is the
  /// sum of that day's approvals.
  final String usageDate;
  final int requestedMinutes;

  /// `child` when it came from the handset's own credential, `guardian` when a parent asked
  /// on the child's behalf.
  final String requestedByKind;
  final String? reasonCode;
  final FoundationGateTimeRequestStatus status;
  final int? grantedMinutes;
  final DateTime expiresAt;
  final DateTime? decidedAt;
  final String? decidedByMembershipId;
  final int version;
  final DateTime createdAt;
}

/// Everything one read of a child's screen time contains.
class FoundationGateScreenTimeSnapshot {
  const FoundationGateScreenTimeSnapshot({
    required this.childId,
    required this.date,
    required this.policy,
    required this.state,
    required this.lock,
    required this.countableUsedMinutes,
    required this.grantedMinutes,
    required this.remainingMinutes,
    required this.usageByApp,
    required this.openRequest,
  });

  final String childId;
  final String date;
  final FoundationGateScreenPolicy policy;
  final FoundationGateScreenState state;
  final FoundationGateChildLock? lock;
  final int countableUsedMinutes;
  final int grantedMinutes;
  final int? remainingMinutes;
  final List<FoundationGateAppUsage> usageByApp;

  /// The question waiting for a parent, if there is one. A request that expired is not here.
  final FoundationGateTimeRequest? openRequest;
}

/// The answer to releasing a lock: whether there was one to release, and the state after.
class FoundationGateUnlockOutcome {
  const FoundationGateUnlockOutcome({
    required this.released,
    required this.snapshot,
  });

  final bool released;
  final FoundationGateScreenTimeSnapshot snapshot;
}

/// Everything the screen-time surface may ask the server, with a bearer token.
///
/// Eleven operations, and one honest gap: the two device-credential routes
/// (`GET`/`POST /v1/devices/{deviceId}/screen-time`) belong to the handset's own credential,
/// which this app hands to the native layer at pairing and does not keep. They exist on the
/// server, they are covered by the real-PostgreSQL journey, and they are deliberately absent
/// here rather than present and unused.
///
/// Nothing in this class invents state. A state, a reason and every number come from the
/// server's own answer, and a value the server could not produce stays absent instead of
/// being defaulted into something a family might act on.
class FamilyScreenTimeApiClient {
  FamilyScreenTimeApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// The whole state: policy, today's minutes, the reason, the lock and any open question.
  Future<FoundationGateScreenTimeSnapshot> readSnapshot({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildScreenTimeUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseSnapshot(response.body),
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

  /// Changes only the fields that are sent.
  ///
  /// A screen that changes bedtime does not resend the daily cap, and the fields it leaves
  /// out keep the value this family chose - which is why every parameter is optional and an
  /// entirely empty call is refused here rather than sent as a request that means nothing.
  Future<FoundationGateScreenPolicy> updatePolicy({
    required String familyId,
    required String childId,
    required String idempotencyKey,
    required String idToken,
    int? dailyLimitMinutes,
    bool? schoolModeEnabled,
    List<int>? schoolDays,
    int? schoolStartMinute,
    int? schoolEndMinute,
    int? bedtimeStartMinute,
    int? bedtimeEndMinute,
    int? timezoneOffsetMinutes,
    int? expectedVersion,
  }) async {
    final body = <String, Object>{};
    if (dailyLimitMinutes != null) {
      body['dailyLimitMinutes'] = dailyLimitMinutes;
    }
    if (timezoneOffsetMinutes != null) {
      body['timezoneOffsetMinutes'] = timezoneOffsetMinutes;
    }
    final schoolMode = <String, Object>{};
    if (schoolModeEnabled != null) schoolMode['enabled'] = schoolModeEnabled;
    if (schoolDays != null) schoolMode['days'] = schoolDays;
    if (schoolStartMinute != null) schoolMode['startMinute'] = schoolStartMinute;
    if (schoolEndMinute != null) schoolMode['endMinute'] = schoolEndMinute;
    if (schoolMode.isNotEmpty) body['schoolMode'] = schoolMode;
    final bedtime = <String, Object>{};
    if (bedtimeStartMinute != null) bedtime['startMinute'] = bedtimeStartMinute;
    if (bedtimeEndMinute != null) bedtime['endMinute'] = bedtimeEndMinute;
    if (bedtime.isNotEmpty) body['bedtime'] = bedtime;
    if (expectedVersion != null) body['expectedVersion'] = expectedVersion;
    if (body.isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _patch(
      _configuration.familyChildScreenTimeUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return _policyFromWrite(response);
  }

  /// The apps on the child's phone, each with today's minutes and the family's decision.
  Future<List<FoundationGateChildApp>> listApps({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildAppsUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseAppList(response.body),
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

  /// Writes one app's rule.
  ///
  /// `pending` is a real value here, not a placeholder: it is how a parent puts an app they
  /// are unsure about back in front of the family instead of leaving a decision they do not
  /// mean.
  Future<FoundationGateAppRule> setAppRule({
    required String familyId,
    required String childId,
    required String appId,
    required FoundationGateAppRuleStatus status,
    required String idempotencyKey,
    required String idToken,
    int? limitMinutes,
    bool unlimited = false,
  }) async {
    final body = <String, Object>{'status': status.wire};
    if (limitMinutes != null) body['limitMinutes'] = limitMinutes;
    if (unlimited) body['unlimited'] = true;
    final response = await _put(
      _configuration.familyChildAppRuleUri(familyId, childId, appId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseAppRuleEnvelope(response.body),
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

  /// Switches the phone off now, with a reason and an author.
  Future<FoundationGateScreenTimeSnapshot> lock({
    required String familyId,
    required String childId,
    required String idempotencyKey,
    required String idToken,
    String reasonCode = 'parent_lock',
  }) async {
    final response = await _post(
      _configuration.familyChildScreenLockUri(familyId, childId),
      idToken,
      <String, Object>{'reasonCode': reasonCode},
      idempotencyKey: idempotencyKey,
    );
    return _snapshotFromWrite(response);
  }

  /// Releases the live lock. The outcome says whether there was one.
  Future<FoundationGateUnlockOutcome> unlock({
    required String familyId,
    required String childId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    final response = await _post(
      _configuration.familyChildScreenUnlockUri(familyId, childId),
      idToken,
      const <String, Object>{},
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode != 200) {
      throw _failureFor(response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final released = decoded['released'];
      if (released is! bool) throw const FormatException();
      return FoundationGateUnlockOutcome(
        released: released,
        snapshot: _snapshotFrom(decoded),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  /// The family's questions and their answers, newest first.
  Future<List<FoundationGateTimeRequest>> listTimeRequests({
    required String familyId,
    required String childId,
    required String idToken,
    String status = 'all',
  }) async {
    final response = await _get(
      _configuration.familyChildTimeRequestsUri(familyId, childId, status: status),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseRequestList(response.body),
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

  /// A guardian asks for extra minutes on a child's behalf.
  ///
  /// The server refuses this when the child has no cap to extend, and refuses a second
  /// question while one is open - naming the open one in the error's details, which is what
  /// [openRequestIdFrom] reads so a screen can show the question instead of an error.
  Future<FoundationGateTimeRequest> requestMinutes({
    required String familyId,
    required String childId,
    required int requestedMinutes,
    required String idempotencyKey,
    required String idToken,
    String? reasonCode,
  }) async {
    final body = <String, Object>{'requestedMinutes': requestedMinutes};
    if (reasonCode != null) body['reasonCode'] = reasonCode;
    final response = await _post(
      _configuration.familyChildTimeRequestsUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      201 => _parseRequestEnvelope(response.body),
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
      409 => throw FoundationGateApiException(
        FoundationGateApiFailure.conflict,
        details: _errorDetails(response.body),
      ),
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// The answer, once. Approving with no number grants what was asked.
  Future<FoundationGateTimeRequest> decideTimeRequest({
    required String familyId,
    required String childId,
    required String requestId,
    required FoundationGateTimeRequestDecision decision,
    required String idempotencyKey,
    required String idToken,
    int? grantedMinutes,
  }) async {
    final body = <String, Object>{'decision': decision.wire};
    if (grantedMinutes != null) body['grantedMinutes'] = grantedMinutes;
    final response = await _post(
      _configuration.familyChildTimeRequestDecisionUri(
        familyId,
        childId,
        requestId,
      ),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseRequestEnvelope(response.body),
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

  /// The open question's id, when the server refused a second one.
  ///
  /// A conflict here is not an error a family caused: it means the child already asked. The
  /// screen should show the question that exists, and this is how it learns which one.
  static String? openRequestIdFrom(FoundationGateApiException exception) {
    final details = exception.details;
    if (details == null) return null;
    final requestId = details['requestId'];
    if (requestId is! String || !isFoundationGateUuid(requestId)) return null;
    return requestId;
  }

  // ── transport ──────────────────────────────────────────────────────────────────────

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(uri, headers: _headers(idToken));
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
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
        headers: {..._headers(idToken), ..._writeHeaders(idempotencyKey)},
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _patch(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.patch(
        uri,
        headers: {..._headers(idToken), ..._writeHeaders(idempotencyKey)},
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _put(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.put(
        uri,
        headers: {..._headers(idToken), ..._writeHeaders(idempotencyKey)},
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Map<String, String> _headers(String idToken) => {
    'accept': 'application/json',
    'authorization': 'Bearer $idToken',
  };

  Map<String, String> _writeHeaders(String idempotencyKey) => {
    'content-type': 'application/json',
    'idempotency-key': idempotencyKey,
  };

  FoundationGateApiException _failureFor(int statusCode) {
    switch (statusCode) {
      case 400:
        return const FoundationGateApiException(
          FoundationGateApiFailure.invalidInput,
        );
      case 401:
        return const FoundationGateApiException(
          FoundationGateApiFailure.unauthenticated,
        );
      case 403:
        return const FoundationGateApiException(
          FoundationGateApiFailure.accessDenied,
        );
      case 404:
        return const FoundationGateApiException(
          FoundationGateApiFailure.notFound,
        );
      case 409:
        return const FoundationGateApiException(
          FoundationGateApiFailure.conflict,
        );
      case 429:
      case 503:
        return const FoundationGateApiException(
          FoundationGateApiFailure.serviceUnavailable,
        );
      default:
        return const FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
        );
    }
  }

  FoundationGateScreenPolicy _policyFromWrite(
    FoundationGateHttpResponse response,
  ) {
    if (response.statusCode != 200) {
      throw _failureFor(response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _policyFrom(decoded['policy']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateScreenTimeSnapshot _snapshotFromWrite(
    FoundationGateHttpResponse response,
  ) {
    if (response.statusCode != 200) {
      throw _failureFor(response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _snapshotFrom(decoded);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  /// The server's `error.details`, when it sent one. Anything else is absent.
  static Map<String, Object?>? _errorDetails(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) return null;
      final error = decoded['error'];
      if (error is! Map<String, Object?>) return null;
      final details = error['details'];
      if (details is! Map<String, Object?>) return null;
      return details;
    } catch (_) {
      return null;
    }
  }

  // ── parsing. A missing field is a refusal, never a default. ─────────────────────────

  FoundationGateScreenTimeSnapshot _parseSnapshot(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _snapshotFrom(decoded);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateScreenTimeSnapshot _snapshotFrom(Map<String, Object?> decoded) {
    final usage = decoded['usage'];
    if (usage is! Map<String, Object?>) throw const FormatException();
    final rawByApp = usage['byApp'];
    if (rawByApp is! List<Object?>) throw const FormatException();
    return FoundationGateScreenTimeSnapshot(
      childId: _uuid(decoded['childId']),
      date: _text(decoded['date']),
      policy: _policyFrom(decoded['policy']),
      state: _stateFrom(decoded['state']),
      lock: decoded['lock'] == null ? null : _lockFrom(decoded['lock']),
      countableUsedMinutes: _int(usage['countableUsedMinutes']),
      grantedMinutes: _int(usage['grantedMinutes']),
      remainingMinutes: _nullableInt(usage['remainingMinutes']),
      usageByApp: List<FoundationGateAppUsage>.unmodifiable(
        rawByApp.map((entry) {
          if (entry is! Map<String, Object?>) throw const FormatException();
          return FoundationGateAppUsage(
            appId: _text(entry['appId']),
            usedMinutes: _int(entry['usedMinutes']),
          );
        }),
      ),
      openRequest:
          decoded['openRequest'] == null ? null : _requestFrom(decoded['openRequest']),
    );
  }

  FoundationGateScreenPolicy _policyFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final schoolMode = value['schoolMode'];
    final bedtime = value['bedtime'];
    if (schoolMode is! Map<String, Object?> || bedtime is! Map<String, Object?>) {
      throw const FormatException();
    }
    final days = schoolMode['days'];
    if (days is! List<Object?>) throw const FormatException();
    final configured = value['configured'];
    if (configured is! bool) throw const FormatException();
    return FoundationGateScreenPolicy(
      childId: _uuid(value['childId']),
      configured: configured,
      dailyLimitMinutes: _int(value['dailyLimitMinutes']),
      schoolModeEnabled: _bool(schoolMode['enabled']),
      schoolDays: List<int>.unmodifiable(days.map(_int)),
      schoolStartMinute: _int(schoolMode['startMinute']),
      schoolEndMinute: _int(schoolMode['endMinute']),
      bedtimeStartMinute: _int(bedtime['startMinute']),
      bedtimeEndMinute: _int(bedtime['endMinute']),
      timezoneOffsetMinutes: _int(value['timezoneOffsetMinutes']),
      version: _nullableInt(value['version']),
      updatedAt: _nullableDateTime(value['updatedAt']),
    );
  }

  FoundationGateScreenState _stateFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final kind = FoundationGateScreenStateKind.parse(value['kind']);
    if (kind == null) throw const FormatException();
    return FoundationGateScreenState(
      kind: kind,
      reason: _reason(value['reasonCode']),
      since: _nullableDateTime(value['since']),
      date: _text(value['date']),
      minuteOfDay: _int(value['minuteOfDay']),
      weekday: _int(value['weekday']),
      capMinutes: _nullableInt(value['capMinutes']),
      grantedMinutes: _int(value['grantedMinutes']),
      countableUsedMinutes: _int(value['countableUsedMinutes']),
      remainingMinutes: _nullableInt(value['remainingMinutes']),
      lock: value['lock'] == null ? null : _lockFrom(value['lock']),
    );
  }

  FoundationGateChildLock _lockFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    return FoundationGateChildLock(
      id: _uuid(value['id']),
      reasonCode: _text(value['reasonCode']),
      lockedAt: _dateTime(value['lockedAt']),
      lockedByMembershipId: _uuid(value['lockedByMembershipId']),
      releasedAt: _nullableDateTime(value['releasedAt']),
      version: _int(value['version']),
    );
  }

  FoundationGateAppRule _ruleFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final status = FoundationGateAppRuleStatus.parse(value['status']);
    if (status == null) throw const FormatException();
    return FoundationGateAppRule(
      status: status,
      limitMinutes: _nullableInt(value['limitMinutes']),
      unlimited: _bool(value['unlimited']),
      version: _int(value['version']),
      updatedAt: _nullableDateTime(value['updatedAt']),
    );
  }

  FoundationGateChildApp _appFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final decision = value['decision'];
    if (decision is! Map<String, Object?>) throw const FormatException();
    final allowed = decision['allowed'];
    if (allowed is! bool) throw const FormatException();
    return FoundationGateChildApp(
      appId: _text(value['appId']),
      displayName: _text(value['displayName']),
      category: _text(value['category']),
      ageRating: _text(value['ageRating']),
      knownOnDevice: _bool(value['knownOnDevice']),
      countable: _bool(value['countable']),
      usedMinutes: _int(value['usedMinutes']),
      remainingMinutes: _nullableInt(value['remainingMinutes']),
      rule: value['rule'] == null ? null : _ruleFrom(value['rule']),
      decision: FoundationGateAppDecision(
        allowed: allowed,
        reason: _reason(decision['reasonCode']),
      ),
    );
  }

  FoundationGateTimeRequest _requestFrom(Object? value) {
    if (value is! Map<String, Object?>) throw const FormatException();
    final status = FoundationGateTimeRequestStatus.parse(value['status']);
    if (status == null) throw const FormatException();
    return FoundationGateTimeRequest(
      id: _uuid(value['id']),
      childId: _uuid(value['childId']),
      usageDate: _text(value['usageDate']),
      requestedMinutes: _int(value['requestedMinutes']),
      requestedByKind: _text(value['requestedByKind']),
      reasonCode: _nullableText(value['reasonCode']),
      status: status,
      grantedMinutes: _nullableInt(value['grantedMinutes']),
      expiresAt: _dateTime(value['expiresAt']),
      decidedAt: _nullableDateTime(value['decidedAt']),
      decidedByMembershipId: _nullableText(value['decidedByMembershipId']),
      version: _int(value['version']),
      createdAt: _dateTime(value['createdAt']),
    );
  }

  List<FoundationGateChildApp> _parseAppList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final apps = decoded['apps'];
      if (apps is! List<Object?>) throw const FormatException();
      return List<FoundationGateChildApp>.unmodifiable(apps.map(_appFrom));
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateAppRule _parseAppRuleEnvelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _ruleFrom(decoded['rule']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  List<FoundationGateTimeRequest> _parseRequestList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final requests = decoded['requests'];
      if (requests is! List<Object?>) throw const FormatException();
      return List<FoundationGateTimeRequest>.unmodifiable(
        requests.map(_requestFrom),
      );
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FoundationGateTimeRequest _parseRequestEnvelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return _requestFrom(decoded['request']);
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  /// A reason the server sent.
  ///
  /// Null is a real answer - nothing is in the way - so an unknown WORD must not be folded
  /// into it: a build that rendered "someday_mode" as "nothing is in the way" would be
  /// telling a family the opposite of what the server said. It refuses instead.
  static FoundationGateScreenReason? _reason(Object? value) {
    if (value == null) return null;
    final reason = FoundationGateScreenReason.parse(value);
    if (reason == null) throw const FormatException();
    return reason;
  }

  static String? _nullableText(Object? value) {
    if (value == null) return null;
    return _text(value);
  }

  static String _text(Object? value) {
    if (value is! String) throw const FormatException();
    return value;
  }

  static String _uuid(Object? value) {
    final text = _text(value);
    if (!isFoundationGateUuid(text)) throw const FormatException();
    return text;
  }

  static int _int(Object? value) {
    if (value is! int) throw const FormatException();
    return value;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    return _int(value);
  }

  static bool _bool(Object? value) {
    if (value is! bool) throw const FormatException();
    return value;
  }

  static DateTime _dateTime(Object? value) {
    final text = _text(value);
    final parsed = DateTime.tryParse(text);
    if (parsed == null) throw const FormatException();
    return parsed;
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    return _dateTime(value);
  }
}
