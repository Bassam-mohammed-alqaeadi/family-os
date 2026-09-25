import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/day_board_bridge.dart';

/// WIR-03b — SCR-FAT-010 (لوحة اليوم) · SCR-FAT-019 (مركز التنبيهات) ·
/// SCR-FAT-020 (تفصيل التنبيه) على صفوف ADR-054 v6 الحقيقية.
void main() {
  group('day board + alerts over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      now = DateTime(2026, 9, 25, 12);
      dir = await Directory.systemTemp.createTemp('wir03b_');
      file = File('${dir.path}/wir03b.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> family({String id = 'fam_1'}) => db
        .into(db.families)
        .insert(
          FamiliesCompanion.insert(
            id: id,
            name: 'Family $id',
            ownerAccountId: 'acc_1',
            createdAt: Value(now),
          ),
        );

    Future<void> child(
      String id, {
      String familyId = 'fam_1',
      String? alias,
      int? birthYear,
      String avatar = 'lion',
      DateTime? createdAt,
    }) => db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: familyId,
            displayName: 'Child $id',
            alias: alias ?? '${id}_alias',
            birthYear: Value(birthYear),
            avatar: Value(avatar),
            createdAt: Value(createdAt ?? now.subtract(const Duration(days: 90))),
          ),
        );

    Future<void> device(
      String id, {
      required String childId,
      String familyId = 'fam_1',
    }) => db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            id: id,
            familyId: familyId,
            childId: Value(childId),
            mode: DeviceMode.childLocked,
            platform: 'android',
            pairedAt: Value(now.subtract(const Duration(days: 30))),
          ),
        );

    Future<void> health(
      String deviceId, {
      int? battery,
      String score = 'GOOD',
      Duration heartbeatAgo = const Duration(minutes: 5),
    }) => db
        .into(db.deviceHealths)
        .insert(
          DeviceHealthsCompanion.insert(
            deviceId: deviceId,
            batteryLevel: Value(battery),
            score: Value(score),
            lastHeartbeat: Value(now.subtract(heartbeatAgo)),
            updatedAt: Value(now.subtract(heartbeatAgo)),
          ),
        );

    Future<void> fence(String id, {String name = 'schoolGate'}) => db
        .into(db.geofences)
        .insert(
          GeofencesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            name: name,
            shape: GeofenceShape.circle,
            lat: 24.7,
            lon: 46.7,
            createdBy: 'acc_1',
          ),
        );

    Future<void> fenceEvent({
      required String geofenceId,
      required String childId,
      required GeofenceEventKind kind,
      required DateTime at,
    }) => db
        .into(db.geofenceEvents)
        .insert(
          GeofenceEventsCompanion.insert(
            geofenceId: geofenceId,
            childId: childId,
            kind: kind,
            occurredAt: at,
          ),
        );

    Future<void> earned({
      required String id,
      required String childId,
      required int minutes,
    }) => db
        .into(db.walletLedgerEntries)
        .insert(
          WalletLedgerEntriesCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            deltaMinutes: minutes,
            reason: 'challenge',
            createdAt: Value(now.subtract(const Duration(hours: 2))),
          ),
        );

    Future<void> memorized({
      required String id,
      required String childId,
      int progress = 50,
    }) => db
        .into(db.quranMemorizations)
        .insert(
          QuranMemorizationsCompanion.insert(
            id: id,
            childId: childId,
            surahRef: 'AlBaqarah',
            progress: Value(progress),
            updatedAt: Value(now),
          ),
        );

    Future<void> task(
      String id, {
      int rewardMinutes = 15,
    }) => db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: id,
            familyId: 'fam_1',
            titleRef: 'roomTidy',
            kind: 'CHORE',
            status: 'OPEN',
            rewardMinutes: Value(rewardMinutes),
            createdByAccount: 'acc_1',
            createdAt: Value(now.subtract(const Duration(hours: 4))),
          ),
        );

    Future<void> submission({
      required String id,
      required String childId,
      required String taskId,
      DateTime? reviewedAt,
    }) => db
        .into(db.taskSubmissions)
        .insert(
          TaskSubmissionsCompanion.insert(
            id: id,
            taskId: taskId,
            childId: childId,
            mediaRef: 'media_$id',
            submittedAt: Value(now.subtract(const Duration(hours: 1))),
            status: 'PENDING',
            reviewedAt: Value(reviewedAt),
          ),
        );

    Future<void> sos({
      required String id,
      required String childId,
      SosStatus status = SosStatus.active,
      DateTime? at,
    }) => db
        .into(db.sosAlerts)
        .insert(
          SosAlertsCompanion.insert(
            id: id,
            familyId: 'fam_1',
            childId: childId,
            triggeredAt: at ?? now.subtract(const Duration(minutes: 30)),
            status: status,
            requestId: 'req_$id',
          ),
        );

    // --- tests (added in the next edits) ---
    test('board: the roster, wallet, Quran and inbox are the family\'s own rows', () async {
      await family();
      await child('kid_1', birthYear: 2015);
      await child(
        'kid_2',
        avatar: 'cat',
        createdAt: now.subtract(const Duration(days: 80)),
      );
      await device('d_1', childId: 'kid_1');
      await health('d_1', battery: 84);
      await fence('gf_1', name: 'schoolGate');
      await fenceEvent(
        geofenceId: 'gf_1',
        childId: 'kid_1',
        kind: GeofenceEventKind.enter,
        at: DateTime(2026, 9, 25, 7, 30),
      );
      await earned(id: 'e_1', childId: 'kid_1', minutes: 45);
      // A spend is not an earning — the wallet line sums the positive entries.
      await earned(id: 'e_2', childId: 'kid_1', minutes: -10);
      await memorized(id: 'm_1', childId: 'kid_1', progress: 50);
      await task('t_1', rewardMinutes: 15);
      await submission(id: 's_1', childId: 'kid_1', taskId: 't_1');

      final board = await DriftDayBoardProjectionRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(board.children, hasLength(2));
      final first = board.children.first;
      expect(first.displayName, 'Child kid_1');
      expect(first.emoji, '🦁');
      expect(first.ageYears, 11);
      expect(first.locationLabel, 'schoolGate');
      expect(first.batteryLabel, '٨٤٪');
      expect(first.quranLabel, '٥٠٪');
      expect(first.walletLabel, '٤٥');
      // No allowance column in v6 — the countdown stays empty (declared).
      expect(first.timeLeftLabel, '');

      // A child with no device / rows keeps empty labels, never planted ones.
      final second = board.children.last;
      expect(second.displayName, 'Child kid_2');
      expect(second.batteryLabel, '');
      expect(second.quranLabel, '');
      expect(second.walletLabel, '٠');
      expect(second.locationLabel, '');

      // The inbox holds the submission still waiting for review.
      expect(board.pendingRequests, hasLength(1));
      expect(board.pendingRequests.single.id, 's_1');
      expect(board.pendingRequests.single.minutes, 15);
      expect(board.pendingRequests.single.inboxPath, '/scr-fat-033');
      expect(board.hasPending, isTrue);

      // A reviewed submission is not pending any more.
      await submission(
        id: 's_2',
        childId: 'kid_1',
        taskId: 't_1',
        reviewedAt: now,
      );
      final after = await DriftDayBoardProjectionRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(after.pendingRequests.map((p) => p.id), ['s_1']);

      // Fail-closed: no family row, no board.
      final stranger = await DriftDayBoardProjectionRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.children, isEmpty);
      expect(stranger.pendingRequests, isEmpty);
    });

    test('alerts hub: SOS, low battery and fence events land in their tiers', () async {
      await family();
      await child('kid_1');
      await child(
        'kid_2',
        avatar: 'cat',
        createdAt: now.subtract(const Duration(days: 80)),
      );
      await device('d_1', childId: 'kid_1');
      await health('d_1', battery: 84);
      await device('d_2', childId: 'kid_2');
      await health('d_2', battery: 15);
      await fence('gf_1', name: 'schoolGate');
      await fenceEvent(
        geofenceId: 'gf_1',
        childId: 'kid_1',
        kind: GeofenceEventKind.enter,
        at: DateTime(2026, 9, 25, 7, 30),
      );
      await fenceEvent(
        geofenceId: 'gf_1',
        childId: 'kid_2',
        kind: GeofenceEventKind.noShow,
        at: DateTime(2026, 9, 25, 8),
      );
      await sos(id: 'sos_1', childId: 'kid_1');
      // A resolved alert is history, not a live tier.
      await sos(id: 'sos_old', childId: 'kid_1', status: SosStatus.resolved);

      final snap = await DriftAlertsHubRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      ).load();
      expect(snap.critical, hasLength(1));
      final critical = snap.critical.single;
      expect(critical.id, 'sos_sos_1');
      // The child's own stored name and the row's own clock.
      expect(critical.title, 'Child kid_1');
      expect(critical.subtitle, '١١:٣٠');
      // The SOS flow is its own screen — this row never opens the detail kinds.
      expect(critical.isTappable, isFalse);

      final attention = snap.attention;
      expect(attention.map((a) => a.id), contains('battery_kid_2'));
      final battery = attention.firstWhere((a) => a.id == 'battery_kid_2');
      expect(battery.title, 'Child kid_2');
      expect(battery.subtitle, '١٥٪');
      expect(battery.alertKind, 'battery');
      expect(battery.isTappable, isTrue);
      expect(attention.map((a) => a.id), contains(startsWith('noshow_')));

      expect(snap.reassurance, hasLength(1));
      expect(snap.reassurance.single.title, 'schoolGate');
      expect(snap.reassurance.single.subtitle, 'Child kid_1');
      expect(snap.reassurance.single.alertKind, 'arrive');

      final stranger = await DriftAlertsHubRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      ).load();
      expect(stranger.isEmpty, isTrue);
    });

    test('alert detail: resolves the hub row and writes nothing it cannot stamp', () async {
      await family();
      await child('kid_1');
      await device('d_1', childId: 'kid_1');
      await health('d_1', battery: 15);
      await fence('gf_1', name: 'schoolGate');
      await fenceEvent(
        geofenceId: 'gf_1',
        childId: 'kid_1',
        kind: GeofenceEventKind.enter,
        at: DateTime(2026, 9, 25, 7, 30),
      );
      final event = (await db.select(db.geofenceEvents).get()).single;

      final repo = DriftAlertDetailRepository(
        db,
        familyId: 'fam_1',
        clock: () => now,
      );
      final battery = await repo.load(alertId: 'battery_kid_1');
      expect(battery, isNotNull);
      expect(battery!.kind, AlertDetailKind.battery);
      expect(battery.childId, 'kid_1');
      expect(battery.urgency, AlertUrgency.attention);
      expect(battery.title, 'Child kid_1');
      expect(battery.body, '١٥٪');

      final arrival = await repo.load(alertId: 'geo_${event.id}');
      expect(arrival, isNotNull);
      expect(arrival!.kind, AlertDetailKind.arrive);
      expect(arrival.childId, 'kid_1');
      expect(arrival.title, 'schoolGate');
      expect(arrival.body, contains('Child kid_1'));

      // Kind lookups answer from the same rows; categories with no v6 row
      // resolve to nothing instead of a planted alert (declared gap).
      expect((await repo.load(alertKind: 'battery'))?.childId, 'kid_1');
      expect((await repo.load(alertKind: 'arrive'))?.title, 'schoolGate');
      expect(await repo.load(alertKind: 'stranger'), isNull);
      expect(await repo.load(alertKind: 'games'), isNull);
      expect(await repo.load(alertId: 'unknown_9'), isNull);
      expect(await repo.load(), isNull);

      // A battery alert has no "done" column in v6: the action returns the
      // row's own state and writes nothing at all.
      final before = await db.select(db.deviceHealths).get();
      final done = await repo.markPrimaryDone('battery_kid_1');
      expect(done.primaryDone, isFalse);
      final after = await db.select(db.deviceHealths).get();
      expect(after.single.updatedAt, before.single.updatedAt);
      expect(await db.select(db.sosAlerts).get(), isEmpty);
      expect(await db.select(db.geofenceEvents).get(), hasLength(1));

      await expectLater(
        repo.markPrimaryDone('unknown_9'),
        throwsA(isA<StateError>()),
      );

      // Fail-closed: a scope that owns no family resolves nothing.
      final stranger = DriftAlertDetailRepository(
        db,
        familyId: 'fam_none',
        clock: () => now,
      );
      expect(await stranger.load(alertId: 'battery_kid_1'), isNull);
      expect(await stranger.load(alertKind: 'battery'), isNull);
    });

  });
}
