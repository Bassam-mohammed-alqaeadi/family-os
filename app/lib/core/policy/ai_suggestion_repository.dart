import 'package:flutter/foundation.dart';

import 'advisor_repository.dart';
import 'rule_consequent.dart';
import 'rules_engine_rule_repository.dart';

/// Decision state for an inbox suggestion (ADR-038 — suggest only).
enum AiSuggestionDecision { pending, approved, rejected }

/// Non-executable AI suggestion row for the father inbox.
///
/// **No `execute()`** — approving creates a [RulesEngineRule], never runs the suggestion.
@immutable
final class AiSuggestionInboxItem {
  const AiSuggestionInboxItem({
    required this.suggestion,
    this.decision = AiSuggestionDecision.pending,
  });

  final AiSuggestion suggestion;
  final AiSuggestionDecision decision;

  String get id => suggestion.id;

  AiSuggestionInboxItem copyWith({
    AiSuggestion? suggestion,
    AiSuggestionDecision? decision,
  }) {
    return AiSuggestionInboxItem(
      suggestion: suggestion ?? this.suggestion,
      decision: decision ?? this.decision,
    );
  }
}

/// Distinct AI-suggestion inbox (ADR-038) — separate from [RulesEngineRuleRepository].
///
/// Reuses SET-014 [MockAdvisorRepository] prototype rows. Never auto-applies.
abstract class AiSuggestionRepository {
  Future<List<AiSuggestionInboxItem>> listInbox();

  /// Pending suggestions only (approve/reject surface).
  Future<List<AiSuggestionInboxItem>> listPending();

  /// Father approves → creates a RulesEngine rule; suggestion remains non-executable.
  ///
  /// Throws [ForbiddenRuleConsequentException] when the draft proposes an
  /// ADR-038(d) owner-only consequent (SET-023) — decision stays pending.
  Future<void> approve(String suggestionId);

  Future<void> reject(String suggestionId);
}

/// Mock inbox backed by [MockAdvisorRepository] + [RulesEngineRuleRepository].
final class MockAiSuggestionRepository implements AiSuggestionRepository {
  MockAiSuggestionRepository({
    AdvisorRepository? advisor,
    RulesEngineRuleRepository? rules,
  }) : _advisor = advisor ?? stage1AdvisorRepository,
       _rules = rules ?? stage1RulesEngineRuleRepository;

  final AdvisorRepository _advisor;
  final RulesEngineRuleRepository _rules;
  final Map<String, AiSuggestionDecision> _decisions = {};

  @override
  Future<List<AiSuggestionInboxItem>> listInbox() async {
    final suggestions = await _advisor.suggestions();
    return List.unmodifiable([
      for (final s in suggestions)
        AiSuggestionInboxItem(
          suggestion: s,
          decision: _decisions[s.id] ?? AiSuggestionDecision.pending,
        ),
    ]);
  }

  @override
  Future<List<AiSuggestionInboxItem>> listPending() async {
    final all = await listInbox();
    return List.unmodifiable([
      for (final item in all)
        if (item.decision == AiSuggestionDecision.pending) item,
    ]);
  }

  @override
  Future<void> approve(String suggestionId) async {
    final inbox = await listInbox();
    final match = inbox.where((i) => i.id == suggestionId);
    if (match.isEmpty) {
      throw StateError('Unknown suggestion: $suggestionId');
    }
    final item = match.first;
    if (item.decision == AiSuggestionDecision.approved) return;
    // SET-023: forbidden draft blocked at approve — leave decision pending.
    await _rules.addFromApprovedSuggestion(item.suggestion);
    _decisions[suggestionId] = AiSuggestionDecision.approved;
  }

  @override
  Future<void> reject(String suggestionId) async {
    final inbox = await listInbox();
    if (inbox.every((i) => i.id != suggestionId)) {
      throw StateError('Unknown suggestion: $suggestionId');
    }
    _decisions[suggestionId] = AiSuggestionDecision.rejected;
  }
}
