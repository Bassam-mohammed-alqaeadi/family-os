import 'package:family_os/features/n02_day/active_call_repository.dart';

/// Test / demo fixtures for SCR-CHD-009 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic peer labels only (أب 1 / أم 1) — never planted names (Rule 23).
abstract final class ChildActiveCallMock {
  const ChildActiveCallMock._();

  static const ActiveCallDetail father = ActiveCallDetail(
    callId: 'call_father',
    peerLabel: 'أب 1',
    emoji: '👨',
    avatarColor: 0xFF7C5CFF,
    elapsedLabel: '0:12',
  );

  static const ActiveCallDetail mother = ActiveCallDetail(
    callId: 'call_mother',
    peerLabel: 'أم 1',
    emoji: '👩',
    avatarColor: 0xFFFF8FA3,
    elapsedLabel: '0:08',
  );

  static const List<ActiveCallDetail> all = [father, mother];
}
