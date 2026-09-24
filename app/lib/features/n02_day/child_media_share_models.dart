import 'package:flutter/foundation.dart';

enum ChildMediaShareType { photo, voice, file }

@immutable
final class ChildMediaShareItem {
  const ChildMediaShareItem({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.subtitleKey,
    this.hasTranscript = false,
  });

  final String id;
  final ChildMediaShareType type;
  final String titleKey;
  final String subtitleKey;

  /// Voice shares may include text transcription (S-COM-019).
  final bool hasTranscript;
}

@immutable
final class ChildMediaShareSnapshot {
  const ChildMediaShareSnapshot({this.recentShares = const []});

  final List<ChildMediaShareItem> recentShares;

  bool get isEmpty => recentShares.isEmpty;
}
