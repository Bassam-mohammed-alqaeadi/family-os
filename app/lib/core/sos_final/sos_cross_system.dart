import 'dart:convert';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/location/sos_location_handoff.dart';
import 'package:family_os/core/location/sos_location_handoff_service.dart';
import 'package:family_os/core/policy/sos_alert.dart';

import 'sos_evidence_policy.dart';
import 'sos_final_service.dart';
import 'sos_final_store.dart';
import 'sos_incident.dart';
import 'sos_location_honesty_bridge.dart';
import 'sos_permanent_exemptions.dart';

/// FS-006-XSYS coordinator — exemptions + location honesty around lifecycle.
///
/// Owns **no** second incident store. Delegates fire/ack/resolve to [SosFinalService].
final class SosCrossSystemCoordinator {
  SosCrossSystemCoordinator({
    required SosFinalService lifecycle,
    required SosFinalRepository store,
    SosLocationHandoff? locationHandoff,
    CapabilityRegistry? capabilities,
  })  : _lifecycle = lifecycle,
        _store = store,
        _handoff = locationHandoff,
        _capabilities = capabilities;

  final SosFinalService _lifecycle;
  final SosFinalRepository _store;
  final SosLocationHandoff? _handoff;
  final CapabilityRegistry? _capabilities;

  SosFinalService get lifecycle => _lifecycle;

  /// Child HOLD → durable fire under OD-14 hostile gates + FS-001 attach.
  Future<SosIncident> fireChildHold({
    required ChildId childId,
    required DeviceId deviceId,
    bool subscriptionExpired = false,
    bool quietHoursActive = false,
    bool screenTimeExpired = false,
    bool entertainmentLocked = false,
    bool deviceLocked = false,
    bool modesActive = false,
    bool webFilterStrict = false,
    bool appControlLockedDown = false,
    int batteryPercent = 0,
    bool panicQuietAtTrigger = false,
    String deliveriesJson = '[]',
    String childDisplayName = '',
    String childEmoji = '',
  }) async {
    SosPermanentExemptions.assertConsistent();
    if (!SosPermanentExemptions.mayFireSos(
      subscriptionExpired: subscriptionExpired,
      quietHoursActive: quietHoursActive,
      screenTimeExpired: screenTimeExpired,
      entertainmentLocked: entertainmentLocked,
      deviceLocked: deviceLocked,
      modesActive: modesActive,
      webFilterStrict: webFilterStrict,
      appControlLockedDown: appControlLockedDown,
    )) {
      throw StateError('OD-14 violated: gate blocked SOS');
    }

    // Fire first — location optional (OD-16).
    var incident = await _lifecycle.fireHold(
      childId: childId,
      locationClass: SosLocationClass.acquiring,
      batteryPercent: batteryPercent,
      panicQuietAtTrigger: panicQuietAtTrigger,
      deliveriesJson: deliveriesJson,
      childDisplayName: childDisplayName,
      childEmoji: childEmoji,
    );

    final handoff = _handoff;
    if (handoff == null) {
      return incident;
    }

    final attach = await SosLocationHonestyBridge.attachAfterFire(
      handoff: handoff,
      incidentId: incident.id,
      familyId: _lifecycle.familyId,
      childId: childId,
      deviceId: deviceId,
      capabilities: _capabilities,
    );

    final klass = SosLocationHonestyBridge.toIncidentClass(attach.honesty);
    incident = incident.copyWith(
      locationClass: klass,
      locationLabel: attach.childStatusWord,
    );
    await _store.saveIncident(incident);

    final e = attach.evidence;
    final payload = <String, Object?>{
      'honesty': attach.honesty.wireName,
      'native_gps_blocked_fire': false,
      if (e?.fixId != null) 'fixId': e!.fixId,
      if (e?.hasCoordinates == true) ...{
        'lat': e!.latitude,
        'lng': e.longitude,
        'accuracy_m': e.accuracyMeters,
      },
    };
    await _store.appendOpsSample(
      SosOpsSample(
        id: '${incident.id}_loc_fs001',
        incidentId: incident.id,
        familyId: _lifecycle.familyId,
        kind: SosOpsSampleKind.location,
        capturedAt: incident.triggeredAt,
        retainUntil: SosEvidencePolicy.retainUntilFrom(incident.triggeredAt),
        payloadJson: jsonEncode(payload),
      ),
    );
    return incident;
  }
}
