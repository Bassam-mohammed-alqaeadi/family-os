import 'package:flutter/foundation.dart';

@immutable
final class ChildQuizOption {
  const ChildQuizOption({
    required this.id,
    required this.labelKey,
    required this.correct,
    this.wrongHintKey,
  });

  final String id;
  final String labelKey;
  final bool correct;

  /// ARB hint when this wrong option is tapped.
  final String? wrongHintKey;
}

@immutable
final class ChildQuizQuestion {
  const ChildQuizQuestion({
    required this.id,
    required this.promptKey,
    required this.options,
    required this.explanationKey,
  });

  final String id;
  final String promptKey;
  final List<ChildQuizOption> options;
  final String explanationKey;
}

@immutable
final class ChildQuizSnapshot {
  const ChildQuizSnapshot({
    this.skillNameKey,
    this.questions = const [],
    this.questionIndex = 0,
    this.rewardMinutes = 20,
    this.successScreenId = 'SCR-CHD-016',
  });

  final String? skillNameKey;
  final List<ChildQuizQuestion> questions;
  final int questionIndex;

  /// Minutes-only wallet reward on correct answer (ع-١).
  final int rewardMinutes;
  final String successScreenId;

  bool get isEmpty => skillNameKey == null || questions.isEmpty;

  ChildQuizQuestion? get currentQuestion {
    if (questions.isEmpty) return null;
    final i = questionIndex.clamp(0, questions.length - 1);
    return questions[i];
  }
}
