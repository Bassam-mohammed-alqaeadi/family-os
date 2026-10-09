import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';
import 'package:family_os/features/n02_day/outer_circle_local_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_local_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_local_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LDR-B3 tasks seed is Minutes VO and idempotent', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final repo = LocalFamilyTasksRepository(db);
    await repo.ensureRealLocalSeeded();
    final snap = await repo.load();
    expect(snap.childTasks.length, 2);
    expect(snap.childTasks.first.reward.inMinutes, 15);
    expect(
      snap.pendingApproval.any(
        (t) => t.status == FamilyTaskStatus.pendingApproval,
      ),
      isTrue,
    );
    await repo.ensureRealLocalSeeded();
    expect((await repo.load()).childTasks.length, 2);
  });

  test('LDR-B3 calendar seed has events', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final repo = LocalFamilyCalendarRepository(db);
    await repo.ensureRealLocalSeeded();
    final snap = await repo.load();
    expect(snap.events, isNotEmpty);
    await repo.ensureRealLocalSeeded();
    expect((await repo.load()).events.length, snap.events.length);
  });

  test('LDR-B3 outer circle seed has relative friend pending', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final repo = LocalOuterCircleRepository(db);
    await repo.ensureRealLocalSeeded();
    final snap = await repo.load();
    expect(snap.relatives, isNotEmpty);
    expect(snap.friends, isNotEmpty);
    expect(snap.pending, isNotEmpty);
  });

  test('LDR-B3 chat sample messages are device-local only', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final store = FamilyChatLocalStore(db);
    final fid = FamilyId('fam_stage1');
    await store.ensureRealLocalSampleMessages(familyId: fid);
    final detail = await store.loadDetail(
      FamilyChatLocalStore.familyChatWith,
      familyId: fid,
    );
    expect(detail, isNotNull);
    expect(detail!.messages.length, 3);
    expect(detail.messages.every((m) => m.status.name == 'sent'), isTrue);
    await store.ensureRealLocalSampleMessages(familyId: fid);
    expect(
      (await store.loadDetail(
        FamilyChatLocalStore.familyChatWith,
        familyId: fid,
      ))!.messages.length,
      3,
    );
  });
}
