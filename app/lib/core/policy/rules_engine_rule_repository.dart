import 'package:flutter/foundation.dart';

import 'advisor_repository.dart';
import 'rule_consequent.dart';
import 'rules_engine_rule.dart';

/// Father-authored deterministic rules store (ADR-038 / A-5).
///
/// **Not** an AI gateway — must not implement Advisor / Insights / Tutor repos.
abstract class RulesEngineRuleRepository {
  Future<List<RulesEngineRule>> listEnabled();

  Future<List<RulesEngineRule>> listAll();

  /// Creates an enabled rule from an approved suggestion (suggestion stays non-executable).
  ///
  /// Rejects when [AiSuggestion.proposedConsequentIds] includes ADR-038(d)
  /// forbidden consequents (SET-023).
  Future<RulesEngineRule> addFromApprovedSuggestion(AiSuggestion suggestion);

  /// Validates raw consequent wire ids (throws on forbidden / unknown).
  void validate(Iterable<String> consequentIds);

  /// Persists a father-authored rule after [validate]. Rejects forbidden payloads.
  Future<RulesEngineRule> save({
    required String title,
    required String body,
    required List<String> consequentIds,
    bool enabled = true,
    String? id,
  });
}

/// In-memory Stage-1 mock — no real RulesEngine fire (SET-024+).
final class InMemoryRulesEngineRuleRepository
    implements RulesEngineRuleRepository {
  InMemoryRulesEngineRuleRepository({List<RulesEngineRule>? seed})
      : _rules = List<RulesEngineRule>.from(seed ?? const []);

  final List<RulesEngineRule> _rules;
  var _seq = 0;

  @override
  Future<List<RulesEngineRule>> listAll() {
    return SynchronousFuture(List.unmodifiable(_rules));
  }

  @override
  Future<List<RulesEngineRule>> listEnabled() {
    return SynchronousFuture(
      List.unmodifiable(_rules.where((r) => r.enabled)),
    );
  }

  @override
  void validate(Iterable<String> consequentIds) {
    validateRuleConsequentIds(consequentIds);
  }

  @override
  Future<RulesEngineRule> save({
    required String title,
    required String body,
    required List<String> consequentIds,
    bool enabled = true,
    String? id,
  }) async {
    validate(consequentIds);
    final parsed = parseRuleConsequentIds(consequentIds);
    final ruleId = id ?? 'rule-${++_seq}';
    final existingIndex = _rules.indexWhere((r) => r.id == ruleId);
    final rule = RulesEngineRule(
      id: ruleId,
      title: title,
      body: body,
      enabled: enabled,
      consequents: parsed.isEmpty
          ? const [RuleConsequent.notifyFather]
          : List.unmodifiable(parsed),
      authoredByFather: true,
    );
    if (existingIndex >= 0) {
      _rules[existingIndex] = rule;
    } else {
      _rules.add(rule);
    }
    return rule;
  }

  @override
  Future<RulesEngineRule> addFromApprovedSuggestion(AiSuggestion suggestion) async {
    final proposed = suggestion.proposedConsequentIds;
    validate(proposed);

    final existing = _rules.where(
      (r) => r.sourceSuggestionId == suggestion.id,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final parsed = parseRuleConsequentIds(proposed);
    _seq += 1;
    final rule = RulesEngineRule(
      id: 'rule-from-${suggestion.id}-$_seq',
      title: suggestion.title,
      body: suggestion.body,
      enabled: true,
      consequents: parsed.isEmpty
          ? const [RuleConsequent.notifyFather]
          : List.unmodifiable(parsed),
      sourceSuggestionId: suggestion.id,
      authoredByFather: true,
    );
    _rules.add(rule);
    return rule;
  }
}

/// Stage-1 shared empty rules store (tests inject their own).
final stage1RulesEngineRuleRepository = InMemoryRulesEngineRuleRepository();
