import 'package:flutter/foundation.dart';

@immutable
final class ChildReviewCard {
  const ChildReviewCard({
    required this.id,
    required this.titleKey,
    required this.metaKey,
    this.strong = false,
  });
  final String id;
  final String titleKey;
  final String metaKey;
  final bool strong;
}

@immutable
final class ChildDailyReviewSnapshot {
  const ChildDailyReviewSnapshot({
    this.hasCards = false,
    this.cards = const [],
    this.rewardMinutes = 10,
    this.sessionDone = false,
  });

  final bool hasCards;
  final List<ChildReviewCard> cards;
  final int rewardMinutes;
  final bool sessionDone;

  bool get isEmpty => !hasCards;

  ChildDailyReviewSnapshot copyWith({bool? sessionDone}) {
    return ChildDailyReviewSnapshot(
      hasCards: hasCards,
      cards: cards,
      rewardMinutes: rewardMinutes,
      sessionDone: sessionDone ?? this.sessionDone,
    );
  }
}
