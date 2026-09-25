import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/entitlement_service.dart';

/// Stage-2 composition root for billing (ADR-054 §11.5).
///
/// The subscription is the one place where the honest answer to "what is my
/// plan?" is a row: `subscription_state` holds the current state and every
/// change leaves a `billing_event` behind. Safety surfaces never read this —
/// SOS, chat and location stay outside the paywall by design (Rule 9 · P-4).
final class Stage1BillingRuntime {
  Stage1BillingRuntime._();

  static FamilyDatabase? _db;
  static DriftEntitlementService? _service;

  static FamilyDatabase ensureOpenSync({FamilyDatabase? override}) {
    if (override != null) {
      _db = override;
      _service = null;
      return override;
    }
    final existing = _db;
    if (existing != null) return existing;
    final opened = FamilyDatabase(NativeDatabase.memory());
    _db = opened;
    return opened;
  }

  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    ensureOpenSync(override: override);
  }

  /// SCR-FAT-056 / SCR-FAT-057 — one service for the whole process, so the two
  /// billing screens always read the same state. The first call also starts the
  /// read from the rows; [ChangeNotifier] tells the screens when it lands.
  static EntitlementService get service {
    final existing = _service;
    if (existing != null) return existing;
    final opened = DriftEntitlementService(ensureOpenSync());
    _service = opened;
    opened.refresh();
    return opened;
  }

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() {
    _service = null;
    _db = null;
  }
}

/// The real entitlement seam: reads `subscription_state`, and every change
/// writes both the new state and the `billing_event` that explains it.
///
/// `EntitlementService.current` is synchronous by contract, so the row is read
/// into an in-memory snapshot and [refresh] re-reads it. Before the first read
/// the honest answer is "no paid plan" — the safety banner never depends on it.
final class DriftEntitlementService extends ChangeNotifier
    implements EntitlementService {
  DriftEntitlementService(
    this._db, {
    String? familyId,
    String? source,
    DateTime Function()? clock,
  }) : _familyIdArg = familyId?.trim(),
       _source = (source ?? Stage1RowVocabulary.sourceStore).trim(),
       clock = clock ?? DateTime.now,
       _current = Entitlement.expired();

  final FamilyDatabase _db;
  final String? _familyIdArg;
  final String _source;
  final DateTime Function() clock;

  Entitlement _current;

  /// The write behind the last change — for callers that must know the row
  /// landed (the contract's `setEntitlement` is synchronous).
  Future<void>? lastWrite;

  String get familyId =>
      (_familyIdArg ?? stage1IdentityRuntime.activeFamilyId.value).trim();

  @override
  Entitlement get current => _current;

  /// Re-reads the family's own row. An unowned or empty scope keeps the honest
  /// "no paid plan" snapshot instead of borrowing another family's plan.
  Future<void> refresh() async {
    final row = await _currentRow();
    final next = row == null ? Entitlement.expired() : _toEntitlement(row);
    _current = next;
    notifyListeners();
  }

  @override
  void setEntitlement(Entitlement value) {
    // Fail-closed: with no family the service neither claims nor writes a plan.
    if (familyId.isEmpty) return;
    final previous = _current;
    _current = value;
    notifyListeners();
    lastWrite = _persist(value, previous: previous);
  }

  @override
  Future<void> cancelRenewal() async {
    // Cancel renew → the paid state ends; safety is unaffected by design (P-4).
    setEntitlement(
      _current.copyWith(
        status: EntitlementStatus.expired,
        planId: 'basic_safety',
        autoRenew: false,
        clearTrialDays: true,
      ),
    );
    await lastWrite;
  }

  Future<SubscriptionState?> _currentRow() async {
    if (familyId.isEmpty) return null;
    return (_db.select(_db.subscriptionStates)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// One row per family — the state is current, the events are history.
  Future<void> _persist(Entitlement value, {required Entitlement previous}) async {
    if (familyId.isEmpty) return;
    final now = clock();
    final status = _statusOf(value.status);
    final existing = await _currentRow();
    final companion = SubscriptionStatesCompanion(
      planRef: Value(value.planId),
      status: Value(status),
      renewsAt: Value(value.autoRenew ? _periodEnd(value, now) : null),
      periodEnd: Value(_periodEnd(value, now)),
      source: Value(_source),
      updatedAt: Value(now),
    );
    if (existing == null) {
      await _db
          .into(_db.subscriptionStates)
          .insert(
            SubscriptionStatesCompanion.insert(
              id: stage1RowId('sub', now),
              familyId: familyId,
              planRef: value.planId,
              status: status,
              startedAt: Value(now),
              renewsAt: Value(value.autoRenew ? _periodEnd(value, now) : null),
              periodEnd: Value(_periodEnd(value, now)),
              source: _source,
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(
        _db.subscriptionStates,
      )..where((t) => t.id.equals(existing.id))).write(companion);
    }

    await _db
        .into(_db.billingEvents)
        .insert(
          BillingEventsCompanion.insert(
            id: stage1RowId('bill', now),
            familyId: familyId,
            kind: _eventKindFor(value, previous),
            occurredAt: Value(now),
            // The digest is the plan+status the event explains — never a
            // receipt the store did not send.
            payloadDigest: Value('${value.planId}:$status'),
          ),
        );
  }

  /// The trial's end is the stored period end, so the remaining days are read
  /// from the clock rather than kept as a counter in the UI.
  static DateTime? _periodEnd(Entitlement value, DateTime now) {
    return switch (value.status) {
      EntitlementStatus.active => DateTime(now.year, now.month + 1, now.day),
      // The trial's end keeps the clock's time of day, so the days read back
      // are the days that were granted.
      EntitlementStatus.trial => now.add(
        Duration(days: value.trialDaysRemaining ?? 0),
      ),
      EntitlementStatus.expired => null,
    };
  }

  Entitlement _toEntitlement(SubscriptionState row) {
    final status = switch (row.status.trim().toUpperCase()) {
      Stage1RowVocabulary.subStatusActive => EntitlementStatus.active,
      Stage1RowVocabulary.subStatusTrial => EntitlementStatus.trial,
      _ => EntitlementStatus.expired,
    };
    return Entitlement(
      status: status,
      planId: row.planRef,
      trialDaysRemaining: status == EntitlementStatus.trial
          ? _daysLeft(row.periodEnd ?? row.renewsAt)
          : null,
      // The contract keeps no auto-renew column: a plan that has not ended is
      // the one still renewing.
      autoRenew: status != EntitlementStatus.expired,
    );
  }

  int? _daysLeft(DateTime? end) {
    if (end == null) return null;
    final days = end.difference(clock()).inDays;
    return days < 0 ? 0 : days;
  }

  static String _statusOf(EntitlementStatus status) => switch (status) {
    EntitlementStatus.active => Stage1RowVocabulary.subStatusActive,
    EntitlementStatus.trial => Stage1RowVocabulary.subStatusTrial,
    EntitlementStatus.expired => Stage1RowVocabulary.subStatusExpired,
  };

  static String _eventKindFor(Entitlement value, Entitlement previous) {
    if (value.status == EntitlementStatus.expired &&
        value.planId == 'basic_safety') {
      return Stage1RowVocabulary.billingCancelRenewal;
    }
    if (value.planId != previous.planId) {
      return previous.status == EntitlementStatus.expired &&
              previous.planId == 'basic_safety'
          ? Stage1RowVocabulary.billingSubscribe
          : Stage1RowVocabulary.billingChangePlan;
    }
    return Stage1RowVocabulary.billingStatusChange;
  }
}
