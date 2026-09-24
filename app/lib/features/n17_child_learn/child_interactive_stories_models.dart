import 'package:flutter/foundation.dart';

@immutable
final class ChildStoryChoice {
  const ChildStoryChoice({
    required this.id,
    required this.labelKey,
    required this.toastKey,
  });

  final String id;
  final String labelKey;
  final String toastKey;
}

@immutable
final class ChildInteractiveStoriesSnapshot {
  const ChildInteractiveStoriesSnapshot({
    this.hasStory = false,
    this.chapterKey = 'desert3',
    this.bodyKey = 'desert3Body',
    this.promptKey = 'whatDoYou',
    this.choices = const [],
    this.lastChoiceId,
  });

  final bool hasStory;
  final String chapterKey;
  final String bodyKey;
  final String promptKey;
  final List<ChildStoryChoice> choices;
  final String? lastChoiceId;

  bool get isEmpty => !hasStory;

  ChildInteractiveStoriesSnapshot copyWith({String? lastChoiceId}) {
    return ChildInteractiveStoriesSnapshot(
      hasStory: hasStory,
      chapterKey: chapterKey,
      bodyKey: bodyKey,
      promptKey: promptKey,
      choices: List<ChildStoryChoice>.from(choices),
      lastChoiceId: lastChoiceId ?? this.lastChoiceId,
    );
  }
}
