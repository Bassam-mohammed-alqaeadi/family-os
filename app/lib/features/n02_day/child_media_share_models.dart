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

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'titleKey': titleKey,
        'subtitleKey': subtitleKey,
        'hasTranscript': hasTranscript,
      };

  static ChildMediaShareItem fromJson(Map<String, Object?> json) {
    final typeRaw = json['type']?.toString() ?? 'photo';
    final type = ChildMediaShareType.values.firstWhere(
      (t) => t.name == typeRaw,
      orElse: () => ChildMediaShareType.photo,
    );
    return ChildMediaShareItem(
      id: json['id']?.toString() ?? '',
      type: type,
      titleKey: json['titleKey']?.toString() ?? '',
      subtitleKey: json['subtitleKey']?.toString() ?? '',
      hasTranscript: json['hasTranscript'] == true,
    );
  }
}

@immutable
final class ChildMediaShareSnapshot {
  const ChildMediaShareSnapshot({
    this.recentShares = const [],
    this.intentJournal = const [],
  });

  final List<ChildMediaShareItem> recentShares;

  /// Local-only share intent journal (camera/mic remain NATIVE_CLOSED).
  final List<String> intentJournal;

  bool get isEmpty => recentShares.isEmpty && intentJournal.isEmpty;

  Map<String, Object?> toJson() => {
        'recentShares': recentShares.map((e) => e.toJson()).toList(),
        'intentJournal': intentJournal,
      };

  static ChildMediaShareSnapshot fromJson(Map<String, Object?> json) {
    final shares = <ChildMediaShareItem>[];
    final raw = json['recentShares'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          shares.add(
            ChildMediaShareItem.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    final intents = <String>[];
    final intentRaw = json['intentJournal'];
    if (intentRaw is List) {
      for (final e in intentRaw) {
        intents.add(e.toString());
      }
    }
    return ChildMediaShareSnapshot(
      recentShares: shares,
      intentJournal: intents,
    );
  }
}
