import 'package:flutter/foundation.dart';

@immutable
final class CallPlayGame {
  const CallPlayGame({
    required this.id,
    required this.titleKey,
    required this.subKey,
    required this.emoji,
    required this.toastKey,
    this.primary = false,
  });

  final String id;
  final String titleKey;
  final String subKey;
  final String emoji;
  final String toastKey;
  final bool primary;
}

@immutable
final class ChildCallPlaySnapshot {
  const ChildCallPlaySnapshot({
    this.hasCall = false,
    this.peerLabelKey = 'grandpa',
    this.timeLabelKey = 'timeNow',
    this.games = const [],
    this.lastGameId,
  });

  final bool hasCall;
  final String peerLabelKey;
  final String timeLabelKey;
  final List<CallPlayGame> games;
  final String? lastGameId;

  bool get isEmpty => !hasCall;

  ChildCallPlaySnapshot copyWith({String? lastGameId}) {
    return ChildCallPlaySnapshot(
      hasCall: hasCall,
      peerLabelKey: peerLabelKey,
      timeLabelKey: timeLabelKey,
      games: List<CallPlayGame>.from(games),
      lastGameId: lastGameId ?? this.lastGameId,
    );
  }
}
