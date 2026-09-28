import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/core/policy/web_unlock_request_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart';
import 'package:family_os/features/n04_web_filter/web_filter_runtime.dart';

/// Shared KV adapter for SOS prefs + web unlock request queue residuals.
final class LocalStringKvStore
    implements SosLadderStore, WebUnlockPrefsStore {
  LocalStringKvStore(this._db, {required this.namespace});

  final FamilyLocalDatabase _db;
  final String namespace;
  static const _table = 'kv_store';

  @override
  Future<String?> read(String key) async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: [namespace, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String value) async {
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}

/// Durable SOS settings — sync read/write API with async flush (DOM-SOS-SETTINGS).
final class DurableSosSettingsStore implements SosSettingsStore {
  DurableSosSettingsStore(this._kv);

  static const _key = 'sos_local_settings';

  final LocalStringKvStore _kv;
  SosLocalSettings _settings = const SosLocalSettings();

  @override
  SosLocalSettings get settings => _settings;

  Future<void> hydrate() async {
    final raw = await _kv.read(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _settings = SosLocalSettings.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (_) {
      // Keep defaults.
    }
  }

  void _flush() {
    _kv.write(_key, jsonEncode(_settings.toJson()));
  }

  @override
  void setPanicQuietPreferred(bool value) {
    _settings = _settings.copyWith(panicQuietPreferred: value);
    // Fire-and-forget durable flush — SOS fire must never block on prefs I/O.
    _flush();
  }

  @override
  void setChildEscalation(String childId, ChildSosEscalationPrefs prefs) {
    final next = Map<String, ChildSosEscalationPrefs>.from(
      _settings.childEscalation,
    );
    next[childId] = prefs;
    _settings = _settings.copyWith(childEscalation: next);
    _flush();
  }

  @override
  void reset() {
    _settings = const SosLocalSettings();
    _flush();
  }
}

/// Boot-once SOS prefs + web unlock request residual (Phase 1.75 debt close).
final class SosPrefsRuntime {
  SosPrefsRuntime._();

  static const ladderNs = 'prefs_sos_ladder';
  static const settingsNs = 'prefs_sos_settings';
  static const unlockNs = 'prefs_web_unlock';

  static var _opened = false;
  static var _unavailable = false;

  static PrefsSosLadderRepository? _ladder;
  static DurableSosSettingsStore? _settings;
  static PrefsWebUnlockRequestRepository? _webUnlockRequests;

  static bool get isOpen => _opened;
  static bool get unavailable => _unavailable;
  static PrefsSosLadderRepository? get ladder => _ladder;
  static SosSettingsStore? get settings => _settings;
  static PrefsWebUnlockRequestRepository? get webUnlockRequests =>
      _webUnlockRequests;

  static Future<void> ensureOpen() async {
    if (_opened) return;
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      _unavailable = true;
      _opened = true;
      return;
    }
    final db = FsSessionKernel.db;
    _ladder = PrefsSosLadderRepository(
      LocalStringKvStore(db, namespace: ladderNs),
    );
    _settings = DurableSosSettingsStore(
      LocalStringKvStore(db, namespace: settingsNs),
    );
    await _settings!.hydrate();
    _webUnlockRequests = PrefsWebUnlockRequestRepository(
      LocalStringKvStore(db, namespace: unlockNs),
    );
    _unavailable = false;
    _opened = true;
  }

  static Future<void> tryBind() async {
    try {
      await ensureOpen();
      if (!_unavailable && _settings != null) {
        rebindStage1SosSettingsStore(_settings!);
      }
    } catch (e, st) {
      debugPrint('SosPrefsRuntime.tryBind soft-fail: $e\n$st');
      _unavailable = true;
      _opened = true;
    }
  }

  static void resetForTest() {
    _opened = false;
    _unavailable = false;
    _ladder = null;
    _settings = null;
    _webUnlockRequests = null;
    rebindStage1SosSettingsStore(InMemorySosSettingsStore());
  }
}

/// Builds production WebUnlockService with Local KV request queue when available.
Future<WebUnlockService?> openWebUnlockServiceWithLocalQueue() async {
  await SosPrefsRuntime.ensureOpen();
  if (SosPrefsRuntime.unavailable ||
      SosPrefsRuntime.webUnlockRequests == null) {
    return null;
  }
  await Stage1WebFilterRuntime.ensureOpen();
  return WebUnlockService(
    requestRepository: SosPrefsRuntime.webUnlockRequests!,
    tempAllows: Stage1WebFilterRuntime.tempAllows,
    familyId: Stage1WebFilterRuntime.familyId,
    audit: stage1WebUnlockAudit,
    decisionBus: stage1WebUnlockDecisionBus,
  );
}
