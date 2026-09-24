import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/web_filter/web_filter_document.dart';
import 'package:family_os/core/web_filter/web_filter_engine.dart';
import 'package:family_os/core/web_filter/web_filter_verdict.dart';

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

  /// Category key when denied via category; null otherwise.
  String? get categoryKey;

  /// Source-of-deny for interstitial honesty (null when allowed).
  WebFilterDenySource? get denySource;
}

/// Navigation allowed.
final class WebFilterAllow extends WebFilterDecision {
  const WebFilterAllow({
    required super.policyVersion,
    this.allowSource = WebFilterAllowSource.defaultAllow,
  });

  final WebFilterAllowSource allowSource;

  @override
  bool get isDenied => false;

  @override
  String? get categoryKey => null;

  @override
  WebFilterDenySource? get denySource => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterAllow &&
          policyVersion == other.policyVersion &&
          allowSource == other.allowSource;

  @override
  int get hashCode => Object.hash(runtimeType, policyVersion, allowSource);
}

/// Navigation denied.
final class WebFilterDeny extends WebFilterDecision {
  const WebFilterDeny(
    this.category, {
    required super.policyVersion,
    this.source = WebFilterDenySource.category,
  });

  /// Category key when [source] is category; otherwise a reason token.
  final String category;

  final WebFilterDenySource source;

  @override
  bool get isDenied => true;

  @override
  String? get categoryKey =>
      source == WebFilterDenySource.category ? category : null;

  @override
  WebFilterDenySource? get denySource => source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterDeny &&
          category == other.category &&
          policyVersion == other.policyVersion &&
          source == other.source;

  @override
  int get hashCode => Object.hash(runtimeType, category, policyVersion, source);
}

/// Shared URL+policy verdict used by child [WebBlockPage] and father preview.
@immutable
final class WebFilterDecisionSnapshot {
  const WebFilterDecisionSnapshot({
    required this.url,
    required this.host,
    required this.decision,
    required this.policyVersion,
  });

  /// Builds a snapshot via [WebFilterEvaluator.decide] — single path for both UIs.
  factory WebFilterDecisionSnapshot.evaluate(
    Uri url,
    WebFilterPolicy policy, {
    Set<String> activeTemporaryAllows = const {},
  }) {
    final decision = WebFilterEvaluator.decide(
      url,
      policy,
      activeTemporaryAllows: activeTemporaryAllows,
    );
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

  WebFilterDenySource? get denySource => decision.denySource;

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

/// Web filter decision engine — FS-002 precedence via [WebFilterEngine].
///
/// Order: blocklist → temp allow → allowlist → dictionary → category → allow.
/// Level `open` does **not** skip explicit category blocks (spec edge case).
abstract final class WebFilterEvaluator {
  /// Decides whether [url] may load under [policy].
  static WebFilterDecision decide(
    Uri url,
    WebFilterPolicy policy, {
    Set<String> activeTemporaryAllows = const {},
  }) {
    // Bridge Stage-1 policy → domain document (ephemeral family id).
    final doc = WebFilterDocument.fromStage1Policy(
      familyId: FamilyId('wf_bridge'),
      scopeKind: WebFilterScopeKind.familyBaseline,
      policy: policy,
    );
    final verdict = WebFilterEngine.decide(
      url,
      doc,
      activeTemporaryAllows: activeTemporaryAllows,
    );
    return _fromVerdict(verdict);
  }

  static WebFilterDecision _fromVerdict(WebFilterVerdict v) {
    if (!v.denied) {
      return WebFilterAllow(
        policyVersion: v.policyVersion,
        allowSource: v.allowSource ?? WebFilterAllowSource.defaultAllow,
      );
    }
    final source = v.denySource ?? WebFilterDenySource.category;
    final label = switch (source) {
      WebFilterDenySource.blocklist => 'blocklist',
      WebFilterDenySource.dictionary => 'dictionary',
      WebFilterDenySource.category => v.categoryKey ?? 'category',
    };
    return WebFilterDeny(label, policyVersion: v.policyVersion, source: source);
  }

  /// Stage-1 fixture classifier — host token → category key.
  static String? classifyHost(String host) =>
      WebFilterEngine.classifyHost(host);
}
