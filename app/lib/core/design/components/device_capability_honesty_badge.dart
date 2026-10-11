import 'package:flutter/material.dart';

import 'tag.dart';

/// S0 spine: honest badge for a single device capability row reported by the
/// server (migration 117).
///
/// R4 / Principle 2 — the badge reflects what the ledger says, NEVER what a
/// toggle implies. A capability that is `unsupported` or `permission_needed`
/// renders as a muted explanatory chip, not a disabled toggle that pretends
/// the parent is in control.
///
/// Labels are intentionally plain Arabic-first text; they move into ARB the
/// moment a screen starts using them live (R4 — Arabic first, in ARB).
enum DeviceCapabilityHonestyState {
  confirmed,
  awaitingSetup,
  permissionNeeded,
  unsupported,
  revoked,
  unknown,
}

class DeviceCapabilityHonestyBadge extends StatelessWidget {
  const DeviceCapabilityHonestyBadge({
    super.key,
    required this.state,
    this.labelOverride,
  });

  final DeviceCapabilityHonestyState state;

  /// Optional short override (e.g. evidence text shown next to the chip).
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (state) {
      DeviceCapabilityHonestyState.confirmed => (
          labelOverride ?? 'مؤكَّد',
          TagVariant.g,
        ),
      DeviceCapabilityHonestyState.awaitingSetup => (
          labelOverride ?? 'ينتظر الإعداد',
          TagVariant.a,
        ),
      DeviceCapabilityHonestyState.permissionNeeded => (
          labelOverride ?? 'إذن مطلوب',
          TagVariant.a,
        ),
      DeviceCapabilityHonestyState.unsupported => (
          labelOverride ?? 'غير مدعوم على هذا الجهاز',
          TagVariant.p,
        ),
      DeviceCapabilityHonestyState.revoked => (
          labelOverride ?? 'تم سحب الإذن',
          TagVariant.p,
        ),
      DeviceCapabilityHonestyState.unknown => (
          labelOverride ?? 'غير معروف',
          TagVariant.p,
        ),
    };
    return Tag(label: label, variant: variant);
  }
}
