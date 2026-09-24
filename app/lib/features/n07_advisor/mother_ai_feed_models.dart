import 'package:flutter/foundation.dart';

@immutable
final class MotherFeedItem {
  const MotherFeedItem({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    this.tagKey = 'good',
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final String tagKey;
}

@immutable
final class MotherAiFeedSnapshot {
  const MotherAiFeedSnapshot({
    this.hasFamily = false,
    this.whisperKey = 'sleepEarly',
    this.whisperSent = false,
    this.items = const [],
  });

  final bool hasFamily;
  final String whisperKey;
  final bool whisperSent;
  final List<MotherFeedItem> items;

  bool get isEmpty => !hasFamily;

  MotherAiFeedSnapshot copyWith({bool? whisperSent}) {
    return MotherAiFeedSnapshot(
      hasFamily: hasFamily,
      whisperKey: whisperKey,
      whisperSent: whisperSent ?? this.whisperSent,
      items: items,
    );
  }
}
