import 'package:flutter/foundation.dart';

/// Learning-path kind on SCR-FAT-064 (prototype Quran / math rows).
enum KnowledgeMapPathKind { quran, math }

/// Social-share segment on the balance bar (prototype 80/15/5).
enum KnowledgeMapSocialSegment { family, approvedFriends, newInteraction }

@immutable
final class KnowledgeMapLearningPath {
  const KnowledgeMapLearningPath({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.subtitleKey,
    required this.progressPercent,
    required this.ctaScreenId,
  });

  final String id;
  final KnowledgeMapPathKind kind;

  /// ARB discriminator for path title.
  final String titleKey;

  /// ARB discriminator for supporting line.
  final String subtitleKey;

  /// 0–100 fill for [ProgressBar].
  final int progressPercent;

  /// GoRouter screen id (e.g. SCR-FAT-072 / SCR-FAT-049).
  final String ctaScreenId;
}

@immutable
final class KnowledgeMapSocialShare {
  const KnowledgeMapSocialShare({
    required this.segment,
    required this.percent,
    required this.titleKey,
    this.subtitleKey,
  });

  final KnowledgeMapSocialSegment segment;

  /// Share of the stacked bar (0–100); sum should be ~100.
  final int percent;
  final String titleKey;
  final String? subtitleKey;
}

@immutable
final class KnowledgeMapsSnapshot {
  const KnowledgeMapsSnapshot({
    this.childNameKey,
    this.masteryPercent = 0,
    this.learningPaths = const [],
    this.socialShares = const [],
    this.dinnerQuestionKeys = const [],
    this.dinnerQuestionIndex = 0,
  });

  /// Rule 23 — `childOne` / `childTwo` / null when empty.
  final String? childNameKey;

  /// Rising mastery tag percent (prototype 68%).
  final int masteryPercent;
  final List<KnowledgeMapLearningPath> learningPaths;
  final List<KnowledgeMapSocialShare> socialShares;

  /// Rotating dinner-prompt ARB keys (advisor suggest-only).
  final List<String> dinnerQuestionKeys;
  final int dinnerQuestionIndex;

  bool get isEmpty => childNameKey == null || learningPaths.isEmpty;

  String? get currentDinnerQuestionKey {
    if (dinnerQuestionKeys.isEmpty) return null;
    final i = dinnerQuestionIndex % dinnerQuestionKeys.length;
    return dinnerQuestionKeys[i];
  }
}
