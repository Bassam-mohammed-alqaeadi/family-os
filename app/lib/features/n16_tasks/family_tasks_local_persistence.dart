import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/features/n16_tasks/family_tasks_local_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

/// Family Tasks Local KV bind (CE-B1 / CE-G012–015).
abstract final class FamilyTasksLocalPersistence {
  FamilyTasksLocalPersistence._();

  static Future<LocalFamilyTasksRepository> openRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'CE-B1 FamilyTasks: refuses SQLite→Memory fallback (not restart-safe)',
      );
    }
    return LocalFamilyTasksRepository(FsSessionKernel.db);
  }

  /// Soft bind from [main] — rebinds stage1 when SQLite honest.
  static Future<void> tryBindStage1() async {
    try {
      final repo = await openRepository();
      await repo.ensureRealLocalSeeded();
      rebindStage1FamilyTasksRepository(repo);
    } catch (e, st) {
      debugPrint(
        'CE-B1 FamilyTasks Local KV bind soft-fail — '
        'InMemory empty stage1 retained (not claimed durable): $e\n$st',
      );
    }
  }
}
