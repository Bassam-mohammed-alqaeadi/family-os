import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';
import 'package:family_os/core/modes/modes.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalModesStore store;
  late ModesLocationFactFeed facts;
  late ModesService service;
  late CapabilityRegistry capabilities;
  final family = FamilyId('fam_modes');
  final childA = ChildId('child_a');
  final childB = ChildId('child_b');
  final now = DateTime.utc(2026, 9, 24, 10, 30);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalModesStore(db, clock: () => now);
    facts = ModesLocationFactFeed(db, clock: () => now);
    service = ModesService(
      store: store,
      familyId: family,
      locationFacts: facts,
      clock: () => now,
      idFactory: () => 'm-1',
    );
    capabilities = CapabilityRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema exposes mode tables', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('mode_document', {
      'id': 'sleep',
      'family_id': family.value,
      'catalog_id': 'sleep',
      'custom_label': null,
      'child_scope': 'allChildren',
      'target_children_json': '[]',
      'clock_json': null,
      'location_zone_id': null,
      'season_json': null,
      'overlay_json': '{}',
      'grace_minutes': 2,
      'enabled': 1,
      'policy_version': 1,
      'updated_at': 1,
    });
    expect((await db.query('mode_document')).length, 1);
  });

  test('exams and famtime normalize to study / familyTime', () {
    expect(ModeCatalogIdWire.parse('exams'), ModeCatalogId.study);
    expect(ModeCatalogIdWire.parse('famtime'), ModeCatalogId.familyTime);
  });

  test('clock channel activates school mode', () async {
    await service.saveMode(
      draft: ModeDefinition(
        id: 'school',
        familyId: family,
        catalogId: ModeCatalogId.school,
        clockWindow: const ModeClockWindow(
          startMinutes: 7 * 60,
          endMinutes: 14 * 60,
        ),
        overlay: const ModeOverlay(tightenAppAccess: true),
      ),
      actor: const ModesActor.father(),
    );
    final eval = await service.evaluateChild(
      childA,
      at: DateTime(2026, 9, 24, 10, 0), // local 10:00
    );
    expect(eval.applicableModeIds, contains('school'));
    expect(eval.channelsByModeId['school'], ModeActivationChannel.clock);
    expect(eval.effectiveOverlay.tightenAppAccess, isTrue);
  });

  test('manual activate skips grace; multi-mode stricter stack', () async {
    await service.saveMode(
      draft: ModeDefinition(
        id: 'sleep',
        familyId: family,
        catalogId: ModeCatalogId.sleep,
        overlay: const ModeOverlay(tightenWebFilter: true),
        graceMinutes: 5,
      ),
      actor: const ModesActor.father(),
    );
    await service.saveMode(
      draft: ModeDefinition(
        id: 'study',
        familyId: family,
        catalogId: ModeCatalogId.study,
        overlay: const ModeOverlay(
          tightenAppAccess: true,
          tightenCameraOs: true,
        ),
      ),
      actor: const ModesActor.father(),
    );

    expect(
      ModesEngine.effectiveGraceMinutes(configured: 5, manualActivation: true),
      0,
    );

    await service.activateManual(
      modeId: 'sleep',
      childId: childA,
      actor: const ModesActor.father(),
    );
    // Second activation needs unique id — use new factory via fresh service call
    final service2 = ModesService(
      store: store,
      familyId: family,
      locationFacts: facts,
      clock: () => now,
      idFactory: () => 'm-2',
    );
    await service2.activateManual(
      modeId: 'study',
      childId: childA,
      actor: const ModesActor.father(),
    );

    final eval = await service.evaluateChild(childA, at: now);
    expect(eval.applicableModeIds, containsAll(['sleep', 'study']));
    expect(eval.effectiveOverlay.tightenWebFilter, isTrue);
    expect(eval.effectiveOverlay.tightenAppAccess, isTrue);
    expect(eval.effectiveOverlay.tightenCameraOs, isTrue);
    expect(eval.sosReachable, isTrue);
    expect(eval.quranReachable, isTrue);
  });

  test('location channel consumes FS-001 facts only', () async {
    await service.saveMode(
      draft: ModeDefinition(
        id: 'school_loc',
        familyId: family,
        catalogId: ModeCatalogId.school,
        locationZoneId: 'zone_school',
        overlay: const ModeOverlay(tightenAppAccess: true),
      ),
      actor: const ModesActor.father(),
    );
    await facts.publishPresence(
      familyId: family,
      childId: childA,
      zoneId: 'zone_school',
      inside: true,
    );
    final eval = await service.evaluateChild(childA, at: now);
    expect(eval.applicableModeIds, contains('school_loc'));
    expect(eval.channelsByModeId['school_loc'], ModeActivationChannel.location);
  });

  test('selectedChildren scope does not silently expand', () async {
    await service.saveMode(
      draft: ModeDefinition(
        id: 'ramadan',
        familyId: family,
        catalogId: ModeCatalogId.ramadan,
        childScope: ModeChildScopeKind.selectedChildren,
        targetChildIds: {childA},
        overlay: const ModeOverlay(tightenWebFilter: true),
      ),
      actor: const ModesActor.father(),
    );
    await service.activateManual(
      modeId: 'ramadan',
      childId: childA,
      actor: const ModesActor.father(),
    );
    expect(
      () => service.activateManual(
        modeId: 'ramadan',
        childId: childB,
        actor: const ModesActor.father(),
      ),
      throwsStateError,
    );
    final forB = await service.evaluateChild(childB, at: now);
    expect(forB.applicableModeIds, isEmpty);
  });

  test('Partner cannot configure; Vacation widen rejected', () async {
    expect(
      () => service.saveMode(
        draft: ModeDefinition(
          id: 'sleep2',
          familyId: family,
          catalogId: ModeCatalogId.sleep,
        ),
        actor: const ModesActor.mother(MotherLevel.partner),
      ),
      throwsStateError,
    );

    final widen = const ModeOverlay(widenAllowedPackages: true);
    // Constructor forces widen false via asTightenOnly in save — assert engine.
    expect(() => ModesEngine.assertNoWiden(widen), throwsStateError);
    expect(widen.asTightenOnly().widenAllowedPackages, isFalse);
  });

  test('ModeException distinct; ScheduleWindow not Mode authority', () async {
    await service.saveMode(
      draft: ModeDefinition(
        id: 'vacation',
        familyId: family,
        catalogId: ModeCatalogId.vacation,
      ),
      actor: const ModesActor.father(),
    );
    final mex = await service.grantModeException(
      modeId: 'vacation',
      childId: childA,
      note: 'short break',
      expiresAt: now.add(const Duration(hours: 1)),
      actor: const ModesActor.father(),
    );
    final eval = await service.evaluateChild(childA, at: now);
    expect(eval.activeExceptionIds, contains(mex.id));
    // Lifestyle Mode path is ModesEngine — not ScheduleWindow.
    expect(eval.hasActiveModes, isFalse);
  });

  test(
    'applyFs005OwnCapabilities: scheduler IMPLEMENTED, wake MOCK-REMOTE',
    () async {
      await capabilities.applyFs005OwnCapabilities();
      final sched = await capabilities.get('fs005.modes_scheduler');
      final wake = await capabilities.get('fs005.os_wake');
      expect(sched?.status, CapabilityStatus.implemented);
      expect(wake?.status, CapabilityStatus.mockRemote);
    },
  );
}
