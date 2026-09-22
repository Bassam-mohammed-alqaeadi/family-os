import 'package:family_os/features/n02_day/active_call_repository.dart';

/// Test / demo fixtures for SCR-CHD-009 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic peer labels only (أب ١ / أم ١) — never planted names (Rule 23).
abstract final class ChildActiveCallMock {
  const ChildActiveCallMock._();

  static const ActiveCallDetail father = ActiveCallDetail(
    callId: 'call_father',
    peerLabel: 'أب ١',
    emoji: '👨',
    avatarColor: 0xFF7C5CFF,
    elapsedLabel: '٠:١٢',
  );

  static const ActiveCallDetail mother = ActiveCallDetail(
    callId: 'call_mother',
    peerLabel: 'أم ١',
    emoji: '👩',
    avatarColor: 0xFFFF8FA3,
    elapsedLabel: '٠:٠٨',
  );

  static const List<ActiveCallDetail> all = [father, mother];
}
