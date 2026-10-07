import 'package:family_os/foundation_gate/family_web_filter_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Why the server could not answer, in the words a screen needs.
///
/// There is no `localFallback` value and there never will be. This surface's whole promise
/// is that the filter a family sees is the filter a phone applies, so a build that cannot
/// reach a server says so instead of drawing a shield it made up.
enum WebFilterAuthorityStatus {
  /// The answer came from the server and means what it says.
  ready,

  /// This build has no server session (no configured API origin, no selected family, no
  /// token). Nothing was asked, because there is nobody to ask.
  notConfigured,

  /// The server refused: this account may not read or change this child's filter.
  accessDenied,

  /// The server is configured but did not answer. Nothing on the screen may move.
  unreachable,

  /// The server answered with a refusal that has a reason - a stale policy, a host that is
  /// already waiting, a grant larger than the ask - which the screen shows as it is.
  refused,
}

/// One answer from the server, or the honest statement that there was none.
class WebFilterAuthorityAnswer<T> {
  const WebFilterAuthorityAnswer._({
    required this.status,
    required this.value,
  });

  const WebFilterAuthorityAnswer.ready(T value)
    : this._(status: WebFilterAuthorityStatus.ready, value: value);

  const WebFilterAuthorityAnswer.unavailable(WebFilterAuthorityStatus status)
    : this._(status: status, value: null);

  final WebFilterAuthorityStatus status;
  final T? value;

  bool get isReady => status == WebFilterAuthorityStatus.ready && value != null;
}

