import 'dart:convert';

import 'smart_mode_prefs.dart';

/// Rule 25 seam — smart mode rows for SET-018 (Drift deferred past Stage-1).
///
/// Service host map (T-1 / ADR-034):
/// - **S-SEC-058** جدول وضع المدرسة → SCR-FAT-085
/// - **S-SEC-059** التفعيل التلقائي بالموقع → SCR-FAT-085
/// Tombstone SCR-FAT-039 is never a host.
abstract class SmartModePrefsRepository {
  Future<SmartModePrefs> load(String childId);

  Future<void> save(SmartModePrefs prefs);
}

/// String KV used by [PrefsSmartModePrefsRepository].
abstract class SmartModePrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class MemorySmartModePrefsStore implements SmartModePrefsStore {
  MemorySmartModePrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared mock prefs (process lifetime).
SmartModePrefsStore stage1SmartModePrefsStore = MemorySmartModePrefsStore();

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsSmartModePrefsRepository implements SmartModePrefsRepository {
  PrefsSmartModePrefsRepository(this._store);

  final SmartModePrefsStore _store;

  static String _key(String childId) => 'smart_modes:$childId';

  @override
  Future<SmartModePrefs> load(String childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return SmartModePrefs.defaults(childId: childId);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return SmartModePrefs.defaults(childId: childId);
      }
      final prefs = SmartModePrefs.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
      return prefs.childId == childId
          ? prefs
          : SmartModePrefs(childId: childId, modes: prefs.modes);
    } on FormatException {
      return SmartModePrefs.defaults(childId: childId);
    }
  }

  @override
  Future<void> save(SmartModePrefs prefs) async {
    await _store.write(_key(prefs.childId), jsonEncode(prefs.toJson()));
  }
}

/// Pure in-memory alternate for unit / widget tests (Rule 25 fake).
final class InMemorySmartModePrefsRepository
    implements SmartModePrefsRepository {
  InMemorySmartModePrefsRepository([Map<String, SmartModePrefs>? seed])
      : _byChild = seed ?? {};

  final Map<String, SmartModePrefs> _byChild;

  @override
  Future<SmartModePrefs> load(String childId) async {
    return _byChild[childId] ?? SmartModePrefs.defaults(childId: childId);
  }

  @override
  Future<void> save(SmartModePrefs prefs) async {
    _byChild[prefs.childId] = prefs;
  }

  Map<String, SmartModePrefs> get debugSnapshot =>
      Map.unmodifiable(_byChild);
}
