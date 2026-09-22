import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../domain/child_id.dart';
import 'schedule_window.dart';

/// Rule 25 seam — schedule windows for SET-001 (Drift deferred past Stage-1).
abstract class ScheduleWindowRepository {
  /// Loads all three kinds for [childId] (missing kinds → disabled stubs).
  Future<List<ScheduleWindow>> load(ChildId childId);

  /// Replaces the full set for [childId].
  Future<void> save(ChildId childId, List<ScheduleWindow> windows);

  /// Single kind lookup (null if never saved — caller may use stub).
  Future<ScheduleWindow?> get(ChildId childId, ScheduleKind kind);
}

/// String KV used by [PrefsScheduleWindowRepository] (SharedPreferences-shaped).
abstract class SchedulePrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share the same [data] map across repo instances to
/// simulate process restart in tests.
final class MemorySchedulePrefsStore implements SchedulePrefsStore {
  MemorySchedulePrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsScheduleWindowRepository implements ScheduleWindowRepository {
  PrefsScheduleWindowRepository(this._store);

  final SchedulePrefsStore _store;

  static String _key(ChildId childId) => 'schedule_windows:${childId.value}';

  @override
  Future<List<ScheduleWindow>> load(ChildId childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return _emptySet();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) return _emptySet();
    final byKind = <ScheduleKind, ScheduleWindow>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final window = ScheduleWindow.fromJson(
        item.map((k, v) => MapEntry(k.toString(), v)),
      );
      byKind[window.kind] = window;
    }
    return [
      for (final kind in ScheduleKind.values)
        byKind[kind] ?? ScheduleWindow(kind: kind, enabled: false),
    ];
  }

  @override
  Future<void> save(ChildId childId, List<ScheduleWindow> windows) async {
    final payload = jsonEncode(windows.map((w) => w.toJson()).toList());
    await _store.write(_key(childId), payload);
  }

  @override
  Future<ScheduleWindow?> get(ChildId childId, ScheduleKind kind) async {
    final all = await load(childId);
    for (final w in all) {
      if (w.kind == kind) return w;
    }
    return null;
  }

  List<ScheduleWindow> _emptySet() => [
        for (final kind in ScheduleKind.values)
          ScheduleWindow(kind: kind, enabled: false),
      ];
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryScheduleWindowRepository
    implements ScheduleWindowRepository {
  InMemoryScheduleWindowRepository([Map<String, List<ScheduleWindow>>? seed])
      : _byChild = seed ?? {};

  final Map<String, List<ScheduleWindow>> _byChild;

  @override
  Future<List<ScheduleWindow>> load(ChildId childId) async {
    final existing = _byChild[childId.value];
    if (existing == null) {
      return [
        for (final kind in ScheduleKind.values)
          ScheduleWindow(kind: kind, enabled: false),
      ];
    }
    return List<ScheduleWindow>.from(existing);
  }

  @override
  Future<void> save(ChildId childId, List<ScheduleWindow> windows) async {
    _byChild[childId.value] = List<ScheduleWindow>.from(windows);
  }

  @override
  Future<ScheduleWindow?> get(ChildId childId, ScheduleKind kind) async {
    final all = await load(childId);
    for (final w in all) {
      if (w.kind == kind) return w;
    }
    return null;
  }
}

/// Snapshot helper TimeEngine / SmartModes can read (SET-001 Stage-1).
@immutable
final class ScheduleSnapshot {
  const ScheduleSnapshot(this.windows);

  final List<ScheduleWindow> windows;

  ScheduleWindow? operator [](ScheduleKind kind) {
    for (final w in windows) {
      if (w.kind == kind) return w;
    }
    return null;
  }

  /// True when [kind] is enabled and [now] is inside its window.
  bool isActive(ScheduleKind kind, TimeOfDay now) {
    final w = this[kind];
    return w != null && w.contains(now);
  }
}
