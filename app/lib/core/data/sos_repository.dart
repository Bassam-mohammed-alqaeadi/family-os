import 'package:drift/drift.dart';

import 'family_database.dart';

/// Raised when a transition would rewrite settled history — acknowledging an
/// alarm that is already resolved, for instance.
class SosStateException implements Exception {
  const SosStateException(this.from, this.attempted);

  final SosStatus from;
  final String attempted;

  @override
  String toString() => 'sos_alert: cannot $attempted from ${from.name}';
}

/// Rule 25 seam — the emergency alarm.
///
/// The contract is blunt about what this table is: "🚨 لا يُحذف أبدًا · لا يعتمد
/// على اشتراك ولا صلاحية". So [remove] exists only to refuse, and the alarm has
/// no dependency on a fence, a schedule, or a permission row.
abstract class SosRepository {
  /// Raises an alarm. Re-sending with the same [requestId] returns the **same**
  /// alarm instead of creating a second one — "منع الازدواج عند إعادة الإرسال".
  Future<SosAlert> trigger({
    required String id,
    required String familyId,
    required String childId,
    required String requestId,
    DateTime? at,
    double? lat,
    double? lon,
  });

  Future<SosAlert?> byId(String id);

  Future<SosAlert?> byRequestId(String requestId);

  Future<List<SosAlert>> activeInFamily(String familyId);

  Future<List<SosAlert>> historyInFamily(String familyId, {int limit = 100});

  /// "I have seen it." Idempotent; refused once the alarm is resolved.
  Future<SosAlert> acknowledge(
    String id, {
    required String byAccountId,
    DateTime? at,
  });

  /// "It is over." Manual only — nothing closes an alarm automatically.
  Future<SosAlert> resolve(
    String id, {
    required String byAccountId,
    DateTime? at,
  });

  /// Always throws. The contract forbids deletion.
  Future<void> remove(String id);
}

final class DriftSosRepository implements SosRepository {
  DriftSosRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<SosAlert> trigger({
    required String id,
    required String familyId,
    required String childId,
    required String requestId,
    DateTime? at,
    double? lat,
    double? lon,
  }) async {
    // The contract's rule: a re-sent alert is the *same* alert. Checked first,
    // then again after a failed write — an emergency path must not fail because
    // it was retried, and must never produce two alarms for one press.
    final existing = await byRequestId(requestId);
    if (existing != null) return existing;

    try {
      await _db.into(_db.sosAlerts).insert(
            SosAlertsCompanion.insert(
              id: id,
              familyId: familyId,
              childId: childId,
              triggeredAt: at ?? DateTime.now(),
              lat: Value(lat),
              lon: Value(lon),
              status: SosStatus.active,
              requestId: requestId,
            ),
          );
    } on Exception {
      final raced = await byRequestId(requestId);
      if (raced != null) return raced;
      rethrow;
    }

    final stored = await byId(id);
    if (stored == null) {
      throw StateError('sos_alert $id لم يُكتب');
    }
    return stored;
  }

  @override
  Future<SosAlert?> byId(String id) {
    return (_db.select(_db.sosAlerts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<SosAlert?> byRequestId(String requestId) {
    return (_db.select(_db.sosAlerts)
          ..where((t) => t.requestId.equals(requestId)))
        .getSingleOrNull();
  }

  @override
  Future<List<SosAlert>> activeInFamily(String familyId) {
    return (_db.select(_db.sosAlerts)
          ..where((t) =>
              t.familyId.equals(familyId) &
              t.status.equalsValue(SosStatus.active))
          ..orderBy([(t) => OrderingTerm.desc(t.triggeredAt)]))
        .get();
  }

  @override
  Future<List<SosAlert>> historyInFamily(String familyId, {int limit = 100}) {
    return (_db.select(_db.sosAlerts)
          ..where((t) => t.familyId.equals(familyId))
          // `id` breaks timestamp ties so the order is total and reproducible.
          ..orderBy([
            (t) => OrderingTerm.desc(t.triggeredAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<SosAlert> acknowledge(
    String id, {
    required String byAccountId,
    DateTime? at,
  }) async {
    final alert = await _require(id);
    if (alert.status == SosStatus.resolved) {
      throw SosStateException(alert.status, 'acknowledge');
    }
    if (alert.status == SosStatus.acknowledged) return alert;

    await (_db.update(_db.sosAlerts)..where((t) => t.id.equals(id))).write(
      SosAlertsCompanion(
        status: const Value(SosStatus.acknowledged),
        acknowledgedBy: Value(byAccountId),
        acknowledgedAt: Value(at ?? DateTime.now()),
      ),
    );
    return _require(id);
  }

  @override
  Future<SosAlert> resolve(
    String id, {
    required String byAccountId,
    DateTime? at,
  }) async {
    final alert = await _require(id);
    if (alert.status == SosStatus.resolved) return alert;

    // Acknowledging is left untouched: both facts are kept, because "I saw it"
    // is part of the record even after the alarm is closed.
    await (_db.update(_db.sosAlerts)..where((t) => t.id.equals(id))).write(
      SosAlertsCompanion(
        status: const Value(SosStatus.resolved),
        resolvedBy: Value(byAccountId),
        resolvedAt: Value(at ?? DateTime.now()),
      ),
    );
    return _require(id);
  }

  @override
  Future<void> remove(String id) async {
    throw UnsupportedError(
      'sos_alert لا يُحذف أبدًا — العقد: «لا يعتمد على اشتراك ولا صلاحية»',
    );
  }

  Future<SosAlert> _require(String id) async {
    final alert = await byId(id);
    if (alert == null) {
      throw ArgumentError.value(id, 'id', 'لا توجد استغاثة بهذا المعرّف');
    }
    return alert;
  }
}
