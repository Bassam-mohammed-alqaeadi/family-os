import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/role.dart';
import 'anti_tamper_permission.dart';
import 'anti_tamper_policy.dart';
import 'web_unlock_service.dart' show AuditAppend;

/// HTTP-style 403 when non-father attempts AT write (SET-007).
@immutable
final class AntiTamperDenied {
  const AntiTamperDenied({
    required this.actor,
    this.statusCode = 403,
    this.message = 'ANTI_TAMPER configure denied',
  });

  final AppRole actor;
  final int statusCode;
  final String message;

  @override
  String toString() =>
      'AntiTamperDenied($statusCode): $message actor=${actor.name}';
}

/// Result of [AntiTamperRepository.write] / [AntiTamperRepository.save].
@immutable
sealed class AntiTamperWriteResult {
  const AntiTamperWriteResult();
}

final class AntiTamperWriteOk extends AntiTamperWriteResult {
  const AntiTamperWriteOk(this.policy);
  final AntiTamperPolicy policy;
}

final class AntiTamperWriteDenied extends AntiTamperWriteResult {
  const AntiTamperWriteDenied(this.denied);
  final AntiTamperDenied denied;
}

/// Rule 25 seam — anti-tamper policy for SET-007 (Drift deferred).
abstract class AntiTamperRepository {
  Future<AntiTamperPolicy> load(ChildId childId);

  /// Persists only when [actor] is father; else returns denied + audit (403).
  Future<AntiTamperWriteResult> write(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  });

  /// Alias for [write] (father session only).
  Future<AntiTamperWriteResult> save(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  }) =>
      write(childId, policy, actor: actor);

  AuditAppend get audit;
}

/// String KV used by [PrefsAntiTamperRepository].
abstract class AntiTamperPrefsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory prefs — share [data] across repo instances to simulate restart.
final class MemoryAntiTamperPrefsStore implements AntiTamperPrefsStore {
  MemoryAntiTamperPrefsStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared prefs store (survives within process; Rule 25 seam).
AntiTamperPrefsStore stage1AntiTamperPrefsStore = MemoryAntiTamperPrefsStore();

/// Stage-1 shared audit for AT write denials.
final AuditAppend stage1AntiTamperAudit = AuditAppend();

void _appendDeniedAudit(AuditAppend audit, AppRole actor, ChildId childId) {
  audit.add(
    '403 ANTI_TAMPER write denied actor=${actor.name} child=${childId.value}',
  );
}

AntiTamperWriteResult _deny(
  AuditAppend audit,
  AppRole actor,
  ChildId childId,
) {
  _appendDeniedAudit(audit, actor, childId);
  return AntiTamperWriteDenied(
    AntiTamperDenied(actor: actor),
  );
}

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsAntiTamperRepository implements AntiTamperRepository {
  PrefsAntiTamperRepository(this._store, {AuditAppend? audit})
      : _audit = audit ?? AuditAppend();

  final AntiTamperPrefsStore _store;
  final AuditAppend _audit;

  @override
  AuditAppend get audit => _audit;

  static String _key(ChildId childId) => 'anti_tamper_policy:${childId.value}';

  @override
  Future<AntiTamperPolicy> load(ChildId childId) async {
    final raw = await _store.read(_key(childId));
    if (raw == null || raw.isEmpty) {
      return AntiTamperPolicy.defaults();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return AntiTamperPolicy.defaults();
    return AntiTamperPolicy.fromJson(
      decoded.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  Future<AntiTamperWriteResult> write(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  }) async {
    if (!canConfigureAntiTamper(actor)) {
      return _deny(_audit, actor, childId);
    }
    final normalized = policy.copyWith(
      updatedAt: policy.updatedAt ?? DateTime.now().toUtc(),
    );
    await _store.write(_key(childId), jsonEncode(normalized.toJson()));
    return AntiTamperWriteOk(normalized);
  }

  @override
  Future<AntiTamperWriteResult> save(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  }) =>
      write(childId, policy, actor: actor);
}

/// Pure in-memory alternate for unit tests (Rule 25 fake).
final class InMemoryAntiTamperRepository implements AntiTamperRepository {
  InMemoryAntiTamperRepository({
    Map<String, AntiTamperPolicy>? seed,
    AuditAppend? audit,
  })  : _byChild = seed ?? {},
        _audit = audit ?? AuditAppend();

  final Map<String, AntiTamperPolicy> _byChild;
  final AuditAppend _audit;

  @override
  AuditAppend get audit => _audit;

  @override
  Future<AntiTamperPolicy> load(ChildId childId) async {
    return _byChild[childId.value] ?? AntiTamperPolicy.defaults();
  }

  @override
  Future<AntiTamperWriteResult> write(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  }) async {
    if (!canConfigureAntiTamper(actor)) {
      return _deny(_audit, actor, childId);
    }
    final normalized = policy.copyWith(
      updatedAt: policy.updatedAt ?? DateTime.now().toUtc(),
    );
    _byChild[childId.value] = normalized;
    return AntiTamperWriteOk(normalized);
  }

  @override
  Future<AntiTamperWriteResult> save(
    ChildId childId,
    AntiTamperPolicy policy, {
    required AppRole actor,
  }) =>
      write(childId, policy, actor: actor);
}
