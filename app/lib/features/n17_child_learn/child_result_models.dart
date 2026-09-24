import 'package:flutter/foundation.dart';

@immutable
final class ChildResultRewardRow {
  const ChildResultRewardRow({
    required this.id,
    required this.titleKey,
    required this.tagKey,
    this.subtitleKey,
  });

  final String id;
  final String titleKey;
  final String tagKey;
  final String? subtitleKey;
}

@immutable
final class ChildResultSnapshot {
  const ChildResultSnapshot({
    this.scoreCorrect,
    this.scoreTotal,
    this.praiseKey,
    this.missedTitleKey,
    this.missedBodyKey,
    this.rewards = const [],
    this.reviewScreenId = 'SCR-CHD-013',
    this.learnHomeScreenId = 'SCR-CHD-012',
  });

  final int? scoreCorrect;
  final int? scoreTotal;
  final String? praiseKey;
  final String? missedTitleKey;
  final String? missedBodyKey;
  final List<ChildResultRewardRow> rewards;
  final String reviewScreenId;
  final String learnHomeScreenId;

  bool get isEmpty => scoreCorrect == null || scoreTotal == null;
}
