import 'package:drift/drift.dart';

import 'communication_rules.dart';
import 'family_database.dart';

/// Rule 25 seam — the audit trail.
///
/// The contract says it in one line: "🔒 append-only — دليلنا عند أي مراجعة".
/// The server enforces that with a trigger; here there is simply no mutation
/// path, and [update] and [delete] exist only to refuse, so the rule can be
/// tested instead of assumed.
abstract class AuditRepository {
  /// Appends one entry. [actorId] null means the system acted, not a person.
  Future<int> append({
    required String familyId,
    required String action,
    String? actorId,
    String? target,
    String detail = '{}',
    DateTime? at,
  });

  Future<List<AuditLog>> forFamily(String familyId, {int limit = 200});

  Future<List<AuditLog>> byActor(
    String familyId,
    String actorId, {
    int limit = 100,
  });

  /// Always throws. Append-only is the point of this table.
  Future<void> update(int id, {required String action});

  /// Always throws. Append-only is the point of this table.
  Future<void> delete(int id);
}

final class DriftAuditRepository implements AuditRepository {
  DriftAuditRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<int> append({
    required String familyId,
    required String action,
    String? actorId,
    String? target,
    String detail = '{}',
    DateTime? at,
  }) async {
    // `detail` is `jsonb` in the contract — malformed text would travel all the
    // way to the server before failing, so it fails here instead. `async` so the
    // refusal arrives through the returned future like every other error.
    requireJson(detail);

    return _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            familyId: familyId,
            actor: Value(actorId),
            action: action,
            target: Value(target),
            detail: Value(detail),
            occurredAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<List<AuditLog>> forFamily(String familyId, {int limit = 200}) {
    return (_db.select(_db.auditLogs)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<List<AuditLog>> byActor(
    String familyId,
    String actorId, {
    int limit = 100,
  }) {
    return (_db.select(_db.auditLogs)
          ..where((t) => t.familyId.equals(familyId) & t.actor.equals(actorId))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
          ..limit(limit))
        .get();
  }

  @override
  Future<void> update(int id, {required String action}) async {
    throw UnsupportedError(
      'audit_log مُلحَق فقط — العقد: «append-only — دليلنا عند أي مراجعة». '
      'لا يُعدَّل الصف $id.',
    );
  }

  @override
  Future<void> delete(int id) async {
    throw UnsupportedError('audit_log مُلحَق فقط — لا يُحذف الصف $id.');
  }
}
