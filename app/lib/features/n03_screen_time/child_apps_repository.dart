import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';

/// Rule 25 seam — child installed-apps inventory for SCR-FAT-034.
abstract interface class ChildAppsRepository {
  List<ChildAppEntry> appsFor(ChildId childId);

  /// Returns false when [appId] unknown.
  bool setStatus(ChildId childId, String appId, ChildAppStatus status);

  void resetForTests();
}

/// In-memory mock — ChangeNotifier for live list updates.
final class InMemoryChildAppsRepository extends ChangeNotifier
    implements ChildAppsRepository {
  InMemoryChildAppsRepository({
    Map<String, List<ChildAppEntry>>? seed,
  }) : _byChild = {
          for (final e in (seed ?? kDefaultChildAppsByChild).entries)
            e.key: List<ChildAppEntry>.from(e.value),
        };

  final Map<String, List<ChildAppEntry>> _byChild;

  @override
  List<ChildAppEntry> appsFor(ChildId childId) {
    final list = _byChild[childId.value];
    if (list == null) return const [];
    return List<ChildAppEntry>.unmodifiable(list);
  }

  @override
  bool setStatus(ChildId childId, String appId, ChildAppStatus status) {
    final list = _byChild[childId.value];
    if (list == null) return false;
    final i = list.indexWhere((a) => a.id == appId);
    if (i < 0) return false;
    var next = list[i].copyWith(status: status);
    if (status == ChildAppStatus.allowed && next.limitMins <= 0) {
      next = next.copyWith(limitMins: 30);
    }
    if (status == ChildAppStatus.free) {
      next = next.copyWith(limitMins: -1);
    }
    if (status == ChildAppStatus.blocked) {
      next = next.copyWith(limitMins: 0);
    }
    list[i] = next;
    notifyListeners();
    return true;
  }

  /// Test helper — replace inventory for one child.
  void seed(ChildId childId, List<ChildAppEntry> apps) {
    _byChild[childId.value] = List<ChildAppEntry>.from(apps);
    notifyListeners();
  }

  @override
  void resetForTests() {
    _byChild
      ..clear()
      ..addAll({
        for (final e in kDefaultChildAppsByChild.entries)
          e.key: List<ChildAppEntry>.from(e.value),
      });
    notifyListeners();
  }
}

/// Process-wide Stage-1 singleton.
final InMemoryChildAppsRepository stage1ChildAppsRepository =
    InMemoryChildAppsRepository();
