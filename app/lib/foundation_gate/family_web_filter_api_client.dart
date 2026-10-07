import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The six categories a family can switch on, named the way the server names them.
///
/// The same six live in `WebFilterCategories.known`, and a server-side test compares the
/// two lists: a toggle the server does not accept would be a switch that does nothing while
/// looking like it does something. That is the failure this wave exists to prevent, so the
/// comparison is a test rather than a comment.
enum FoundationGateWebFilterCategory {
  adults('adults'),
  gambling('gambling'),
  violence('violence'),
  social('social'),
  games('games'),
  streaming('streaming');

  const FoundationGateWebFilterCategory(this.wire);

  final String wire;

  static FoundationGateWebFilterCategory? parse(Object? value) {
    for (final category in values) {
      if (category.wire == value) return category;
    }
    return null;
  }
}

/// How strict the family chose to be. A preset, not a permission: what is enforced
/// afterwards is always the category list.
enum FoundationGateWebFilterLevel {
  strict('strict'),
  balanced('balanced'),
  open('open');

  const FoundationGateWebFilterLevel(this.wire);

  final String wire;

  static FoundationGateWebFilterLevel? parse(Object? value) {
    for (final level in values) {
      if (level.wire == value) return level;
    }
    return null;
  }
}

/// Why the engine refused a page. Stated rather than implied, so the child's block page and
/// the father's preview describe the same refusal the same way.
enum FoundationGateWebDenySource {
  blocklist('blocklist'),
  dictionary('dictionary'),
  category('category');

  const FoundationGateWebDenySource(this.wire);

  final String wire;

  static FoundationGateWebDenySource? parse(Object? value) {
    for (final source in values) {
      if (source.wire == value) return source;
    }
    return null;
  }
}

/// What a request for a host is now, computed from the stored decision and the clock.
/// `expired` is never stored: an approval carries the minute it closes at and closes itself.
enum FoundationGateTempAllowState {
  pending('pending'),
  active('active'),
  expired('expired'),
  denied('denied');

  const FoundationGateTempAllowState(this.wire);

  final String wire;

