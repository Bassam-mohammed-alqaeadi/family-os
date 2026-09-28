import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/education/education_local_persistence.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/features/education/learning_assignment_local_repository.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    rebindStage1LearningAssignmentRepository(
      InMemoryLearningAssignmentRepository(),
    );
    await FsSessionKernel.resetForTest();
  });

  test('assignment publish→close→reopen→latest', () async {
    final dir = await Directory.systemTemp.createTemp('dom_edu_a_');
    final path = p.join(dir.path, 'edu.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await EducationLocalPersistence.openAssignmentRepository();
    final published = await repo1.publish(
      LearningAssignmentPublishRequest(
        childId: child,
        titleKey: 'assignedChallenge',
        rewardMinutes: Minutes(20),
        source: LearningAssignmentSource.attribution,
      ),
    );
    expect(published.rewardMinutes.inMinutes, 20);
    // Honesty: metadata keys only — no verse/audio fields.
    expect(published.toJson().containsKey('verseText'), isFalse);
    expect(published.toJson().containsKey('audioUrl'), isFalse);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final latest =
        await (await EducationLocalPersistence.openAssignmentRepository())
            .latestForChild(child);
    expect(latest, isNotNull);
    expect(latest!.id, published.id);
    expect(latest.titleKey, 'assignedChallenge');
    expect(latest.rewardMinutes.inMinutes, 20);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openAssignmentRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      EducationLocalPersistence.openAssignmentRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('tryBind rebinds stage1 singleton', () async {
    final dir = await Directory.systemTemp.createTemp('dom_edu_a_b_');
    final path = p.join(dir.path, 'edu.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    await EducationLocalPersistence.tryBindStage1Assignments();
    expect(
      stage1LearningAssignmentRepository,
      isA<LocalLearningAssignmentRepository>(),
    );
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
