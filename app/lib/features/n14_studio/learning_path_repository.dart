import 'package:family_os/features/n14_studio/learning_path_models.dart';

/// Rule 25 seam — Stage-1 mock learning path (no backend).
abstract class LearningPathRepository {
  Future<LearningPathSnapshot> load();
}

/// In-memory mock — prototype FAT-047 shape by default.
final class InMemoryLearningPathRepository implements LearningPathRepository {
  InMemoryLearningPathRepository({LearningPathSnapshot? seed})
    : _snap = seed ?? learningPathPrototypeFixture();

  LearningPathSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<LearningPathSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return LearningPathSnapshot(
      childNameKey: _snap.childNameKey,
      subjectKey: _snap.subjectKey,
      progressPercent: _snap.progressPercent,
      completedLessons: _snap.completedLessons,
      totalLessons: _snap.totalLessons,
      stops: List<LearningPathStop>.from(_snap.stops),
    );
  }

  void seed(LearningPathSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryLearningPathRepository stage1LearningPathRepository =
    InMemoryLearningPathRepository();

/// Empty — Rule 23 empty-state coverage.
LearningPathSnapshot learningPathEmptyFixture() {
  return const LearningPathSnapshot();
}

/// One stop only — current lesson (empty/one/many coverage).
LearningPathSnapshot learningPathOneFixture() {
  return const LearningPathSnapshot(
    childNameKey: 'one',
    subjectKey: 'fractions',
    progressPercent: 20,
    completedLessons: 0,
    totalLessons: 1,
    stops: [
      LearningPathStop(
        id: 'stop_adding',
        titleKey: 'adding',
        status: LearningStopStatus.current,
        kind: LearningStopKind.lesson,
        subtitleKey: 'quizPending',
      ),
    ],
  );
}

/// Prototype FAT-047 — five stops · 45% · two mastered · current · two locked.
///
/// Rule 23: generic childNameKey / titleKeys only (no planted person names).
LearningPathSnapshot learningPathPrototypeFixture() {
  return const LearningPathSnapshot(
    childNameKey: 'one',
    subjectKey: 'fractions',
    progressPercent: 45,
    completedLessons: 2,
    totalLessons: 5,
    stops: [
      LearningPathStop(
        id: 'stop_concept',
        titleKey: 'concept',
        status: LearningStopStatus.mastered,
        kind: LearningStopKind.lesson,
        masteryPercent: 90,
        subtitleKey: 'mastered',
      ),
      LearningPathStop(
        id: 'stop_similar',
        titleKey: 'similar',
        status: LearningStopStatus.mastered,
        kind: LearningStopKind.lesson,
        masteryPercent: 85,
        subtitleKey: 'mastered',
      ),
      LearningPathStop(
        id: 'stop_adding',
        titleKey: 'adding',
        status: LearningStopStatus.current,
        kind: LearningStopKind.lesson,
        subtitleKey: 'quizPending',
      ),
      LearningPathStop(
        id: 'stop_subtract',
        titleKey: 'subtract',
        status: LearningStopStatus.locked,
        kind: LearningStopKind.lesson,
        subtitleKey: 'locked',
      ),
      LearningPathStop(
        id: 'stop_final',
        titleKey: 'finalQuiz',
        status: LearningStopStatus.locked,
        kind: LearningStopKind.quiz,
        subtitleKey: 'reward',
        rewardMinutes: 50,
      ),
    ],
  );
}
