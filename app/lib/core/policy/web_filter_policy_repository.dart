import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'web_filter_policy.dart';

/// Rule 25 seam — web filter policy for SET-004 (Drift deferred past Stage-1).
abstract class WebFilterPolicyRepository {
  /// Loads policy for [childId] (missing → [WebFilterPolicy.defaults]).
  Future<WebFilterPolicy> load(ChildId childId);

  /// Replaces the full policy for [childId].
  Future<void> save(ChildId childId, WebFilterPolicy policy);
}

/// String KV used by [PrefsWebFilterPolicyRepository].
abstract class WebFilterPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share the same [data] map across repo instances to
/// simulate process restart in tests.
final class MemoryWebFilterPrefsStore implements WebFilterPrefsStore {
  MemoryWebFilterPrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsWebFilterPolicyRepository
    implements WebFilterPolicyRepository {
  PrefsWebFilterPolicyRepository(this._store);

  final WebFilterPrefsStore _store;

  static String _key(ChildId childId) => 'web_filter_policy:${childId.value}';

  @override
  Future<WebFilterPolicy> load(ChildId childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return WebFilterPolicy.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return WebFilterPolicy.defaults();
    return WebFilterPolicy.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  Future<void> save(ChildId childId, WebFilterPolicy policy) async {
    final normalized = WebFilterPolicy(
      level: policy.level,
      categories: policy.categories,
      allowList: policy.allowList,
      policyVersion: policy.policyVersion,
      updatedAt: policy.updatedAt,
    );
    await _store.write(_key(childId), jsonEncode(normalized.toJson()));
  }
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryWebFilterPolicyRepository
    implements WebFilterPolicyRepository {
  InMemoryWebFilterPolicyRepository([Map<String, WebFilterPolicy>? seed])
      : _byChild = seed ?? {};

  final Map<String, WebFilterPolicy> _byChild;

  @override
  Future<WebFilterPolicy> load(ChildId childId) async {
    return _byChild[childId.value] ?? WebFilterPolicy.defaults();
  }

  @override
  Future<void> save(ChildId childId, WebFilterPolicy policy) async {
    _byChild[childId.value] = WebFilterPolicy(
      level: policy.level,
      categories: policy.categories,
      allowList: policy.allowList,
      policyVersion: policy.policyVersion,
      updatedAt: policy.updatedAt,
    );
  }
}

/// Snapshot helper evaluators / SET-005 preview can read.
@immutable
final class WebFilterPolicySnapshot {
  const WebFilterPolicySnapshot(this.policy);

  final WebFilterPolicy policy;

  WebFilterLevel get level => policy.level;

  int get policyVersion => policy.policyVersion;

  bool isCategoryEnabled(String key) => policy.isCategoryEnabled(key);
}
