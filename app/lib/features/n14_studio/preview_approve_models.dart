import 'package:flutter/foundation.dart';

/// Preview content kinds on SCR-FAT-044 (prototype FAT-044 · quiz + lesson).
enum PreviewContentKind { quiz, lesson }

/// Mock difficulty for light parent edit (Rule 23 — discrete).
enum PreviewDifficulty { easier, normal, harder }

/// Discrete inline citation keys for NotebookLM source verification.
enum PreviewCitationKey { textbookP47, worksheetP2 }

@immutable
final class PreviewSourceCitation {
  const PreviewSourceCitation({
    required this.id,
    required this.refLabel,
    required this.citationKey,
  });

  final String id;
  final String refLabel;
  final PreviewCitationKey citationKey;
}

const List<PreviewSourceCitation> defaultPreviewCitations = [
  PreviewSourceCitation(
    id: 'cit-p47',
    refLabel: '1 · p.47',
    citationKey: PreviewCitationKey.textbookP47,
  ),
  PreviewSourceCitation(
    id: 'cit-w2',
    refLabel: '2 · p.2',
    citationKey: PreviewCitationKey.worksheetP2,
  ),
];

@immutable
final class PreviewQuizOption {
  const PreviewQuizOption({
    required this.id,
    required this.labelKey,
    this.isCorrect = false,
  });

  final String id;

  /// ARB key discriminator — screen maps to localized label.
  final String labelKey;
  final bool isCorrect;
}

@immutable
final class PreviewQuizQuestion {
  const PreviewQuizQuestion({
    required this.id,
    required this.promptKey,
    required this.options,
  });

  final String id;
  final String promptKey;
  final List<PreviewQuizOption> options;

  PreviewQuizQuestion copyWith({List<PreviewQuizOption>? options}) {
    return PreviewQuizQuestion(
      id: id,
      promptKey: promptKey,
      options: options ?? this.options,
    );
  }
}

@immutable
final class PreviewLessonBlock {
  const PreviewLessonBlock({required this.id, required this.summaryKey});

  final String id;
  final String summaryKey;
}

@immutable
final class PreviewApproveSnapshot {
  const PreviewApproveSnapshot({
    this.quizTitleKey = 'quiz',
    this.lessonTitleKey = 'lesson',
    this.questions = const [],
    this.lesson,
    this.difficulty = PreviewDifficulty.normal,
    this.elapsedSeconds = 70,
    this.ruleSeconds = 90,
    this.rejected = false,
    this.approved = false,
    this.citations = defaultPreviewCitations,
    this.selectedCitationId = 'cit-p47',
  });

  final String quizTitleKey;
  final String lessonTitleKey;
  final List<PreviewQuizQuestion> questions;
  final PreviewLessonBlock? lesson;
  final PreviewDifficulty difficulty;
  final int elapsedSeconds;
  final int ruleSeconds;
  final bool rejected;

  /// True after father Approve publishes pack (P15-EDU-004).
  final bool approved;

  /// Grounded inline citations for NotebookLM provenance verification.
  final List<PreviewSourceCitation> citations;
  final String? selectedCitationId;

  bool get isEmpty => rejected || (questions.isEmpty && lesson == null);

  bool get withinNinetySeconds => elapsedSeconds <= ruleSeconds;

  bool get canApprove => !rejected && !approved && questions.isNotEmpty;

  PreviewSourceCitation? get activeCitation {
    for (final c in citations) {
      if (c.id == selectedCitationId) return c;
    }
    return citations.isNotEmpty ? citations.first : null;
  }

  PreviewApproveSnapshot withSelectedCitation(String citationId) {
    return PreviewApproveSnapshot(
      quizTitleKey: quizTitleKey,
      lessonTitleKey: lessonTitleKey,
      questions: questions,
      lesson: lesson,
      difficulty: difficulty,
      elapsedSeconds: elapsedSeconds,
      ruleSeconds: ruleSeconds,
      rejected: rejected,
      approved: approved,
      citations: citations,
      selectedCitationId: citationId,
    );
  }

  PreviewApproveSnapshot withQuestions(List<PreviewQuizQuestion> next) {
    return PreviewApproveSnapshot(
      quizTitleKey: quizTitleKey,
      lessonTitleKey: lessonTitleKey,
      questions: next,
      lesson: lesson,
      difficulty: difficulty,
      elapsedSeconds: elapsedSeconds,
      ruleSeconds: ruleSeconds,
      rejected: rejected,
      approved: approved,
      citations: citations,
      selectedCitationId: selectedCitationId,
    );
  }

  PreviewApproveSnapshot withDifficulty(PreviewDifficulty next) {
    return PreviewApproveSnapshot(
      quizTitleKey: quizTitleKey,
      lessonTitleKey: lessonTitleKey,
      questions: questions,
      lesson: lesson,
      difficulty: next,
      elapsedSeconds: elapsedSeconds,
      ruleSeconds: ruleSeconds,
      rejected: rejected,
      approved: approved,
      citations: citations,
      selectedCitationId: selectedCitationId,
    );
  }

  PreviewApproveSnapshot withApproved() {
    return PreviewApproveSnapshot(
      quizTitleKey: quizTitleKey,
      lessonTitleKey: lessonTitleKey,
      questions: questions,
      lesson: lesson,
      difficulty: difficulty,
      elapsedSeconds: elapsedSeconds,
      ruleSeconds: ruleSeconds,
      rejected: false,
      approved: true,
      citations: citations,
      selectedCitationId: selectedCitationId,
    );
  }

  PreviewApproveSnapshot withRejected() {
    return PreviewApproveSnapshot(
      quizTitleKey: quizTitleKey,
      lessonTitleKey: lessonTitleKey,
      questions: const [],
      lesson: null,
      difficulty: difficulty,
      elapsedSeconds: elapsedSeconds,
      ruleSeconds: ruleSeconds,
      rejected: true,
      approved: false,
      citations: citations,
      selectedCitationId: selectedCitationId,
    );
  }

  PreviewApproveSnapshot withoutQuestion(String questionId) {
    return withQuestions([
      for (final q in questions)
        if (q.id != questionId) q,
    ]);
  }
}
