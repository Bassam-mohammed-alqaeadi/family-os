import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/features/n11_billing/billing_ux_bridge.dart';

/// DEV-7 — the subscription screens (SCR-FAT-056 · SCR-FAT-057) over the
/// ADR-054 v6 rows: `subscription_state` + `billing_event`.
void main() {
  group('billing over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev7_');
      file = File('${dir.path}/dev7.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> subscription({
      required String id,
      String familyId = 'fam_1',
      String planRef = 'family_smart',
      String status = Stage1RowVocabulary.subStatusActive,
      DateTime? startedAt,
      DateTime? renewsAt,
      DateTime? periodEnd,
      DateTime? updatedAt,
    }) => db.into(db.subscriptionStates).insert(
      SubscriptionStatesCompanion.insert(
        id: id,
        familyId: familyId,
        planRef: planRef,
        status: status,
        startedAt: Value(startedAt ?? now),
        renewsAt: Value(renewsAt),
        periodEnd: Value(periodEnd),
        source: Stage1RowVocabulary.sourceSeed,
        updatedAt: Value(updatedAt ?? now),
      ),
    );

    DriftEntitlementService service({String familyId = 'fam_1', String? source}) =>
        DriftEntitlementService(
          db,
          familyId: familyId,
          source: source,
          clock: () => now,
        );

    test('the stored row is the plan', () async {
      await subscription(
        id: 'sub_1',
        renewsAt: DateTime(2026, 10, 24),
        periodEnd: DateTime(2026, 10, 24),
      );
      final seam = service();
      var notifications = 0;
      seam.addListener(() => notifications++);

      await seam.refresh();

      expect(seam.current.status, EntitlementStatus.active);
      expect(seam.current.planId, 'family_smart');
      expect(seam.current.autoRenew, isTrue);
      expect(seam.current.trialDaysRemaining, isNull);
      expect(notifications, 1);
    });

    test('a trial counts its days from the stored end', () async {
      await subscription(
        id: 'sub_trial',
        planRef: 'trial_full',
        status: Stage1RowVocabulary.subStatusTrial,
        periodEnd: DateTime(2026, 9, 29, 12),
      );

      final seam = service();
      await seam.refresh();

      expect(seam.current.status, EntitlementStatus.trial);
      expect(seam.current.planId, 'trial_full');
      expect(seam.current.trialDaysRemaining, 5);
    });

    test('no row means no paid plan, and another family stays separate', () async {
      await subscription(id: 'sub_other', familyId: 'fam_2');

      final mine = service();
      await mine.refresh();

      expect(mine.current.status, EntitlementStatus.expired);
      expect(mine.current.planId, 'basic_safety');
      expect(mine.current.autoRenew, isFalse);
      expect((await db.select(db.subscriptionStates).get()), hasLength(1));
    });

    test('a change leaves the state and the event that explains it', () async {
      final seam = service();
      await seam.refresh();

      seam.setEntitlement(Entitlement.activeFamily());
      await seam.lastWrite;

      var rows = await db.select(db.subscriptionStates).get();
      expect(rows, hasLength(1));
      expect(rows.single.status, Stage1RowVocabulary.subStatusActive);
      expect(rows.single.planRef, 'family_smart');
      expect(rows.single.renewsAt, isNotNull);
      expect(rows.single.source, Stage1RowVocabulary.sourceStore);

      var events = await db.select(db.billingEvents).get();
      expect(events, hasLength(1));
      expect(events.single.kind, Stage1RowVocabulary.billingSubscribe);
      expect(events.single.payloadDigest, 'family_smart:ACTIVE');

      // A second change updates the same row and adds a second event.
      seam.setEntitlement(Entitlement.trial(daysRemaining: 9));
      await seam.lastWrite;

      rows = await db.select(db.subscriptionStates).get();
      expect(rows, hasLength(1));
      expect(rows.single.planRef, 'trial_full');
      expect(rows.single.status, Stage1RowVocabulary.subStatusTrial);

      events = await db.select(db.billingEvents).get();
      expect(events, hasLength(2));
      expect(events.last.kind, Stage1RowVocabulary.billingChangePlan);

      await db.close();
      dbClosed = true;
      db = FamilyDatabase(NativeDatabase(file));

      final reopened = service();
      await reopened.refresh();
      expect(reopened.current.planId, 'trial_full', reason: 'ADR-042 — the row is the fact');
      expect(reopened.current.trialDaysRemaining, 9);
    });

    test('cancelling renewal ends the paid plan and is written down', () async {
      await subscription(id: 'sub_1', renewsAt: DateTime(2026, 10, 24));
      final seam = service();
      await seam.refresh();
      expect(seam.current.isActive, isTrue);

      await seam.cancelRenewal();

      expect(seam.current.status, EntitlementStatus.expired);
      expect(seam.current.planId, 'basic_safety');
      expect(seam.current.autoRenew, isFalse);
      expect(seam.current.trialDaysRemaining, isNull);

      final row = (await db.select(db.subscriptionStates).get()).single;
      expect(row.status, Stage1RowVocabulary.subStatusExpired);
      expect(row.planRef, 'basic_safety');
      expect(row.renewsAt, isNull);
      expect(row.periodEnd, isNull);

      final event = (await db.select(db.billingEvents).get()).single;
      expect(event.kind, Stage1RowVocabulary.billingCancelRenewal);

      final reopened = service();
      await reopened.refresh();
      expect(reopened.current.status, EntitlementStatus.expired);
    });

    test('an empty family scope never writes', () async {
      final seam = service(familyId: '');
      await seam.refresh();
      seam.setEntitlement(Entitlement.activeFamily());
      await seam.lastWrite;

      expect(seam.current.status, EntitlementStatus.expired);
      expect(await db.select(db.subscriptionStates).get(), isEmpty);
      expect(await db.select(db.billingEvents).get(), isEmpty);
    });

    test('the runtime shares one service for both screens', () async {
      Stage1BillingRuntime.resetForTest();
      Stage1BillingRuntime.ensureOpenSync(override: db);

      final first = Stage1BillingRuntime.service;
      expect(identical(first, Stage1BillingRuntime.service), isTrue);

      // No row for the acting family: the honest answer is «no paid plan».
      await (first as DriftEntitlementService).refresh();
      expect(first.current.status, EntitlementStatus.expired);
      expect(first.current.planId, 'basic_safety');

      Stage1BillingRuntime.resetForTest();
    });
  });
}
