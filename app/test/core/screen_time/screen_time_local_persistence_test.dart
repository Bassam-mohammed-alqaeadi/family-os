import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';

void main() {
  test('LocalScreenTimeKvPrefsStore refuses closed Memory DB', () async {
    final db = MemoryLocalDatabase();
    // Not opened — production must not silently fall back to Prefs.
    final store = LocalScreenTimeKvPrefsStore(
      db,
      namespace: ScreenTimeKvNamespaces.policy,
    );
    expect(() => store.write('k', 'v'), throwsA(isA<StateError>()));
  });

  test('policy round-trip on open MemoryLocalDatabase', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final repo = ScreenTimeLocalPersistence.policyRepository(db);
    final child = ChildId('c1');
    await repo.save(child, ScreenTimePolicy(dailyCapMinutes: 60));
    final loaded = await repo.load(child);
    expect(loaded.dailyCapMinutes, 60);
    await db.close();
  });
}
