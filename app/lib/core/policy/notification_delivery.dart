import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../domain/mother_level.dart';
import 'notification_prefs.dart';
import 'notification_tier.dart';

/// Result of a (mock) delivery attempt.
@immutable
final class NotificationDeliveryResult {
  const NotificationDeliveryResult({
    required this.recipientId,
    required this.tier,
    required this.delivered,
  });

  final String recipientId;
  final NotificationTier tier;
  final bool delivered;
}

/// Quiet-hours + analysis delivery gate (SET-010 / SET-011 / SET-021 / P-4 / R-3).
///
/// Critical/SOS always delivers — quiet hours never silence them.
/// Mother authority level (including [MotherLevel.observer]) never gates SOS.
/// Analysis notices (`S-AIC-029`) deliver only when the member's flag is on.
abstract final class NotificationDelivery {
  /// Whether [tier] should be delivered given [prefs] at [now].
  ///
  /// - [NotificationTier.critical] → always `true`
  /// - [NotificationTier.nonCritical] → `false` inside quiet window when enabled
  static bool shouldDeliver(
    NotificationTier tier,
    NotificationPrefs prefs,
    TimeOfDay now,
  ) {
    if (tier == NotificationTier.critical) return true;
    if (!prefs.quietHoursEnabled) return true;
    if (!prefs.isValid) return true;
    return !prefs.isInQuietWindow(now);
  }

  /// Guardians always receive SOS — mother level is ignored (SET-021 / P-4).
  ///
  /// [MotherLevel.observer] is explicitly included (see-only ≠ mute SOS).
  static bool guardianReceivesSos({
    required String memberId,
    MotherLevel? motherLevel,
  }) {
    // Enumerate levels so OBSERVER is a first-class, non-excluding case.
    switch (motherLevel) {
      case MotherLevel.observer:
      case MotherLevel.partner:
      case MotherLevel.full:
      case null:
        break;
    }
    // Every Stage-1 simulate recipient gets critical SOS (P-4).
    return memberId.isNotEmpty;
  }

  /// Simulates an SOS (critical) alert to [recipients].
  ///
  /// Always delivers — quiet hours, prefs, and mother level cannot mute SOS (P-4).
  /// Typical Stage-1 recipients: `father`, `mother` (any [MotherLevel]).
  static List<NotificationDeliveryResult> simulateSosAlert(
    List<String> recipients, {
    Map<String, NotificationPrefs>? prefsByMember,
    Map<String, MotherLevel?>? motherLevelByMember,
    TimeOfDay? now,
  }) {
    final clock = now ?? const TimeOfDay(hour: 23, minute: 0);
    return [
      for (final id in recipients)
        NotificationDeliveryResult(
          recipientId: id,
          tier: NotificationTier.critical,
          delivered: guardianReceivesSos(
                memberId: id,
                motherLevel: motherLevelByMember?[id],
              ) &&
              shouldDeliver(
                NotificationTier.critical,
                prefsByMember?[id] ??
                    NotificationPrefs.defaults(memberId: id).copyWith(
                      quietHoursEnabled: true,
                      quietStart: NotificationPrefs.defaultQuietStart,
                      quietEnd: NotificationPrefs.defaultQuietEnd,
                    ),
                clock,
              ),
        ),
    ];
  }

  /// Simulates R-3 / `S-AIC-029` analysis notice to one member (SET-011 lean).
  ///
  /// Delivers only when [NotificationPrefs.analysisNoticesEnabled] is true and
  /// quiet hours do not suppress non-critical.
  static NotificationDeliveryResult simulateAnalysisNotify(
    String recipientId, {
    NotificationPrefs? prefs,
    TimeOfDay? now,
  }) {
    final p = prefs ?? NotificationPrefs.defaults(memberId: recipientId);
    final clock = now ?? const TimeOfDay(hour: 12, minute: 0);
    final delivered = p.analysisNoticesEnabled &&
        shouldDeliver(NotificationTier.nonCritical, p, clock);
    return NotificationDeliveryResult(
      recipientId: recipientId,
      tier: NotificationTier.nonCritical,
      delivered: delivered,
    );
  }
}
