import 'package:flutter/foundation.dart';

import 'package:family_os/core/sos_final/sos_escalation_resolver.dart';

import '../domain/role.dart';
import 'sos_alert.dart';
import 'sos_fire.dart';
import 'sos_ladder.dart';
import 'sos_role_actions.dart';
import 'sos_settings.dart';

/// Rule 25 seam — active SOS alert for SCR-FAT-018 (no Firebase).
abstract class SosAlertRepository {
  /// Returns the open alert, or `null` when none / already resolved.
  Future<SosAlert?> loadActive({String? alertId});

  /// Marks alert acknowledged (ACK ≠ RESOLVE).
  Future<SosAlert> acknowledge(String alertId, {required SosActor actor});

  /// Marks alert resolved (parent close or child false-alarm).
  Future<SosAlert> resolve(
    String alertId, {
    required SosActor actor,
    SosTerminalReason reason = SosTerminalReason.helped,
  });

  /// S-SEC-030 backup escalate — sets [SosAlertStatus.escalating].
  /// Delivery transport remains honest / mock (no real SMS).
  Future<SosAlert> escalateEmergencyContacts(
    String alertId, {
    required SosActor actor,
  });
}

/// In-memory Stage-1 store. Default has **no** planted names (Rule 23 empty).
final class InMemorySosAlertRepository implements SosAlertRepository {
  InMemorySosAlertRepository({SosAlert? initialActive})
    : _active = initialActive;

  SosAlert? _active;
  final List<SosAlert> _resolved = [];

  /// Test/demo fixture — generic labels only (ابن ١), never product defaults.
  static SosAlert demoActive({
    String id = 'sos_1',
    String childId = 'demo-child',
    String? raisedByActorId,
    DateTime? pressedAt,
    SosLocationClass locationClass = SosLocationClass.acquiring,
    SosConnectionClass connectionClass = SosConnectionClass.online,
    List<SosDeliveryRow> deliveries = const [],
    bool panicQuietAtTrigger = false,
  }) {
    return SosAlert(
      id: id,
      childId: childId,
      raisedByActorId: raisedByActorId,
      childDisplayName: 'ابن ١',
      childEmoji: '🦁',
      pressedAt: pressedAt ?? DateTime.utc(2026, 9, 21, 12, 47),
      locationLabel: 'شارع الأمير سعود — قرب حديقة الحي',
      batteryPercent: 83,
      movementLabel: 'يتحرك ببطء شرقًا',
      accuracyMeters: 8,
      recipientLabels: const ['أنت', 'الأم', 'جهة احتياط'],
      status: SosAlertStatus.active,
      locationClass: locationClass,
      connectionClass: connectionClass,
      deliveries: deliveries.isEmpty
          ? const [
              SosDeliveryRow(
                recipientId: 'father',
                channel: 'in_app',
                status: SosDeliveryClass.pending,
              ),
              SosDeliveryRow(
                recipientId: 'mother',
                channel: 'push',
                status: SosDeliveryClass.unavailable,
              ),
              SosDeliveryRow(
                recipientId: 'backup',
                channel: 'sms',
                status: SosDeliveryClass.notConfigured,
              ),
            ]
          : deliveries,
      panicQuietAtTrigger: panicQuietAtTrigger,
    );
  }

  int resolveCount = 0;
  int escalateCount = 0;
  int acknowledgeCount = 0;

  @override
  Future<SosAlert?> loadActive({String? alertId}) async {
    final a = _active;
    if (a == null || !a.isOpen) return null;
    if (alertId != null && alertId.isNotEmpty && a.id != alertId) return null;
    return a;
  }

  @override
  Future<SosAlert> acknowledge(
    String alertId, {
    required SosActor actor,
  }) async {
    if (!SosRoleActions.canAcknowledge(actor)) {
      throw StateError('acknowledge denied for actor');
    }
    final a = _active;
    if (a == null || a.id != alertId || !a.isOpen) {
      throw StateError('no open SOS alert $alertId');
    }
    if (a.status == SosAlertStatus.acknowledged ||
        a.status == SosAlertStatus.escalating) {
      return a;
    }
    final next = a.copyWith(
      status: SosAlertStatus.acknowledged,
      acknowledgedAt: DateTime.now().toUtc(),
    );
    _active = next;
    acknowledgeCount++;
    return next;
  }

  @override
  Future<SosAlert> resolve(
    String alertId, {
    required SosActor actor,
    SosTerminalReason reason = SosTerminalReason.helped,
  }) async {
    final isChildFalseAlarm =
        actor.role == AppRole.child &&
        SosRoleActions.canCancelOwnSos(actor) &&
        reason == SosTerminalReason.falseAlarm;
    if (!isChildFalseAlarm && !SosRoleActions.canResolve(actor)) {
      throw StateError('resolve denied for actor');
    }
    final a = _active;
    if (a == null || a.id != alertId) {
      throw StateError('no active SOS alert $alertId');
    }
    final closed = a.copyWith(
      status: SosAlertStatus.resolved,
      terminalReason: reason,
    );
    _active = null;
    _resolved.add(closed);
    resolveCount++;
    return closed;
  }

