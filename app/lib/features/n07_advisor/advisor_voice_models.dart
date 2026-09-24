import 'package:flutter/foundation.dart';

@immutable
final class AdvisorVoiceTurn {
  const AdvisorVoiceTurn({
    required this.id,
    required this.userKey,
    required this.replyKey,
  });
  final String id;
  final String userKey;
  final String replyKey;
}

@immutable
final class AdvisorVoiceSnapshot {
  const AdvisorVoiceSnapshot({
    this.hasFamily = false,
    this.listening = false,
    this.lastTurns = const [],
  });

  final bool hasFamily;
  final bool listening;
  final List<AdvisorVoiceTurn> lastTurns;

  bool get isEmpty => !hasFamily;

  AdvisorVoiceSnapshot copyWith({bool? listening}) {
    return AdvisorVoiceSnapshot(
      hasFamily: hasFamily,
      listening: listening ?? this.listening,
      lastTurns: lastTurns,
    );
  }
}
