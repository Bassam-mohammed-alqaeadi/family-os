import 'package:family_os/core/app_control/app_control_protected.dart';
import 'package:family_os/core/location/sos_location_handoff.dart';
import 'package:family_os/core/modes/mode_overlay.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/time_expiry_surface.dart';
import 'package:family_os/core/screen_camera/screen_camera_protected.dart';

/// OD-14 gate kinds that must **never** suppress SOS fire / receipt / UI.
enum SosGateKind {
  subscription,
  quietHours,
  screenTimeExpiry,
  entertainmentLock,
  deviceLock,
  modesOverlay,
  webFilter,
  appControlBlock,
  notificationMute,
}

/// Permanent SOS exemptions (OD-14) + cross-system consistency (FS-006-XSYS).
///
/// Does **not** own lifecycle — only reachability / never-gate law.
abstract final class SosPermanentExemptions {
  /// Product law: no gate may block SOS.
  static bool allowsGate(SosGateKind kind) => false;

  /// Fire path ignores billing / Modes / locks — always allowed.
  static bool mayFireSos({
    bool subscriptionExpired = false,
    bool quietHoursActive = false,
    bool screenTimeExpired = false,
    bool entertainmentLocked = false,
    bool deviceLocked = false,
    bool modesActive = false,
    bool webFilterStrict = false,
    bool appControlLockedDown = false,
  }) {
    // Hostile environment flags are intentionally unused: OD-14 forbids gating.
    assert(() {
      // Touch args so analyzers treat them as part of the public fire contract.
      final hostile = subscriptionExpired ||
          quietHoursActive ||
          screenTimeExpired ||
          entertainmentLocked ||
          deviceLocked ||
          modesActive ||
          webFilterStrict ||
          appControlLockedDown;
      return hostile || !hostile;
    }());
    for (final kind in SosGateKind.values) {
      if (allowsGate(kind)) return false;
    }
    return true;
  }

  /// Sibling-system consistency audit (implementation must stay aligned).
  static List<String> auditConsistencyIssues() {
    final issues = <String>[];
    if (!ModeProtectedReachability.sosReachable) {
      issues.add('modes:sosReachable');
    }
    if (!ProtectedPackageIds.isProtected(ProtectedPackageIds.sos)) {
      issues.add('app_control:sos_protected');
    }
    if (!TimeExpirySurface.isExempt('sos')) {
      issues.add('screen_time:sos_exempt');
    }
    if (!kDeviceLockExemptSurfaces.contains('sos')) {
      issues.add('device_lock:sos_exempt');
    }
    if (!NotificationPrefs.sosReceiptAlwaysOn) {
      issues.add('notifications:sos_receipt');
    }
    if (ScreenCameraProtectedMatrix.sosAudioInScope) {
      issues.add('screen_camera:sos_audio_forbidden');
    }
    if (SosBreakGlassLocationLaw.breakGlassIsFindMyChild) {
      issues.add('location:break_glass_find_my_child');
    }
    return issues;
  }

  static void assertConsistent() {
    final issues = auditConsistencyIssues();
    if (issues.isNotEmpty) {
      throw StateError(
        'SOS cross-system exemption drift: ${issues.join(', ')}',
      );
    }
  }
}
