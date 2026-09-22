import 'dart:convert';

import 'ai_stage_flags.dart';
import 'ai_stage_id.dart';

/// Rule 25 seam — AI stage flags from **server** remote config (SET-014).
///
/// Local cache is UI-only. There is **no** lawful path to unlock on-device
/// inference from the client (Bark: AI suggests, parent decides; Rule 26).
abstract class AiStageFlagsRepository {
  /// Last fetched flags for offline UI (may be null → treat as all off).
  AiStageFlags? get cachedFlags;

  /// Fetch from remote (mock server) and refresh local cache.
  Future<AiStageFlags> fetchFlags();

  /// Forbidden — local toggle cannot enable inference (SET-014).
  ///
  /// Always throws [UnsupportedError]. Kept as an explicit API so architecture
  /// tests and call sites fail loudly instead of silently enabling stages.
  Never setLocalEnableInference(AiStageId stage, {required bool enable});
}

/// String KV used by [MockRemoteAiStageFlags] local cache.
abstract class AiStageFlagsCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory cache — share [data] across instances to simulate restart.
final class MemoryAiStageFlagsCacheStore implements AiStageFlagsCacheStore {
  MemoryAiStageFlagsCacheStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Mock remote config + local cache (Stage-1 / Rule 26).
///
/// [simulateServerPush] is the **only** way to change flags — stands in for
/// server remote config. Client code must not invent a local unlock.
final class MockRemoteAiStageFlags implements AiStageFlagsRepository {
  MockRemoteAiStageFlags({
    AiStageFlags? initialServer,
    AiStageFlagsCacheStore? cache,
    this.prefsKey = 'ai_stage_flags_v1',
  })  : _server = initialServer ?? AiStageFlags.allOff(),
        _cacheStore = cache ?? MemoryAiStageFlagsCacheStore();

  static const _unsupported =
      'AI stages are server flags only (SET-014 / Rule 26). '
      'Local inference unlock is forbidden.';

  final AiStageFlagsCacheStore _cacheStore;
  final String prefsKey;

  AiStageFlags _server;
  AiStageFlags? _cached;

  /// Test/dev: push new remote-config values (simulates backend).
  void simulateServerPush(AiStageFlags flags) {
    _server = flags;
  }

  @override
  AiStageFlags? get cachedFlags => _cached;

  @override
  Future<AiStageFlags> fetchFlags() async {
    _cached = _server;
    await _persist(_server);
    return _server;
  }

  /// Hydrate UI from last cache without contacting server (offline).
  Future<AiStageFlags> loadCachedOrOff() async {
    final raw = await _cacheStore.read(prefsKey);
    if (raw == null || raw.isEmpty) {
      _cached = AiStageFlags.allOff();
      return _cached!;
    }
    _cached = _decode(raw);
    return _cached!;
  }

  @override
  Never setLocalEnableInference(AiStageId stage, {required bool enable}) {
    throw UnsupportedError(_unsupported);
  }

  Future<void> _persist(AiStageFlags flags) async {
    await _cacheStore.write(prefsKey, _encode(flags));
  }

  static String _encode(AiStageFlags flags) {
    final map = <String, bool>{
      for (final id in AiStageId.values) id.storageKey: flags.isEnabled(id),
    };
    return jsonEncode(map);
  }

  static AiStageFlags _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AiStageFlags.allOff();
      final map = <AiStageId, bool>{};
      for (final id in AiStageId.values) {
        final v = decoded[id.storageKey];
        map[id] = v == true;
      }
      return AiStageFlags.fromMap(map);
    } on Object {
      return AiStageFlags.allOff();
    }
  }
}

/// Stage-1 shared mock remote (process lifetime).
final MockRemoteAiStageFlags stage1AiStageFlags =
    MockRemoteAiStageFlags(
  initialServer: AiStageFlags.fromMap({
    AiStageId.suggest: true,
    AiStageId.analyze: false,
    AiStageId.coach: false,
  }),
);
