import 'package:family\_os/features/n02\_day/active\_call\_repository.dart';

/// Test / demo fixtures for SCR-FAT-023 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١ / ابن ٢…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-023 without planted person names.
abstract final class ActiveCallMock {
  const ActiveCallMock.\_();

  /// Child A voice call (prototype default shape — lion avatar).
  static const ActiveCallDetail childA = ActiveCallDetail(
    callId: 'call\_child\_a',
    peerLabel: 'ابن ١',
    emoji: '🦁',
    avatarColor: 0xFF7C5CE6,
    elapsedLabel: '٠٣:٢٦',
    kind: ActiveCallKind.audio,
  );

  /// Child B voice call.
  static const ActiveCallDetail childB = ActiveCallDetail(
    callId: 'call\_child\_b',
    peerLabel: 'ابن ٢',
    emoji: '🐱',
    avatarColor: 0xFF4FC3F7,
    elapsedLabel: '٠١:١٢',
    kind: ActiveCallKind.audio,
  );

  /// Child C video call.
  static const ActiveCallDetail childCVideo = ActiveCallDetail(
    callId: 'call\_child\_c\_video',
    peerLabel: 'ابن ٣',
    emoji: '🐼',
    avatarColor: 0xFFFFB547,
    elapsedLabel: '٠٨:١٥',
    kind: ActiveCallKind.video,
  );

  /// Co-parent voice call.
  static const ActiveCallDetail mother = ActiveCallDetail(
    callId: 'call\_mother',
    peerLabel: 'شريكة ١',
    emoji: '🌸',
    avatarColor: 0xFFFF8FA3,
    elapsedLabel: '١٢:١٠',
    kind: ActiveCallKind.audio,
  );

  /// All prototype branches for parametric coverage.
  static const List&lt;ActiveCallDetail&gt; all = \[
    childA,
    childB,
    childCVideo,
    mother,
  \];
}