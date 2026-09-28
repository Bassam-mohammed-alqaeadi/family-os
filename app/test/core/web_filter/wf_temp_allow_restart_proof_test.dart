import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/core/web_filter/web_filter_temp_allow.dart';
import 'package:family_os/core/web_filter/web_filter_temp_allow_store.dart';

/// AUTH-FS002-UNLOCK — timed allow survives real SQLite reopen + expiry.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('temp allow write→close→reopen→activeHosts; expires after timestamp',
      () async {
    final dir = await Directory.systemTemp.createTemp('fs_wf_unlock_');
    final path = p.join(dir.path, 'wf.db');
    final family = FamilyId('fam_wf');
    final child = ChildId('child_a');
    final starts = DateTime.utc(2026, 9, 24, 18);
    final expires = starts.add(const Duration(hours: 1));

    final db1 = await SqliteLocalDatabase.openAt(path);
    final store1 = LocalWebFilterTempAllowStore(db1, clock: () => starts);
    await store1.save(
      WebFilterTempAllow(
        id: 'ta_reopen',
        familyId: family,
        childId: child,
        host: 'adult.example',
        requestId: 'req_1',
        startsAt: starts,
        expiresAt: expires,
        status: WebFilterTempAllowStatus.active,
      ),
    );
    expect(
      await store1.activeHosts(family, child, now: starts.add(const Duration(minutes: 5))),
      {'adult.example'},
    );
    await db1.close();

    final db2 = await SqliteLocalDatabase.openAt(path);
    final store2 = LocalWebFilterTempAllowStore(db2);
    final mid = starts.add(const Duration(minutes: 30));
    expect(
      await store2.activeHosts(family, child, now: mid),
      {'adult.example'},
    );

    final after = expires.add(const Duration(minutes: 1));
    expect(await store2.activeHosts(family, child, now: after), isEmpty);
    final listed = await store2.listForChild(family, child);
    expect(listed.single.status, WebFilterTempAllowStatus.expired);

    await db2.close();
    await dir.delete(recursive: true);
  });
}
