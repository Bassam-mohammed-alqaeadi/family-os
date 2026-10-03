import 'package:flutter/foundation.dart';

/// Multi-modal study modes on SCR-CHD-013 (NotebookLM child study modes).
enum ChildLessonStudyMode { groundedReader, audioOverview, conceptMindMap }

@immutable
final class ChildLessonSnapshot {
  const ChildLessonSnapshot({
    this.titleKey,
    this.hookKey,
    this.bodyKey,
    this.progressPercent = 0,
    this.pizzaFilled = const [],
    this.nextScreenId = 'SCR-CHD-014',
    this.tutorScreenId = 'SCR-CHD-017',
    this.rewardMinutes = 10,
    this.studyMode = ChildLessonStudyMode.groundedReader,
    this.notePinned = false,
  });

  final String? titleKey;
  final String? hookKey;
  final String? bodyKey;
  final int progressPercent;

  /// True = filled slice (prototype 5 of 7).
  final List<bool> pizzaFilled;
  final String nextScreenId;
  final String tutorScreenId;
  final int rewardMinutes;
  final ChildLessonStudyMode studyMode;
  final bool notePinned;

  bool get isEmpty => titleKey == null;

  ChildLessonSnapshot withStudyMode(ChildLessonStudyMode next) {
    return ChildLessonSnapshot(
      titleKey: titleKey,
      hookKey: hookKey,
      bodyKey: bodyKey,
      progressPercent: progressPercent,
      pizzaFilled: pizzaFilled,
      nextScreenId: nextScreenId,
      tutorScreenId: tutorScreenId,
      rewardMinutes: rewardMinutes,
      studyMode: next,
      notePinned: notePinned,
    );
  }

  ChildLessonSnapshot withNotePinned(bool pinned) {
    return ChildLessonSnapshot(
      titleKey: titleKey,
      hookKey: hookKey,
      bodyKey: bodyKey,
      progressPercent: progressPercent,
      pizzaFilled: pizzaFilled,
      nextScreenId: nextScreenId,
      tutorScreenId: tutorScreenId,
      rewardMinutes: rewardMinutes,
      studyMode: studyMode,
      notePinned: pinned,
    );
  }
}
