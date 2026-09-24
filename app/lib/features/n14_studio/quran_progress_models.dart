import 'package:flutter/foundation.dart';

enum QuranRecitationStatus { none, recorded, approved }

@immutable
final class QuranProgressSnapshot {
  const QuranProgressSnapshot({
    this.childNameKey,
    this.surahKey,
    this.fromAyah = 1,
    this.toAyah = 40,
    this.completedAyahs = 0,
    this.reciterKey,
    this.streakDays = 0,
    this.rewardMinutes = 30,
    this.offlineReady = true,
    this.audioSizeKey,
    this.recitationStatus = QuranRecitationStatus.none,
    this.playingAudio = false,
  });

  final String? childNameKey;
  final String? surahKey;
  final int fromAyah;
  final int toAyah;
  final int completedAyahs;
  final String? reciterKey;
  final int streakDays;

  /// Minutes-only reward on approve (ع-١).
  final int rewardMinutes;
  final bool offlineReady;
  final String? audioSizeKey;
  final QuranRecitationStatus recitationStatus;
  final bool playingAudio;

  bool get isEmpty => childNameKey == null || surahKey == null;

  double get progress {
    if (toAyah <= 0) return 0;
    return (completedAyahs / toAyah).clamp(0.0, 1.0);
  }

  QuranProgressSnapshot copyWith({
    String? surahKey,
    int? fromAyah,
    int? toAyah,
    int? completedAyahs,
    String? reciterKey,
    int? rewardMinutes,
    QuranRecitationStatus? recitationStatus,
    bool? playingAudio,
  }) {
    return QuranProgressSnapshot(
      childNameKey: childNameKey,
      surahKey: surahKey ?? this.surahKey,
      fromAyah: fromAyah ?? this.fromAyah,
      toAyah: toAyah ?? this.toAyah,
      completedAyahs: completedAyahs ?? this.completedAyahs,
      reciterKey: reciterKey ?? this.reciterKey,
      streakDays: streakDays,
      rewardMinutes: rewardMinutes ?? this.rewardMinutes,
      offlineReady: offlineReady,
      audioSizeKey: audioSizeKey,
      recitationStatus: recitationStatus ?? this.recitationStatus,
      playingAudio: playingAudio ?? this.playingAudio,
    );
  }
}
