import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'time_request.dart';

/// Rule 25 seam — time requests / grants for UI-006 (Drift deferred / D-3).
abstract class TimeRequestRepository {
  Future<List<TimeRequest>> loadAll();

  Future<TimeRequest?> getById(String id);

  Future<void> save(TimeRequest request);

  Future<void> saveAll(List<TimeRequest> requests);

  Future<List<TimeGrant>> loadGrants();

  Future<void> saveGrant(TimeGrant grant);
}

/// String KV used by [PrefsTimeRequestRepository].
abstract class TimeRequestPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across repo instances to simulate restart.
final class MemoryTimeRequestPrefsStore implements TimeRequestPrefsStore {
  MemoryTimeRequestPrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsTimeRequestRepository implements TimeRequestRepository {
  PrefsTimeRequestRepository(this._store);

  final TimeRequestPrefsStore _store;

  static const _requestsKey = 'time_requests';
  static const _grantsKey = 'time_grants';

  @override
  Future<List<TimeRequest>> loadAll() async {
    final raw = await _store.read(_requestsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          TimeRequest.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
    ];
  }

  @override
  Future<TimeRequest?> getById(String id) async {
    final all = await loadAll();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> save(TimeRequest request) async {
    final all = await loadAll();
    final next = <TimeRequest>[];
    var replaced = false;
    for (final r in all) {
      if (r.id == request.id) {
        next.add(request);
        replaced = true;
      } else {
        next.add(r);
      }
    }
    if (!replaced) next.add(request);
    await saveAll(next);
  }

  @override
  Future<void> saveAll(List<TimeRequest> requests) async {
    await _store.write(
      _requestsKey,
      jsonEncode([for (final r in requests) r.toJson()]),
    );
  }

  @override
  Future<List<TimeGrant>> loadGrants() async {
    final raw = await _store.read(_grantsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          TimeGrant.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
    ];
  }

  @override
  Future<void> saveGrant(TimeGrant grant) async {
    final all = await loadGrants();
    final next = [...all.where((g) => g.id != grant.id), grant];
    await _store.write(
      _grantsKey,
      jsonEncode([for (final g in next) g.toJson()]),
    );
  }
}

/// Pure in-memory alternate for unit / widget tests (Rule 25 fake).
final class InMemoryTimeRequestRepository implements TimeRequestRepository {
  InMemoryTimeRequestRepository([List<TimeRequest>? seed])
      : _items = [if (seed != null) ...seed];

  final List<TimeRequest> _items;
  final List<TimeGrant> _grants = [];

  @override
  Future<List<TimeRequest>> loadAll() async => List.unmodifiable(_items);

  @override
  Future<TimeRequest?> getById(String id) async {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> save(TimeRequest request) async {
    final idx = _items.indexWhere((r) => r.id == request.id);
    if (idx >= 0) {
      _items[idx] = request;
    } else {
      _items.add(request);
    }
  }

  @override
  Future<void> saveAll(List<TimeRequest> requests) async {
    _items
      ..clear()
      ..addAll(requests);
  }

  @override
  Future<List<TimeGrant>> loadGrants() async => List.unmodifiable(_grants);

  @override
  Future<void> saveGrant(TimeGrant grant) async {
    final idx = _grants.indexWhere((g) => g.id == grant.id);
    if (idx >= 0) {
      _grants[idx] = grant;
    } else {
      _grants.add(grant);
    }
  }
}

/// Snapshot helper for list UIs.
@immutable
final class TimeRequestList {
  const TimeRequestList(this.items);

  final List<TimeRequest> items;

  List<TimeRequest> get pending =>
      items.where((r) => r.isPending).toList(growable: false);
}
