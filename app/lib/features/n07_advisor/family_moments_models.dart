import 'package:flutter/foundation.dart';

@immutable
final class FamilyMomentStar {
  const FamilyMomentStar({
    required this.id,
    required this.childLabelKey,
    required this.titleKey,
    required this.subKey,
    required this.emoji,
  });

  final String id;
  final String childLabelKey;
  final String titleKey;
  final String subKey;
  final String emoji;
}

@immutable
final class FamilyMomentAlbumItem {
  const FamilyMomentAlbumItem({
    required this.id,
    required this.captionKey,
    required this.byKey,
    required this.whenKey,
    required this.emoji,
  });

  final String id;
  final String captionKey;
  final String byKey;
  final String whenKey;
  final String emoji;
}

@immutable
final class FamilyMomentsSnapshot {
  const FamilyMomentsSnapshot({
    this.hasFamily = false,
    this.weekLabelKey = 'weekSep',
    this.learnHours = 0,
    this.versesMemorized = 0,
    this.tasksDone = 0,
    this.worryAlerts = 0,
    this.stars = const [],
    this.touchHintKey = 'touchKhalid',
    this.album = const [],
    this.prideShared = false,
    this.touchReminded = false,
  });

  final bool hasFamily;
  final String weekLabelKey;
  final int learnHours;
  final int versesMemorized;
  final int tasksDone;
  final int worryAlerts;
  final List<FamilyMomentStar> stars;
  final String touchHintKey;
  final List<FamilyMomentAlbumItem> album;
  final bool prideShared;
  final bool touchReminded;

  bool get isEmpty => !hasFamily;
}
