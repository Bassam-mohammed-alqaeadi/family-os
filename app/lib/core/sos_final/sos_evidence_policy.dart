import 'package:flutter/foundation.dart';

/// RD-03 / Q-SOS-RD-03A evidence retention (frozen).
@immutable
abstract final class SosEvidencePolicy {
  /// Operational samples (location snapshots, delivery rows, device/battery…).
  static const int operationalRetentionDays = 90;

  /// Core header + lifecycle audit are retained indefinitely.
  static const bool coreAuditIndefinite = true;

  /// Audio / video evidence is forbidden (OD-10 / OD-11).
  static const bool audioVideoForbidden = true;

  static DateTime retainUntilFrom(DateTime triggeredAt) =>
      triggeredAt.toUtc().add(const Duration(days: operationalRetentionDays));
}

/// Kind of operational sample row (never audio/video).
enum SosOpsSampleKind {
  location,
  delivery,
  deviceBattery,
  connectivity,
  escalation,
  communication,
}

/// Kind of indefinite lifecycle audit event.
enum SosAuditEventType {
  fired,
  acknowledged,
  escalating,
  resolved,
  cancelled,
  breakGlassStarted,
  breakGlassExpired,
  breakGlassRevoked,
}
