import 'package:flutter/foundation.dart';

/// Parent-facing enforcement availability (WF-OD-04 / WF-SF-10).
///
/// Never claim `enforced` when the native plane is MOCK-REMOTE / unverified.
enum WebFilterEnforcementAvailability {
  /// Verified on-device plane actively filtering.
  enforced,

  /// Partial / degraded capability.
  degraded,

  /// Policy configured but not yet acked on device.
  pendingPolicy,

  /// Platform cannot support this plane.
  unsupported,

  /// User/OS permission denied.
  disabledByPermission,

  /// Unknown / not probed.
  unknown,
}

extension WebFilterEnforcementAvailabilityWire
    on WebFilterEnforcementAvailability {
  String get wireName => switch (this) {
    WebFilterEnforcementAvailability.enforced => 'ENFORCED',
    WebFilterEnforcementAvailability.degraded => 'DEGRADED',
    WebFilterEnforcementAvailability.pendingPolicy => 'PENDING_POLICY',
    WebFilterEnforcementAvailability.unsupported => 'UNSUPPORTED',
    WebFilterEnforcementAvailability.disabledByPermission =>
      'DISABLED_BY_PERMISSION',
    WebFilterEnforcementAvailability.unknown => 'UNKNOWN',
  };

  static WebFilterEnforcementAvailability parse(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'ENFORCED':
        return WebFilterEnforcementAvailability.enforced;
      case 'DEGRADED':
        return WebFilterEnforcementAvailability.degraded;
      case 'PENDING_POLICY':
        return WebFilterEnforcementAvailability.pendingPolicy;
      case 'UNSUPPORTED':
        return WebFilterEnforcementAvailability.unsupported;
      case 'DISABLED_BY_PERMISSION':
        return WebFilterEnforcementAvailability.disabledByPermission;
      case 'UNKNOWN':
        return WebFilterEnforcementAvailability.unknown;
      default:
        throw FormatException('Unknown enforcement availability: $raw');
    }
  }
}

/// Honesty law for enforcement claims (product contract, not OS probe).
@immutable
final class WebFilterEnforcementClaim {
  const WebFilterEnforcementClaim({
    required this.availability,
    required this.deliveryVerified,
    required this.nativePlaneMockRemote,
  });

  final WebFilterEnforcementAvailability availability;
  final bool deliveryVerified;

  /// True while VPN/DNS/agent remains MOCK-REMOTE (FS campaign default).
  final bool nativePlaneMockRemote;

  /// May the parent UI say “filtering is enforced on this device”?
  bool get mayClaimEnforced {
    if (nativePlaneMockRemote) return false;
    if (!deliveryVerified) return false;
    return availability == WebFilterEnforcementAvailability.enforced;
  }

  /// Stage-1 / campaign baseline — honest MOCK-REMOTE native plane.
  static WebFilterEnforcementClaim campaignBaseline({
    bool deliveryVerified = false,
  }) {
    return WebFilterEnforcementClaim(
      availability: WebFilterEnforcementAvailability.degraded,
      deliveryVerified: deliveryVerified,
      nativePlaneMockRemote: true,
    );
  }
}

/// Transient child interstitial feedback (Q-WF-15) — no separate result screen.
enum WebFilterInterstitialFeedback { none, pending, approved, denied, expired }
