import 'package:flutter/foundation.dart';

import 'web_filter_policy.dart';

/// Outcome of [WebFilterEvaluator.decide] / [WebFilterDecisionSnapshot.evaluate].
///
/// Always carries [policyVersion] so child block page and father preview
/// can assert they share the same WFP snapshot (SET-005).
sealed class WebFilterDecision {
  const WebFilterDecision({required this.policyVersion});

  /// [WebFilterPolicy.policyVersion] at decision time.
  final int policyVersion;

  /// True when navigation must be blocked.
  bool get isDenied;

  /// Category key when denied; null when allowed.
  String? get categoryKey;
}

/// Navigation allowed.
final class WebFilterAllow extends WebFilterDecision {
  const WebFilterAllow({required super.policyVersion});

  @override
  bool get isDenied => false;

  @override
  String? get categoryKey => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterAllow && policyVersion == other.policyVersion;

  @override
  int get hashCode => Object.hash(runtimeType, policyVersion);
}

/// Navigation denied because [category] is enabled on the policy.
final class WebFilterDeny extends WebFilterDecision {
  const WebFilterDeny(this.category, {required super.policyVersion});

  final String category;

  @override
  bool get isDenied => true;

  @override
  String? get categoryKey => category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterDeny &&
          category == other.category &&
          policyVersion == other.policyVersion;

  @override
  int get hashCode => Object.hash(runtimeType, category, policyVersion);
}

/// Shared URL+policy verdict used by child [WebBlockPage] and father preview.
///
/// UI-009 / SET-005 / P-8: both UIs MUST call this factory — never a parallel
/// evaluator. Re-evaluate on each open: if the father changes policy while a
/// preview sheet is closed, the next open uses the fresh `policy_version`
/// snapshot (stale→refresh).
@immutable
final class WebFilterDecisionSnapshot {
  const WebFilterDecisionSnapshot({
    required this.url,
    required this.host,
    required this.decision,
    required this.policyVersion,
  });

  /// Builds a snapshot via [WebFilterEvaluator.decide] — single path for both UIs.
  factory WebFilterDecisionSnapshot.evaluate(Uri url, WebFilterPolicy policy) {
    final decision = WebFilterEvaluator.decide(url, policy);
    // Single source: decision.policyVersion (== policy.policyVersion).
    return WebFilterDecisionSnapshot(
      url: url,
      host: WebFilterPolicy.normalizeHost(url.host),
      decision: decision,
      policyVersion: decision.policyVersion,
    );
  }

  final Uri url;

  /// Safe display host (normalized, no scheme/path).
  final String host;

  final WebFilterDecision decision;

  final int policyVersion;

  bool get isDenied => decision.isDenied;

  String? get categoryKey => decision.categoryKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterDecisionSnapshot &&
          url == other.url &&
          host == other.host &&
          decision == other.decision &&
          policyVersion == other.policyVersion;

  @override
  int get hashCode => Object.hash(url, host, decision, policyVersion);
}

/// Stage-1 web filter decision engine (SET-004 / SET-005).
///
/// Order: allow-list host → category match when enabled → else allow.
/// Level `open` does **not** skip explicit category blocks (spec edge case).
abstract final class WebFilterEvaluator {
  /// Decides whether [url] may load under [policy].
  static WebFilterDecision decide(Uri url, WebFilterPolicy policy) {
    final version = policy.policyVersion;
    final host = WebFilterPolicy.normalizeHost(url.host);
    if (host.isEmpty) return WebFilterAllow(policyVersion: version);

    if (_isAllowListed(host, policy.allowList)) {
      return WebFilterAllow(policyVersion: version);
    }

    final category = classifyHost(host);
    if (category != null && policy.isCategoryEnabled(category)) {
      return WebFilterDeny(category, policyVersion: version);
    }

    return WebFilterAllow(policyVersion: version);
  }

  /// Stage-1 fixture classifier — host token → category key.
  ///
  /// Example: `adult.example` → [WebFilterCategories.adults].
  static String? classifyHost(String host) {
    final h = WebFilterPolicy.normalizeHost(host);
    if (h.isEmpty) return null;

    // Explicit fixture hosts first.
    const fixtures = <String, String>{
      'adult.example': WebFilterCategories.adults,
      'gambling.example': WebFilterCategories.gambling,
      'casino.example': WebFilterCategories.gambling,
      'violence.example': WebFilterCategories.violence,
      'social.example': WebFilterCategories.social,
      'games.example': WebFilterCategories.games,
      'streaming.example': WebFilterCategories.streaming,
    };
    final exact = fixtures[h];
    if (exact != null) return exact;

    // Subdomain / keyword fallbacks for fixtures like adult.example.com.
    if (_hostMatches(h, const ['adult', 'porn', 'xxx'])) {
      return WebFilterCategories.adults;
    }
    if (_hostMatches(h, const ['gambling', 'casino', 'betting'])) {
      return WebFilterCategories.gambling;
    }
    if (_hostMatches(h, const ['violence', 'gore'])) {
      return WebFilterCategories.violence;
    }
    if (_hostMatches(h, const ['social', 'facebook', 'instagram', 'tiktok'])) {
      return WebFilterCategories.social;
    }
    if (_hostMatches(h, const ['games', 'steam', 'roblox'])) {
      return WebFilterCategories.games;
    }
    if (_hostMatches(h, const ['streaming', 'netflix', 'youtube', 'twitch'])) {
      return WebFilterCategories.streaming;
    }
    return null;
  }

  static bool _isAllowListed(String host, Set<String> allowList) {
    for (final entry in allowList) {
      final a = WebFilterPolicy.normalizeHost(entry);
      if (a.isEmpty) continue;
      if (host == a || host.endsWith('.$a')) return true;
    }
    return false;
  }

  static bool _hostMatches(String host, List<String> tokens) {
    for (final t in tokens) {
      if (host == t ||
          host.startsWith('$t.') ||
          host.contains('.$t.') ||
          host.endsWith('.$t')) {
        return true;
      }
    }
    return false;
  }
}
