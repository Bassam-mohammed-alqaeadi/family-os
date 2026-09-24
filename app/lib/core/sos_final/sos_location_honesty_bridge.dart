import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/location/sos_location_handoff.dart';
import 'package:family_os/core/location/sos_location_handoff_service.dart';
import 'package:family_os/core/policy/sos_alert.dart';

/// FS-006 consumes FS-001 location facts — never owns geometry / GPS plane.
///
/// `native_gps` may be NOT IMPLEMENTED; honesty stays UNAVAILABLE and SOS still fires.
abstract final class SosLocationHonestyBridge {
  /// Map FS-001 honesty → SOS UI [SosLocationClass] (incident ≠ delivery).
  static SosLocationClass toIncidentClass(SosLocationHonesty h) => switch (h) {
        SosLocationHonesty.acquiring => SosLocationClass.acquiring,
        SosLocationHonesty.located => SosLocationClass.ready,
        SosLocationHonesty.staleLastKnown => SosLocationClass.stale,
        SosLocationHonesty.unavailable => SosLocationClass.unavailable,
      };

  /// Prefer handoff mapper token when string UI is needed.
  static String toUiToken(SosLocationHonesty h) =>
      SosLocationClassMapper.toSosUiToken(h);

  /// Attach Domain facts after fire. Never throws to cancel SOS.
  static Future<SosLocationAttachResult> attachAfterFire({
    required SosLocationHandoff handoff,
    required String incidentId,
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
    CapabilityRegistry? capabilities,
  }) async {
    SosBreakGlassLocationLaw.assertNotFindMyChild();
    if (capabilities != null) {
      final gps = await capabilities.get('fs001.native_gps');
      // Honesty only — NOT IMPLEMENTED must not block attach/fire.
      assert(
        gps == null ||
            gps.status == CapabilityStatus.notImplemented ||
            gps.status == CapabilityStatus.implemented ||
            gps.status == CapabilityStatus.degraded ||
            gps.status == CapabilityStatus.mockRemote ||
            gps.status == CapabilityStatus.unsupported,
      );
    }
    final result = await handoff.attachForIncident(
      incidentId: incidentId,
      familyId: familyId,
      childId: childId,
      deviceId: deviceId,
    );
    assert(
      result.firedWithoutLocationBlocked,
      'FS-001 handoff must never block SOS fire (OD-16)',
    );
    return result;
  }
}
