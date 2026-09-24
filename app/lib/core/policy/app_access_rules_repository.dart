import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'app_access_rules.dart';

/// Rule 25 seam — per-app access axes for FAT-034 (Drift later).
abstract class AppAccessRulesRepository {
  Future<AppAccessRuleSet> load(ChildId childId);

  Future<void> save(ChildId childId, AppAccessRuleSet set);
}

/// String KV used by [PrefsAppAccessRulesRepository].
abstract class AppAccessRulesPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across repo instances to simulate restart.
final class MemoryAppAccessRulesPrefsStore implements AppAccessRulesPrefsStore {
  MemoryAppAccessRulesPrefsStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared prefs store for app access rules.
final MemoryAppAccessRulesPrefsStore stage1AppAccessRulesStore =
    MemoryAppAccessRulesPrefsStore();

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsAppAccessRulesRepository implements AppAccessRulesRepository {
  PrefsAppAccessRulesRepository(this._store);

  final AppAccessRulesPrefsStore _store;

  static String _key(ChildId childId) => 'app_access_rules:${childId.value}';

  @override
  Future<AppAccessRuleSet> load(ChildId childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return AppAccessRuleSet(childId: childId);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return AppAccessRuleSet(childId: childId);
    final rulesRaw = decoded['rules'];
    final rules = <AppAccessRule>[];
    if (rulesRaw is List) {
      for (final item in rulesRaw) {
        if (item is! Map) continue;
        rules.add(
          AppAccessRule.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }
    return AppAccessRuleSet(childId: childId, rules: rules);
  }

  @override
  Future<void> save(ChildId childId, AppAccessRuleSet set) async {
    await _store.write(
      _key(childId),
      jsonEncode({
        'childId': childId.value,
        'rules': [for (final r in set.rules) r.toJson()],
      }),
    );
  }
}

/// Pure in-memory alternate for unit / widget tests (Rule 25 fake).
final class InMemoryAppAccessRulesRepository
    implements AppAccessRulesRepository {
  InMemoryAppAccessRulesRepository([Map<String, AppAccessRuleSet>? seed])
      : _byChild = seed ?? {};

  final Map<String, AppAccessRuleSet> _byChild;

  @override
  Future<AppAccessRuleSet> load(ChildId childId) async {
    return _byChild[childId.value] ?? AppAccessRuleSet(childId: childId);
  }

  @override
  Future<void> save(ChildId childId, AppAccessRuleSet set) async {
    _byChild[childId.value] = set;
  }
}

/// Maps FAT-034 list status ↔ [AppAccessRule] axes (ST-OD-010).
@immutable
abstract final class AppAccessRuleMapper {
  static AppAccessRule fromEntry({
    required String appId,
    required bool blocked,
    required bool freeOrEdu,
    int? limitMinutes,
    bool unlimited = false,
  }) {
    return AppAccessRule(
      appId: appId,
      blocked: blocked,
      limitMinutes: blocked
          ? null
          : (limitMinutes != null && limitMinutes > 0 ? limitMinutes : null),
      countable: !freeOrEdu,
      unlimited: unlimited && !blocked && !freeOrEdu,
    );
  }
}
