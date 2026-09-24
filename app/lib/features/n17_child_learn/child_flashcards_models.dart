import 'package:flutter/foundation.dart';

@immutable
final class ChildFlashcard {
  const ChildFlashcard({
    required this.id,
    required this.questionKey,
    required this.answerKey,
    required this.hintKey,
  });

  final String id;
  final String questionKey;
  final String answerKey;
  final String hintKey;
}

@immutable
final class ChildFlashcardsSnapshot {
  const ChildFlashcardsSnapshot({
    this.lessonTitleKey,
    this.sourceNameKey,
    this.cards = const [],
    this.currentIndex = 0,
    this.flipped = false,
    this.quizScreenId = 'SCR-CHD-015',
    this.quizRewardMinutes = 50,
  });

  final String? lessonTitleKey;
  final String? sourceNameKey;
  final List<ChildFlashcard> cards;
  final int currentIndex;
  final bool flipped;
  final String quizScreenId;
  final int quizRewardMinutes;

  bool get isEmpty => lessonTitleKey == null || cards.isEmpty;

  ChildFlashcard? get currentCard {
    if (cards.isEmpty) return null;
    final i = currentIndex.clamp(0, cards.length - 1);
    return cards[i];
  }
}
