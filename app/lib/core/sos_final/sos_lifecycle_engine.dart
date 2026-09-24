import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';

import 'sos_incident.dart';

/// Pure lifecycle transition rules (incident ≠ delivery).
abstract final class SosLifecycleEngine {
  /// HOLD complete → local ACTIVE incident (FIRING is ephemeral).
  static void assertCanFire({required bool alreadyOpen}) {
    if (alreadyOpen) {
      throw StateError('Cannot fire SOS while an open incident exists');
    }
  }

  static SosIncident acknowledge({
    required SosIncident incident,
    required SosActor actor,
    required DateTime now,
    required String actorId,
  }) {
    if (!SosRoleActions.canAcknowledge(actor)) {
      throw StateError('Actor cannot acknowledge SOS');
    }
    if (!incident.isOpen) {
      throw StateError('Incident is not open');
    }
    if (incident.status == SosAlertStatus.acknowledged ||
        incident.status == SosAlertStatus.escalating) {
      return incident;
    }
    if (incident.status != SosAlertStatus.active) {
      throw StateError('Acknowledge only from ACTIVE');
    }
    return incident.copyWith(
      status: SosAlertStatus.acknowledged,
      acknowledgedAt: now.toUtc(),
      acknowledgedBy: actorId,
    );
  }

  static SosIncident escalate({
    required SosIncident incident,
    required SosActor actor,
  }) {
    if (!SosRoleActions.canEscalate(actor)) {
      throw StateError('Actor cannot escalate SOS');
    }
    if (!incident.isOpen) {
      throw StateError('Incident is not open');
    }
    return incident.copyWith(status: SosAlertStatus.escalating);
  }

  static SosIncident resolve({
    required SosIncident incident,
    required SosActor actor,
    required DateTime now,
    required String actorId,
    SosTerminalReason reason = SosTerminalReason.helped,
  }) {
    if (!SosRoleActions.canResolve(actor)) {
      throw StateError('Actor cannot resolve SOS');
    }
    if (!incident.isOpen) {
      throw StateError('Incident is not open');
    }
    return incident.copyWith(
      status: SosAlertStatus.resolved,
      terminalReason: reason,
      resolvedAt: now.toUtc(),
      resolvedBy: actorId,
    );
  }

  /// Child false-alarm cancel → RESOLVED + FALSE_ALARM (OD-06).
  static SosIncident cancelAsFalseAlarm({
    required SosIncident incident,
    required SosActor actor,
    required DateTime now,
    required String actorId,
  }) {
    if (!SosRoleActions.canCancelOwnSos(actor)) {
      throw StateError('Only child can cancel own SOS');
    }
    if (!incident.isOpen) {
      throw StateError('Incident is not open');
    }
    return incident.copyWith(
      status: SosAlertStatus.resolved,
      terminalReason: SosTerminalReason.falseAlarm,
      resolvedAt: now.toUtc(),
      resolvedBy: actorId,
    );
  }
}
