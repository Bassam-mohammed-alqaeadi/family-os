import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'screen_time_policy.dart';

/// Rule 25 seam — daily policy + wallets for SET-002 (Drift later).
abstract class ScreenTimePolicyRepository {
  /// Loads policy for [childId] (missing → [ScreenTimePolicy.defaults]).
  Future<ScreenTimePolicy> load(ChildId childId);

  /// Replaces the full policy for [childId].
  Future<void> save(ChildId childId, ScreenTimePolicy policy);
}

/// String KV used by [PrefsScreenTimePolicyRepository].
abstract class ScreenTimePolicyPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share the same [data] map across repo instances to
/// simulate process restart in tests.
final class MemoryScreenTimePolicyPrefsStore
    implements ScreenTimePolicyPrefsStore {
  MemoryScreenTimePolicyPrefsStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsScreenTimePolicyRepository
    implements ScreenTimePolicyRepository {
  PrefsScreenTimePolicyRepository(this._store);

  final ScreenTimePolicyPrefsStore _store;

  static String _key(ChildId childId) => 'screen_time_policy:${childId.value}';

  @override
  Future<ScreenTimePolicy> load(ChildId childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return ScreenTimePolicy.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return ScreenTimePolicy.defaults();
    return ScreenTimePolicy.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  Future<void> save(ChildId childId, ScreenTimePolicy policy) async {
    // Re-run through factory so S-1 education invariant is enforced on write.
    final normalized = ScreenTimePolicy(
      dailyCapMinutes: policy.dailyCapMinutes,
      allowWalletOverflow: policy.allowWalletOverflow,
      usedMinutesToday: policy.usedMinutesToday,
      wallets: [
        for (final w in policy.wallets)
          AppWallet(
            appId: w.appId,
            earnedMinutes: w.earnedMinutes,
            countable: w.countable,
          ),
      ],
    );
    await _store.write(_key(childId), jsonEncode(normalized.toJson()));
  }
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryScreenTimePolicyRepository
    implements ScreenTimePolicyRepository {
  InMemoryScreenTimePolicyRepository([Map<String, ScreenTimePolicy>? seed])
      : _byChild = seed ?? {};

  final Map<String, ScreenTimePolicy> _byChild;

  @override
  Future<ScreenTimePolicy> load(ChildId childId) async {
    return _byChild[childId.value] ?? ScreenTimePolicy.defaults();
  }

  @override
  Future<void> save(ChildId childId, ScreenTimePolicy policy) async {
    final normalized = ScreenTimePolicy(
      dailyCapMinutes: policy.dailyCapMinutes,
      allowWalletOverflow: policy.allowWalletOverflow,
      usedMinutesToday: policy.usedMinutesToday,
      wallets: [
        for (final w in policy.wallets)
          AppWallet(
            appId: w.appId,
            earnedMinutes: w.earnedMinutes,
            countable: w.countable,
          ),
      ],
    );
    _byChild[childId.value] = normalized;
  }
}

/// Snapshot helper TimeEngine can read (SET-002 Stage-1).
@immutable
final class ScreenTimePolicySnapshot {
  const ScreenTimePolicySnapshot(this.policy);

  final ScreenTimePolicy policy;

  AppWallet? walletFor(String appId) => policy.walletFor(appId);

  bool get isCapExhausted => policy.isCapExhausted;

  bool get allowWalletOverflow => policy.allowWalletOverflow;
}
