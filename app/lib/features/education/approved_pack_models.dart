import 'package:flutter/foundation.dart';

import 'package:family_os/features/n14_studio/preview_approve_models.dart';

/// Father gate outcome for AI-suggested learning pack (P15-EDU-004 · Rule 7).
enum ApprovedPackStatus { approved, rejected }

/// Immutable approved (or rejected) pack — child may load only when [approved].
@immutable
final class ApprovedLearningPack {
  const ApprovedLearningPack({
    required this.id,
    required this.status,
    required this.quizTitleKey,
    required this.lessonTitleKey,
    required this.questions,
    required this.updatedAt,
    this.lesson,
    this.difficulty = PreviewDifficulty.normal,
  });

  final String id;
  final ApprovedPackStatus status;
  final String quizTitleKey;
  final String lessonTitleKey;
  final List<PreviewQuizQuestion> questions;
  final PreviewLessonBlock? lesson;
  final PreviewDifficulty difficulty;
  final DateTime updatedAt;

  bool get isApproved => status == ApprovedPackStatus.approved;

  bool get isRejected => status == ApprovedPackStatus.rejected;
}
