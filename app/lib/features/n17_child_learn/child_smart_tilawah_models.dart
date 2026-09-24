import 'package:flutter/foundation.dart';

@immutable
final class ChildSmartTilawahSnapshot {
  const ChildSmartTilawahSnapshot({
    this.hasSession = false,
    this.surahKey = 'mulk',
    this.ayahNumber = 16,
    this.ayahKey = 'mulk16',
    this.tipTitleKey = 'maddSamaa',
    this.tipBodyKey = 'maddSamaaBody',
    this.praiseKey = 'praiseDefaults',
    this.listening = false,
    this.sheikhPlayed = false,
  });

  final bool hasSession;
  final String surahKey;
  final int ayahNumber;
  final String ayahKey;
  final String tipTitleKey;
  final String tipBodyKey;
  final String praiseKey;
  final bool listening;
  final bool sheikhPlayed;

  bool get isEmpty => !hasSession;

  ChildSmartTilawahSnapshot copyWith({bool? listening, bool? sheikhPlayed}) {
    return ChildSmartTilawahSnapshot(
      hasSession: hasSession,
      surahKey: surahKey,
      ayahNumber: ayahNumber,
      ayahKey: ayahKey,
      tipTitleKey: tipTitleKey,
      tipBodyKey: tipBodyKey,
      praiseKey: praiseKey,
      listening: listening ?? this.listening,
      sheikhPlayed: sheikhPlayed ?? this.sheikhPlayed,
    );
  }
}
