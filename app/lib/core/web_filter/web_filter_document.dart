import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/web_filter_policy.dart';

/// Scope of a Web Filter policy document (Q-WF-01 / WF-OD-01).
enum WebFilterScopeKind {
  /// Family baseline — applies when no child override exists.
  familyBaseline,

  /// Per-child override — wins when present.
  childOverride,
}

/// Authoritative Web Filter policy document (lists + categories + level).
@immutable
final class WebFilterDocument {
  factory WebFilterDocument({
    required FamilyId familyId,
    required WebFilterScopeKind scopeKind,
    ChildId? childId,
    WebFilterLevel level = WebFilterLevel.balanced,
    Map<String, bool>? categories,
    Set<String>? allowList,
    Set<String>? blockList,
    Set<String>? dictionaryKeywords,
    int policyVersion = 1,
    DateTime? updatedAt,
  }) {
    if (scopeKind == WebFilterScopeKind.childOverride && childId == null) {
      throw ArgumentError('childOverride requires childId');
    }
    if (scopeKind == WebFilterScopeKind.familyBaseline && childId != null) {
      throw ArgumentError('familyBaseline must not set childId');
    }
    final normalizedCats = Map<String, bool>.from(
      WebFilterPolicy.categoriesForLevel(level),
    );
    if (categories != null) {
      for (final e in categories.entries) {
        if (WebFilterCategories.isKnown(e.key)) {
          normalizedCats[e.key] = e.value;
        }
      }
    }
    return WebFilterDocument._(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      level: level,
      categories: Map<String, bool>.unmodifiable(normalizedCats),
      allowList: Set<String>.unmodifiable(_hosts(allowList)),
      blockList: Set<String>.unmodifiable(_hosts(blockList)),
      dictionaryKeywords: Set<String>.unmodifiable(
        _keywords(dictionaryKeywords),
      ),
      policyVersion: policyVersion < 1 ? 1 : policyVersion,
      updatedAt:
          updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  const WebFilterDocument._({
    required this.familyId,
    required this.scopeKind,
    required this.childId,
    required this.level,
    required this.categories,
    required this.allowList,
    required this.blockList,
    required this.dictionaryKeywords,
    required this.policyVersion,
    required this.updatedAt,
  });

  /// Stable primary key for SQLite (`family` or `child:<id>`).
  String get scopeKey => switch (scopeKind) {
    WebFilterScopeKind.familyBaseline => 'family',
    WebFilterScopeKind.childOverride => 'child:${childId!.value}',
  };

  final FamilyId familyId;
  final WebFilterScopeKind scopeKind;
  final ChildId? childId;
  final WebFilterLevel level;
  final Map<String, bool> categories;
  final Set<String> allowList;
  final Set<String> blockList;
  final Set<String> dictionaryKeywords;
  final int policyVersion;
  final DateTime updatedAt;

  /// Stage-1 six keys remain fixtures; taxonomy is TBD (Q-WF-05 / T-WF-02).
  static const bool taxonomyIsTbd = true;

  bool isCategoryEnabled(String key) => categories[key] == true;

  WebFilterDocument copyWith({
    WebFilterLevel? level,
    Map<String, bool>? categories,
    Set<String>? allowList,
    Set<String>? blockList,
    Set<String>? dictionaryKeywords,
    int? policyVersion,
    DateTime? updatedAt,
    bool applyLevelPreset = false,
  }) {
    final nextLevel = level ?? this.level;
    final nextCats = applyLevelPreset && level != null
        ? WebFilterPolicy.categoriesForLevel(level)
        : (categories ?? this.categories);
    return WebFilterDocument(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      level: nextLevel,
      categories: nextCats,
      allowList: allowList ?? this.allowList,
      blockList: blockList ?? this.blockList,
      dictionaryKeywords: dictionaryKeywords ?? this.dictionaryKeywords,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Bridge to Stage-1 [WebFilterPolicy] for existing screens / unlock.
  WebFilterPolicy toStage1Policy() => WebFilterPolicy(
    level: level,
    categories: categories,
    allowList: allowList,
    blockList: blockList,
    dictionaryKeywords: dictionaryKeywords,
    policyVersion: policyVersion,
    updatedAt: updatedAt,
  );

  factory WebFilterDocument.fromStage1Policy({
    required FamilyId familyId,
    required WebFilterScopeKind scopeKind,
    ChildId? childId,
    required WebFilterPolicy policy,
  }) {
    return WebFilterDocument(
      familyId: familyId,
      scopeKind: scopeKind,
      childId: childId,
      level: policy.level,
      categories: policy.categories,
      allowList: policy.allowList,
      blockList: policy.blockList,
      dictionaryKeywords: policy.dictionaryKeywords,
      policyVersion: policy.policyVersion,
      updatedAt: policy.updatedAt,
    );
  }

  factory WebFilterDocument.familyDefaults(FamilyId familyId) =>
      WebFilterDocument(
        familyId: familyId,
        scopeKind: WebFilterScopeKind.familyBaseline,
      );

  Map<String, Object?> toRow() => {
    'scope_key': scopeKey,
    'family_id': familyId.value,
    'child_id': childId?.value,
    'level': level.name,
    'categories_json': jsonEncode(categories),
    'allow_json': jsonEncode(allowList.toList()..sort()),
    'block_json': jsonEncode(blockList.toList()..sort()),
    'dict_json': jsonEncode(dictionaryKeywords.toList()..sort()),
    'policy_version': policyVersion,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory WebFilterDocument.fromRow(Map<String, Object?> row) {
    final childRaw = row['child_id'] as String?;
    final scope = childRaw == null || childRaw.isEmpty
        ? WebFilterScopeKind.familyBaseline
        : WebFilterScopeKind.childOverride;
    final levelName = row['level'] as String? ?? WebFilterLevel.balanced.name;
    final level = WebFilterLevel.values.firstWhere(
      (l) => l.name == levelName,
      orElse: () => WebFilterLevel.balanced,
    );
    return WebFilterDocument(
      familyId: FamilyId(row['family_id']! as String),
      scopeKind: scope,
      childId: scope == WebFilterScopeKind.childOverride
          ? ChildId(childRaw!)
          : null,
      level: level,
      categories: _decodeBoolMap(row['categories_json'] as String? ?? '{}'),
      allowList: _decodeStringSet(row['allow_json'] as String? ?? '[]'),
      blockList: _decodeStringSet(row['block_json'] as String? ?? '[]'),
      dictionaryKeywords: _decodeStringSet(row['dict_json'] as String? ?? '[]'),
      policyVersion: row['policy_version'] as int? ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int? ?? 0,
        isUtc: true,
      ),
    );
  }

  static Map<String, bool> _decodeBoolMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return {
      for (final e in decoded.entries)
        if (e.key != null) e.key.toString(): e.value == true,
    };
  }

  static Set<String> _decodeStringSet(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return {};
    return {
      for (final item in decoded)
        if (item is String) item,
    };
  }

  static Set<String> _hosts(Set<String>? hosts) {
    final out = <String>{};
    for (final h in hosts ?? const <String>{}) {
      final n = WebFilterPolicy.normalizeHost(h);
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }

  static Set<String> _keywords(Set<String>? words) {
    final out = <String>{};
    for (final w in words ?? const <String>{}) {
      final n = w.trim().toLowerCase();
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }
}
