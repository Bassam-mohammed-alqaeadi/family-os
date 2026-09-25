import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/day_followup_bridge.dart';

/// DEV-9 — SCR-FAT-012's roster on the ADR-054 v6 rows: `child` holds the
/// roster, `device` + `device_health` hold link health, battery and the last
/// heartbeat, and `geofence` + `geofence_event` hold where the child was last
/// seen. Anything without a column stays empty and is declared.
void main() {
  group('SCR-FAT-012 roster over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('dev9_day_');
      file = File('${dir.path}/dev9_day.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child(
      String id, {
      String familyId = 'fam_1',
      required String displayName,
      String alias = '',
      int? birthYear,
      String avatar = 'lion',
      int daysOld = 90,
    }) => db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: displayName,
            alias: alias.isEmpty ? '${id}_alias' : alias,
            birthYear: Value(birthYear),
            avatar: Value(avatar),
            createdAt: Value(now.subtract(Duration(days: daysOld))),
          ),
        );

    Future<void> device(
      String id, {
      String familyId = 'fam_1',
      required String childId,
      DeviceMode mode = DeviceMode.childLocked,
    }) => db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: id,
            familyId: familyId,
            childId: Value(childId),
            mode: mode,
            platform: 'android',
            pairedAt: Value(now),
          ),
        );

    Future<void> health(
      String deviceId, {
      DateTime? lastHeartbeat,
      int? batteryLevel,
      String score = kHealthGood,
      String? reason,
    }) => db
        .into(db.deviceHealths)
        .insert(
          DeviceHealthsCompanion.insert(
            deviceId: deviceId,
            lastHeartbeat: Value(lastHeartbeat),
            batteryLevel: Value(batteryLevel),
            score: Value(score),
            reason: Value(reason),
            updatedAt: Value(now),
          ),
        );

    Future<void> fence(
      String id, {
      required String name,
      String? childId,
    }) => db
        .into(db.geofences)
        .insert(
          GeofencesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: Value(childId),
            name: name,
            shape: GeofenceShape.circle,
            lat: 24.7,
            lon: 46.7,
            createdBy: 'acc_1',
          ),
        );

    Future<void> enter(
      String geofenceId, {
      required String childId,
      DateTime? at,
      GeofenceEventKind kind = GeofenceEventKind.enter,
    }) => db
        .into(db.geofenceEvents)
        .insert(
          GeofenceEventsCompanion.insert(
            geofenceId: geofenceId,
            childId: childId,
            kind: kind,
            occurredAt: at ?? now,
          ),
        );

    DriftChildrenListRepository repo() => DriftChildrenListRepository(
      db,
      familyId: 'fam_1',
      clock: () => now,
    );

    test('the roster is the family own children with stored names', () async {
      await child('kid_2', displayName: 'الثاني', birthYear: 2015);
      await child('kid_1', displayName: 'الأول', birthYear: 2012, daysOld: 100);
      await child('kid_other', familyId: 'fam_2', displayName: 'آخر');

      final rows = await repo().listChildren(familyId: FamilyId('fam_1'));

      expect(rows, hasLength(2));
      // Creation order, not insertion order.
      expect(rows.map((r) => r.id).toList(), ['kid_1', 'kid_2']);
      expect(rows.first.displayName, 'الأول');
      expect(rows.first.ageYears, 2026 - 2012);
      // Rule 23 — the colour cycles by roster order, never by a planted name.
      expect(rows.map((r) => r.swatch).toList(), [
        DayChildSwatch.purple,
        DayChildSwatch.sky,
      ]);
      // No allowance column in v6 — the line stays empty, not invented.
      expect(rows.first.timeLeftLabel, '');
    });

    test('health, battery and last-seen come from the paired device row', () async {
      await child('kid_1', displayName: 'الأول', birthYear: 2012);
      await device('dev_1', childId: 'kid_1');
      await health(
        'dev_1',
        lastHeartbeat: now.subtract(const Duration(minutes: 30)),
        batteryLevel: 84,
      );
      await child('kid_2', displayName: 'الثاني', daysOld: 80);
      await device('dev_2', childId: 'kid_2');
      await health(
        'dev_2',
        lastHeartbeat: now.subtract(const Duration(hours: 40)),
        batteryLevel: 32,
        score: kHealthOffline,
        reason: 'no_heartbeat',
      );

      final rows = await repo().listChildren(familyId: FamilyId('fam_1'));

      expect(rows.first.health, ChildListHealth.excellent);
      expect(rows.first.warnRing, isFalse);
      expect(rows.first.batteryLabel, isNotEmpty);
      expect(rows.first.lastSeenLabel, 'tenMinAgo');
      // A stale heartbeat is a link at risk, and it says so.
      expect(rows.last.health, ChildListHealth.atRisk);
      expect(rows.last.warnRing, isTrue);
    });

    test('the place line is the last entered fence own name', () async {
      await child('kid_1', displayName: 'الأول');
      await fence('fence_1', name: 'المدرسة', childId: 'kid_1');
      await fence('fence_2', name: 'البيت', childId: 'kid_1');
      await enter('fence_2', childId: 'kid_1');
      await enter(
        'fence_1',
        childId: 'kid_1',
        at: now.subtract(const Duration(minutes: 5)),
      );
      // An exit is not where the child is now.
      await enter(
        'fence_1',
        childId: 'kid_1',
        at: now,
        kind: GeofenceEventKind.exit,
      );

      final rows = await repo().listChildren(familyId: FamilyId('fam_1'));

      expect(rows.single.locationLabel, 'البيت');
    });

    test('a child with no device keeps unknown values empty or at risk', () async {
      await child('kid_1', displayName: 'الأول', birthYear: null);

      final rows = await repo().listChildren(familyId: FamilyId('fam_1'));

      expect(rows.single.displayName, 'الأول');
      // An unknown birth year reads as unknown, never as a guessed age.
      expect(rows.single.ageYears, 0);
      expect(rows.single.batteryLabel, '');
      expect(rows.single.lastSeenLabel, '');
      expect(rows.single.locationLabel, '');
      expect(rows.single.health, ChildListHealth.atRisk);
    });

    test('an empty scope reads nothing, and a foreign family stays out', () async {
      await child('kid_other', familyId: 'fam_2', displayName: 'آخر');

      expect(await repo().listChildren(familyId: FamilyId('fam_1')), isEmpty);
      expect(
        await DriftChildrenListRepository(db, familyId: '', clock: () => now)
            .listChildren(),
        isEmpty,
      );
    });

    test('the shared-policies half is declared, never a planted value', () async {
      final repository = repo();
      final policies = await repository.loadSharedPolicies();

      expect(policies.bedtimeLabel, '');
      expect(policies.dailyCapHours, 4);

      // Declared gap: v6 holds no shared-policy row, so nothing is written.
      await repository.saveSharedPolicies(
        const SharedChildrenPolicies(bedtimeLabel: '21:30', dailyCapHours: 3),
      );
      final after = await repository.loadSharedPolicies();
      expect(after.bedtimeLabel, '');
      expect(after.dailyCapHours, 4);
      expect(Stage1RowVocabulary.unattributedAccount, 'unattributed');
    });
  });
}
