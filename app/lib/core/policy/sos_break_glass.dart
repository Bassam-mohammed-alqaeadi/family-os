/// Break-glass UI seam (OD-08) — temporary override; never mutates permanent policy.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/sos_final/sos_final_store.dart';

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
    this.incidentId,
  });

  final String id;
  final String capabilityKey;
  final String reason;
  final DateTime startedAt;
  final DateTime expiresAt;
  final SosBreakGlassPhase phase;
  final String? auditNote;

  /// Domain incident when bound from FAT-018; UI-only rows use [uiIncidentId].
  final String? incidentId;

  bool get isActive =>
      phase == SosBreakGlassPhase.overrideActive &&
      DateTime.now().toUtc().isBefore(expiresAt);

  SosBreakGlassSession copyWith({
    SosBreakGlassPhase? phase,
    String? auditNote,
    String? incidentId,
  }) =>
      SosBreakGlassSession(
        id: id,
        capabilityKey: capabilityKey,
        reason: reason,
        startedAt: startedAt,
        expiresAt: expiresAt,
        phase: phase ?? this.phase,
        auditNote: auditNote ?? this.auditNote,
        incidentId: incidentId ?? this.incidentId,
      );
}

/// Rule 25 seam — break-glass temporary override store.
abstract class SosBreakGlassStore {
  SosBreakGlassSession? get active;
  List<SosBreakGlassSession> get auditLog;

  /// Starts override. Throws if [actor] lacks [SosRoleActions.canBreakGlass].
  Future<SosBreakGlassSession> start({
    required SosActor actor,
    required String capabilityKey,
    required String reason,
    required Duration duration,
    DateTime? now,
    String? incidentId,
    String? actorId,
  });

  Future<void> revoke({String? note});

  void clear();
}

/// Marker incident_id for sheet sessions without an open Domain incident.
const String kSosBreakGlassUiIncidentId = 'ui_break_glass';

/// In-memory break-glass store — does **not** change SOS ladder or permanent rules.
///
/// Retained for tests / injection. Production binds [LocalSosBreakGlassStore].
final class InMemorySosBreakGlassStore implements SosBreakGlassStore {
  SosBreakGlassSession? _active;
  final List<SosBreakGlassSession> _audit = [];

  @override
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

  @override
  List<SosBreakGlassSession> get auditLog => List.unmodifiable(_audit);

  @override
  Future<SosBreakGlassSession> start({
    required SosActor actor,
    required String capabilityKey,
    required String reason,
    required Duration duration,
    DateTime? now,
    String? incidentId,
    String? actorId,
  }) async {
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
      incidentId: incidentId ?? kSosBreakGlassUiIncidentId,
    );
    _active = session;
    _audit.add(session);
    return session;
  }

  @override
  Future<void> revoke({String? note}) async {
    final a = _active;
    if (a == null) return;
    final revoked = a.copyWith(
      phase: SosBreakGlassPhase.revoked,
      auditNote: note ?? 'break_glass_revoked',
    );
    _active = null;
    _audit.add(revoked);
  }

  @override
  void clear() {
    _active = null;
    _audit.clear();
  }
}

/// Durable break-glass — Domain `sos_break_glass` table (AUTH-FS006-BG).
///
/// Single Local authority with [SosFinalService] / [LocalSosFinalStore].
/// Does not claim remote delivery. Preserves UI RBAC; does not mutate ladder.
final class LocalSosBreakGlassStore implements SosBreakGlassStore {
  LocalSosBreakGlassStore(
    this._store, {
    FamilyId? familyId,
    DateTime Function()? clock,
  })  : familyId = familyId ?? FamilyId('fam_stage1'),
        _clock = clock ?? DateTime.now;

  final LocalSosFinalStore _store;
  final FamilyId familyId;
  final DateTime Function() _clock;

  SosBreakGlassSession? _active;
  final List<SosBreakGlassSession> _audit = [];

  Future<void> hydrate() async {
    final rows = await _store.listBreakGlass();
    _audit.clear();
    SosBreakGlassSession? active;
    for (final row in rows) {
      final session = _fromRow(row);
      _audit.add(session);
      if (session.phase == SosBreakGlassPhase.overrideActive &&
          _clock().toUtc().isBefore(session.expiresAt)) {
        active = session;
      }
    }
    _active = active;
  }

