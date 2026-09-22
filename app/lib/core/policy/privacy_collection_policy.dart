import 'package:flutter/foundation.dart';

import 'collection_scope.dart';

/// Per-child collection scopes (SET-012 / P-7 / `S-ADM-035`).
@immutable
final class PrivacyCollectionPolicy {
  const PrivacyCollectionPolicy({
    required this.childId,
    required this.scopes,
    this.updatedAt,
  });

  /// Stage-1 default: all lean scopes collecting (honest baseline).
  factory PrivacyCollectionPolicy.defaults({required String childId}) {
    return PrivacyCollectionPolicy(
      childId: childId,
      scopes: {
        for (final s in kLeanCollectionScopes) s: true,
      },
    );
  }

  final String childId;
  final Map<CollectionScope, bool> scopes;
  final DateTime? updatedAt;

  bool isEnabled(CollectionScope scope) => scopes[scope] ?? false;

  /// Enabled scopes only — child transparency list input.
  List<CollectionScope> get enabledScopes => [
        for (final s in kLeanCollectionScopes)
          if (isEnabled(s)) s,
      ];

  PrivacyCollectionPolicy copyWith({
    String? childId,
    Map<CollectionScope, bool>? scopes,
    DateTime? updatedAt,
  }) {
    return PrivacyCollectionPolicy(
      childId: childId ?? this.childId,
      scopes: scopes ?? Map<CollectionScope, bool>.from(this.scopes),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  PrivacyCollectionPolicy withScope(CollectionScope scope, bool enabled) {
    final next = Map<CollectionScope, bool>.from(scopes);
    next[scope] = enabled;
    return copyWith(scopes: next);
  }

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'scopes': {
          for (final s in kLeanCollectionScopes) s.key: isEnabled(s),
        },
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };

  factory PrivacyCollectionPolicy.fromJson(Map<String, dynamic> json) {
    final childId = (json['childId'] ?? '').toString();
    final rawScopes = json['scopes'];
    final scopes = <CollectionScope, bool>{
      for (final s in kLeanCollectionScopes) s: true,
    };
    if (rawScopes is Map) {
      for (final e in rawScopes.entries) {
        final scope = CollectionScope.tryParse(e.key.toString());
        if (scope == null) continue;
        final v = e.value;
        scopes[scope] = v == true || v == 'true' || v == 1;
      }
    }
    DateTime? updatedAt;
    final rawAt = json['updatedAt'];
    if (rawAt is String && rawAt.isNotEmpty) {
      updatedAt = DateTime.tryParse(rawAt)?.toUtc();
    }
    return PrivacyCollectionPolicy(
      childId: childId,
      scopes: scopes,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyCollectionPolicy &&
          other.childId == childId &&
          other.updatedAt == updatedAt &&
          _scopesEqual(other.scopes, scopes);

  @override
  int get hashCode => Object.hash(
        childId,
        updatedAt,
        Object.hashAll(
          kLeanCollectionScopes.map((s) => scopes[s]),
        ),
      );
}

bool _scopesEqual(
  Map<CollectionScope, bool> a,
  Map<CollectionScope, bool> b,
) {
  for (final s in kLeanCollectionScopes) {
    if ((a[s] ?? false) != (b[s] ?? false)) return false;
  }
  return true;
}
