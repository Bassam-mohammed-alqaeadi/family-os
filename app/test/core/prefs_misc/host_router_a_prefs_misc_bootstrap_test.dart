import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/notification_prefs.dart';
import 'package:family_os/core/policy/privacy_collection_policy.dart';
import 'package:family_os/core/policy/collection_scope.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    PrefsMiscRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test('PrefsMiscRuntime boot-once opens all five namespaces', () async {
    final dir = await Directory.systemTemp.createTemp('host_router_a_');
    final path = p.join(dir.path, 'prefs.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);

    await PrefsMiscRuntime.ensureOpen();
    expect(PrefsMiscRuntime.isOpen, isTrue);
    expect(PrefsMiscRuntime.unavailable, isFalse);
    expect(PrefsMiscRuntime.notification, isNotNull);
    expect(PrefsMiscRuntime.privacy, isNotNull);
    expect(PrefsMiscRuntime.antiTamper, isNotNull);
    expect(PrefsMiscRuntime.deviceLock, isNotNull);
    expect(PrefsMiscRuntime.monitoring, isNotNull);

    // Idempotent — same instances.
    final n = PrefsMiscRuntime.notification;
    await PrefsMiscRuntime.ensureOpen();
    expect(identical(PrefsMiscRuntime.notification, n), isTrue);

    PrefsMiscRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('runtime repos survive close→reopen via same SQLite file', () async {
    final dir = await Directory.systemTemp.createTemp('host_router_a_r_');
    final path = p.join(dir.path, 'prefs.db');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    await PrefsMiscRuntime.ensureOpen();

    await PrefsMiscRuntime.notification!.save(
      NotificationPrefs.defaults(memberId: 'father').copyWith(
        quietHoursEnabled: true,
        quietStart: NotificationPrefs.defaultQuietStart,
        quietEnd: NotificationPrefs.defaultQuietEnd,
        analysisNoticesEnabled: false,
      ),
    );
    await PrefsMiscRuntime.privacy!.save(
      PrivacyCollectionPolicy.defaults(
        childId: 'demo-child',
      ).withScope(CollectionScope.location, false),
      actor: AppRole.father,
    );
    await PrefsMiscRuntime.antiTamper!.write(
      ChildId('demo-child'),
      AntiTamperPolicy.defaults().copyWith(noVpn: true),
      actor: AppRole.father,
    );
    await PrefsMiscRuntime.deviceLock!.lock(
      ChildId('demo-child'),
      const DeviceLockActor.father(),
    );
    await PrefsMiscRuntime.monitoring!.save(
      DesiredMonitoringPrefs.defaults(
        childId: 'demo-child',
      ).copyWith(webFilter: true),
    );

    PrefsMiscRuntime.resetForTest();
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    await PrefsMiscRuntime.ensureOpen();

    final notif = await PrefsMiscRuntime.notification!.load('father');
    expect(notif.quietHoursEnabled, isTrue);
    expect(notif.analysisNoticesEnabled, isFalse);
    expect(
      (await PrefsMiscRuntime.privacy!.load(
        'demo-child',
      )).isEnabled(CollectionScope.location),
      isFalse,
    );
    expect(
      (await PrefsMiscRuntime.antiTamper!.load(ChildId('demo-child'))).noVpn,
      isTrue,
    );
    expect(
      (await PrefsMiscRuntime.deviceLock!.load(ChildId('demo-child'))).locked,
      isTrue,
    );
    expect(
      (await PrefsMiscRuntime.monitoring!.load('demo-child')).webFilter,
      isTrue,
    );

    PrefsMiscRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
