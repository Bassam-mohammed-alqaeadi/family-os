import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/features/n02_day/child_arrival_local_repository.dart';
import 'package:family_os/features/n02_day/child_arrival_repository.dart';
import 'package:family_os/features/n02_day/child_media_share_local_repository.dart';
import 'package:family_os/features/n02_day/child_media_share_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_local_repository.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_local_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_local_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_repository.dart';

/// CE-B1 remainder — calendar / circle / media / arrival / focus Local KV binds.
abstract final class FamilyOpsLocalPersistence {
  FamilyOpsLocalPersistence._();

  static Future<void> tryBindStage1() async {
    try {
      await FsSessionKernel.ensureOpen();
      if (FsSessionKernel.sqliteFallbackToMemory) {
        throw StateError(
          'CE-B1 FamilyOps: refuses SQLite→Memory fallback (not restart-safe)',
        );
      }
      final db = FsSessionKernel.db;
      final calendar = LocalFamilyCalendarRepository(db);
      await calendar.ensureRealLocalSeeded();
      rebindStage1FamilyCalendarRepository(calendar);
      final circle = LocalOuterCircleRepository(db);
      await circle.ensureRealLocalSeeded();
      rebindStage1OuterCircleRepository(circle);
      rebindStage1ChildMediaShareRepository(LocalChildMediaShareRepository(db));
      rebindStage1ChildArrivalRepository(LocalChildArrivalRepository(db));
      rebindStage1ChildFocusSoundsRepository(
        LocalChildFocusSoundsRepository(db),
      );
    } catch (e, st) {
      debugPrint(
        'CE-B1 FamilyOps Local KV bind soft-fail — '
        'InMemory empty stage1 retained (not claimed durable): $e\n$st',
      );
    }
  }
}
