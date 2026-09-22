import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'desired_monitoring_prefs.dart';

/// Rule 25 seam — desired monitoring prefs for SET-016 (Drift deferred).
abstract class DesiredMonitoringPrefsRepository {
  Future<DesiredMonitoringPrefs> load(String childId);

  Future<void> save(DesiredMonitoringPrefs prefs);
}

/// String KV used by [PrefsDesiredMonitoringPrefsRepository].
abstract class DesiredMonitoringPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across instances to simulate restart.
final class MemoryDesiredMonitoringPrefsStore
    implements DesiredMonitoringPrefsStore {
  MemoryDesiredMonitoringPrefsStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Shared Stage-1 store (survives within process).
final MemoryDesiredMonitoringPrefsStore stage1DesiredMonitoringPrefsStore =
    MemoryDesiredMonitoringPrefsStore();

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsDesiredMonitoringPrefsRepository
    implements DesiredMonitoringPrefsRepository {
  PrefsDesiredMonitoringPrefsRepository(this._store);

  final DesiredMonitoringPrefsStore _store;

  static String _key(String childId) => 'desired_monitoring:$childId';

  @override
  Future<DesiredMonitoringPrefs> load(String childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return DesiredMonitoringPrefs.defaults(childId: childId);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return DesiredMonitoringPrefs.defaults(childId: childId);
    }
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    final prefs = DesiredMonitoringPrefs.fromJson(map);
    if (prefs.childId != childId) {
      return prefs.copyWith(childId: childId);
    }
    return prefs;
  }

  @override
  Future<void> save(DesiredMonitoringPrefs prefs) async {
    await _store.write(_key(prefs.childId), jsonEncode(prefs.toJson()));
  }
}

/// Pure in-memory alternate for unit/widget tests (Rule 25 fake).
final class InMemoryDesiredMonitoringPrefsRepository
    implements DesiredMonitoringPrefsRepository {
  InMemoryDesiredMonitoringPrefsRepository(
      [Map<String, DesiredMonitoringPrefs>? seed])
      : _byChild = {
          if (seed != null)
            for (final e in seed.entries) e.key: e.value,
        };

  final Map<String, DesiredMonitoringPrefs> _byChild;

  @override
  Future<DesiredMonitoringPrefs> load(String childId) async {
    return _byChild[childId] ??
        DesiredMonitoringPrefs.defaults(childId: childId);
  }

  @override
  Future<void> save(DesiredMonitoringPrefs prefs) async {
    _byChild[prefs.childId] = prefs;
  }

  @visibleForTesting
  Map<String, DesiredMonitoringPrefs> get debugSnapshot =>
      Map.unmodifiable(_byChild);
}
