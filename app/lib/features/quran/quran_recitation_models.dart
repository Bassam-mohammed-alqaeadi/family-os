import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';

/// Child→father Quran recitation event (P15-QUR-003 · P12).
enum QuranRecitationSubmitStatus { pending, approved }

@immutable
final class QuranRecitationSubmission {
  const QuranRecitationSubmission({
    required this.id,
    required this.childId,
    required this.surahKey,
    required this.status,
    required this.rewardMinutes,
    required this.submittedAt,
    this.fromAyah = 1,
    this.toAyah = 30,
  });

  final String id;
  final ChildId childId;
  final String surahKey;
  final QuranRecitationSubmitStatus status;
  final Minutes rewardMinutes;
  final DateTime submittedAt;
  final int fromAyah;
  final int toAyah;

  QuranRecitationSubmission copyWith({QuranRecitationSubmitStatus? status}) {
    return QuranRecitationSubmission(
      id: id,
      childId: childId,
      surahKey: surahKey,
      status: status ?? this.status,
      rewardMinutes: rewardMinutes,
      submittedAt: submittedAt,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
  }
}

@immutable
final class QuranRecitationSubmitRequest {
  const QuranRecitationSubmitRequest({
    required this.childId,
    required this.surahKey,
    required this.rewardMinutes,
    this.fromAyah = 1,
    this.toAyah = 30,
  });

  final ChildId childId;
  final String surahKey;
  final Minutes rewardMinutes;
  final int fromAyah;
  final int toAyah;
}
