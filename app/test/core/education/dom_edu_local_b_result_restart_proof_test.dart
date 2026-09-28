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
import 'package:family_os/features/education/learning_result_local_repository.dart';
import 'package:family_os/features/education/learning_result_models.dart';
import 'package:family_os/features/education/learning_result_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    rebindStage1LearningResultRepository(InMemoryLearningResultRepository());
    await FsSessionKernel.resetForTest();
  });

  test('result submit→close→reopen→listRecent', () async {
    final dir = await Directory.systemTemp.createTemp('dom_edu_b_');
    final path = p.join(dir.path, 'edu.db');
    final child = ChildId('demo-child');

    final db1 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db1);
    final repo1 = await EducationLocalPersistence.openResultRepository();
    final submitted = await repo1.submit(
      LearningResultSubmitRequest(
        childId: child,
        kind: LearningResultKind.quiz,
        titleKey: 'quizSubmitted',
        rewardMinutes: Minutes(15),
        scoreCorrect: 3,
        scoreTotal: 4,
      ),
    );
    expect(submitted.rewardMinutes.inMinutes, 15);
    expect(submitted.toJson().containsKey('verseText'), isFalse);
    await FsSessionKernel.resetForTest();

    final db2 = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db2);
    final recent =
        await (await EducationLocalPersistence.openResultRepository())
            .listRecent();
    expect(recent, isNotEmpty);
    expect(recent.first.id, submitted.id);
    expect(recent.first.scoreCorrect, 3);

    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });

  test('openResultRepository refuses sqliteFallbackToMemory', () async {
    await FsSessionKernel.resetForTest();
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    if (FsSessionKernel.usingSqlite) {
      expect(FsSessionKernel.sqliteFallbackToMemory, isFalse);
      return;
    }
    expect(FsSessionKernel.sqliteFallbackToMemory, isTrue);
    expect(FsSessionKernel.db, isA<MemoryLocalDatabase>());
    await expectLater(
      EducationLocalPersistence.openResultRepository(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('refuses SQLite→Memory'),
        ),
      ),
    );
  });

  test('tryBind rebinds stage1 results singleton', () async {
    final dir = await Directory.systemTemp.createTemp('dom_edu_b_b_');
    final path = p.join(dir.path, 'edu.db');
    final db = await SqliteLocalDatabase.openAt(path);
    await FsSessionKernel.ensureOpen(override: db);
    await EducationLocalPersistence.tryBindStage1Results();
    expect(
      stage1LearningResultRepository,
      isA<LocalLearningResultRepository>(),
    );
    await FsSessionKernel.resetForTest();
    await dir.delete(recursive: true);
  });
}
