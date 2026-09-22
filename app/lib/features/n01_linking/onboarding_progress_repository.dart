import 'dart:convert';

import 'package:family_os/features/n01_linking/onboarding_progress_flags.dart';

/// Rule 25 seam — non-blocking onboarding progress for UI-002 (Drift deferred).
abstract class OnboardingProgressRepository {
  Future<OnboardingProgressFlags> load();

  Future<void> save(OnboardingProgressFlags flags);
}

/// String KV used by [PrefsOnboardingProgressRepository]
/// (SharedPreferences adapter-ready).
abstract class OnboardingProgressStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across instances to simulate restart / offline cache.
final class MemoryOnboardingProgressStore implements OnboardingProgressStore {
  MemoryOnboardingProgressStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Shared Stage-1 store (survives within process — offline shows last cache).
final MemoryOnboardingProgressStore stage1OnboardingProgressStore =
    MemoryOnboardingProgressStore();

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsOnboardingProgressRepository
    implements OnboardingProgressRepository {
  PrefsOnboardingProgressRepository(this._store);

  final OnboardingProgressStore _store;

  static const storageKey = 'onboarding_progress_flags';

  @override
  Future<OnboardingProgressFlags> load() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.isEmpty) {
      // Post-create default — still non-blocking if empty cache appears later.
      return OnboardingProgressFlags.afterFamilyCreate();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return OnboardingProgressFlags.afterFamilyCreate();
    }
    final map = <String, Object?>{
      for (final e in decoded.entries) e.key.toString(): e.value,
    };
    return OnboardingProgressFlags.fromJson(map);
  }

  @override
  Future<void> save(OnboardingProgressFlags flags) async {
    await _store.write(storageKey, jsonEncode(flags.toJson()));
  }
}

/// Pure in-memory alternate for unit/widget tests (Rule 25 fake).
final class InMemoryOnboardingProgressRepository
    implements OnboardingProgressRepository {
  InMemoryOnboardingProgressRepository([OnboardingProgressFlags? seed])
      : _flags = seed ?? OnboardingProgressFlags.afterFamilyCreate();

  OnboardingProgressFlags _flags;

  @override
  Future<OnboardingProgressFlags> load() async => _flags;

  @override
  Future<void> save(OnboardingProgressFlags flags) async {
    _flags = flags;
  }
}