  @override
  Future<SosAlert> escalateEmergencyContacts(
    String alertId, {
    required SosActor actor,
  }) async {
    if (!SosRoleActions.canEscalate(actor)) {
      throw StateError('escalate denied for actor');
    }
    final a = _active;
    if (a == null || a.id != alertId || !a.isOpen) {
      throw StateError('no open SOS alert $alertId');
    }
    // Local Stage-1: mark escalating + attach eligible outside contacts only.
    // Unverified hard-skipped via SosEscalationResolver / verifiedEscalationBackups.
    final ladder =
        await (_ladderLoader?.call() ?? Future.value(SosLadder.defaults()));
    final settings = _settingsLoader?.call() ?? const SosLocalSettings();
    final plan = SosEscalationResolver.resolve(
      childId: a.childId,
      ladder: ladder,
      settings: settings,
    );
    final deliveries = <SosDeliveryRow>[
      ...a.deliveries,
      for (final c in plan.contacts)
        SosDeliveryRow(
          recipientId: c.id,
          channel: plan.prepareSmsFallback ? 'sms_prepare' : 'in_app',
          status: SosDeliveryClass.pending,
        ),
    ];
    final next = a.copyWith(
      status: SosAlertStatus.escalating,
      deliveries: deliveries,
    );
    _active = next;
    escalateCount++;
    lastEscalationPlan = plan;
    return next;
  }

  /// Optional test / DI seams for escalate recipient resolution.
  Future<SosLadder> Function()? _ladderLoader;
  SosLocalSettings Function()? _settingsLoader;

  @visibleForTesting
  void bindEscalationSources({
    Future<SosLadder> Function()? ladderLoader,
    SosLocalSettings Function()? settingsLoader,
  }) {
    _ladderLoader = ladderLoader;
    _settingsLoader = settingsLoader;
  }

  @visibleForTesting
  SosEscalationPlan? lastEscalationPlan;

  /// Test seam — plant or clear the active alert.
  void seed(SosAlert? alert) {
    _active = alert;
  }

  @visibleForTesting
  List<SosAlert> get resolvedLog => List.unmodifiable(_resolved);
}

/// Stage-1 shared SOS alert store (empty by default — Rule 23).
final InMemorySosAlertRepository stage1SosAlertRepository =
    InMemorySosAlertRepository();

/// Builds recipient display labels from [SosLadder] + ARB parent names.
///
/// Outside backups: only [SosBackupContact.isEscalationEligible] (hard-skip).
/// When [childId] + [settings] are set, FAT-028 per-child prefs gate the net.
List<String> sosAlertRecipientsFromLadder(
  SosLadder ladder, {
  required String fatherLabel,
  required String motherLabel,
  String? childId,
  SosLocalSettings? settings,
}) {
  final labels = <String>[];
  for (final id in ladder.rung1MemberIds) {
    if (id == 'father') labels.add(fatherLabel);
    if (id == 'mother') labels.add(motherLabel);
  }
  final backups = _outsideEscalationContacts(
    ladder: ladder,
    childId: childId,
    settings: settings,
  );
  for (final b in backups) {
    labels.add(b.name);
  }
  return labels;
}

List<SosBackupContact> _outsideEscalationContacts({
  required SosLadder ladder,
  String? childId,
  SosLocalSettings? settings,
}) {
  if (childId != null && settings != null) {
    return SosEscalationResolver.resolve(
      childId: childId,
      ladder: ladder,
      settings: settings,
    ).contacts;
  }
  return ladder.verifiedEscalationBackups;
}

/// Fires SOS via [SosFireService] and seeds [SosAlertRepository] (P-4 path).
///
/// Entitlement-free — [SosFireService] has no billing parameter (UI-007).
Future<SosFireResult> fireAndSeedSosAlert({
  required String childId,
  String? actorId,
  required SosFireService sosFire,
  required InMemorySosAlertRepository alerts,
  SosLadder? ladder,
  SosAlert Function(SosFireResult result)? alertFactory,
  SosSettingsStore? settings,
}) async {
  final result = await sosFire.fire(childId: childId, actorId: actorId);
  final panicQuiet = settings?.settings.panicQuietPreferred ?? false;
  final alert =
      alertFactory?.call(result) ??
      InMemorySosAlertRepository.demoActive(
        id: 'sos_${result.at.millisecondsSinceEpoch}',
        childId: result.childId,
        raisedByActorId: result.actorId,
        pressedAt: result.at,
        panicQuietAtTrigger: panicQuiet,
      );
  alerts.seed(alert);
  return result;
}
