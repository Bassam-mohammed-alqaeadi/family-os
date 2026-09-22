import 'package:family_os/features/n14_studio/preview_approve_models.dart';

/// Rule 25 seam — Stage-1 mock preview/approve content (no AI).
abstract class PreviewApproveRepository {
  Future<PreviewApproveSnapshot> load();
}

/// In-memory mock — prototype FAT-044 shape by default.
final class InMemoryPreviewApproveRepository implements PreviewApproveRepository {
  InMemoryPreviewApproveRepository({PreviewApproveSnapshot? seed})
    : _snap = seed ?? previewApprovePrototypeFixture();

  PreviewApproveSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<PreviewApproveSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return PreviewApproveSnapshot(
      quizTitleKey: _snap.quizTitleKey,
      lessonTitleKey: _snap.lessonTitleKey,
      questions: List<PreviewQuizQuestion>.from(_snap.questions),
      lesson: _snap.lesson,
      difficulty: _snap.difficulty,
      elapsedSeconds: _snap.elapsedSeconds,
      ruleSeconds: _snap.ruleSeconds,
      rejected: _snap.rejected,
    );
  }

  void seed(PreviewApproveSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryPreviewApproveRepository stage1PreviewApproveRepository =
    InMemoryPreviewApproveRepository();

/// Empty — Rule 23 empty-state coverage.
PreviewApproveSnapshot previewApproveEmptyFixture() {
  return const PreviewApproveSnapshot(questions: [], lesson: null);
}

/// Prototype FAT-044 — quiz Q1+Q2 + lesson pizza metaphor · ~70s / 90s rule.
PreviewApproveSnapshot previewApprovePrototypeFixture() {
  return const PreviewApproveSnapshot(
    questions: [
      PreviewQuizQuestion(
        id: 'q1',
        promptKey: 'q1',
        options: [
          PreviewQuizOption(id: 'q1a', labelKey: 'q1a', isCorrect: true),
          PreviewQuizOption(id: 'q1b', labelKey: 'q1b'),
          PreviewQuizOption(id: 'q1c', labelKey: 'q1c'),
        ],
      ),
      PreviewQuizQuestion(
        id: 'q2',
        promptKey: 'q2',
        options: [
          PreviewQuizOption(id: 'q2a', labelKey: 'q2a', isCorrect: true),
          PreviewQuizOption(id: 'q2b', labelKey: 'q2b'),
          PreviewQuizOption(id: 'q2c', labelKey: 'q2c'),
        ],
      ),
    ],
    lesson: PreviewLessonBlock(id: 'lesson-1', summaryKey: 'pizza'),
    elapsedSeconds: 70,
    ruleSeconds: 90,
  );
}

/// Alternate question used when parent taps «swap» (mock seam).
PreviewQuizQuestion previewApproveSwapQuestionFixture() {
  return const PreviewQuizQuestion(
    id: 'q3',
    promptKey: 'q3',
    options: [
      PreviewQuizOption(id: 'q3a', labelKey: 'q3a', isCorrect: true),
      PreviewQuizOption(id: 'q3b', labelKey: 'q3b'),
      PreviewQuizOption(id: 'q3c', labelKey: 'q3c'),
    ],
  );
}
