import 'package:flutter/foundation.dart';

import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_settings.dart';

/// Local Stage-1 escalation plan for one child (FAT-028 → fire/escalate path).
///
/// **Hard rules:** unverified / disabled backups never appear in [contacts].
/// SMS is intent-only until Native/Backend wires send.
@immutable
final class SosEscalationPlan {
  const SosEscalationPlan({
    required this.childId,
    required this.enabled,
    required this.delaySeconds,
    required this.notifyTrustedBackups,
    required this.prepareSmsFallback,
    required this.contacts,
  });

  factory SosEscalationPlan.disabled(String childId) => SosEscalationPlan(
        childId: childId,
        enabled: false,
        delaySeconds: 60,
        notifyTrustedBackups: false,
        prepareSmsFallback: false,
        contacts: const [],
      );

  final String childId;
  final bool enabled;
  final int delaySeconds;
  final bool notifyTrustedBackups;
  final bool prepareSmsFallback;

  /// Only [SosBackupContact.isEscalationEligible] contacts, priority order.
  final List<SosBackupContact> contacts;

  /// True when outside net should be considered after [delaySeconds].
  bool get willEscalateOutside =>
      enabled && (contacts.isNotEmpty || prepareSmsFallback);

  /// True when Local can list dial/SMS targets (verified phones only).
  bool get hasEligibleContacts => contacts.isNotEmpty;

  Map<String, Object?> toJson() => {
        'childId': childId,
        'enabled': enabled,
        'delaySeconds': delaySeconds,
        'notifyTrustedBackups': notifyTrustedBackups,
        'prepareSmsFallback': prepareSmsFallback,
        'contactIds': [for (final c in contacts) c.id],
      };
}

/// Resolves FAT-028 per-child prefs against the family ladder.
///
/// Unverified backups are **hard-skipped** even if enabled in the UI.
abstract final class SosEscalationResolver {
  static SosEscalationPlan resolve({
    required String childId,
    required SosLadder ladder,
    required SosLocalSettings settings,
  }) {
    final prefs = settings.escalationFor(childId);
    if (!prefs.enabled) {
      return SosEscalationPlan.disabled(childId);
    }
    final contacts = prefs.notifyTrustedBackups
        ? List<SosBackupContact>.unmodifiable(ladder.verifiedEscalationBackups)
        : const <SosBackupContact>[];
    return SosEscalationPlan(
      childId: childId,
      enabled: true,
      delaySeconds: prefs.delaySeconds,
      notifyTrustedBackups: prefs.notifyTrustedBackups,
      prepareSmsFallback: prefs.prepareSmsFallback,
      contacts: contacts,
    );
  }
}
