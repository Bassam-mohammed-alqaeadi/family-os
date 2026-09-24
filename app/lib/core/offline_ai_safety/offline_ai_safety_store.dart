import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

import 'safety_models.dart';

abstract class OfflineAiSafetyRepository {
  Future<void> saveModel(FamilyId familyId, SignedModelManifest model);
  Future<SignedModelManifest?> activeModel(FamilyId familyId);
  Future<void> saveSignal(SafetySignal signal);
  Future<SafetySignal?> getSignal(String id);
  Future<List<SafetySignal>> listSignals(FamilyId familyId, {ChildId? childId});
  Future<void> saveTicket(SafetyTicket ticket);
  Future<SafetyTicket?> getTicket(String id);
  Future<List<SafetyTicket>> listTickets(FamilyId familyId);
  Future<void> saveSuggestion(SafetySuggestion suggestion);
  Future<List<SafetySuggestion>> listSuggestions({
    required FamilyId familyId,
    String? ticketId,
  });
  Future<void> appendAudit({
    required String id,
    required FamilyId familyId,
    required String eventType,
    required DateTime at,
    String? actorId,
    String payloadJson = '{}',
  });
  Future<List<Map<String, Object?>>> listAudit(FamilyId familyId);
}

/// SQLite / memory-backed FS-007 store (schema v10).
final class LocalOfflineAiSafetyStore implements OfflineAiSafetyRepository {
  LocalOfflineAiSafetyStore(this._db);

  final FamilyLocalDatabase _db;

  static const _models = 'ai_model_manifest';
  static const _signals = 'ai_safety_signal';
  static const _tickets = 'ai_safety_ticket';
  static const _suggestions = 'ai_safety_suggestion';
  static const _audit = 'ai_safety_audit';

  @override
  Future<void> saveModel(FamilyId familyId, SignedModelManifest model) async {
    if (model.active) {
      final existing = await _db.query(
        _models,
        where: 'family_id = ?',
        whereArgs: [familyId.value],
      );
      for (final row in existing) {
        final id = row['model_id']! as String;
        if (id == model.modelId) continue;
        await _db.insert(
          _models,
          {
            ...row,
            'active': 0,
          },
          conflictAlgorithm: LocalConflictAlgorithm.replace,
        );
      }
    }
    await _db.insert(
      _models,
      model.toRow(familyId),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<SignedModelManifest?> activeModel(FamilyId familyId) async {
    final rows = await _db.query(
      _models,
      where: 'family_id = ? AND active = ?',
      whereArgs: [familyId.value, 1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SignedModelManifest.fromRow(rows.first);
  }

  @override
  Future<void> saveSignal(SafetySignal signal) async {
    await _db.insert(
      _signals,
      signal.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<SafetySignal?> getSignal(String id) async {
    final rows = await _db.query(
      _signals,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SafetySignal.fromRow(rows.first);
  }

  @override
  Future<List<SafetySignal>> listSignals(
    FamilyId familyId, {
    ChildId? childId,
  }) async {
    if (childId == null) {
      final rows = await _db.query(
        _signals,
        where: 'family_id = ?',
        whereArgs: [familyId.value],
        orderBy: 'created_at DESC',
      );
      return [for (final r in rows) SafetySignal.fromRow(r)];
    }
    final rows = await _db.query(
      _signals,
      where: 'family_id = ? AND child_id = ?',
      whereArgs: [familyId.value, childId.value],
      orderBy: 'created_at DESC',
    );
    return [for (final r in rows) SafetySignal.fromRow(r)];
  }

  @override
  Future<void> saveTicket(SafetyTicket ticket) async {
    await _db.insert(
      _tickets,
      ticket.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<SafetyTicket?> getTicket(String id) async {
    final rows = await _db.query(
      _tickets,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SafetyTicket.fromRow(rows.first);
  }

  @override
  Future<List<SafetyTicket>> listTickets(FamilyId familyId) async {
    final rows = await _db.query(
      _tickets,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'created_at DESC',
    );
    return [for (final r in rows) SafetyTicket.fromRow(r)];
  }

  @override
  Future<void> saveSuggestion(SafetySuggestion suggestion) async {
    await _db.insert(
      _suggestions,
      suggestion.toRow(),
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SafetySuggestion>> listSuggestions({
    required FamilyId familyId,
    String? ticketId,
  }) async {
    if (ticketId == null) {
      final rows = await _db.query(
        _suggestions,
        where: 'family_id = ?',
        whereArgs: [familyId.value],
        orderBy: 'created_at DESC',
      );
      return [for (final r in rows) SafetySuggestion.fromRow(r)];
    }
    final rows = await _db.query(
      _suggestions,
      where: 'family_id = ? AND ticket_id = ?',
      whereArgs: [familyId.value, ticketId],
      orderBy: 'created_at DESC',
    );
    return [for (final r in rows) SafetySuggestion.fromRow(r)];
  }

  @override
  Future<void> appendAudit({
    required String id,
    required FamilyId familyId,
    required String eventType,
    required DateTime at,
    String? actorId,
    String payloadJson = '{}',
  }) async {
    await _db.insert(
      _audit,
      {
        'id': id,
        'family_id': familyId.value,
        'event_type': eventType,
        'at_ms': at.toUtc().millisecondsSinceEpoch,
        'actor_id': actorId,
        'payload_json': payloadJson,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, Object?>>> listAudit(FamilyId familyId) {
    return _db.query(
      _audit,
      where: 'family_id = ?',
      whereArgs: [familyId.value],
      orderBy: 'at_ms ASC',
    );
  }
}
