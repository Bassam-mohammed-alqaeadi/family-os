import 'package:flutter/foundation.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/prefs_misc/kv_snapshot_store.dart';

/// Shared Local Quran/Athkar bridge (CE-B4 / P15-QUR-004…007).
///
/// Licensed mushaf/audio remain REMOTE_CLOSED — this only stores Local flags
/// and father↔child session signals (offline-ready, whisper, athkar blessing,
/// memorization review events).
final class QuranLocalBridge {
  QuranLocalBridge();

  /// Local offline-ready flag (not a claim that licensed audio downloaded).
  bool offlineReady = false;

  /// Father whisper pending for child ward (consume on child load).
  String? pendingWhisperKey;

  /// Athkar session completions for day-board blessing (P12).
  final List<String> athkarBlessings = [];

  /// Memorization review starts visible to father surfaces.
  final List<String> memorizationReviews = [];

  void markOfflineReady() {
    offlineReady = true;
  }

  void enqueueWhisper({String key = 'encourage'}) {
    pendingWhisperKey = key;
  }

  String? consumeWhisper() {
    final key = pendingWhisperKey;
    pendingWhisperKey = null;
    return key;
  }

  void recordAthkarComplete({String key = 'athkarDone'}) {
    athkarBlessings.add(key);
  }

  void recordMemorizationReview(String id) {
    memorizationReviews.add(id);
  }

  void resetForTests() {
    offlineReady = false;
    pendingWhisperKey = null;
    athkarBlessings.clear();
    memorizationReviews.clear();
  }

  Map<String, Object?> toJson() => {
    'offlineReady': offlineReady,
    'pendingWhisperKey': pendingWhisperKey,
    'athkarBlessings': List<String>.from(athkarBlessings),
    'memorizationReviews': List<String>.from(memorizationReviews),
  };

  void applyJson(Map<String, Object?> json) {
    offlineReady = json['offlineReady'] == true;
    pendingWhisperKey = json['pendingWhisperKey']?.toString();
    athkarBlessings
      ..clear()
      ..addAll(_stringList(json['athkarBlessings']));
    memorizationReviews
      ..clear()
      ..addAll(_stringList(json['memorizationReviews']));
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }
}

/// Process-wide Stage-1 bridge (same-session P12).
QuranLocalBridge stage1QuranLocalBridge = QuranLocalBridge();

void rebindStage1QuranLocalBridge(QuranLocalBridge bridge) {
  stage1QuranLocalBridge = bridge;
}

/// Durable offline-ready + whisper/athkar/memo journals via kv_store.
final class LocalQuranBridgeStore {
  LocalQuranBridgeStore(FamilyLocalDatabase db)
    : _store = KvSnapshotStore(db, namespace: kvNamespace);

  static const kvNamespace = 'quran_local';

  final KvSnapshotStore _store;

  Future<void> hydrate(QuranLocalBridge bridge) async {
    final map = await _store.readMap();
    if (map == null) return;
    bridge.applyJson(map);
  }

  Future<void> persist(QuranLocalBridge bridge) =>
      _store.writeMap(bridge.toJson());
}

/// LDR-B1 — hydrate [stage1QuranLocalBridge] from kv and keep a write-through store.
abstract final class QuranLocalPersistence {
  QuranLocalPersistence._();

  static LocalQuranBridgeStore? _store;

  static Future<void> tryBindStage1() async {
    try {
      await FsSessionKernel.ensureOpen();
      if (FsSessionKernel.sqliteFallbackToMemory) return;
      _store = LocalQuranBridgeStore(FsSessionKernel.db);
      await _store!.hydrate(stage1QuranLocalBridge);
    } catch (e, st) {
      debugPrint('LDR QuranLocalPersistence.tryBind soft-fail: $e\n$st');
    }
  }

  static Future<void> persistCurrent() async {
    final s = _store;
    if (s == null) return;
    await s.persist(stage1QuranLocalBridge);
  }

  static void resetForTest() {
    _store = null;
    stage1QuranLocalBridge = QuranLocalBridge();
  }
}
