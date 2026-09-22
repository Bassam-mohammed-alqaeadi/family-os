import 'package:flutter/foundation.dart';

/// Stage-1 Advisor memory notes (SET-013 forget target).
///
/// Forget clears **only** this store — never chat messages or [AuditAppend].
@immutable
final class AdvisorMemoryNote {
  const AdvisorMemoryNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;
}

/// Rule 25 seam — in-memory / prefs-backed Advisor memory (Drift deferred).
abstract class AdvisorMemoryStore {
  List<AdvisorMemoryNote> get notes;

  Future<void> add(AdvisorMemoryNote note);

  /// Clears all advisor memory. Does not touch chat or audit.
  Future<void> clear();
}

/// In-memory Advisor memory — share [notes] across instances to simulate restart.
final class MemoryAdvisorMemoryStore implements AdvisorMemoryStore {
  MemoryAdvisorMemoryStore([List<AdvisorMemoryNote>? seed])
      : _notes = List<AdvisorMemoryNote>.from(seed ?? const []);

  final List<AdvisorMemoryNote> _notes;

  @override
  List<AdvisorMemoryNote> get notes => List.unmodifiable(_notes);

  @override
  Future<void> add(AdvisorMemoryNote note) async {
    _notes.add(note);
  }

  @override
  Future<void> clear() async {
    _notes.clear();
  }
}

/// Prefs-backed Advisor memory (JSON-ish line list for Stage-1).
final class PrefsAdvisorMemoryStore implements AdvisorMemoryStore {
  PrefsAdvisorMemoryStore(this._store, {this.prefsKey = 'advisor_memory_v1'});

  final AdvisorMemoryPrefsStore _store;
  final String prefsKey;
  final List<AdvisorMemoryNote> _cache = [];
  var _hydrated = false;

  @override
  List<AdvisorMemoryNote> get notes => List.unmodifiable(_cache);

  Future<void> hydrate() async {
    if (_hydrated) return;
    final raw = await _store.read(prefsKey);
    _cache
      ..clear()
      ..addAll(_decode(raw));
    _hydrated = true;
  }

  @override
  Future<void> add(AdvisorMemoryNote note) async {
    await hydrate();
    _cache.add(note);
    await _persist();
  }

  @override
  Future<void> clear() async {
    await hydrate();
    _cache.clear();
    await _persist();
  }

  Future<void> _persist() async {
    await _store.write(prefsKey, _encode(_cache));
  }

  static String _encode(List<AdvisorMemoryNote> notes) {
    return notes
        .map((n) => '${n.id}|${n.createdAt.toUtc().toIso8601String()}|${n.text}')
        .join('\n');
  }

  static List<AdvisorMemoryNote> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\n').where((l) => l.isNotEmpty).map((line) {
      final parts = line.split('|');
      if (parts.length < 3) {
        return AdvisorMemoryNote(
          id: line,
          text: line,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      }
      return AdvisorMemoryNote(
        id: parts[0],
        createdAt: DateTime.tryParse(parts[1]) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        text: parts.sublist(2).join('|'),
      );
    }).toList();
  }
}

/// String KV used by [PrefsAdvisorMemoryStore].
abstract class AdvisorMemoryPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class MemoryAdvisorMemoryPrefsStore implements AdvisorMemoryPrefsStore {
  MemoryAdvisorMemoryPrefsStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared Advisor memory (survives within process).
final MemoryAdvisorMemoryStore stage1AdvisorMemoryStore =
    MemoryAdvisorMemoryStore();
