import 'package:flutter/material.dart';

import '../../i18n/app_localizations.dart';
import 'tag.dart';

/// S0 spine: the honest word for one capability a device reported about itself.
///
/// R4 / Principle 2 — the badge reflects what the ledger says, NEVER what a toggle implies. A
/// capability that is `unsupported` or `permission_needed` renders as a muted explanatory chip,
/// not a disabled control that pretends the parent is in control.
///
/// The wording is deliberately about the handset rather than about our system: a parent reading
/// "this phone cannot do it" knows what to do (change phone, or stop relying on it), while
/// "unsupported" leaves them asking by whom. Every screen that shows a device capability uses these
/// six words, so the same state never appears under two different names — the reason the labels
/// moved out of this component's source and into ARB when the ledger screen became their first user.
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
    final l10n = AppLocalizations.of(context);
    final label =
        labelOverride ??
        (switch (state) {
          DeviceCapabilityHonestyState.confirmed => l10n.capabilityStateConfirmed,
          DeviceCapabilityHonestyState.awaitingSetup => l10n
              .capabilityStateAwaitingSetup,
          DeviceCapabilityHonestyState.permissionNeeded => l10n
              .capabilityStatePermissionNeeded,
          DeviceCapabilityHonestyState.unsupported => l10n
              .capabilityStateUnsupported,
          DeviceCapabilityHonestyState.revoked => l10n.capabilityStateRevoked,
          DeviceCapabilityHonestyState.unknown => l10n.capabilityStateUnknown,
        });
    final variant = switch (state) {
      DeviceCapabilityHonestyState.confirmed => TagVariant.g,
      DeviceCapabilityHonestyState.awaitingSetup => TagVariant.a,
      DeviceCapabilityHonestyState.permissionNeeded => TagVariant.a,
      DeviceCapabilityHonestyState.unsupported => TagVariant.p,
      DeviceCapabilityHonestyState.revoked => TagVariant.p,
      DeviceCapabilityHonestyState.unknown => TagVariant.p,
    };
    return Tag(key: key, label: label, variant: variant);
  }
}