  static FoundationGateTempAllowState? parse(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

/// Whether protection is actually on. `unverified` is a first-class answer, not an error:
/// a device that stopped reporting is neither claimed safe nor called broken.
enum FoundationGateProtectionState {
  protected('protected'),
  atRisk('at_risk'),
  unverified('unverified'),
  unsupported('unsupported');

  const FoundationGateProtectionState(this.wire);

  final String wire;

  static FoundationGateProtectionState? parse(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

/// Why the state is what it is. A closed vocabulary, because "at risk" alone is not
/// something a family can act on - "a VPN is running" is.
enum FoundationGateProtectionReason {
  reportedHealthy('reported_healthy'),
  staleReport('stale_report'),
  neverReported('never_reported'),
  platformUnsupported('platform_unsupported'),
  unrecognisedObservation('unrecognised_observation'),
  vpnActive('vpn_active'),
  profileRemoved('profile_removed'),
  permissionRevoked('permission_revoked'),
  dnsBypassed('dns_bypassed'),
  deviceAdminRemoved('device_admin_removed');

  const FoundationGateProtectionReason(this.wire);

  final String wire;

  static FoundationGateProtectionReason? parse(Object? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

/// The family's stored filter for one child, with the doors that are open at this read.
class FoundationGateWebFilterPolicy {
  const FoundationGateWebFilterPolicy({
    required this.level,
    required this.enabledCategories,
    required this.allowHosts,
    required this.blockHosts,
    required this.dictionaryKeywords,
    required this.activeTempAllows,
    required this.version,
  });

  final FoundationGateWebFilterLevel level;
  final Set<FoundationGateWebFilterCategory> enabledCategories;
  final List<String> allowHosts;
  final List<String> blockHosts;
  final List<String> dictionaryKeywords;

  /// Computed by the server against the clock, never stored as "open".
  final List<String> activeTempAllows;

  final int version;

  bool isCategoryEnabled(FoundationGateWebFilterCategory category) =>
      enabledCategories.contains(category);
}

/// The server's answer about one host: allowed, or refused with the source stated.
class FoundationGateWebDecision {
  const FoundationGateWebDecision({
    required this.allowed,
    required this.denySource,
    required this.categoryKey,
    required this.policyVersion,
    required this.normalizedHost,
  });

  final bool allowed;
  final FoundationGateWebDenySource? denySource;

  /// The category that refused, when the source is `category`. Null otherwise.
  final FoundationGateWebFilterCategory? categoryKey;

  final int policyVersion;
  final String normalizedHost;
}

/// One request for a host, and the guardian's answer to it.
class FoundationGateTempAllow {
  const FoundationGateTempAllow({
    required this.id,
    required this.host,
    required this.status,
    required this.state,
    required this.requestedMinutes,
    required this.grantedMinutes,
    required this.reason,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String host;

  /// What was stored: `pending`, `approved` or `denied`.
  final String status;

  /// What to show. An approval whose minute has passed reads `expired` here.
  final FoundationGateTempAllowState state;

  final int requestedMinutes;

  /// The guardian's answer, never more than was asked. Null until answered, and on a denial.
  final int? grantedMinutes;

  final String reason;
  final DateTime? expiresAt;
  final DateTime createdAt;
}

/// One device's protection, as the server computed it from the newest report and the clock.
class FoundationGateDeviceProtection {
  const FoundationGateDeviceProtection({
    required this.deviceId,
    required this.deviceLabel,
    required this.state,
    required this.reason,
    required this.since,
    required this.ageMinutes,
    required this.signals,
  });

  final String deviceId;
  final String deviceLabel;
  final FoundationGateProtectionState state;
  final FoundationGateProtectionReason? reason;

  /// When the server heard the report this state is computed from. Null when it never did.
  final DateTime? since;

  /// How long the silence has lasted. Null when there was never a report to age.
  final int? ageMinutes;

  /// What the handset said it saw, verbatim. Empty is honest: nothing was observed.
  final List<String> signals;
}

/// The family's protection state: every device, with the counts a screen shows.
class FoundationGateFamilyProtection {
  const FoundationGateFamilyProtection({
    required this.devices,
    required this.protectedCount,
    required this.atRiskCount,
    required this.unverifiedCount,
    required this.unsupportedCount,
    required this.freshnessMinutes,
  });

  final List<FoundationGateDeviceProtection> devices;
  final int protectedCount;
  final int atRiskCount;
  final int unverifiedCount;
  final int unsupportedCount;

  /// How long a report speaks for. Beyond it a device reads `unverified`.
  final int freshnessMinutes;
}

/// The web filter's one connection to the server.
///
/// Nothing here invents state. A category, a decision, a permission state and every number
/// come from the server's own answer, and a value the server could not produce stays absent
/// rather than being defaulted into something a family might act on.
///
/// **What this build can and cannot do, stated once and plainly:** everything a GUARDIAN
/// does on this surface is here - read the policy, change it, preview a host, read the
/// questions, ask on a child's behalf and answer. The CHILD'S OWN handset does not fetch its
/// policy or report its protection through this class: those routes authenticate with the
/// device credential, which this build hands to the native layer at pairing and does not
/// keep. They exist on the server and are covered by the real-PostgreSQL journey.
class FamilyWebFilterApiClient {
  FamilyWebFilterApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  /// The family's stored filter for one child, with the doors open right now.
  Future<FoundationGateWebFilterPolicy> readPolicy({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildWebFilterUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parsePolicyEnvelope(response.body),
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

  /// Changes only the fields that were chosen.
  ///
  /// Every argument is optional for the same reason the server's body is: flipping one
  /// switch must not reset the other five. An entirely empty call is refused here rather
  /// than sent as a request that means nothing.
  Future<FoundationGateWebFilterPolicy> updatePolicy({
    required String familyId,
    required String childId,
    required String idempotencyKey,
    required String idToken,
    FoundationGateWebFilterLevel? level,
    Set<FoundationGateWebFilterCategory>? categories,
    List<String>? allowHosts,
    List<String>? blockHosts,
    List<String>? dictionaryKeywords,
    int? expectedVersion,
  }) async {
    if (level == null &&
        categories == null &&
        allowHosts == null &&
        blockHosts == null &&
        dictionaryKeywords == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final body = <String, Object>{};
    if (level != null) body['level'] = level.wire;
    if (categories != null) {
      body['categories'] = categories.map((entry) => entry.wire).toList();
    }
    if (allowHosts != null) body['allowHosts'] = allowHosts;
    if (blockHosts != null) body['blockHosts'] = blockHosts;
    if (dictionaryKeywords != null) {
      body['dictionaryKeywords'] = dictionaryKeywords;
    }
    if (expectedVersion != null) body['expectedVersion'] = expectedVersion;
    final response = await _patch(
      _configuration.familyChildWebFilterUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parsePolicyEnvelope(response.body),
      400 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
      ),
      409 => throw const FoundationGateApiException(
        FoundationGateApiFailure.conflict,
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

  /// What this child would get for one host - the same rules the handset applies.
  Future<FoundationGateWebDecision> evaluate({
    required String familyId,
    required String childId,
    required String host,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildWebFilterEvaluateUri(familyId, childId, host),
      idToken,
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
      429 || 503 => throw const FoundationGateApiException(
        FoundationGateApiFailure.serviceUnavailable,
      ),
      _ => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      ),
    };
  }

  /// Every question this child asked or was given, newest first.
  Future<List<FoundationGateTempAllow>> listTempAllows({
    required String familyId,
    required String childId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyChildWebFilterTempAllowsUri(familyId, childId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseTempAllowList(response.body),
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

  /// A guardian asks on a child's behalf. A child who speaks rather than taps still gets a
  /// record, and the question lands in the same inbox either way.
  Future<FoundationGateTempAllow> requestTempAllow({
    required String familyId,
    required String childId,
    required String host,
    required int minutes,
    required String idempotencyKey,
    required String idToken,
    String reason = '',
  }) async {
    final body = <String, Object>{
      'host': host,
      'minutes': minutes,
      if (reason.isNotEmpty) 'reason': reason,
    };
    final response = await _post(
      _configuration.familyChildWebFilterTempAllowsUri(familyId, childId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      201 => _parseTempAllowEnvelope(response.body),
      400 || 422 => throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      ),
      401 => throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      ),
      403 => throw const FoundationGateApiException(
        FoundationGateApiFailure.accessDenied,
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

  /// Approve a door or refuse it.
  ///
  /// `grantedMinutes` may be fewer than the child asked for; the server refuses more, and
  /// this client does not silently clamp it, because a screen that quietly changes a
  /// guardian's decision is worse than one that reports the refusal.
  Future<FoundationGateTempAllow> decideTempAllow({
    required String familyId,
    required String childId,
    required String requestId,
    required bool approve,
    required String idempotencyKey,
    required String idToken,
    int? grantedMinutes,
  }) async {
    final body = <String, Object>{'decision': approve ? 'approve' : 'deny'};
    if (approve && grantedMinutes != null) {
      body['grantedMinutes'] = grantedMinutes;
    }
    final response = await _post(
      _configuration.familyChildWebFilterTempAllowDecisionUri(
        familyId,
        childId,
        requestId,
      ),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    return switch (response.statusCode) {
      200 => _parseTempAllowEnvelope(response.body),
      400 || 422 => throw const FoundationGateApiException(
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

  /// Whether protection is actually on, device by device.
  Future<FoundationGateFamilyProtection> readProtection({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyProtectionUri(familyId),
      idToken,
    );
    return switch (response.statusCode) {
      200 => _parseProtection(response.body),
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

  // ── parsing ────────────────────────────────────────────────────────────────────────
  //
  // Every parser is strict about the shape and refuses to guess: a body that is not the
  // documented object, or a value outside the declared vocabulary, becomes
  // `invalidResponse` instead of a screen showing something the server never said.

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

  static List<String> _stringList(Object? value, String field) {
    if (value is! List) {
      throw FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
        details: <String, Object?>{'field': field},
      );
    }
    return value.map((item) => _string(item, field)).toList(growable: false);
  }

  static DateTime? _instant(Object? value, String field) {
    if (value == null) return null;
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
    return parsed.toUtc();
  }

  static Map<String, Object?> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static FoundationGateWebFilterPolicy _parsePolicy(Object? value) {
    final policy = _object(value, 'policy');
    final rawCategories = policy['enabledCategories'];
    if (rawCategories is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final categories = <FoundationGateWebFilterCategory>{};
    for (final entry in rawCategories) {
      final category = FoundationGateWebFilterCategory.parse(entry);
      if (category == null) {
        // A category this build cannot name is not silently ignored: a screen that dropped
        // it would show a family fewer switches than the server is enforcing.
        throw FoundationGateApiException(
          FoundationGateApiFailure.invalidResponse,
          details: <String, Object?>{'category': entry},
        );
      }
      categories.add(category);
    }
    final level = FoundationGateWebFilterLevel.parse(policy['level']);
    if (level == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateWebFilterPolicy(
      level: level,
      enabledCategories: Set.unmodifiable(categories),
      allowHosts: _stringList(policy['allowHosts'], 'allowHosts'),
      blockHosts: _stringList(policy['blockHosts'], 'blockHosts'),
      dictionaryKeywords: _stringList(
        policy['dictionaryKeywords'],
        'dictionaryKeywords',
      ),
      activeTempAllows: _stringList(
        policy['activeTempAllows'],
        'activeTempAllows',
      ),
      version: _integer(policy['version'], 'version'),
    );
  }

  static FoundationGateWebFilterPolicy _parsePolicyEnvelope(String body) =>
      _parsePolicy(_decode(body)['policy']);

  static FoundationGateWebDecision _parseDecision(String body) {
    final decoded = _decode(body);
    final allowed = decoded['allowed'];
    if (allowed is! bool) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawSource = decoded['denySource'];
    final source = rawSource == null
        ? null
        : FoundationGateWebDenySource.parse(rawSource);
    if (rawSource != null && source == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawCategory = decoded['categoryKey'];
    final category = rawCategory == null
        ? null
        : FoundationGateWebFilterCategory.parse(rawCategory);
    if (rawCategory != null && category == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return FoundationGateWebDecision(
      allowed: allowed,
      denySource: source,
      categoryKey: category,
      policyVersion: _integer(decoded['policyVersion'], 'policyVersion'),
      normalizedHost: _string(decoded['normalizedHost'], 'normalizedHost'),
    );
  }

  static FoundationGateTempAllow _parseTempAllow(Object? value) {
    final request = _object(value, 'request');
    final state = FoundationGateTempAllowState.parse(request['state']);
    if (state == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final createdAt = _instant(request['createdAt'], 'createdAt');
    if (createdAt == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final granted = request['grantedMinutes'];
    return FoundationGateTempAllow(
      id: _string(request['id'], 'id'),
      host: _string(request['host'], 'host'),
      status: _string(request['status'], 'status'),
      state: state,
      requestedMinutes: _integer(request['requestedMinutes'], 'requestedMinutes'),
      grantedMinutes: granted == null
          ? null
          : _integer(granted, 'grantedMinutes'),
      reason: request['reason'] is String ? request['reason']! as String : '',
      expiresAt: _instant(request['expiresAt'], 'expiresAt'),
      createdAt: createdAt,
    );
  }

  static FoundationGateTempAllow _parseTempAllowEnvelope(String body) =>
      _parseTempAllow(_decode(body)['request']);

  static List<FoundationGateTempAllow> _parseTempAllowList(String body) {
    final raw = _decode(body)['requests'];
    if (raw is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return raw
        .map((entry) => _parseTempAllow(entry))
        .toList(growable: false);
  }

  static FoundationGateDeviceProtection _parseDevice(Object? value) {
    final device = _object(value, 'device');
    final state = FoundationGateProtectionState.parse(device['state']);
    if (state == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawReason = device['reason'];
    final reason = rawReason == null
        ? null
        : FoundationGateProtectionReason.parse(rawReason);
    if (rawReason != null && reason == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final rawAge = device['ageMinutes'];
    return FoundationGateDeviceProtection(
      deviceId: _string(device['deviceId'], 'deviceId'),
      deviceLabel: _string(device['deviceLabel'], 'deviceLabel'),
      state: state,
      reason: reason,
      since: _instant(device['since'], 'since'),
      ageMinutes: rawAge == null ? null : _integer(rawAge, 'ageMinutes'),
      signals: _stringList(device['signals'], 'signals'),
    );
  }

  static FoundationGateFamilyProtection _parseProtection(String body) {
    final decoded = _decode(body);
    final rawDevices = decoded['devices'];
    if (rawDevices is! List) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    final counts = _object(decoded['counts'], 'counts');
    return FoundationGateFamilyProtection(
      devices: rawDevices
          .map((entry) => _parseDevice(entry))
          .toList(growable: false),
      protectedCount: _integer(counts['protected'], 'counts.protected'),
      atRiskCount: _integer(counts['at_risk'], 'counts.at_risk'),
      unverifiedCount: _integer(counts['unverified'], 'counts.unverified'),
      unsupportedCount: _integer(counts['unsupported'], 'counts.unsupported'),
      freshnessMinutes: _integer(
        decoded['freshnessMinutes'],
        'freshnessMinutes',
      ),
    );
  }

  // ── transport ──────────────────────────────────────────────────────────────────────

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

  Future<FoundationGateHttpResponse> _patch(
    Uri uri,
    String idToken,
    Map<String, Object> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.patch(
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
}
