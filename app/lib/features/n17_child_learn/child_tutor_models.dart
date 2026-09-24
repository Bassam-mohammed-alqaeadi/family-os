import 'package:flutter/foundation.dart';

enum ChildTutorBubbleKind { tutor, child }

@immutable
final class ChildTutorBubble {
  const ChildTutorBubble({
    required this.id,
    required this.kind,
    required this.textKey,
  });

  final String id;
  final ChildTutorBubbleKind kind;
  final String textKey;
}

@immutable
final class ChildTutorChoice {
  const ChildTutorChoice({
    required this.id,
    required this.labelKey,
    required this.replyKey,
  });

  final String id;
  final String labelKey;
  final String replyKey;
}

@immutable
final class ChildTutorSnapshot {
  const ChildTutorSnapshot({
    this.bubbles = const [],
    this.choices = const [],
    this.hasThread = false,
  });

  final List<ChildTutorBubble> bubbles;
  final List<ChildTutorChoice> choices;

  /// False → empty (no conversation started).
  final bool hasThread;

  bool get isEmpty => !hasThread || bubbles.isEmpty;
}
