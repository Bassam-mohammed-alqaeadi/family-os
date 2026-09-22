import 'package:flutter/foundation.dart';

import 'ai_stage_id.dart';

/// Suggest-only Advisor item (Rule 26 / Bark: AI suggests, parent decides).
///
/// **No `execute()`** — type system and product law forbid auto-apply.
@immutable
final class AiSuggestion {
  const AiSuggestion({
    required this.id,
    required this.title,
    required this.body,
    this.stage = AiStageId.suggest,
    this.proposedConsequentIds = const [],
  });

  final String id;
  final String title;
  final String body;
  final AiStageId stage;

  /// Draft consequents for approve→rule (SET-023). May include forbidden
  /// wire ids; [RulesEngineRuleRepository.addFromApprovedSuggestion] rejects them.
  final List<String> proposedConsequentIds;
}

/// Rule 26 gateway — prototype suggestions only; never runs a local model.
abstract class AdvisorRepository {
  /// Mock / gateway suggestions for [stage] (default: suggest).
  Future<List<AiSuggestion>> suggestions({AiStageId stage = AiStageId.suggest});
}

/// Frozen prototype-style suggestions (Rule 26 last clause).
final class MockAdvisorRepository implements AdvisorRepository {
  const MockAdvisorRepository();

  static const List<AiSuggestion> prototypeSuggestions = [
    AiSuggestion(
      id: 'sug-bedtime',
      title: 'Bedtime games pause',
      body:
          'Khalid’s game time rose after 9pm three nights. Suggestion: pause '
          'games after 9pm for one week and watch the effect — you decide.',
      stage: AiStageId.suggest,
    ),
    AiSuggestion(
      id: 'sug-study',
      title: 'Study window nudge',
      body:
          'Math practice dipped while evening apps rose. Suggestion: protect a '
          '30-minute study window before free time — approve only if you agree.',
      stage: AiStageId.suggest,
    ),
    AiSuggestion(
      id: 'sug-place',
      title: 'After-school place check',
      body:
          'Usual after-school place pattern shifted twice. Suggestion: ask '
          'gently — no auto lock or alert without your approval.',
      stage: AiStageId.suggest,
    ),
  ];

  @override
  Future<List<AiSuggestion>> suggestions({
    AiStageId stage = AiStageId.suggest,
  }) {
    return SynchronousFuture(suggestionsSync(stage: stage));
  }

  /// Eager Stage-1 read for UI that must setState in the same turn.
  List<AiSuggestion> suggestionsSync({AiStageId stage = AiStageId.suggest}) {
    return List.unmodifiable(
      prototypeSuggestions.where((s) => s.stage == stage),
    );
  }
}

/// Stage-1 shared mock advisor.
const MockAdvisorRepository stage1AdvisorRepository = MockAdvisorRepository();
