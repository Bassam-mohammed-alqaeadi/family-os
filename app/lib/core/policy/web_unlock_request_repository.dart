import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'web_unlock_request.dart';

/// Rule 25 seam — web unlock requests for SET-006 (Drift deferred).
abstract class WebUnlockRequestRepository {
  Future<List<WebUnlockRequest>> loadAll();

  Future<WebUnlockRequest?> getById(String id);

  Future<void> save(WebUnlockRequest request);

  Future<void> saveAll(List<WebUnlockRequest> requests);
}

/// String KV used by [PrefsWebUnlockRequestRepository].
abstract class WebUnlockPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across repo instances to simulate restart.
final class MemoryWebUnlockPrefsStore implements WebUnlockPrefsStore {
  MemoryWebUnlockPrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsWebUnlockRequestRepository
    implements WebUnlockRequestRepository {
  PrefsWebUnlockRequestRepository(this._store);

  final WebUnlockPrefsStore _store;

  static const _key = 'web_unlock_requests';

  @override
  Future<List<WebUnlockRequest>> loadAll() async {
    final raw = await _store.read(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          WebUnlockRequest.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
    ];
  }

  @override
  Future<WebUnlockRequest?> getById(String id) async {
    final all = await loadAll();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> save(WebUnlockRequest request) async {
    final all = await loadAll();
    final next = <WebUnlockRequest>[];
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
  Future<void> saveAll(List<WebUnlockRequest> requests) async {
    await _store.write(
      _key,
      jsonEncode([for (final r in requests) r.toJson()]),
    );
  }
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryWebUnlockRequestRepository
    implements WebUnlockRequestRepository {
  InMemoryWebUnlockRequestRepository([List<WebUnlockRequest>? seed])
      : _items = [if (seed != null) ...seed];

  final List<WebUnlockRequest> _items;

  @override
  Future<List<WebUnlockRequest>> loadAll() async => List.unmodifiable(_items);

  @override
  Future<WebUnlockRequest?> getById(String id) async {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> save(WebUnlockRequest request) async {
    final idx = _items.indexWhere((r) => r.id == request.id);
    if (idx >= 0) {
      _items[idx] = request;
    } else {
      _items.add(request);
    }
  }

  @override
  Future<void> saveAll(List<WebUnlockRequest> requests) async {
    _items
      ..clear()
      ..addAll(requests);
  }
}

/// Snapshot helper for list UIs.
@immutable
final class WebUnlockRequestList {
  const WebUnlockRequestList(this.items);

  final List<WebUnlockRequest> items;

  List<WebUnlockRequest> get pending =>
      items.where((r) => r.isPending).toList(growable: false);
}
