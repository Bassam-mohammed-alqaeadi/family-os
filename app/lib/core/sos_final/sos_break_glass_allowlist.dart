import 'package:flutter/foundation.dart';

/// Q-SOS-RD-02B break-glass capability allowlist / denylist (frozen).
@immutable
abstract final class SosBreakGlassAllowlist {
  /// Temporary response overrides only.
  static const allowed = <String>{
    'lock_shell_bypass',
    'screen_time_bypass',
    'web_app_emergency_comms',
    'emergency_communication_surface',
    'active_sos_location_context',
    'parent_sos_notification_handling',
  };

  /// Never grantable via break-glass.
  static const forbidden = <String>{
    'permanent_policy_change',
    'role_change',
    'billing_change',
    'disable_sos',
    'disable_audit',
    'delete_evidence',
    'privacy_bypass',
    'permanent_exception',
    'unlock_everything',
  };

  static bool isAllowed(String capabilityId) {
    if (forbidden.contains(capabilityId)) return false;
    return allowed.contains(capabilityId);
  }

  static void assertAllowed(String capabilityId) {
    if (!isAllowed(capabilityId)) {
      throw StateError('break-glass capability not allowlisted: $capabilityId');
    }
  }
}
