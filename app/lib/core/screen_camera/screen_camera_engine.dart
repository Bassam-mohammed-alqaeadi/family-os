import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';

import 'screen_camera_document.dart';
import 'screen_camera_protected.dart';

/// Domain evaluation result — never implies native enforcement alone.
@immutable
final class ScreenCameraEvaluation {
  const ScreenCameraEvaluation({
    required this.document,
    required this.childTransparencyRequired,
    required this.cameraOsIntent,
    required this.capturePreventIntent,
    required this.screenshotMonitorActive,
    required this.protectSensitive,
    required this.claimableEnforcement,
  });

  final ScreenCameraDocument document;
  final bool childTransparencyRequired;
  final bool cameraOsIntent;
  final bool capturePreventIntent;
  final bool screenshotMonitorActive;
  final bool protectSensitive;

  /// True only when policy configured AND plane status allows claims.
  final bool claimableEnforcement;
}

/// Deterministic Screen & Camera engine (domain only).
abstract final class ScreenCameraEngine {
  static ScreenCameraDocument resolveEffective({
    required ScreenCameraDocument? familyBaseline,
    required ScreenCameraDocument? childOverride,
    required FamilyId familyId,
  }) {
    if (childOverride != null) return childOverride;
    if (familyBaseline != null) return familyBaseline;
    return ScreenCameraDocument.familyDefaults(familyId);
  }

  /// Modes may tighten (OR in true) but never permanently remove via this engine.
  static ScreenCameraDocument applyModeTighten({
    required ScreenCameraDocument base,
    bool tightenCameraOs = false,
    bool tightenCapturePrevent = false,
    bool tightenProtect = false,
  }) {
    return base.copyWith(
      preventCameraOs: base.preventCameraOs || tightenCameraOs,
      preventCapture: base.preventCapture || tightenCapturePrevent,
      protectSensitiveSurfaces: base.protectSensitiveSurfaces || tightenProtect,
      // Monitoring is not silently enabled by Modes.
    );
  }

  static ScreenCameraEvaluation evaluate(
    ScreenCameraDocument document, {
    CapabilityStatus cameraOsPlane = CapabilityStatus.mockRemote,
    CapabilityStatus capturePlane = CapabilityStatus.mockRemote,
  }) {
    final canClaimCamera = _planeAllowsClaim(cameraOsPlane);
    final canClaimCapture = _planeAllowsClaim(capturePlane);
    return ScreenCameraEvaluation(
      document: document,
      childTransparencyRequired: document.childTransparencyRequired,
      cameraOsIntent: document.preventCameraOs,
      capturePreventIntent: document.preventCapture,
      screenshotMonitorActive: document.monitorScreenshots,
      protectSensitive: document.protectSensitiveSurfaces,
      // Never claim enforced when plane is MOCK-REMOTE / unavailable.
      claimableEnforcement:
          (document.preventCameraOs && canClaimCamera) ||
          (document.preventCapture && canClaimCapture),
    );
  }

  static bool exceptionEnabled(
    ScreenCameraDocument document,
    ScreenCameraExceptionClass clazz,
  ) {
    return document.enabledExceptions.contains(clazz);
  }

  static bool _planeAllowsClaim(CapabilityStatus status) {
    return status == CapabilityStatus.implemented;
  }
}
