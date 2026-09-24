import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/location/geo_point.dart';
import 'package:family_os/core/location/location_fix.dart';
import 'package:family_os/core/location/safe_zone_definition.dart';
import 'package:family_os/core/location/zone_geometry.dart';
import 'package:family_os/core/modes/modes_runtime.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n03_screen_time/app_control_ux_bridge.dart';

void main() {
  setUp(() async {
    Stage1LocationRuntime.resetForTest();
    Stage1ModesRuntime.resetForTest();
    Stage1AppControlRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  tearDown(() async {
    Stage1LocationRuntime.resetForTest();
    Stage1ModesRuntime.resetForTest();
    Stage1AppControlRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test('shared kernel: Location and Modes see the same capability rows', () async {
    await Stage1LocationRuntime.ensureOpen();
    await Stage1ModesRuntime.ensureOpen();

    expect(
      identical(Stage1LocationRuntime.db, Stage1ModesRuntime.db),
      isTrue,
    );

    final locCaps = await Stage1LocationRuntime.capabilities.listAll();
    final modeCaps = await Stage1ModesRuntime.capabilities.listAll();
    expect(locCaps.length, modeCaps.length);
    expect(
      locCaps.any((e) => e.id == 'fs001.modes_fact_feed'),
      isTrue,
    );
    expect(
      locCaps.firstWhere((e) => e.id == 'fs005.modes_scheduler').status,
      CapabilityStatus.implemented,
    );
  });

  test('Location evaluate publishes Modes facts on shared DB', () async {
    await Stage1LocationRuntime.ensureOpen();
    final family = FamilyId('fam_stage1');
    final child = ChildId('child_a');
    final now = DateTime.utc(2026, 9, 24, 15);

    await Stage1LocationRuntime.store.saveZone(
      SafeZoneDefinition(
        id: 'zone_home',
        familyId: family,
        name: 'Home',
        geometry: const CircleGeometry(
          center: GeoPoint(latitude: 24.7, longitude: 46.7),
          radiusMeters: 200,
        ),
        assignedChildIds: [child],
        alertEnter: true,
        alertExit: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final events = await Stage1LocationRuntime.evaluateFixAcrossZones(
      fix: LocationFix(
        id: 'fix1',
        familyId: family,
        childId: child,
        deviceId: DeviceId('dev1'),
        point: const GeoPoint(latitude: 24.7, longitude: 46.7),
        recordedAt: now,
        acquisition: LocationAcquisitionStatus.located,
      ),
    );
    expect(events, isNotEmpty);

    final facts = await Stage1LocationRuntime.db.query(
      'loc_mode_fact',
      orderBy: 'occurred_at ASC',
    );
    expect(facts, isNotEmpty);
  });

  test('defaultSeeds match post-campaign IMPLEMENTED honesty', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final registry = CapabilityRegistry(db);
    await registry.ensureSeeded();
    expect(
      (await registry.get('fs003.app_dispositions'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs004.screen_camera_policy'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs006.sos_lifecycle'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs007.local_classifier'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs007.cloud_classify'))!.status,
      CapabilityStatus.unsupported,
    );
    expect(
      (await registry.get('fs001.native_gps'))!.status,
      CapabilityStatus.notImplemented,
    );
    await db.close();
  });

  test('AppControlUxBridge child actor cannot configure', () {
    final actor = AppControlUxBridge.actorFor(role: AppRole.child);
    expect(actor.canConfigure, isFalse);
    expect(actor.canDecideTickets, isFalse);
    expect(actor.role, AppRole.child);
  });

  test('schema createStatements include FS tables through v10', () {
    expect(FamilyLocalSchema.currentVersion, 10);
    final sql = FamilyLocalSchema.createStatements.join('\n');
    for (final table in [
      'loc_zone',
      'loc_mode_fact',
      'wf_document',
      'ac_document',
      'sc_document',
      'mode_document',
      'sos_incident',
      'ai_safety_ticket',
    ]) {
      expect(sql, contains(table), reason: 'missing $table');
    }
  });

  test('SQLite onUpgrade migrates empty v1 file to v10', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await Directory.systemTemp.createTemp('fs_p15_mig_');
    final path = p.join(dir.path, 'upgrade.db');

    // Create at schema v1 (foundation tables only).
    final v1 = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        for (final sql in [
          FamilyLocalSchema.createStatements[0], // schema_meta
          FamilyLocalSchema.createStatements[1], // kv_store
          FamilyLocalSchema.createStatements[2], // capability_entry
          FamilyLocalSchema.createStatements[3], // sync_outbox
          FamilyLocalSchema.createStatements[4], // policy_delivery
        ]) {
          await db.execute(sql);
        }
        await db.insert('schema_meta', {
          'key': 'schema_version',
          'value': '1',
        });
      },
    );
    await v1.close();

    final upgraded = await SqliteLocalDatabase.openAt(path);
    expect(await upgraded.schemaVersion(), FamilyLocalSchema.currentVersion);

    await upgraded.insert('ai_safety_ticket', {
      'id': 't1',
      'family_id': 'fam',
      'child_id': 'c1',
      'signal_id': 's1',
      'status': 'open',
      'created_at': 1,
    });
    final rows = await upgraded.query('ai_safety_ticket');
    expect(rows, isNotEmpty);

    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
