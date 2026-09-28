import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_composition_runtime.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/sos_final/sos_final_runtime.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    FsCompositionRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
  });

  test('HOST-ROUTER-C boot-once opens FS Domain runtimes', () async {
    final dir = await Directory.systemTemp.createTemp('host_c_');
    final path = p.join(dir.path, 'fs.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);

    await FsCompositionRuntime.tryBind();
    expect(FsCompositionRuntime.isOpen, isTrue);
    expect(FsCompositionRuntime.partialUnavailable, isFalse);
    expect(() => Stage1SosFinalRuntime.service, returnsNormally);
    expect(() => Stage1AppControlRuntime.service, returnsNormally);

    await FsCompositionRuntime.tryBind(); // idempotent
    expect(FsCompositionRuntime.isOpen, isTrue);

    FsCompositionRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('DOM-AC-ST-AXES ST limit axes survive restart', () async {
    final dir = await Directory.systemTemp.createTemp('ac_st_');
    final path = p.join(dir.path, 'ac.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    await Stage1AppControlRuntime.ensureOpen();

    final set = AppAccessRuleSet(
      childId: child,
      rules: [
        AppAccessRule(
          appId: 'com.example.game',
          limitMinutes: 45,
          countable: true,
        ),
      ],
    );
    await Stage1AppControlRuntime.accessRules.save(child, set);

    Stage1AppControlRuntime.resetForTest();
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    await Stage1AppControlRuntime.ensureOpen();
    final loaded = await Stage1AppControlRuntime.accessRules.load(child);
    final rule = loaded.ruleFor('com.example.game');
    expect(rule, isNotNull);
    expect(rule!.limitMinutes, 45);
    expect(rule.countable, isTrue);

    Stage1AppControlRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
