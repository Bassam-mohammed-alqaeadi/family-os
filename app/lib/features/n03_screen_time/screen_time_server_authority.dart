import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Why the server could not answer, in the words a screen needs.
///
/// There is no `localFallback` value and there never will be: this surface's entire promise
/// is that the minutes a family sees are the minutes the server enforces, so a build that
/// cannot reach a server says so instead of drawing a clock it made up.
enum ScreenTimeAuthorityStatus {
  /// The answer came from the server and means what it says.
  ready,

  /// This build has no server session (no configured API origin, no selected family, no
  /// token). Nothing was asked, because there is nobody to ask.
  notConfigured,

  /// The server refused: this account may not read or change this child's screen time.
  accessDenied,

  /// The server is configured but did not answer. The numbers on the screen must not move.
  unreachable,

  /// The server answered with a refusal that has a reason - a stale policy, a question
  /// already waiting, a grant larger than the ask - which the screen shows as it is.
  refused,
}

/// One answer from the server, or the honest statement that there was none.
///
/// `snapshot` is non-null exactly when `status` is [ScreenTimeAuthorityStatus.ready].
class ScreenTimeAuthorityAnswer<T> {
  const ScreenTimeAuthorityAnswer._({
    required this.status,
    required this.value,
    required this.openRequestId,
  });

  const ScreenTimeAuthorityAnswer.ready(T value)
    : this._(
        status: ScreenTimeAuthorityStatus.ready,
        value: value,
        openRequestId: null,
      );

  const ScreenTimeAuthorityAnswer.unavailable(
    ScreenTimeAuthorityStatus status, {
    String? openRequestId,
  }) : this._(
         status: status,
         value: null,
         openRequestId: openRequestId,
       );

  final ScreenTimeAuthorityStatus status;
  final T? value;

  /// Present when the refusal was "a question is already waiting": the screen should show
  /// that question rather than an error, and this is which one.
  final String? openRequestId;

  bool get isReady => status == ScreenTimeAuthorityStatus.ready && value != null;
}

