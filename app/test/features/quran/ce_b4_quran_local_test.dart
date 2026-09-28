import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n14_studio/quran_progress_repository.dart';
import 'package:family_os/features/n17_child_learn/child_athkar_repository.dart';
import 'package:family_os/features/n17_child_learn/child_memorization_repository.dart';
import 'package:family_os/features/n17_child_learn/child_quran_ward_repository.dart';
import 'package:family_os/features/quran/quran_local_bridge.dart';

/// CE-B4 — Quran Local GapClose 004–007 (Q-CEX-004).
void main() {
  late QuranLocalBridge bridge;

  setUp(() {
    bridge = QuranLocalBridge();
  });

  test('QUR-004 download sets shared offlineReady (Local flag only)', () async {
    final father = InMemoryQuranProgressRepository(
      seed: quranProgressOneFixture().copyWith(offlineReady: false),
      bridge: bridge,
    );
    final child = InMemoryChildQuranWardRepository(
      seed: childQuranWardOneFixture().copyWith(offlineReady: false),
      bridge: bridge,
    );

    expect((await father.load()).offlineReady, isFalse);
    await father.requestDownload();
    expect(bridge.offlineReady, isTrue);
    expect((await father.load()).offlineReady, isTrue);
    expect((await child.load()).offlineReady, isTrue);
  });

  test('QUR-007 whisper reaches child gift count', () async {
    final father = InMemoryQuranProgressRepository(bridge: bridge);
    final child = InMemoryChildQuranWardRepository(
      seed: childQuranWardOneFixture().copyWith(giftCount: 0),
      bridge: bridge,
    );

    await father.whisperEncourage();
    final snap = await child.load();
    expect(snap.giftCount, 1);
    expect(bridge.pendingWhisperKey, isNull);
  });

  test('QUR-005 athkar complete records day-board blessing', () async {
    final athkar = InMemoryChildAthkarRepository(
      seed: childAthkarOneFixture(),
      bridge: bridge,
    );
    await athkar.markSaid();
    await athkar.markSaid();
    await athkar.markSaid();
    expect(bridge.athkarBlessings, isNotEmpty);
  });

  test('QUR-006 memorization review visible on Local bridge', () async {
    final memo = InMemoryChildMemorizationRepository(bridge: bridge);
    await memo.startReview('r1');
    expect(bridge.memorizationReviews, ['r1']);
  });

  test('Local bridge KV restart proof for offlineReady', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final store = LocalQuranBridgeStore(db);
    bridge.markOfflineReady();
    bridge.enqueueWhisper();
    await store.persist(bridge);

    final restored = QuranLocalBridge();
    await store.hydrate(restored);
    expect(restored.offlineReady, isTrue);
    expect(restored.pendingWhisperKey, 'encourage');
  });
}
