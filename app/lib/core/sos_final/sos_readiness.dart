import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_settings.dart';

/// OD-21 readiness capability class (matches sos_final vocabulary).
enum SosReadinessClass {
  available,
  degraded,
  unavailable,
  notConfigured,
}

@immutable
final class SosReadinessRow {
  const SosReadinessRow({
    required this.id,
    required this.klass,
    this.note = '',
  });

  final String id;
  final SosReadinessClass klass;
  final String note;
}

@immutable
final class SosReadinessSnapshot {
  const SosReadinessSnapshot({
    required this.rows,
    required this.checkedAt,
  });

  final List<SosReadinessRow> rows;
  final DateTime checkedAt;

  /// Never green if push unavailable and no SMS/call configured (OD-21).
  bool get claimsReady {
    SosReadinessRow? byId(String id) {
      for (final r in rows) {
        if (r.id == id) return r;
      }
      return null;
    }

    final push = byId('push_alerts');
    final sms = byId('sms_fallback');
    final call = byId('call_fallback');
    final pushBad = push == null ||
        push.klass == SosReadinessClass.unavailable ||
        push.klass == SosReadinessClass.notConfigured;
    final smsOk = sms?.klass == SosReadinessClass.available ||
        sms?.klass == SosReadinessClass.degraded;
    final callOk = call?.klass == SosReadinessClass.available ||
        call?.klass == SosReadinessClass.degraded;
    if (pushBad && !smsOk && !callOk) return false;

    for (final r in rows) {
      if (r.id == 'audio_emergency_dial') continue; // excluded — omit
      if (r.klass == SosReadinessClass.unavailable) return false;
    }
    return true;
  }
}

/// Inputs for Stage-1 readiness honesty (no fake native proofs).
@immutable
final class SosReadinessInputs {
  const SosReadinessInputs({
    required this.ladder,
    required this.settings,
    this.childLinked = true,
    this.localPersistenceOk = true,
    this.pushCapability = CapabilityStatus.mockRemote,
    this.smsConfigured = false,
    this.callConfigured = false,
    this.locationClass = SosLocationClass.unavailable,
    this.breakGlassApplicable = true,
  });

  final SosLadder ladder;
  final SosLocalSettings settings;
  final bool childLinked;
  final bool localPersistenceOk;
  final CapabilityStatus pushCapability;
  final bool smsConfigured;
  final bool callConfigured;
  final SosLocationClass locationClass;
  final bool breakGlassApplicable;
}

/// Builds OD-21 readiness checklist (FAT-028 / empty FAT-018 CTA).
abstract final class SosReadinessEvaluator {
  static SosReadinessSnapshot evaluate(
    SosReadinessInputs input, {
    DateTime Function()? clock,
  }) {
    final now = (clock ?? DateTime.now)().toUtc();
    final verified = input.ladder.verifiedEscalationBackups.length;
    final backups = input.ladder.backups.length;
    final rung1Ok = input.ladder.presentParentIds.isNotEmpty;

    final (SosReadinessClass pushClass, String pushNote) =
        switch (input.pushCapability) {
      CapabilityStatus.implemented => (
          SosReadinessClass.available,
          'Push entitlement OK',
        ),
      CapabilityStatus.degraded || CapabilityStatus.mockRemote => (
          SosReadinessClass.degraded,
          'Push MOCK-REMOTE — no live FCM claim',
        ),
      CapabilityStatus.unsupported => (
          SosReadinessClass.unavailable,
          'Push unsupported on this platform',
        ),
      CapabilityStatus.notImplemented => (
          SosReadinessClass.notConfigured,
          'Push not configured',
        ),
    };

    final rows = <SosReadinessRow>[
      SosReadinessRow(
        id: 'child_trigger',
        klass: input.childLinked
            ? SosReadinessClass.available
            : SosReadinessClass.notConfigured,
        note: input.childLinked ? 'Child linked' : 'Child not linked',
      ),
      SosReadinessRow(
        id: 'local_persistence',
        klass: input.localPersistenceOk
            ? SosReadinessClass.available
            : SosReadinessClass.unavailable,
        note: input.localPersistenceOk
            ? 'Local incident store healthy'
            : 'Local store unhealthy',
      ),
      SosReadinessRow(id: 'push_alerts', klass: pushClass, note: pushNote),
      SosReadinessRow(
        id: 'sms_fallback',
        klass: input.smsConfigured
            ? SosReadinessClass.degraded
            : SosReadinessClass.notConfigured,
        note: input.smsConfigured
            ? 'SMS numbers present — transport MOCK-REMOTE'
            : 'SMS not configured',
      ),
      SosReadinessRow(
        id: 'call_fallback',
        klass: input.callConfigured
            ? SosReadinessClass.degraded
            : SosReadinessClass.notConfigured,
        note: input.callConfigured
            ? 'Call numbers present — dialer MOCK-REMOTE'
            : 'Call not configured',
      ),
      SosReadinessRow(
        id: 'location',
        klass: switch (input.locationClass) {
          SosLocationClass.ready => SosReadinessClass.available,
          SosLocationClass.acquiring ||
          SosLocationClass.stale =>
            SosReadinessClass.degraded,
          SosLocationClass.unavailable => SosReadinessClass.unavailable,
        },
        note: 'Location ${input.locationClass.name} (never blocks fire)',
      ),
      SosReadinessRow(
        id: 'trusted_ladder',
        klass: !rung1Ok
            ? SosReadinessClass.notConfigured
            : (verified == 0 && backups > 0)
                ? SosReadinessClass.degraded
                : SosReadinessClass.available,
        note: rung1Ok
            ? 'Rung-1 OK · verified backups $verified/$backups'
            : 'Rung-1 parents missing',
      ),
      SosReadinessRow(
        id: 'panic_quiet',
        klass: SosReadinessClass.available,
        note: input.settings.panicQuietPreferred
            ? 'Panic Quiet preferred ON (informational)'
            : 'Panic Quiet preferred OFF',
      ),
      SosReadinessRow(
        id: 'break_glass',
        klass: input.breakGlassApplicable
            ? SosReadinessClass.available
            : SosReadinessClass.notConfigured,
        note: input.breakGlassApplicable
            ? 'Break-glass for Primary/Full when ACTIVE'
            : 'Break-glass N/A for this role',
      ),
    ];

    return SosReadinessSnapshot(rows: rows, checkedAt: now);
  }
}
