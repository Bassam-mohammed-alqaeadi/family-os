import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'notification_prefs.dart';

/// Rule 25 seam — notification prefs for SET-010/011 (Drift deferred).
abstract class NotificationPrefsRepository {
  Future<NotificationPrefs> load(String memberId);

  Future<void> save(NotificationPrefs prefs);

  /// Always rejected — SOS receipt is ungradeable (doc 20 / SET-011 / SET-021).
  ///
  /// Guardians (`father` / `mother` / `guardian`) especially cannot write
  /// `sosMuted=true`; the field is omitted from schema for all members.
  Future<void> setSosMuted(String memberId, bool muted);
}

/// String KV used by [PrefsNotificationPrefsRepository].
abstract class NotificationPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across instances to simulate restart.
final class MemoryNotificationPrefsStore implements NotificationPrefsStore {
  MemoryNotificationPrefsStore([Map<String, String>? data])
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
NotificationPrefsStore stage1NotificationPrefsStore =
    MemoryNotificationPrefsStore();

Never _rejectSosMute([String field = 'setSosMuted']) =>
    throw ForbiddenSosMuteFieldException(field);

/// Rejects SOS-mute writes — guardians cannot set `sosMuted=true` (SET-021).
Never rejectSosMutedWrite(String memberId, bool muted) {
  if (muted && NotificationPrefs.isGuardianMemberId(memberId)) {
    _rejectSosMute('sosMuted');
  }
  // Field does not exist for any member — even unmute / non-guardian.
  _rejectSosMute('setSosMuted');
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsNotificationPrefsRepository
    implements NotificationPrefsRepository {
  PrefsNotificationPrefsRepository(this._store);

  final NotificationPrefsStore _store;

  static String _key(String memberId) => 'notification_prefs:$memberId';

  @override
  Future<NotificationPrefs> load(String memberId) async {
    final raw = await _store.read(_key(memberId));
    if (raw == null || raw.isEmpty) {
      return NotificationPrefs.defaults(memberId: memberId);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return NotificationPrefs.defaults(memberId: memberId);
    }
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    final prefs = NotificationPrefs.fromJson(map);
    if (prefs.memberId != memberId) {
      return prefs.copyWith(memberId: memberId);
    }
    return prefs;
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    if (!prefs.isValid) {
      throw ArgumentError('NotificationPrefs quiet window invalid');
    }
    // Re-parse via JSON to enforce forbidden-field gate on round-trip.
    final json = prefs.toJson();
    final guarded = NotificationPrefs.fromJson(json);
    await _store.write(_key(prefs.memberId), jsonEncode(guarded.toJson()));
  }

  @override
  Future<void> setSosMuted(String memberId, bool muted) async {
    rejectSosMutedWrite(memberId, muted);
  }
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryNotificationPrefsRepository
    implements NotificationPrefsRepository {
  InMemoryNotificationPrefsRepository([Map<String, NotificationPrefs>? seed])
      : _byMember = {
          if (seed != null)
            for (final e in seed.entries) e.key: e.value,
        };

  final Map<String, NotificationPrefs> _byMember;

  @override
  Future<NotificationPrefs> load(String memberId) async {
    return _byMember[memberId] ??
        NotificationPrefs.defaults(memberId: memberId);
  }

  @override
  Future<void> save(NotificationPrefs prefs) async {
    if (!prefs.isValid) {
      throw ArgumentError('NotificationPrefs quiet window invalid');
    }
    NotificationPrefs.fromJson(prefs.toJson());
    _byMember[prefs.memberId] = prefs;
  }

  @override
  Future<void> setSosMuted(String memberId, bool muted) async {
    rejectSosMutedWrite(memberId, muted);
  }

  @visibleForTesting
  Map<String, NotificationPrefs> get debugSnapshot =>
      Map.unmodifiable(_byMember);
}