/// The screen-time surface's one server connection.
///
/// It holds the client, the bearer token and the selected family, and it decides nothing
/// about the rules: the server computes the state, the reason and every number, and this
/// class only carries them to a screen - or reports, in a value a screen can render, that it
/// could not.
///
/// **What this build can and cannot do, stated once and plainly:**
///
///   * A GUARDIAN can read the state, set the cap, the bedtime and the school week, decide
///     each app, lock the phone now, release the lock, ask for extra minutes on a child's
///     behalf and answer the child's own question. All of that is the live contract.
///   * The CHILD'S OWN handset does not report or read through this class: those two routes
///     authenticate with the device credential, which this build hands to the native layer
///     at pairing and does not keep. They exist on the server, they are covered by the
///     real-PostgreSQL journey, and they are declared rather than imitated - a screen that
///     showed a phone its own minutes from a local guess would be exactly the lie this wave
///     deletes.
final class ScreenTimeServerAuthority {
  ScreenTimeServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyScreenTimeApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  Future<ScreenTimeAuthorityAnswer<FoundationGateScreenTimeSnapshot>> read(
    String childId,
  ) => _ask(
    (family, token) => api.readSnapshot(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  /// Changes only the fields it is given, and reports a stale policy as a refusal so a
  /// screen can reload rather than silently overwrite somebody else's decision.
  Future<ScreenTimeAuthorityAnswer<FoundationGateScreenPolicy>> writePolicy(
    String childId, {
    int? dailyLimitMinutes,
    bool? schoolModeEnabled,
    List<int>? schoolDays,
    int? schoolStartMinute,
    int? schoolEndMinute,
    int? bedtimeStartMinute,
    int? bedtimeEndMinute,
    int? timezoneOffsetMinutes,
    int? expectedVersion,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.updatePolicy(
      familyId: family,
      childId: childId,
      idempotencyKey: idempotencyKey(),
      idToken: token,
      dailyLimitMinutes: dailyLimitMinutes,
      schoolModeEnabled: schoolModeEnabled,
      schoolDays: schoolDays,
      schoolStartMinute: schoolStartMinute,
      schoolEndMinute: schoolEndMinute,
      bedtimeStartMinute: bedtimeStartMinute,
      bedtimeEndMinute: bedtimeEndMinute,
      timezoneOffsetMinutes: timezoneOffsetMinutes,
      expectedVersion: expectedVersion,
    ),
  );

  Future<ScreenTimeAuthorityAnswer<List<FoundationGateChildApp>>> apps(
    String childId,
  ) => _ask(
    (family, token) => api.listApps(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  Future<ScreenTimeAuthorityAnswer<FoundationGateAppRule>> writeAppRule(
    String childId, {
    required String appId,
    required FoundationGateAppRuleStatus status,
    int? limitMinutes,
    bool unlimited = false,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.setAppRule(
      familyId: family,
      childId: childId,
      appId: appId,
      status: status,
      limitMinutes: limitMinutes,
      unlimited: unlimited,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// "This phone is off now." The state that comes back is the server's, not the intent's.
  Future<ScreenTimeAuthorityAnswer<FoundationGateScreenTimeSnapshot>> lockNow(
    String childId, {
    String reasonCode = 'parent_lock',
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.lock(
      familyId: family,
      childId: childId,
      reasonCode: reasonCode,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// Releasing a lock, which may honestly release nothing at all.
  Future<ScreenTimeAuthorityAnswer<FoundationGateUnlockOutcome>> releaseLock(
    String childId, {
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.unlock(
      familyId: family,
      childId: childId,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  Future<ScreenTimeAuthorityAnswer<List<FoundationGateTimeRequest>>> requests(
    String childId, {
    String status = 'all',
  }) => _ask(
    (family, token) => api.listTimeRequests(
      familyId: family,
      childId: childId,
      status: status,
      idToken: token,
    ),
  );

  /// A guardian asking for extra minutes on a child's behalf.
  ///
  /// "A question is already waiting" comes back as a refusal carrying the open question's
  /// id, because the screen should show the question rather than an error the parent cannot
  /// act on.
  Future<ScreenTimeAuthorityAnswer<FoundationGateTimeRequest>> ask(
    String childId, {
    required int requestedMinutes,
    String? reasonCode,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.requestMinutes(
      familyId: family,
      childId: childId,
      requestedMinutes: requestedMinutes,
      reasonCode: reasonCode,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  Future<ScreenTimeAuthorityAnswer<FoundationGateTimeRequest>> answer(
    String childId, {
    required String requestId,
    required FoundationGateTimeRequestDecision decision,
    int? grantedMinutes,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.decideTimeRequest(
      familyId: family,
      childId: childId,
      requestId: requestId,
      decision: decision,
      grantedMinutes: grantedMinutes,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// The one place an exception becomes a status, so no screen has to translate failures
  /// and no screen can invent a value out of one.
  Future<ScreenTimeAuthorityAnswer<T>> _ask<T>(
    Future<T> Function(String familyId, String idToken) run,
  ) async {
    final family = familyId();
    if (family == null || family.trim().isEmpty) {
      // Nothing is asked, because there is nobody to ask: a screen bound without a session
      // is a screen that says so.
      return const ScreenTimeAuthorityAnswer.unavailable(
        ScreenTimeAuthorityStatus.notConfigured,
      );
    }
    // Not final on purpose: an assignment inside a try block that can throw is exactly the
    // shape the definite-assignment rules exist for, and there is no reason to make a
    // reader of this method reason about it.
    String token;
    try {
      token = await idToken();
    } on Object {
      return const ScreenTimeAuthorityAnswer.unavailable(
        ScreenTimeAuthorityStatus.notConfigured,
      );
    }
    if (token.trim().isEmpty) {
      return const ScreenTimeAuthorityAnswer.unavailable(
        ScreenTimeAuthorityStatus.notConfigured,
      );
    }
    try {
      return ScreenTimeAuthorityAnswer.ready(await run(family, token));
    } on FoundationGateApiException catch (exception) {
      return ScreenTimeAuthorityAnswer.unavailable(
        switch (exception.failure) {
          FoundationGateApiFailure.unauthenticated ||
          FoundationGateApiFailure.accessDenied =>
            ScreenTimeAuthorityStatus.accessDenied,
          FoundationGateApiFailure.networkUnavailable => ScreenTimeAuthorityStatus.unreachable,
          _ => ScreenTimeAuthorityStatus.refused,
        },
        openRequestId: FamilyScreenTimeApiClient.openRequestIdFrom(exception),
      );
    } on Object {
      return const ScreenTimeAuthorityAnswer.unavailable(
        ScreenTimeAuthorityStatus.unreachable,
      );
    }
  }
}

ScreenTimeServerAuthority? _activeScreenTimeAuthority;

/// The authority the screen-time screens read, or null when no server session is bound.
ScreenTimeServerAuthority? get activeScreenTimeServerAuthority =>
    _activeScreenTimeAuthority;

/// Binds every screen-time surface to one server session, or clears them all.
///
/// One call site, at boot: the state a parent reads, the app list, the lock and the answer
/// to a child's question all move together - a build that locked a phone through one path
/// while reading its minutes through another would be two products wearing one screen.
void bindScreenTimeServerAuthority(ScreenTimeServerAuthority? authority) {
  _activeScreenTimeAuthority = authority;
}
