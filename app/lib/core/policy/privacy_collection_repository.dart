import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/role.dart';
import 'privacy_collection_policy.dart';
import 'web_unlock_service.dart' show AuditAppend;

/// Owner-only privacy collection writes (Rule 8 / SET-012).
bool canEditPrivacyCollection(AppRole role) => role == AppRole.father;

/// HTTP-style 403 when mother/child attempt privacy collection write.
@immutable
final class PrivacyCollectionDenied {
  const PrivacyCollectionDenied({
    required this.actor,
    this.statusCode = 403,
    this.message = 'PRIVACY_COLLECTION write denied',
  });

  final AppRole actor;
  final int statusCode;
  final String message;

  @override
  String toString() =>
      'PrivacyCollectionDenied($statusCode): $message actor=${actor.name}';
}

@immutable
sealed class PrivacyCollectionWriteResult {
  const PrivacyCollectionWriteResult();
}

final class PrivacyCollectionWriteOk extends PrivacyCollectionWriteResult {
  const PrivacyCollectionWriteOk(this.policy);
  final PrivacyCollectionPolicy policy;
}

final class PrivacyCollectionWriteDenied extends PrivacyCollectionWriteResult {
  const PrivacyCollectionWriteDenied(this.denied);
  final PrivacyCollectionDenied denied;
}

/// Rule 25 seam — privacy collection scopes for SET-012 (Drift deferred).
abstract class PrivacyCollectionRepository {
  Future<PrivacyCollectionPolicy> load(String childId);

  /// Persists only when [actor] is father; else denied (mother/child).
  Future<PrivacyCollectionWriteResult> save(
    PrivacyCollectionPolicy policy, {
    required AppRole actor,
  });

  AuditAppend get audit;
}

/// String KV used by [PrefsPrivacyCollectionRepository].
abstract class PrivacyCollectionPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across instances to simulate restart.
final class MemoryPrivacyCollectionPrefsStore
    implements PrivacyCollectionPrefsStore {
  MemoryPrivacyCollectionPrefsStore([Map<String, String>? data])
      : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared prefs store (survives within process).
PrivacyCollectionPrefsStore stage1PrivacyCollectionPrefsStore =
    MemoryPrivacyCollectionPrefsStore();

final AuditAppend stage1PrivacyCollectionAudit = AuditAppend();

void _appendDeniedAudit(
  AuditAppend audit,
  AppRole actor,
  String childId,
) {
  audit.add(
    '403 PRIVACY_COLLECTION write denied actor=${actor.name} child=$childId',
  );
}

PrivacyCollectionWriteResult _deny(
  AuditAppend audit,
  AppRole actor,
  String childId,
) {
  _appendDeniedAudit(audit, actor, childId);
  return PrivacyCollectionWriteDenied(
    PrivacyCollectionDenied(actor: actor),
  );
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsPrivacyCollectionRepository
    implements PrivacyCollectionRepository {
  PrefsPrivacyCollectionRepository(this._store, {AuditAppend? audit})
      : _audit = audit ?? AuditAppend();

  final PrivacyCollectionPrefsStore _store;
  final AuditAppend _audit;

  @override
  AuditAppend get audit => _audit;

  static String _key(String childId) => 'privacy_collection_scopes:$childId';

  @override
  Future<PrivacyCollectionPolicy> load(String childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return PrivacyCollectionPolicy.defaults(childId: childId);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return PrivacyCollectionPolicy.defaults(childId: childId);
    }
    final policy = PrivacyCollectionPolicy.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
    if (policy.childId != childId) {
      return policy.copyWith(childId: childId);
    }
    return policy;
  }

  @override
  Future<PrivacyCollectionWriteResult> save(
    PrivacyCollectionPolicy policy, {
    required AppRole actor,
  }) async {
    if (!canEditPrivacyCollection(actor)) {
      return _deny(_audit, actor, policy.childId);
    }
    final normalized = policy.copyWith(
      updatedAt: policy.updatedAt ?? DateTime.now().toUtc(),
    );
    await _store.write(
      _key(normalized.childId),
      jsonEncode(normalized.toJson()),
    );
    return PrivacyCollectionWriteOk(normalized);
  }
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryPrivacyCollectionRepository
    implements PrivacyCollectionRepository {
  InMemoryPrivacyCollectionRepository({
    Map<String, PrivacyCollectionPolicy>? seed,
    AuditAppend? audit,
  })  : _byChild = {
          if (seed != null)
            for (final e in seed.entries) e.key: e.value,
        },
        _audit = audit ?? AuditAppend();

  final Map<String, PrivacyCollectionPolicy> _byChild;
  final AuditAppend _audit;

  @override
  AuditAppend get audit => _audit;

  @override
  Future<PrivacyCollectionPolicy> load(String childId) async {
    return _byChild[childId] ??
        PrivacyCollectionPolicy.defaults(childId: childId);
  }

  @override
  Future<PrivacyCollectionWriteResult> save(
    PrivacyCollectionPolicy policy, {
    required AppRole actor,
  }) async {
    if (!canEditPrivacyCollection(actor)) {
      return _deny(_audit, actor, policy.childId);
    }
    final normalized = policy.copyWith(
      updatedAt: policy.updatedAt ?? DateTime.now().toUtc(),
    );
    _byChild[normalized.childId] = normalized;
    return PrivacyCollectionWriteOk(normalized);
  }

  @visibleForTesting
  Map<String, PrivacyCollectionPolicy> get debugSnapshot =>
      Map.unmodifiable(_byChild);
}
