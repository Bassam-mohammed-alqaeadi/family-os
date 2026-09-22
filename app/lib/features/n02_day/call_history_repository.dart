import 'package:flutter/foundation.dart';

/// Direction of a logged family call (prototype FAT-024).
enum CallLogDirection {
  /// ↗ صادرة
  outgoing,

  /// ↙ واردة
  incoming,

  /// ↙ فائتة
  missed,
}

/// Media kind for a logged call (schema AUDIO | VIDEO).
enum CallLogKind {
  audio,
  video,
}

/// One row in SCR-FAT-024 call history.
@immutable
final class CallLogEntry {
  const CallLogEntry({
    required this.id,
    required this.callId,
    required this.peerLabel,
    required this.emoji,
    required this.avatarColor,
    required this.direction,
    required this.whenLabel,
    this.kind = CallLogKind.audio,
    this.durationLabel,
  });

  final String id;

  /// Redial target for FAT-023 (`?callId=`).
  final String callId;

  /// Generic peer label only (Rule 23 — never planted person names).
  final String peerLabel;

  final String emoji;

  /// ARGB avatar fill (prototype row avatar).
  final int avatarColor;

  final CallLogDirection direction;

  final CallLogKind kind;

  /// Preformatted duration (null for missed).
  final String? durationLabel;

  /// Relative / calendar when-label (الآن · أمس · الجمعة…).
  final String whenLabel;

  CallLogEntry copyWith({
    String? id,
    String? callId,
    String? peerLabel,
    String? emoji,
    int? avatarColor,
    CallLogDirection? direction,
    CallLogKind? kind,
    String? durationLabel,
    String? whenLabel,
  }) {
    return CallLogEntry(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      peerLabel: peerLabel ?? this.peerLabel,
      emoji: emoji ?? this.emoji,
      avatarColor: avatarColor ?? this.avatarColor,
      direction: direction ?? this.direction,
      kind: kind ?? this.kind,
      durationLabel: durationLabel ?? this.durationLabel,
      whenLabel: whenLabel ?? this.whenLabel,
    );
  }
}

/// Call history snapshot for SCR-FAT-024.
@immutable
final class CallHistorySnapshot {
  const CallHistorySnapshot({this.entries = const []});

  final List<CallLogEntry> entries;

  bool get isEmpty => entries.isEmpty;

  int get count => entries.length;
}

/// Rule 25 seam — call history for SCR-FAT-024 (no LiveKit/Firebase; Drift later).
abstract class CallHistoryRepository {
  Future<CallHistorySnapshot> load();
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryCallHistoryRepository implements CallHistoryRepository {
  InMemoryCallHistoryRepository({
    CallHistorySnapshot? initial,
    this.failLoad = false,
  }) : _snapshot = initial ?? const CallHistorySnapshot();

  CallHistorySnapshot _snapshot;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(CallHistorySnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  Future<CallHistorySnapshot> load() async {
    if (failLoad) {
      throw StateError('mock call history load failure');
    }
    return CallHistorySnapshot(
      entries: List.unmodifiable(_snapshot.entries),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1CallHistoryRepository = InMemoryCallHistoryRepository();
