import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/policy/schedule_window.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

/// DOM-ST-01 — real SQLite write→close→reopen for ST foundation (Option A).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('ScreenTimePolicy survives SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st01_policy_');
    final path = p.join(dir.path, 'st.db');
    final child = ChildId('child_a');

    final db1 = await SqliteLocalDatabase.openAt(path);
    final repo1 = ScreenTimeLocalPersistence.policyRepository(db1);
    final policy = ScreenTimePolicy(
      dailyCapMinutes: 90,
      allowWalletOverflow: true,
      usedMinutesToday: 12,
      wallets: [
        AppWallet(appId: 'yt', earnedMinutes: Minutes(15), countable: true),
      ],
    );
    await repo1.save(child, policy);
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final repo2 = ScreenTimeLocalPersistence.policyRepository(db2);
    final loaded = await repo2.load(child);
    expect(loaded.dailyCapMinutes, 90);
    expect(loaded.allowWalletOverflow, isTrue);
    expect(loaded.usedMinutesToday, 12);
    expect(loaded.wallets.single.appId, 'yt');
    expect(loaded.wallets.single.earnedMinutes.inMinutes, 15);

    await db2.close();
    await dir.delete(recursive: true);
  });

  test('ScheduleWindow survives SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st01_sched_');
    final path = p.join(dir.path, 'st.db');
    final child = ChildId('child_b');

    final windows = [
      const ScheduleWindow(
        kind: ScheduleKind.sleep,
        enabled: true,
        start: TimeOfDay(hour: 21, minute: 0),
        end: TimeOfDay(hour: 22, minute: 30),
      ),
      const ScheduleWindow(kind: ScheduleKind.prayer, enabled: false),
      const ScheduleWindow(
        kind: ScheduleKind.study,
        enabled: true,
        start: TimeOfDay(hour: 16, minute: 0),
        end: TimeOfDay(hour: 18, minute: 0),
      ),
    ];

    final db1 = await SqliteLocalDatabase.openAt(path);
    await ScreenTimeLocalPersistence.scheduleRepository(
      db1,
    ).save(child, windows);
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final loaded = await ScreenTimeLocalPersistence.scheduleRepository(
      db2,
    ).load(child);
    expect(loaded.length, 3);
    final sleep = loaded.firstWhere((w) => w.kind == ScheduleKind.sleep);
    expect(sleep.enabled, isTrue);
    expect(ScheduleWindow.toMinutes(sleep.start), 21 * 60);
    expect(ScheduleWindow.toMinutes(sleep.end), 22 * 60 + 30);
    expect(
      loaded.firstWhere((w) => w.kind == ScheduleKind.study).enabled,
      isTrue,
    );
    expect(
      loaded.firstWhere((w) => w.kind == ScheduleKind.prayer).enabled,
      isFalse,
    );

    await db2.close();
    await dir.delete(recursive: true);
  });

  test('TimeRequest pending/decided survives SQLite reopen', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st01_req_');
    final path = p.join(dir.path, 'st.db');
    final child = ChildId('child_c');
    final created = DateTime.utc(2026, 9, 24, 18);

    final pending = TimeRequest(
      id: 'tr_pending',
      childId: child,
      requestedMinutes: 20,
      childReason: 'homework done',
      status: TimeRequestStatus.pending,
      createdAt: created,
    );
    final decided = TimeRequest(
      id: 'tr_decided',
      childId: child,
      requestedMinutes: 30,
      status: TimeRequestStatus.approved,
      createdAt: created,
      decidedBy: 'father',
      grantedMinutes: 30,
    );

    final db1 = await SqliteLocalDatabase.openAt(path);
    final repo1 = ScreenTimeLocalPersistence.timeRequestRepository(db1);
    await repo1.saveAll([pending, decided]);
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final repo2 = ScreenTimeLocalPersistence.timeRequestRepository(db2);
    final all = await repo2.loadAll();
    expect(all.length, 2);
    expect(
      all.firstWhere((r) => r.id == 'tr_pending').status,
      TimeRequestStatus.pending,
    );
    final ok = all.firstWhere((r) => r.id == 'tr_decided');
    expect(ok.status, TimeRequestStatus.approved);
    expect(ok.grantedMinutes, 30);
    expect(ok.decidedBy, 'father');

    await db2.close();
    await dir.delete(recursive: true);
  });

  test('TimeGrant survives reopen; expiry remains authoritative', () async {
    final dir = await Directory.systemTemp.createTemp('dom_st01_grant_');
    final path = p.join(dir.path, 'st.db');
    final child = ChildId('child_d');
    final created = DateTime.utc(2026, 9, 24, 10);
    final expires = DateTime.utc(2026, 9, 24, 22);

    final grant = TimeGrant(
      id: 'tg_1',
      requestId: 'tr_1',
      childId: child,
      minutes: 45,
      remainingMinutes: 40,
      grantedBy: 'father',
      createdAt: created,
      expiresAt: expires,
      status: TimeGrantStatus.active,
    );

    final db1 = await SqliteLocalDatabase.openAt(path);
    await ScreenTimeLocalPersistence.timeRequestRepository(
      db1,
    ).saveGrant(grant);
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final grants = await ScreenTimeLocalPersistence.timeRequestRepository(
      db2,
    ).loadGrants();
    expect(grants.single.id, 'tg_1');
    expect(grants.single.expiresAt, expires);
    expect(grants.single.remainingMinutes, 40);

    final mid = DateTime.utc(2026, 9, 24, 15);
    expect(grants.single.isActiveAt(mid), isTrue);

    final after = DateTime.utc(2026, 9, 24, 22, 1);
    expect(grants.single.isActiveAt(after), isFalse);

    await db2.close();
    await dir.delete(recursive: true);
  });
}
