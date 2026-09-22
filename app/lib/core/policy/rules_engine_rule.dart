import 'package:flutter/foundation.dart';

import 'rule_consequent.dart';

/// Deterministic father-authored (or father-approved) RulesEngine rule (ADR-038).
///
/// Lives **outside** Advisor / Insights / Tutor AI gateways. Not an [AiSuggestion].
@immutable
final class RulesEngineRule {
  const RulesEngineRule({
    required this.id,
    required this.title,
    required this.body,
    required this.enabled,
    this.consequents = const [RuleConsequent.notifyFather],
    this.sourceSuggestionId,
    this.authoredByFather = true,
  });

  final String id;
  final String title;
  final String body;
  final bool enabled;

  /// Allow-listed consequents only (SET-023 / ADR-038(d)).
  final List<RuleConsequent> consequents;

  /// When set, rule was created by approving an AI suggestion (still not executable as AI).
  final String? sourceSuggestionId;

  /// A-5 — RulesEngine authorship is father-only.
  final bool authoredByFather;

  RulesEngineRule copyWith({
    String? id,
    String? title,
    String? body,
    bool? enabled,
    List<RuleConsequent>? consequents,
    String? sourceSuggestionId,
    bool? authoredByFather,
  }) {
    return RulesEngineRule(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      enabled: enabled ?? this.enabled,
      consequents: consequents ?? this.consequents,
      sourceSuggestionId: sourceSuggestionId ?? this.sourceSuggestionId,
      authoredByFather: authoredByFather ?? this.authoredByFather,
    );
  }
}
