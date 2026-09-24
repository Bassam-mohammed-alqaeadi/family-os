import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';

/// Child→father learning result event (P15-EDU-006 · P12).
enum LearningResultKind { quiz, homework, familyChallenge }

@immutable
final class LearningResultSubmission {
  const LearningResultSubmission({
    required this.id,
    required this.childId,
    required this.kind,
    required this.titleKey,
    required this.submittedAt,
    this.rewardMinutes = Minutes.zero,
    this.scoreCorrect,
    this.scoreTotal,
  });

  final String id;
  final ChildId childId;
  final LearningResultKind kind;

  /// ARB discriminator for activity title (Rule 23).
  final String titleKey;
  final DateTime submittedAt;
  final Minutes rewardMinutes;
  final int? scoreCorrect;
  final int? scoreTotal;
}

@immutable
final class LearningResultSubmitRequest {
  const LearningResultSubmitRequest({
    required this.childId,
    required this.kind,
    required this.titleKey,
    this.rewardMinutes = Minutes.zero,
    this.scoreCorrect,
    this.scoreTotal,
  });

  final ChildId childId;
  final LearningResultKind kind;
  final String titleKey;
  final Minutes rewardMinutes;
  final int? scoreCorrect;
  final int? scoreTotal;
}
