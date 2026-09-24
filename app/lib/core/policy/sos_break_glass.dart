/// Break-glass UI seam (OD-08) — temporary override; never mutates permanent policy.
library;

import 'package:flutter/foundation.dart';

import 'sos_role_actions.dart';

/// Break-glass lifecycle for FAT-018 sheet (UI-only; no backend).
enum SosBreakGlassPhase {
  start,
  reason,
  confirm,
  overrideActive,
  expired,
  revoked,
}

@immutable
final class SosBreakGlassSession {
  const SosBreakGlassSession({
    required this.id,
    required this.capabilityKey,
    required this.reason,
    required this.startedAt,
    required this.expiresAt,
    required this.phase,
    this.auditNote,
  });

  final String id;
  final String capabilityKey;
  final String reason;
  final DateTime startedAt;
  final DateTime expiresAt;
  final SosBreakGlassPhase phase;
  final String? auditNote;

  bool get isActive =>
      phase == SosBreakGlassPhase.overrideActive &&
      DateTime.now().toUtc().isBefore(expiresAt);

  SosBreakGlassSession copyWith({
    SosBreakGlassPhase? phase,
    String? auditNote,
  }) =>
      SosBreakGlassSession(
        id: id,
        capabilityKey: capabilityKey,
        reason: reason,
        startedAt: startedAt,
        expiresAt: expiresAt,
        phase: phase ?? this.phase,
        auditNote: auditNote ?? this.auditNote,
      );
}

/// In-memory break-glass store — does **not** change SOS ladder or permanent rules.
final class InMemorySosBreakGlassStore {
  SosBreakGlassSession? _active;
  final List<SosBreakGlassSession> _audit = [];

  SosBreakGlassSession? get active {
    final a = _active;
    if (a == null) return null;
    if (a.phase == SosBreakGlassPhase.overrideActive &&
        !DateTime.now().toUtc().isBefore(a.expiresAt)) {
      final expired = a.copyWith(phase: SosBreakGlassPhase.expired);
      _active = null;
      _audit.add(expired);
      return null;
    }
    return a;
  }

  List<SosBreakGlassSession> get auditLog => List.unmodifiable(_audit);

  /// Starts override. Throws if [actor] lacks [SosRoleActions.canBreakGlass].
  SosBreakGlassSession start({
    required SosActor actor,
    required String capabilityKey,
    required String reason,
    required Duration duration,
    DateTime? now,
  }) {
    if (!SosRoleActions.canBreakGlass(actor)) {
      throw StateError('break-glass denied for actor');
    }
    final t = now ?? DateTime.now().toUtc();
    final session = SosBreakGlassSession(
      id: 'bg_${t.millisecondsSinceEpoch}',
      capabilityKey: capabilityKey,
      reason: reason,
      startedAt: t,
      expiresAt: t.add(duration),
      phase: SosBreakGlassPhase.overrideActive,
      auditNote: 'break_glass_started',
    );
    _active = session;
    _audit.add(session);
    return session;
  }

  void revoke({String? note}) {
    final a = _active;
    if (a == null) return;
    final revoked = a.copyWith(
      phase: SosBreakGlassPhase.revoked,
      auditNote: note ?? 'break_glass_revoked',
    );
    _active = null;
    _audit.add(revoked);
  }

  void clear() {
    _active = null;
    _audit.clear();
  }
}

final InMemorySosBreakGlassStore stage1SosBreakGlassStore =
    InMemorySosBreakGlassStore();
