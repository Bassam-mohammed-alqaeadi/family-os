import 'package:family_os/features/n02_day/active_call_repository.dart';

/// Test / demo fixtures for SCR-FAT-023 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1 / ابن 2…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-023 without planted person names.
abstract final class ActiveCallMock {
  const ActiveCallMock._();

  /// Child A voice call (prototype default shape — lion avatar).
  static const ActiveCallDetail childA = ActiveCallDetail(
    callId: 'call_child_a',
    peerLabel: 'ابن 1',
    emoji: '🦁',
    avatarColor: 0xFF7C5CE6,
    elapsedLabel: '03:26',
    kind: ActiveCallKind.audio,
  );

  /// Child B voice call.
  static const ActiveCallDetail childB = ActiveCallDetail(
    callId: 'call_child_b',
    peerLabel: 'ابن 2',
    emoji: '🐱',
    avatarColor: 0xFF4FC3F7,
    elapsedLabel: '01:12',
    kind: ActiveCallKind.audio,
  );

  /// Child C video call.
  static const ActiveCallDetail childCVideo = ActiveCallDetail(
    callId: 'call_child_c_video',
    peerLabel: 'ابن 3',
    emoji: '🐼',
    avatarColor: 0xFFFFB547,
    elapsedLabel: '08:15',
    kind: ActiveCallKind.video,
  );

  /// Co-parent voice call.
  static const ActiveCallDetail mother = ActiveCallDetail(
    callId: 'call_mother',
    peerLabel: 'شريكة 1',
    emoji: '🌸',
    avatarColor: 0xFFFF8FA3,
    elapsedLabel: '12:10',
    kind: ActiveCallKind.audio,
  );

  /// All prototype branches for parametric coverage.
  static const List<ActiveCallDetail> all = [
    childA,
    childB,
    childCVideo,
    mother,
  ];
}
