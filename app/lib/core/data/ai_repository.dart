import 'package:drift/drift.dart';

import 'communication_rules.dart';
import 'family_database.dart';

/// Raised when a suggestion is applied, undone or dismissed outside the rules —
/// an undo after its ten minutes, or an apply that already happened.
class SuggestionStateException implements Exception {
  const SuggestionStateException(this.reason);

  final String reason;

  @override
  String toString() => 'ai_suggestion: $reason';
}

/// Rule 25 seam — what the AI layer observed, and what it suggested.
///
/// Two asymmetries are deliberate and structural:
///  · events are keyed by **alias**, never by name or child id (Rule 13/23);
///  · a suggestion is never executable — applying one records that a *person*
///    acted on it, and the ten-minute undo is a real window, not a UI state.
abstract class AiRepository {
  Future<int> recordEvent({
    required String familyId,
    required String childAlias,
    required String domain,
    required String kind,
    required int severity,
    String payload = '{}',
    DateTime? at,
  });

  Future<List<AiEvent>> eventsInFamily(
    String familyId, {
    String? childAlias,
    int limit = 200,
  });

  Future<List<AiEvent>> severeEventsInFamily(
    String familyId, {
    int minSeverity = 4,
    int limit = 100,
  });

  Future<AiSuggestionRow> addSuggestion({
    required String id,
    required String familyId,
    required String headline,
    required String actionLabel,
    required String actionKind,
    required AiConfidence confidence,
    String? childAlias,
    int? confidencePct,
    DateTime? at,
  });

  Future<AiSuggestionRow?> suggestionById(String id);

  Future<List<AiSuggestionRow>> suggestionsInFamily(
    String familyId, {
    int limit = 100,
  });

  Future<AiSuggestionRow> applySuggestion(String id, {DateTime? at});

  /// Only inside [kSuggestionUndoWindow] of the apply, and only once.
  Future<AiSuggestionRow> undoSuggestion(String id, {DateTime? at});

  Future<AiSuggestionRow> dismissSuggestion(String id, {DateTime? at});
}

final class DriftAiRepository implements AiRepository {
  DriftAiRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<int> recordEvent({
    required String familyId,
    required String childAlias,
    required String domain,
    required String kind,
    required int severity,
    String payload = '{}',
    DateTime? at,
  }) async {
    // Four rules from the contract, applied where the row is written: the alias
    // and never the name (Rule 13/23); the domain and severity from their sets;
    // and a payload that is an excerpt (S-AIC-006) and real JSON, because the
    // column is `jsonb`.
    //
    // Deliberately `async`: a refusal must arrive through the returned future,
    // so a caller that handles errors one way handles them all the same way.
    requireAlias(childAlias);
    requireDomain(domain);
    requireSeverity(severity);
    requireExcerpt(payload);
    requireJson(payload);

    return _db.into(_db.aiEvents).insert(
          AiEventsCompanion.insert(
            familyId: familyId,
            childAlias: childAlias,
            domain: domain,
            kind: kind,
            severity: severity,
            payload: Value(payload),
            occurredAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<List<AiEvent>> eventsInFamily(
    String familyId, {
    String? childAlias,
    int limit = 200,
  }) {
    final query = _db.select(_db.aiEvents)
      ..where((t) => t.familyId.equals(familyId))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    if (childAlias != null) {
      query.where((t) => t.childAlias.equals(childAlias));
    }
    return query.get();
  }

  @override
  Future<List<AiEvent>> severeEventsInFamily(
    String familyId, {
    int minSeverity = 4,
    int limit = 100,
  }) {
    return (_db.select(_db.aiEvents)
          ..where((t) =>
              t.familyId.equals(familyId) &
              t.severity.isBiggerOrEqualValue(minSeverity))
          ..orderBy([
            (t) => OrderingTerm.desc(t.severity),
            (t) => OrderingTerm.desc(t.occurredAt),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<AiSuggestionRow> addSuggestion({
    required String id,
    required String familyId,
    required String headline,
    required String actionLabel,
    required String actionKind,
    required AiConfidence confidence,
    String? childAlias,
    int? confidencePct,
    DateTime? at,
  }) async {
    requireAction(label: actionLabel, kind: actionKind);
    if (childAlias != null) requireAlias(childAlias);
    if (confidencePct != null && (confidencePct < 0 || confidencePct > 100)) {
      throw ArgumentError.value(confidencePct, 'confidencePct', '0..100');
    }

    await _db.into(_db.aiSuggestions).insertOnConflictUpdate(
          AiSuggestionsCompanion.insert(
            id: id,
            familyId: familyId,
            childAlias: Value(childAlias),
            headline: headline,
            actionLabel: actionLabel,
            actionKind: actionKind,
            confidence: confidence,
            confidencePct: Value(confidencePct),
            createdAt: Value(at ?? DateTime.now()),
          ),
        );
    return _requireSuggestion(id);
  }

  @override
  Future<AiSuggestionRow?> suggestionById(String id) {
    return (_db.select(_db.aiSuggestions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<AiSuggestionRow>> suggestionsInFamily(
    String familyId, {
    int limit = 100,
  }) {
    return (_db.select(_db.aiSuggestions)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  @override
  Future<AiSuggestionRow> applySuggestion(String id, {DateTime? at}) async {
    final suggestion = await _requireSuggestion(id);
    if (suggestion.appliedAt != null) {
      throw const SuggestionStateException('اقتراح مُطبَّق مسبقًا');
    }

    await _patch(
      id,
      AiSuggestionsCompanion(appliedAt: Value(at ?? DateTime.now())),
    );
    return _requireSuggestion(id);
  }

  @override
  Future<AiSuggestionRow> undoSuggestion(String id, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final suggestion = await _requireSuggestion(id);
    final appliedAt = suggestion.appliedAt;

    if (appliedAt == null) {
      throw const SuggestionStateException('لم يُطبَّق بعد — لا شيء للتراجع عنه');
    }
    if (!suggestionIsUndoable(
      appliedAt: appliedAt,
      now: now,
      undone: suggestion.undoneAt != null,
      dismissed: suggestion.dismissedAt != null,
    )) {
      throw const SuggestionStateException(
        'مضت نافذة التراجع (١٠ دقائق) أو سبق التراجع',
      );
    }

    await _patch(id, AiSuggestionsCompanion(undoneAt: Value(now)));
    return _requireSuggestion(id);
  }

  @override
  Future<AiSuggestionRow> dismissSuggestion(String id, {DateTime? at}) async {
    await _requireSuggestion(id);
    await _patch(
      id,
      AiSuggestionsCompanion(dismissedAt: Value(at ?? DateTime.now())),
    );
    return _requireSuggestion(id);
  }

  Future<void> _patch(String id, AiSuggestionsCompanion patch) {
    return (_db.update(_db.aiSuggestions)..where((t) => t.id.equals(id)))
        .write(patch);
  }

  Future<AiSuggestionRow> _requireSuggestion(String id) async {
    final suggestion = await suggestionById(id);
    if (suggestion == null) {
      throw ArgumentError.value(id, 'id', 'لا يوجد اقتراح بهذا المعرّف');
    }
    return suggestion;
  }
}
