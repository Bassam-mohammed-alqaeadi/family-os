import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/app_control/app_control_protected.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/location_fix.dart';
import 'package:family_os/core/location/location_store.dart';
import 'package:family_os/core/location/sos_location_handoff.dart';
import 'package:family_os/core/location/sos_location_handoff_service.dart';
import 'package:family_os/core/modes/mode_overlay.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/sos_final/sos_final.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalSosFinalStore store;
  late SosFinalService lifecycle;
  late LocalLocationStore locStore;
  late SosLocationHandoff handoff;
  late CapabilityRegistry capabilities;
  late SosCrossSystemCoordinator cross;
  final family = FamilyId('fam_xsys');
  final child = ChildId('child_a');
  final device = DeviceId('dev_a');
  final now = DateTime.utc(2026, 9, 24, 14, 0);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    store = LocalSosFinalStore(db);
    var seq = 0;
    lifecycle = SosFinalService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'sos_x_${++seq}',
    );
    locStore = LocalLocationStore(db, clock: () => now);
    handoff = SosLocationHandoff(db, locStore, clock: () => now);
    capabilities = CapabilityRegistry(db);
    await capabilities.applyFs001XsysCapabilities();
    await capabilities.applyFs006XsysCapabilities();
    cross = SosCrossSystemCoordinator(
      lifecycle: lifecycle,
      store: store,
      locationHandoff: handoff,
      capabilities: capabilities,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('OD-14: no gate kind may block SOS; sibling systems consistent', () {
    for (final kind in SosGateKind.values) {
      expect(SosPermanentExemptions.allowsGate(kind), isFalse);
    }
    expect(
      SosPermanentExemptions.mayFireSos(
        subscriptionExpired: true,
        quietHoursActive: true,
        screenTimeExpired: true,
        entertainmentLocked: true,
        deviceLocked: true,
        modesActive: true,
        webFilterStrict: true,
        appControlLockedDown: true,
      ),
      isTrue,
    );
    expect(SosPermanentExemptions.auditConsistencyIssues(), isEmpty);
    expect(ModeProtectedReachability.sosReachable, isTrue);
    expect(ProtectedPackageIds.isProtected(ProtectedPackageIds.sos), isTrue);
    // Entitlement exists in product but must not be required to fire.
    expect(Entitlement.expired().isExpired, isTrue);
  });

  test('fire under hostile gates + unavailable GPS still creates incident',
      () async {
    expect(
      (await capabilities.get('fs001.native_gps'))!.status,
      CapabilityStatus.notImplemented,
    );

    final incident = await cross.fireChildHold(
      childId: child,
      deviceId: device,
      subscriptionExpired: true,
      quietHoursActive: true,
      screenTimeExpired: true,
      modesActive: true,
      appControlLockedDown: true,
      batteryPercent: 40,
    );

    expect(incident.status, SosAlertStatus.active);
    expect(incident.locationClass, SosLocationClass.unavailable);
    expect(incident.locationLabel, 'unavailable');

    final ops = await lifecycle.opsSamples(incident.id);
    expect(
      ops.any((s) => s.kind == SosOpsSampleKind.location),
      isTrue,
    );
    final evidence = await handoff.listEvidence(incident.id);
    expect(evidence, isNotEmpty);
    expect(evidence.first.honesty, SosLocationHonesty.unavailable);
  });

  test('located fix maps to ready honesty without owning GPS', () async {
    await locStore.appendFix(
      LocationFix(
        id: 'fix_1',
        familyId: family,
        childId: child,
        deviceId: device,
        recordedAt: now,
        acquisition: LocationAcquisitionStatus.located,
        point: const GeoPoint(latitude: 24.71, longitude: 46.67),
        accuracyMeters: 12,
      ),
    );

    final incident = await cross.fireChildHold(
      childId: child,
      deviceId: device,
    );
    expect(incident.locationClass, SosLocationClass.ready);
    expect(
      SosLocationHonestyBridge.toUiToken(SosLocationHonesty.located),
      'ready',
    );
    expect(SosBreakGlassLocationLaw.breakGlassIsFindMyChild, isFalse);
  });

  test('applyFs006XsysCapabilities keeps remote_delivery MOCK-REMOTE', () async {
    expect(
      (await capabilities.get('fs006.permanent_exemptions'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs006.location_honesty_bridge'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs006.remote_delivery'))!.status,
      CapabilityStatus.mockRemote,
    );
    expect(
      (await capabilities.get('fs001.native_gps'))!.status,
      CapabilityStatus.notImplemented,
    );
  });
}
