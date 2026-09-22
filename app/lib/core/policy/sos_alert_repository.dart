import 'package:flutter/foundation.dart';

import 'sos_alert.dart';
import 'sos_fire.dart';
import 'sos_ladder.dart';

/// Rule 25 seam — active SOS alert for SCR-FAT-018 (no Firebase).
abstract class SosAlertRepository {
  /// Returns the active alert, or `null` when none / already resolved.
  Future<SosAlert?> loadActive({String? alertId});

  /// Marks alert resolved (parent «وصلتُ إليه»). Audit retained in-memory.
  Future<SosAlert> resolve(String alertId);

  /// S-SEC-030 national / backup escalate — mock always succeeds.
  Future<void> escalateEmergencyContacts(String alertId);
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
    String childId = 'child_a',
    DateTime? pressedAt,
  }) {
    return SosAlert(
      id: id,
      childId: childId,
      childDisplayName: 'ابن ١',
      childEmoji: '🦁',
      pressedAt: pressedAt ?? DateTime.utc(2026, 9, 21, 12, 47),
      locationLabel: 'شارع الأمير سعود — قرب حديقة الحي',
      batteryPercent: 83,
      movementLabel: 'يتحرك ببطء شرقًا',
      accuracyMeters: 8,
      recipientLabels: const ['أنت', 'الأم', 'جهة احتياط'],
      status: SosAlertStatus.active,
    );
  }

  int resolveCount = 0;
  int escalateCount = 0;

  @override
  Future<SosAlert?> loadActive({String? alertId}) async {
    final a = _active;
    if (a == null || !a.isActive) return null;
    if (alertId != null && alertId.isNotEmpty && a.id != alertId) return null;
    return a;
  }

  @override
  Future<SosAlert> resolve(String alertId) async {
    final a = _active;
    if (a == null || a.id != alertId) {
      throw StateError('no active SOS alert $alertId');
    }
    final closed = a.copyWith(status: SosAlertStatus.resolved);
    _active = null;
    _resolved.add(closed);
    resolveCount++;
    return closed;
  }

  @override
  Future<void> escalateEmergencyContacts(String alertId) async {
    final a = _active;
    if (a == null || a.id != alertId || !a.isActive) {
      throw StateError('no active SOS alert $alertId');
    }
    escalateCount++;
  }

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
/// Used when the alert payload omits recipients; keeps SET-020 ladder as source.
List<String> sosAlertRecipientsFromLadder(
  SosLadder ladder, {
  required String fatherLabel,
  required String motherLabel,
}) {
  final labels = <String>[];
  for (final id in ladder.rung1MemberIds) {
    if (id == 'father') labels.add(fatherLabel);
    if (id == 'mother') labels.add(motherLabel);
  }
  for (final b in ladder.backups.where((b) => b.enabled)) {
    labels.add(b.name);
  }
  return labels;
}

/// Fires SOS via [SosFireService] and seeds [SosAlertRepository] (P-4 path).
///
/// Entitlement-free — [SosFireService] has no billing parameter (UI-007).
Future<SosFireResult> fireAndSeedSosAlert({
  required String childId,
  required SosFireService sosFire,
  required InMemorySosAlertRepository alerts,
  SosLadder? ladder,
  SosAlert Function(SosFireResult result)? alertFactory,
}) async {
  final result = await sosFire.fire(childId: childId);
  final alert = alertFactory?.call(result) ??
      InMemorySosAlertRepository.demoActive(
        id: 'sos_${result.at.millisecondsSinceEpoch}',
        childId: childId,
        pressedAt: result.at,
      );
  alerts.seed(alert);
  return result;
}