/// The web filter's one server connection.
///
/// It holds the client, the bearer token and the selected family, and it decides nothing
/// about the rules: the server computes the decision, the state and every number, and this
/// class only carries them to a screen - or reports, in a value a screen can render, that it
/// could not.
///
/// **What this build can and cannot do, stated once and plainly:**
///
///   * A GUARDIAN can read the filter, switch categories on and off, edit the two lists,
///     preview what a child would get for one host, read the questions, ask on a child's
///     behalf and answer. All of that is the live contract.
///   * The CHILD'S OWN handset does not fetch its policy or report its protection through
///     this class: those routes authenticate with the device credential, which this build
///     hands to the native layer at pairing and does not keep. They exist on the server, the
///     real-PostgreSQL journey covers them, and they are declared rather than imitated - a
///     screen that showed a phone a locally-invented filter would be exactly the lie this
///     wave deletes.
final class WebFilterServerAuthority {
  WebFilterServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyWebFilterApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// The family's filter for one child, with the doors open right now.
  Future<WebFilterAuthorityAnswer<FoundationGateWebFilterPolicy>> readPolicy(
    String childId,
  ) => _ask(
    (family, token) => api.readPolicy(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  /// Changes only the fields it is given, and reports a stale policy as a refusal so a
  /// screen can reload rather than silently overwriting another guardian's decision.
  Future<WebFilterAuthorityAnswer<FoundationGateWebFilterPolicy>> writePolicy(
    String childId, {
    FoundationGateWebFilterLevel? level,
    Set<FoundationGateWebFilterCategory>? categories,
    List<String>? allowHosts,
    List<String>? blockHosts,
    List<String>? dictionaryKeywords,
    int? expectedVersion,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.updatePolicy(
      familyId: family,
      childId: childId,
      idempotencyKey: idempotencyKey(),
      idToken: token,
      level: level,
      categories: categories,
      allowHosts: allowHosts,
      blockHosts: blockHosts,
      dictionaryKeywords: dictionaryKeywords,
      expectedVersion: expectedVersion,
    ),
  );

  /// The father's preview: the same rules the handset applies, so a screen can never
  /// promise a child a page the phone would refuse.
  Future<WebFilterAuthorityAnswer<FoundationGateWebDecision>> evaluate(
    String childId, {
    required String host,
  }) => _ask(
    (family, token) => api.evaluate(
      familyId: family,
      childId: childId,
      host: host,
      idToken: token,
    ),
  );

  Future<WebFilterAuthorityAnswer<FoundationGateTempAllow>> requestHost(
    String childId, {
    required String host,
    required int minutes,
    String reason = '',
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.requestTempAllow(
      familyId: family,
      childId: childId,
      host: host,
      minutes: minutes,
      reason: reason,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  /// The answer to one question. `grantedMinutes` may be fewer than the child asked for;
  /// the server refuses more rather than clamping, and so does this call.
  Future<WebFilterAuthorityAnswer<FoundationGateTempAllow>> decideHost(
    String childId, {
    required String requestId,
    required bool approve,
    int? grantedMinutes,
    required String Function() idempotencyKey,
  }) => _ask(
    (family, token) => api.decideTempAllow(
      familyId: family,
      childId: childId,
      requestId: requestId,
      approve: approve,
      grantedMinutes: grantedMinutes,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  Future<WebFilterAuthorityAnswer<List<FoundationGateTempAllow>>> openQuestions(
    String childId,
  ) => _ask(
    (family, token) => api.listTempAllows(
      familyId: family,
      childId: childId,
      idToken: token,
    ),
  );

  /// Whether protection is actually on. The answer carries `unverified` for a device that
  /// stopped reporting, and that is the honest answer rather than a failure to render.
  Future<WebFilterAuthorityAnswer<FoundationGateFamilyProtection>> protection() {
    final family = familyId();
    if (family == null || family.trim().isEmpty) {
      return Future.value(
        const WebFilterAuthorityAnswer.unavailable(
          WebFilterAuthorityStatus.notConfigured,
        ),
      );
    }
    return _ask(
      (resolved, token) => api.readProtection(
        familyId: resolved,
        idToken: token,
      ),
    );
  }

  Future<WebFilterAuthorityAnswer<T>> _ask<T>(
    Future<T> Function(String family, String token) run,
  ) async {
    final family = familyId();
    if (family == null || family.trim().isEmpty) {
      // Nothing is asked, because there is nobody to ask: a screen bound without a session
      // is a screen that says so.
      return const WebFilterAuthorityAnswer.unavailable(
        WebFilterAuthorityStatus.notConfigured,
      );
    }
    String token;
    try {
      token = await idToken();
    } on Object {
      return const WebFilterAuthorityAnswer.unavailable(
        WebFilterAuthorityStatus.notConfigured,
      );
    }
    if (token.trim().isEmpty) {
      return const WebFilterAuthorityAnswer.unavailable(
        WebFilterAuthorityStatus.notConfigured,
      );
    }
    try {
      return WebFilterAuthorityAnswer.ready(await run(family, token));
    } on FoundationGateApiException catch (exception) {
      return WebFilterAuthorityAnswer.unavailable(
        switch (exception.failure) {
          FoundationGateApiFailure.unauthenticated ||
          FoundationGateApiFailure.accessDenied =>
            WebFilterAuthorityStatus.accessDenied,
          FoundationGateApiFailure.networkUnavailable =>
            WebFilterAuthorityStatus.unreachable,
          _ => WebFilterAuthorityStatus.refused,
        },
      );
    } on Object {
      return const WebFilterAuthorityAnswer.unavailable(
        WebFilterAuthorityStatus.unreachable,
      );
    }
  }
}

WebFilterServerAuthority? _activeWebFilterAuthority;

/// The authority the web-filter screens read, or null when no server session is bound.
WebFilterServerAuthority? get activeWebFilterServerAuthority =>
    _activeWebFilterAuthority;

/// Binds every web-filter surface to one server session, or clears them all.
///
/// One call site, at boot: the policy a parent edits, the preview a parent reads, the
/// questions a family answers and the protection state all move together - a build that
/// filtered through one path while reporting health through another would be two products
/// wearing one screen.
void bindWebFilterServerAuthority(WebFilterServerAuthority? authority) {
  _activeWebFilterAuthority = authority;
}
