import 'package:flutter/foundation.dart';

/// Subscription / plan lifecycle states (UI-007 mock — no RevenueCat).
enum EntitlementStatus {
  /// Paid plan currently entitled.
  active,

  /// Free trial window (no auto-charge per product law).
  trial,

  /// Trial or paid period ended — safety must still work (P-4).
  expired,
}

/// Snapshot of family entitlement (billing / AI / education tiers only).
///
/// **Architecture:** SOS, chat, and location modules must never read this type
/// (UI-007 / SET-PAYWALL-RISK / Rule 9 / P-4).
@immutable
final class Entitlement {
  const Entitlement({
    required this.status,
    required this.planId,
    this.trialDaysRemaining,
    this.autoRenew = false,
  });

  /// Stage-1 demo: active family plan.
  factory Entitlement.activeFamily() => const Entitlement(
        status: EntitlementStatus.active,
        planId: 'family_smart',
        autoRenew: true,
      );

  /// Stage-1 demo: trial with days left.
  factory Entitlement.trial({int daysRemaining = 9}) => Entitlement(
        status: EntitlementStatus.trial,
        planId: 'trial_full',
        trialDaysRemaining: daysRemaining,
      );

  /// Stage-1 demo: expired — safety surfaces must still work.
  factory Entitlement.expired() => const Entitlement(
        status: EntitlementStatus.expired,
        planId: 'basic_safety',
      );

  final EntitlementStatus status;
  final String planId;
  final int? trialDaysRemaining;
  final bool autoRenew;

  bool get isExpired => status == EntitlementStatus.expired;
  bool get isTrial => status == EntitlementStatus.trial;
  bool get isActive => status == EntitlementStatus.active;

  Entitlement copyWith({
    EntitlementStatus? status,
    String? planId,
    int? trialDaysRemaining,
    bool? autoRenew,
    bool clearTrialDays = false,
  }) {
    return Entitlement(
      status: status ?? this.status,
      planId: planId ?? this.planId,
      trialDaysRemaining:
          clearTrialDays ? null : (trialDaysRemaining ?? this.trialDaysRemaining),
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}
