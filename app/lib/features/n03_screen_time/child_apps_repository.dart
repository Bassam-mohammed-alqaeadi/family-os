import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';
import 'package:family_os/features/n03_screen_time/child_apps_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';

/// Rule 25 seam — child installed-apps inventory for SCR-FAT-034.
abstract interface class ChildAppsRepository {
  List<ChildAppEntry> appsFor(ChildId childId);

  /// Returns false when [appId] unknown.
  bool setStatus(ChildId childId, String appId, ChildAppStatus status);

  /// Updates unlimited axis (games) and persists [AppAccessRuleSet].
  bool setUnlimited(ChildId childId, String appId, bool unlimited);

  void resetForTests();
}

/// In-memory mock — ChangeNotifier for live list updates.
///
/// Persists [AppAccessRule] axes to [AppAccessRulesRepository] on mutation.
final class InMemoryChildAppsRepository extends ChangeNotifier
    implements ChildAppsRepository {
  InMemoryChildAppsRepository({
    Map<String, List<ChildAppEntry>>? seed,
    AppAccessRulesRepository? accessRules,
  }) : _byChild = {
         for (final e in (seed ?? kDefaultChildAppsByChild).entries)
           e.key: List<ChildAppEntry>.from(e.value),
       },
       _accessRules =
           accessRules ??
           PrefsAppAccessRulesRepository(
             seed != null
                 ? MemoryAppAccessRulesPrefsStore()
                 : stage1AppAccessRulesStore,
           ) {
    _hydrateFromRulesSync();
  }

  final Map<String, List<ChildAppEntry>> _byChild;
  final AppAccessRulesRepository _accessRules;

  void _hydrateFromRulesSync() {
    // Fire-and-forget hydrate; callers that need rules should await loadRules.
    for (final entry in _byChild.entries) {
      final childId = ChildId(entry.key);
      _accessRules.load(childId).then((set) {
        if (set.rules.isEmpty) {
          _persistAll(childId);
          return;
        }
        final list = _byChild[entry.key];
        if (list == null) return;
        for (var i = 0; i < list.length; i++) {
          final rule = set.ruleFor(list[i].id);
          if (rule != null) {
            list[i] = list[i].applyAccessRule(rule);
          }
        }
        notifyListeners();
      });
    }
  }

  Future<void> _persistAll(ChildId childId) async {
    final list = _byChild[childId.value];
    if (list == null) return;
    var set = AppAccessRuleSet(childId: childId);
    for (final app in list) {
      if (app.status == ChildAppStatus.pending) continue;
      set = set.upsert(app.toAccessRule());
    }
    await _accessRules.save(childId, set);
  }

  Future<void> _persistOne(ChildId childId, ChildAppEntry app) async {
    if (app.status == ChildAppStatus.pending) return;
    final existing = await _accessRules.load(childId);
    await _accessRules.save(childId, existing.upsert(app.toAccessRule()));
  }

  @override
  List<ChildAppEntry> appsFor(ChildId childId) {
    final key = _resolveChildKey(childId.value);
    final list = key == null ? null : _byChild[key];
    if (list == null) return const [];
    return List<ChildAppEntry>.unmodifiable(list);
  }

  @override
  bool setStatus(ChildId childId, String appId, ChildAppStatus status) {
    final key = _resolveChildKey(childId.value);
    if (key == null) return false;
    final list = _byChild[key];
    if (list == null) return false;
    final i = list.indexWhere((a) => a.id == appId);
    if (i < 0) return false;
    var next = list[i].copyWith(status: status);
    if (status == ChildAppStatus.allowed && next.limitMins <= 0) {
      next = next.copyWith(limitMins: 30, unlimited: false);
    }
    if (status == ChildAppStatus.free) {
      next = next.copyWith(limitMins: -1, unlimited: false);
    }
    if (status == ChildAppStatus.blocked) {
      next = next.copyWith(limitMins: 0, unlimited: false);
    }
    list[i] = next;
    _persistOne(ChildId(key), next);
    notifyListeners();
    return true;
  }

  @override
  bool setUnlimited(ChildId childId, String appId, bool unlimited) {
    final key = _resolveChildKey(childId.value);
    if (key == null) return false;
    final list = _byChild[key];
    if (list == null) return false;
    final i = list.indexWhere((a) => a.id == appId);
    if (i < 0) return false;
    final app = list[i];
    if (app.status == ChildAppStatus.blocked ||
        app.status == ChildAppStatus.pending ||
        app.isFreeOrEdu) {
      return false;
    }
    final next = app.copyWith(unlimited: unlimited);
    list[i] = next;
    _persistOne(ChildId(key), next);
    notifyListeners();
    return true;
  }

  /// Test helper — replace inventory for one child.
  void seed(ChildId childId, List<ChildAppEntry> apps) {
    _byChild[childId.value] = List<ChildAppEntry>.from(apps);
    _persistAll(childId);
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
    stage1AppAccessRulesStore.data.clear();
    _persistAll(ChildId(kDefaultChildAppsChildKey));
    notifyListeners();
  }

  String? _resolveChildKey(String raw) {
    if (_byChild.containsKey(raw)) return raw;
    final sep = raw.indexOf('::');
    if (sep > 0 && sep < raw.length - 2) {
      final suffix = raw.substring(sep + 2);
      if (_byChild.containsKey(suffix)) return suffix;
    }
    return null;
  }
}

/// Process-wide Stage-1 singleton.
final InMemoryChildAppsRepository stage1ChildAppsRepository =
    InMemoryChildAppsRepository();
