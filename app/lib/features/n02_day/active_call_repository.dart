import 'package:flutter/foundation.dart';

/// Call media mode for SCR-FAT-023 (LiveKit audio/video — Stage-1 mock).
enum ActiveCallKind {
  audio,
  video,
}

/// Live call payload for SCR-FAT-023 (`?callId=`).
@immutable
final class ActiveCallDetail {
  const ActiveCallDetail({
    required this.callId,
    required this.peerLabel,
    required this.emoji,
    required this.avatarColor,
    required this.elapsedLabel,
    this.kind = ActiveCallKind.audio,
  });

  /// Route / deep-link id (`?callId=`).
  final String callId;

  /// Generic peer label only (Rule 23 — never planted person names).
  final String peerLabel;

  final String emoji;

  /// ARGB avatar fill (prototype pulse circle).
  final int avatarColor;

  /// Preformatted elapsed timer (ARB-sourced in mocks / Stage-3 later).
  final String elapsedLabel;

  final ActiveCallKind kind;

  ActiveCallDetail copyWith({
    String? callId,
    String? peerLabel,
    String? emoji,
    int? avatarColor,
    String? elapsedLabel,
    ActiveCallKind? kind,
  }) {
    return ActiveCallDetail(
      callId: callId ?? this.callId,
      peerLabel: peerLabel ?? this.peerLabel,
      emoji: emoji ?? this.emoji,
      avatarColor: avatarColor ?? this.avatarColor,
      elapsedLabel: elapsedLabel ?? this.elapsedLabel,
      kind: kind ?? this.kind,
    );
  }
}

/// Rule 25 seam — active call for SCR-FAT-023 (no LiveKit/Firebase; Drift later).
abstract class ActiveCallRepository {
  /// Resolve call by id. Null → not found.
  Future<ActiveCallDetail?> load(String callId);

  /// Mute toggle mock seam — returns new muted state.
  Future<bool> setMuted(String callId, {required bool muted});

  /// Speaker toggle mock seam — returns new speaker-on state.
  Future<bool> setSpeaker(String callId, {required bool speakerOn});

  /// Camera toggle mock seam — returns new camera-on state.
  Future<bool> setCamera(String callId, {required bool cameraOn});

  /// End call mock seam.
  Future<void> end(String callId);
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryActiveCallRepository implements ActiveCallRepository {
  InMemoryActiveCallRepository({
    List<ActiveCallDetail>? initial,
    this.failLoad = false,
  }) : _calls = {
          for (final c in initial ?? const <ActiveCallDetail>[]) c.callId: c,
        };

  final Map<String, ActiveCallDetail> _calls;

  /// Test seam — next [load] throws.
  bool failLoad;

  final Map<String, bool> _muted = {};
  final Map<String, bool> _speaker = {};
  final Map<String, bool> _camera = {};

  void seed(List<ActiveCallDetail> calls) {
    _calls
      ..clear()
      ..addEntries(calls.map((c) => MapEntry(c.callId, c)));
    _muted.clear();
    _speaker.clear();
    _camera.clear();
  }

  @override
  Future<ActiveCallDetail?> load(String callId) async {
    if (failLoad) {
      throw StateError('mock active call load failure');
    }
    final key = callId.trim();
    if (key.isEmpty) return null;
    return _calls[key];
  }

  @override
  Future<bool> setMuted(String callId, {required bool muted}) async {
    final key = callId.trim();
    if (!_calls.containsKey(key)) {
      throw StateError('call not found: $key');
    }
    _muted[key] = muted;
    return muted;
  }

  @override
  Future<bool> setSpeaker(String callId, {required bool speakerOn}) async {
    final key = callId.trim();
    if (!_calls.containsKey(key)) {
      throw StateError('call not found: $key');
    }
    _speaker[key] = speakerOn;
    return speakerOn;
  }

  @override
  Future<bool> setCamera(String callId, {required bool cameraOn}) async {
    final key = callId.trim();
    if (!_calls.containsKey(key)) {
      throw StateError('call not found: $key');
    }
    _camera[key] = cameraOn;
    return cameraOn;
  }

  @override
  Future<void> end(String callId) async {
    final key = callId.trim();
    if (!_calls.containsKey(key)) {
      throw StateError('call not found: $key');
    }
    _calls.remove(key);
    _muted.remove(key);
    _speaker.remove(key);
    _camera.remove(key);
  }

  bool isMuted(String callId) => _muted[callId.trim()] ?? false;
  bool isSpeakerOn(String callId) => _speaker[callId.trim()] ?? false;
  bool isCameraOn(String callId) => _camera[callId.trim()] ?? false;
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1ActiveCallRepository = InMemoryActiveCallRepository();
