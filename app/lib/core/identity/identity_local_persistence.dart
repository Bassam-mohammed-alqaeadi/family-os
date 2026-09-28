import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n12_devices/family_members_identity_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Identity local KV namespaces (DOM-IDENTITY-A / B).
abstract final class IdentityKvNamespaces {
  static const familyContext = 'id_family_ctx';
  static const roster = 'id_roster';
}

/// Sync [FamilyContextStore] over `kv_store` with in-memory cache.
///
/// Call [hydrate] after open before using as IdentityRuntime store.
final class CachedKvFamilyContextStore implements FamilyContextStore {
  CachedKvFamilyContextStore(
    this._db, {
    this.namespace = IdentityKvNamespaces.familyContext,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FamilyLocalDatabase _db;
  final String namespace;
  final DateTime Function() _clock;
  final Map<String, String> _cache = {};

  static const _table = 'kv_store';

  /// Loads all rows in [namespace] into the sync cache.
  Future<void> hydrate() async {
    final rows = await _db.query(
      _table,
      where: 'namespace = ?',
      whereArgs: [namespace],
    );
    _cache
      ..clear()
      ..addEntries([
        for (final row in rows)
          MapEntry(
            row['key']! as String,
            row['value']! as String,
          ),
      ]);
  }

  @override
  FamilyId? loadActiveFamily(AccountId accountId) {
    final raw = _cache[accountId.value];
    if (raw == null || raw.trim().isEmpty) return null;
    return FamilyId(raw);
  }

  @override
  Future<void> saveActiveFamily(AccountId accountId, FamilyId familyId) async {
    _cache[accountId.value] = familyId.value;
    await _db.insert(
      _table,
      {
        'namespace': namespace,
        'key': accountId.value,
        'value': familyId.value,
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }
}

/// Composition helpers for identity Local KV (DOM-IDENTITY-A).
abstract final class IdentityLocalPersistence {
  IdentityLocalPersistence._();

  /// Opens session DB, refuses Memory fallback, returns hydrated family context.
  static Future<CachedKvFamilyContextStore> openFamilyContextStore() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-IDENTITY-A: FamilyContext refuses SQLite→Memory fallback '
        '(not restart-safe)',
      );
    }
    final store = CachedKvFamilyContextStore(FsSessionKernel.db);
    await store.hydrate();
    return store;
  }

  /// Binds [stage1IdentityRuntime] to Local KV family context.
  ///
  /// Returns `true` when Local KV bound. Returns `false` when refused/failed —
  /// default create keeps Memory [stage1FamilyContextStore] (process-RAM only;
  /// not restart-safe). Does not silently claim durability.
  static Future<bool> tryBindStage1FamilyContext() async {
    try {
      final store = await openFamilyContextStore();
      rebindStage1IdentityRuntime(familyContextStore: store);
      return true;
    } catch (e, st) {
      debugPrint(
        'DOM-IDENTITY-A: Local family context bind failed — '
        'Memory Prefs retained (not restart-safe): $e\n$st',
      );
      return false;
    }
  }

  /// Opens Local children display roster (`id_roster`); refuses Memory fallback.
  ///
  /// Seeds deterministic LOCAL DEMO rows when family keys are empty.
  static Future<LocalChildrenListRepository> openChildrenListRepository() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      throw StateError(
        'DOM-IDENTITY-B: Children roster refuses SQLite→Memory fallback '
        '(not restart-safe)',
      );
    }
    final repo = LocalChildrenListRepository(FsSessionKernel.db);
    await repo.ensureSeeded(ChildrenListLocalSeed.famStage1);
    await repo.ensureSeeded(ChildrenListLocalSeed.famStage2);
    await repo.ensurePoliciesSeeded();
    return repo;
  }

  /// Binds [stage1ChildrenListRepository] to Local KV roster.
  static Future<bool> tryBindStage1ChildrenList() async {
    try {
      final repo = await openChildrenListRepository();
      rebindStage1ChildrenListRepository(repo);
      return true;
    } catch (e, st) {
      debugPrint(
        'DOM-IDENTITY-B: Local children roster bind failed — '
        'InMemory retained (not restart-safe): $e\n$st',
      );
      return false;
    }
  }

  /// Binds FAT-027 family members to Identity + Local children projection.
  ///
  /// Safe even when children Local bind failed — projection still lists adults.
  static Future<bool> tryBindStage1FamilyMembers() async {
    try {
      rebindStage1FamilyMembersRepository(
        IdentityFamilyMembersRepository(),
      );
      return true;
    } catch (e, st) {
      debugPrint(
        'FE-W1-FAT-027: Family members Identity bind failed — '
        'InMemory empty retained: $e\n$st',
      );
      return false;
    }
  }
}
