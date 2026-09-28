import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';

/// VX-B6 / OD-09 — family thread seeded from Local DB; no planted messages.
void main() {
  test('seed family thread with zero messages; send persists across reload',
      () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final runtime = IdentityRuntime(
      account: Account(id: AccountId('acc_chat')),
      session: Session(
        id: SessionId('sess_chat'),
        accountId: AccountId('acc_chat'),
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_chat'),
          name: 'C',
          ownerMemberId: MemberId('mem_chat'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_chat'),
          accountId: AccountId('acc_chat'),
          familyId: FamilyId('fam_chat'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_chat'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_chat'),
        childId: ChildId('child_chat'),
      ),
      children: [
        ChildIdentity(
          id: ChildId('child_chat'),
          familyId: FamilyId('fam_chat'),
        ),
      ],
    );

    final a = FamilyChatLocalStore(db, runtime: () => runtime);
    await a.ensureFamilyThreadSeeded();
    final snap = await a.loadThreads();
    expect(snap.threads, hasLength(1));
    expect(snap.threads.single.chatWith, FamilyChatLocalStore.familyChatWith);
    expect(snap.threads.single.pinned, isTrue);

    final detail = await a.loadDetail(FamilyChatLocalStore.familyChatWith);
    expect(detail, isNotNull);
    expect(detail!.messages, isEmpty);

    await a.send(
      FamilyChatLocalStore.familyChatWith,
      'hello family',
      timeLabel: 'now',
    );

    final b = FamilyChatLocalStore(db, runtime: () => runtime);
    final again = await b.loadDetail(FamilyChatLocalStore.familyChatWith);
    expect(again!.messages, hasLength(1));
    expect(again.messages.single.body, 'hello family');
    expect(again.messages.single.isMine, isTrue);

    final threads = await b.loadThreads();
    expect(threads.threads.single.preview, 'hello family');
  });
}
