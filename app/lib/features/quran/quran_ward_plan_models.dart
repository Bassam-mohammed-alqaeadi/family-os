import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';

/// Shared father→child Quran ward plan (P15-QUR-002 · P12).
@immutable
final class QuranWardPlan {
  const QuranWardPlan({
    required this.id,
    required this.childId,
    required this.surahKey,
    required this.fromAyah,
    required this.toAyah,
    required this.reciterKey,
    required this.rewardMinutes,
    required this.publishedAt,
    this.ayahKey = 'mulk16',
  });

  final String id;
  final ChildId childId;

  /// ARB discriminator (Rule 23) — e.g. `naba` / `mulk`.
  final String surahKey;
  final int fromAyah;
  final int toAyah;
  final String reciterKey;
  final Minutes rewardMinutes;
  final DateTime publishedAt;

  /// Current practice ayah key for child card.
  final String ayahKey;
}

@immutable
final class QuranWardPlanPublishRequest {
  const QuranWardPlanPublishRequest({
    required this.childId,
    required this.surahKey,
    required this.fromAyah,
    required this.toAyah,
    required this.reciterKey,
    required this.rewardMinutes,
    this.ayahKey = 'mulk16',
  });

  final ChildId childId;
  final String surahKey;
  final int fromAyah;
  final int toAyah;
  final String reciterKey;
  final Minutes rewardMinutes;
  final String ayahKey;
}
