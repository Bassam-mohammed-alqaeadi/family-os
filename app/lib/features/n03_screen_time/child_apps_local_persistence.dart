import 'package:flutter/foundation.dart';

import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/features/n02_day/children_list_local_seed_mock.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n03_screen_time/child_apps_real_local_seed_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';

/// LDR-B2 — bind child apps inventory to AC/ST axes + REAL_LOCAL managed seed.
abstract final class ChildAppsLocalPersistence {
  ChildAppsLocalPersistence._();

  static Future<void> tryBindStage1() async {
    try {
      await FsSessionKernel.ensureOpen();
      if (FsSessionKernel.sqliteFallbackToMemory) return;
      await Stage1AppControlRuntime.ensureOpen();
      final kids = await stage1ChildrenListRepository.listChildren(
        familyId: ChildrenListLocalSeedMock.famStage1,
      );
      final ids = <ChildId>[for (final k in kids) ChildId(k.id)];
      if (ids.isEmpty) {
        ids.addAll(activeFamilyRosterChildren().map((child) => child.id));
      }
      if (ids.isEmpty) return;

      // Seed only when production inventory is empty (idempotent).
      final existing = stage1ChildAppsRepository.appsFor(ids.first);
      final seed = existing.isEmpty
          ? ChildAppsRealLocalSeedMock.forChildren(ids)
          : null;

      rebindStage1ChildAppsRepository(
        InMemoryChildAppsRepository(
          seed: seed,
          accessRules: Stage1AppControlRuntime.accessRules,
        ),
      );

      // If we did not pass seed (already had rows), still rebind rules.
      if (seed == null) {
        // Ensure each child has at least managed catalog once.
        for (final id in ids) {
          if (stage1ChildAppsRepository.appsFor(id).isEmpty) {
            stage1ChildAppsRepository.seed(
              id,
              ChildAppsRealLocalSeedMock.managedCatalog,
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('LDR ChildAppsLocalPersistence.tryBind soft-fail: $e\n$st');
    }
  }
}
