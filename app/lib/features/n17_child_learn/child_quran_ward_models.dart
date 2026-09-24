import 'package:flutter/foundation.dart';

enum ChildWardRecitationStatus { none, sent, approved }

@immutable
final class ChildQuranWardSnapshot {
  const ChildQuranWardSnapshot({
    this.hasWard = false,
    this.surahKey = 'mulk',
    this.fromAyah = 1,
    this.toAyah = 30,
    this.reciterKey = 'defaultReciter',
    this.rewardMinutes = 30,
    this.offlineReady = true,
    this.giftCount = 0,
    this.ayahKey = 'mulk16',
    this.recitationStatus = ChildWardRecitationStatus.none,
    this.playing = false,
  });

  final bool hasWard;
  final String surahKey;
  final int fromAyah;
  final int toAyah;
  final String reciterKey;
  final int rewardMinutes;
  final bool offlineReady;
  final int giftCount;
  final String ayahKey;
  final ChildWardRecitationStatus recitationStatus;
  final bool playing;

  bool get isEmpty => !hasWard;

  ChildQuranWardSnapshot copyWith({
    ChildWardRecitationStatus? recitationStatus,
    bool? playing,
  }) {
    return ChildQuranWardSnapshot(
      hasWard: hasWard,
      surahKey: surahKey,
      fromAyah: fromAyah,
      toAyah: toAyah,
      reciterKey: reciterKey,
      rewardMinutes: rewardMinutes,
      offlineReady: offlineReady,
      giftCount: giftCount,
      ayahKey: ayahKey,
      recitationStatus: recitationStatus ?? this.recitationStatus,
      playing: playing ?? this.playing,
    );
  }
}
