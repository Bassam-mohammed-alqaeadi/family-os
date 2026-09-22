import 'package:flutter/foundation.dart';

/// Filter strictness for SET-004 (WFP.level).
enum WebFilterLevel { strict, balanced, open }

/// Known category keys (WFP.categories). Enabled = block matching URLs.
abstract final class WebFilterCategories {
  static const adults = 'adults';
  static const gambling = 'gambling';
  static const violence = 'violence';
  static const social = 'social';
  static const games = 'games';
  static const streaming = 'streaming';

  static const List<String> known = [
    adults,
    gambling,
    violence,
    social,
    games,
    streaming,
  ];

  static bool isKnown(String key) => known.contains(key);
}

/// Child web-filter policy snapshot (Rule 25 / SET-004).
@immutable
final class WebFilterPolicy {
  factory WebFilterPolicy({
    WebFilterLevel level = WebFilterLevel.balanced,
    Map<String, bool>? categories,
    Set<String>? allowList,
    int policyVersion = 1,
    DateTime? updatedAt,
  }) {
    final normalized = _normalizeCategories(level, categories);
    final allows = _normalizeHosts(allowList ?? const {});
    return WebFilterPolicy._(
      level: level,
      categories: Map<String, bool>.unmodifiable(normalized),
      allowList: Set<String>.unmodifiable(allows),
      policyVersion: policyVersion < 1 ? 1 : policyVersion,
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  const WebFilterPolicy._({
    required this.level,
    required this.categories,
    required this.allowList,
    required this.policyVersion,
    required this.updatedAt,
  });

  /// Stage-1 default: balanced presets.
  static WebFilterPolicy defaults() =>
      WebFilterPolicy(level: WebFilterLevel.balanced);

  /// Seeds category toggles for a level (UI preset; open still evaluates
  /// any explicit blocks the father leaves on).
  static Map<String, bool> categoriesForLevel(WebFilterLevel level) {
    return switch (level) {
      WebFilterLevel.strict => {
          for (final k in WebFilterCategories.known) k: true,
        },
      WebFilterLevel.balanced => {
          WebFilterCategories.adults: true,
          WebFilterCategories.gambling: true,
          WebFilterCategories.violence: true,
          WebFilterCategories.social: false,
          WebFilterCategories.games: false,
          WebFilterCategories.streaming: false,
        },
      WebFilterLevel.open => {
          for (final k in WebFilterCategories.known) k: false,
        },
    };
  }

  final WebFilterLevel level;

  /// Known keys only; `true` means block that category.
  final Map<String, bool> categories;

  /// Host exceptions — allow wins over category deny.
  final Set<String> allowList;

  /// Bumped on save for SET-005 snapshot identity.
  final int policyVersion;

  final DateTime updatedAt;

  bool isCategoryEnabled(String key) => categories[key] == true;

  WebFilterPolicy copyWith({
    WebFilterLevel? level,
    Map<String, bool>? categories,
    Set<String>? allowList,
    int? policyVersion,
    DateTime? updatedAt,
    bool applyLevelPreset = false,
  }) {
    final nextLevel = level ?? this.level;
    final nextCategories = applyLevelPreset && level != null
        ? categoriesForLevel(level)
        : (categories ?? this.categories);
    return WebFilterPolicy(
      level: nextLevel,
      categories: nextCategories,
      allowList: allowList ?? this.allowList,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  WebFilterPolicy withCategory(String key, bool enabled) {
    if (!WebFilterCategories.isKnown(key)) return this;
    final next = Map<String, bool>.from(categories);
    next[key] = enabled;
    return copyWith(categories: next);
  }

  Map<String, Object?> toJson() => {
        'level': level.name,
        'categories': categories,
        'allowList': allowList.toList()..sort(),
        'policyVersion': policyVersion,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory WebFilterPolicy.fromJson(Map<String, Object?> json) {
    final levelName = json['level'] as String? ?? WebFilterLevel.balanced.name;
    final level = WebFilterLevel.values.firstWhere(
      (l) => l.name == levelName,
      orElse: () => WebFilterLevel.balanced,
    );

    Map<String, bool>? cats;
    final rawCats = json['categories'];
    if (rawCats is Map) {
      cats = {
        for (final e in rawCats.entries)
          if (e.key != null) e.key.toString(): e.value == true,
      };
    }

    Set<String>? allows;
    final rawAllows = json['allowList'];
    if (rawAllows is List) {
      allows = {
        for (final item in rawAllows)
          if (item is String) item,
      };
    }

    final version = json['policyVersion'];
    DateTime? updated;
    final rawUpdated = json['updatedAt'];
    if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated)?.toUtc();
    }

    return WebFilterPolicy(
      level: level,
      categories: cats ?? categoriesForLevel(level),
      allowList: allows,
      policyVersion: version is int ? version : 1,
      updatedAt: updated,
    );
  }

  static Map<String, bool> _normalizeCategories(
    WebFilterLevel level,
    Map<String, bool>? input,
  ) {
    final base = Map<String, bool>.from(categoriesForLevel(level));
    if (input == null) return base;
    for (final e in input.entries) {
      if (WebFilterCategories.isKnown(e.key)) {
        base[e.key] = e.value;
      }
    }
    return base;
  }

  static Set<String> _normalizeHosts(Set<String> hosts) {
    final out = <String>{};
    for (final h in hosts) {
      final n = normalizeHost(h);
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }

  /// Lowercase host without leading `www.`.
  static String normalizeHost(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('www.')) h = h.substring(4);
    return h;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebFilterPolicy &&
          level == other.level &&
          mapEquals(categories, other.categories) &&
          setEquals(allowList, other.allowList) &&
          policyVersion == other.policyVersion &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        level,
        Object.hashAll(
          categories.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAll(allowList.toList()..sort()),
        policyVersion,
        updatedAt,
      );
}
