import 'package:flutter/foundation.dart';

/// Why Web Filter denied navigation (source-of-deny · WF-OD-12 / Q-WF-12).
enum WebFilterDenySource {
  /// Explicit blocklist host hit (highest deny).
  blocklist,

  /// Keyword dictionary hit.
  dictionary,

  /// Category model hit (Stage-1 taxonomy; T-WF-02 TBD).
  category,
}

extension WebFilterDenySourceWire on WebFilterDenySource {
  String get wireName => switch (this) {
    WebFilterDenySource.blocklist => 'BLOCKLIST',
    WebFilterDenySource.dictionary => 'DICTIONARY',
    WebFilterDenySource.category => 'CATEGORY',
  };

  /// Family-safe reason class token for interstitial / preview.
  String get reasonClass => switch (this) {
    WebFilterDenySource.blocklist => 'blocklist',
    WebFilterDenySource.dictionary => 'dictionary',
    WebFilterDenySource.category => 'category',
  };

  static WebFilterDenySource parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'BLOCKLIST':
        return WebFilterDenySource.blocklist;
      case 'DICTIONARY':
        return WebFilterDenySource.dictionary;
      case 'CATEGORY':
        return WebFilterDenySource.category;
      default:
        throw FormatException('Unknown WebFilterDenySource: $raw');
    }
  }
}

/// How allow was granted (audit / preview honesty).
enum WebFilterAllowSource { defaultAllow, allowlist, temporaryAllow }

@immutable
final class WebFilterVerdict {
  const WebFilterVerdict.allow({
    required this.policyVersion,
    this.allowSource = WebFilterAllowSource.defaultAllow,
  }) : denied = false,
       denySource = null,
       categoryKey = null;

  const WebFilterVerdict.deny({
    required this.policyVersion,
    required this.denySource,
    this.categoryKey,
  }) : denied = true,
       allowSource = null;

  final bool denied;
  final int policyVersion;
  final WebFilterDenySource? denySource;
  final WebFilterAllowSource? allowSource;
  final String? categoryKey;

  String? get reasonClass => denySource?.reasonClass;
}
