import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/features/education/learning_assignment_local_repository.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/education/learning_result_local_repository.dart';
import 'package:family_os/features/education/learning_result_repository.dart';

/// Education Local KV binds (DOM-EDU-LOCAL-A / B).
abstract final class EducationLocalPersistence {
  EducationLocalPersistence._();

  static Future<LocalLearningAssignmentRepository>
      openAssignmentRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-EDU-LOCAL-A: LearningAssignment refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return LocalLearningAssignmentRepository(FsSessionKernel.db);
  }

  /// Soft bind from [main] — rebinds stage1 singleton when SQLite honest.
  static Future<void> tryBindStage1Assignments() async {
    try {
      final repo = await openAssignmentRepository();
      await repo.ensureRealLocalSeeded();
      rebindStage1LearningAssignmentRepository(repo);
    } catch (e, st) {
      debugPrint(
        'DOM-EDU-LOCAL-A: assignment Local KV bind soft-fail — '
        'InMemory stage1 retained (not claimed durable): $e\n$st',
      );
    }
  }

  static Future<LocalLearningResultRepository> openResultRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-EDU-LOCAL-B: LearningResult refuses SQLite→Memory '
        'fallback (not restart-safe)',
      );
    }
    return LocalLearningResultRepository(FsSessionKernel.db);
  }

  static Future<void> tryBindStage1Results() async {
    try {
      final repo = await openResultRepository();
      rebindStage1LearningResultRepository(repo);
    } catch (e, st) {
      debugPrint(
        'DOM-EDU-LOCAL-B: result Local KV bind soft-fail — '
        'InMemory stage1 retained (not claimed durable): $e\n$st',
      );
    }
  }
}
