import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';

import 'web_filter_document.dart';
import 'web_filter_verdict.dart';

/// Deterministic Web Filter engine (WF-OD-08 precedence).
///
/// Order: blocklist → temp allow → allowlist → dictionary → category → allow.
/// Timed temporary allow is injected by callers (FS-002-ENF owns tickets).
/// Native VPN/DNS plane is **not** claimed here — domain verdict only.
abstract final class WebFilterEngine {
  /// Resolves effective document: child override wins when present (Q-WF-01).
  static WebFilterDocument resolveEffective({
    required WebFilterDocument? familyBaseline,
    required WebFilterDocument? childOverride,
    required FamilyId familyId,
  }) {
    if (childOverride != null) return childOverride;
    if (familyBaseline != null) return familyBaseline;
    return WebFilterDocument.familyDefaults(familyId);
  }

  /// Evaluates [url] against [document] (+ optional active temp allows).
  static WebFilterVerdict decide(
    Uri url,
    WebFilterDocument document, {
    Set<String> activeTemporaryAllows = const {},
  }) {
    final version = document.policyVersion;
    final host = WebFilterPolicy.normalizeHost(url.host);
    if (host.isEmpty) {
      return WebFilterVerdict.allow(policyVersion: version);
    }

    // 1. Blocklist → DENY (highest)
    if (_hostListed(host, document.blockList)) {
      return WebFilterVerdict.deny(
        policyVersion: version,
        denySource: WebFilterDenySource.blocklist,
      );
    }

    // 2. Active timed temporary allow → ALLOW (does not mutate allowlist)
    if (_hostListed(host, activeTemporaryAllows)) {
      return WebFilterVerdict.allow(
        policyVersion: version,
        allowSource: WebFilterAllowSource.temporaryAllow,
      );
    }

    // 3. Allowlist → ALLOW
    if (_hostListed(host, document.allowList)) {
      return WebFilterVerdict.allow(
        policyVersion: version,
        allowSource: WebFilterAllowSource.allowlist,
      );
    }

    // 4. Dictionary / keyword → DENY
    if (_dictionaryHit(url, host, document.dictionaryKeywords)) {
      return WebFilterVerdict.deny(
        policyVersion: version,
        denySource: WebFilterDenySource.dictionary,
      );
    }

    // 5. Category model → DENY
    final category = classifyHost(host);
    if (category != null && document.isCategoryEnabled(category)) {
      return WebFilterVerdict.deny(
        policyVersion: version,
        denySource: WebFilterDenySource.category,
        categoryKey: category,
      );
    }

    // 6/7. Safe Search TBD / else ALLOW — no fake enforcement claim
    return WebFilterVerdict.allow(policyVersion: version);
  }

  /// Stage-1 fixture classifier — same tokens as legacy evaluator.
  static String? classifyHost(String host) {
    final h = WebFilterPolicy.normalizeHost(host);
    if (h.isEmpty) return null;

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

  static bool _hostListed(String host, Set<String> list) {
    for (final entry in list) {
      final a = WebFilterPolicy.normalizeHost(entry);
      if (a.isEmpty) continue;
      if (host == a || host.endsWith('.$a')) return true;
    }
    return false;
  }

  static bool _dictionaryHit(Uri url, String host, Set<String> keywords) {
    if (keywords.isEmpty) return false;
    final hay = '$host ${url.path} ${url.query}'.toLowerCase();
    for (final kw in keywords) {
      if (kw.isNotEmpty && hay.contains(kw)) return true;
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

/// Load effective document for a child (override ∥ baseline ∥ defaults).
Future<WebFilterDocument> loadEffectiveDocument({
  required Future<WebFilterDocument?> Function() loadFamily,
  required Future<WebFilterDocument?> Function(ChildId childId) loadOverride,
  required FamilyId familyId,
  required ChildId childId,
}) async {
  final override = await loadOverride(childId);
  final baseline = await loadFamily();
  return WebFilterEngine.resolveEffective(
    familyBaseline: baseline,
    childOverride: override,
    familyId: familyId,
  );
}
