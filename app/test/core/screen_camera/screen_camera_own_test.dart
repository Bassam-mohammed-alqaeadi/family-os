import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/screen_camera/screen_camera.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalScreenCameraStore store;
  late ScreenCameraService service;
  late CapabilityRegistry capabilities;
  final family = FamilyId('fam_sc');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 20);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalScreenCameraStore(db, clock: () => now);
    service = ScreenCameraService(
      documents: store,
      familyId: family,
      clock: () => now,
    );
    capabilities = CapabilityRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema v7 exposes sc_document', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('sc_document', {
      'scope_key': 'family',
      'family_id': family.value,
      'child_id': null,
      'prevent_camera_os': 0,
      'prevent_capture': 0,
      'monitor_screenshots': 0,
      'monitored_packages_json': '[]',
      'protect_sensitive': 1,
      'exceptions_json': '["sos","qrEnrollment"]',
      'policy_version': 1,
      'updated_at': 1,
    });
    expect((await db.query('sc_document')).length, 1);
  });

  test('SC-OD-12 child override wins over family baseline', () async {
    await store.save(
      ScreenCameraDocument(
        familyId: family,
        scopeKind: ScreenCameraScopeKind.familyBaseline,
        monitorScreenshots: false,
        preventCameraOs: false,
      ),
    );
    await store.save(
      ScreenCameraDocument(
        familyId: family,
        scopeKind: ScreenCameraScopeKind.childOverride,
        childId: child,
        monitorScreenshots: true,
        monitoredPackageIds: {'com.snapchat.android'},
        preventCameraOs: true,
      ),
    );
    final effective = await store.loadEffective(family, child);
    expect(effective.scopeKind, ScreenCameraScopeKind.childOverride);
    expect(effective.monitorScreenshots, isTrue);
    expect(effective.preventCameraOs, isTrue);
    expect(effective.childTransparencyRequired, isTrue);
    expect(effective.monitoredPackageIds, contains('com.snapchat.android'));
  });

  test('mic and SOS audio stay out of scope', () {
    expect(ScreenCameraProtectedMatrix.microphoneInScope, isFalse);
    expect(ScreenCameraProtectedMatrix.sosAudioInScope, isFalse);
    final doc = ScreenCameraDocument.familyDefaults(family);
    expect(doc.microphoneControlled, isFalse);
  });

  test('evaluate never claims enforcement on MOCK-REMOTE planes', () {
    final doc = ScreenCameraDocument(
      familyId: family,
      scopeKind: ScreenCameraScopeKind.childOverride,
      childId: child,
      preventCameraOs: true,
      preventCapture: true,
      monitorScreenshots: true,
    );
    final eval = ScreenCameraEngine.evaluate(doc);
    expect(eval.cameraOsIntent, isTrue);
    expect(eval.capturePreventIntent, isTrue);
    expect(eval.screenshotMonitorActive, isTrue);
    expect(eval.childTransparencyRequired, isTrue);
    expect(eval.claimableEnforcement, isFalse);

    final claimable = ScreenCameraEngine.evaluate(
      doc,
      cameraOsPlane: CapabilityStatus.implemented,
      capturePlane: CapabilityStatus.implemented,
    );
    expect(claimable.claimableEnforcement, isTrue);
  });

  test('Modes tighten-only never silently enables monitoring', () {
    final base = ScreenCameraDocument.familyDefaults(family);
    final tightened = ScreenCameraEngine.applyModeTighten(
      base: base,
      tightenCameraOs: true,
      tightenCapturePrevent: true,
      tightenProtect: true,
    );
    expect(tightened.preventCameraOs, isTrue);
    expect(tightened.preventCapture, isTrue);
    expect(tightened.protectSensitiveSurfaces, isTrue);
    expect(tightened.monitorScreenshots, isFalse);
  });

  test('father configures screenshot monitoring; Partner cannot', () async {
    await service.setScreenshotMonitoring(
      childId: child,
      enabled: true,
      monitoredPackageIds: {'com.instagram.android'},
      actor: const ScreenCameraActor.father(),
    );
    final loaded = await service.loadEffective(child);
    expect(loaded.monitorScreenshots, isTrue);
    expect(loaded.monitoredPackageIds, contains('com.instagram.android'));

    expect(
      () => service.setCameraOsPrevent(
        childId: child,
        enabled: true,
        actor: const ScreenCameraActor.mother(MotherLevel.partner),
      ),
      throwsStateError,
    );

    await service.setCameraOsPrevent(
      childId: child,
      enabled: true,
      actor: const ScreenCameraActor.mother(MotherLevel.full),
    );
    final after = await service.loadEffective(child);
    expect(after.preventCameraOs, isTrue);
  });

  test('family baseline save + restore override', () async {
    await service.saveFamilyBaseline(
      draft: ScreenCameraDocument(
        familyId: family,
        scopeKind: ScreenCameraScopeKind.familyBaseline,
        protectSensitiveSurfaces: true,
        preventCapture: true,
      ),
      actor: const ScreenCameraActor.father(),
    );
    await service.setScreenshotMonitoring(
      childId: child,
      enabled: true,
      actor: const ScreenCameraActor.father(),
    );
    expect((await service.loadEffective(child)).monitorScreenshots, isTrue);

    await service.restoreBaseline(child, const ScreenCameraActor.father());
    final restored = await service.loadEffective(child);
    expect(restored.scopeKind, ScreenCameraScopeKind.familyBaseline);
    expect(restored.monitorScreenshots, isFalse);
    expect(restored.preventCapture, isTrue);
  });

  test(
    'applyFs004OwnCapabilities: policy IMPLEMENTED, planes MOCK-REMOTE',
    () async {
      await capabilities.applyFs004OwnCapabilities();
      final policy = await capabilities.get('fs004.screen_camera_policy');
      final capture = await capabilities.get('fs004.capture_pipeline');
      final cameraOs = await capabilities.get('fs004.camera_os_plane');
      expect(policy?.status, CapabilityStatus.implemented);
      expect(capture?.status, CapabilityStatus.mockRemote);
      expect(cameraOs?.status, CapabilityStatus.mockRemote);
    },
  );

  test('DesiredMonitoringPrefs axes stay outside FS-004 document', () {
    // SET-016 G1 (web/app/notif/location) must not be absorbed here.
    final doc = ScreenCameraDocument.familyDefaults(family);
    expect(doc.toRow().containsKey('web_filter'), isFalse);
    expect(doc.toRow().containsKey('location_always'), isFalse);
  });
}