  @override
  SosBreakGlassSession? get active {
    final a = _active;
    if (a == null) return null;
    if (a.phase == SosBreakGlassPhase.overrideActive &&
        !_clock().toUtc().isBefore(a.expiresAt)) {
      // Lazy expiry — flush async; callers may also call [expireIfNeeded].
      final expired = a.copyWith(phase: SosBreakGlassPhase.expired);
      _active = null;
      _audit.add(expired);
      unawaited(_persist(expired, endReason: 'expiry'));
      return null;
    }
    return a;
  }

  @override
  List<SosBreakGlassSession> get auditLog => List.unmodifiable(_audit);

  @override
  Future<SosBreakGlassSession> start({
    required SosActor actor,
    required String capabilityKey,
    required String reason,
    required Duration duration,
    DateTime? now,
    String? incidentId,
    String? actorId,
  }) async {
    if (!SosRoleActions.canBreakGlass(actor)) {
      throw StateError('break-glass denied for actor');
    }
    final t = (now ?? _clock()).toUtc();
    final session = SosBreakGlassSession(
      id: 'bg_${t.millisecondsSinceEpoch}',
      capabilityKey: capabilityKey,
      reason: reason,
      startedAt: t,
      expiresAt: t.add(duration),
      phase: SosBreakGlassPhase.overrideActive,
      auditNote: 'break_glass_started',
      incidentId: incidentId ?? kSosBreakGlassUiIncidentId,
    );
    _active = session;
    _audit.add(session);
    await _persist(
      session,
      actorId: actorId ?? 'actor_${actor.role.name}',
    );
    return session;
  }

  @override
  Future<void> revoke({String? note}) async {
    final a = _active;
    if (a == null) return;
    final revoked = a.copyWith(
      phase: SosBreakGlassPhase.revoked,
      auditNote: note ?? 'break_glass_revoked',
    );
    _active = null;
    _audit.add(revoked);
    await _persist(revoked, endReason: 'manual');
  }

  @override
  void clear() {
    _active = null;
    _audit.clear();
  }

  Future<void> _persist(
    SosBreakGlassSession session, {
    String? actorId,
    String? endReason,
  }) async {
    final ended = session.phase == SosBreakGlassPhase.expired ||
        session.phase == SosBreakGlassPhase.revoked;
    final row = <String, Object?>{
      'id': session.id,
      'incident_id': session.incidentId ?? kSosBreakGlassUiIncidentId,
      'family_id': familyId.value,
      'actor_id': actorId ?? 'unknown',
      'capability_id': session.capabilityKey,
      'reason': session.reason,
      'phase': session.phase.name,
      'started_at': session.startedAt.millisecondsSinceEpoch,
      'ends_at': session.expiresAt.millisecondsSinceEpoch,
      'ended_at': ended ? _clock().toUtc().millisecondsSinceEpoch : null,
      'end_reason': endReason,
    };
    await _store.saveBreakGlass(row);
  }

  static SosBreakGlassSession _fromRow(Map<String, Object?> row) {
    final phaseName = row['phase'] as String? ?? 'overrideActive';
    final phase = SosBreakGlassPhase.values.firstWhere(
      (p) => p.name == phaseName,
      orElse: () => SosBreakGlassPhase.overrideActive,
    );
    return SosBreakGlassSession(
      id: row['id']! as String,
      capabilityKey: row['capability_id']! as String,
      reason: row['reason']! as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row['started_at']! as int,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row['ends_at']! as int,
        isUtc: true,
      ),
      phase: phase,
      auditNote: phase == SosBreakGlassPhase.overrideActive
          ? 'break_glass_started'
          : phase.name,
      incidentId: row['incident_id'] as String?,
    );
  }
}

/// Production singleton — rebound to [LocalSosBreakGlassStore] when SOS Final opens.
SosBreakGlassStore stage1SosBreakGlassStore = InMemorySosBreakGlassStore();

void rebindStage1SosBreakGlassStore(SosBreakGlassStore store) {
  stage1SosBreakGlassStore = store;
}
