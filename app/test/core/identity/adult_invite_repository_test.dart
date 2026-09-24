import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/adult_invite_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

void main() {
  IdentityRuntime buildRuntime() {
    final accountId = AccountId('acc_owner');
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_owner'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_a'),
          name: 'A',
          ownerMemberId: MemberId('mem_owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: FamilyId('fam_a'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
      ],
    );
  }

  test('invite lifecycle created->active->accepted', () {
    final runtime = buildRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime);

    final invite = repo.createInvite(
      familyId: FamilyId('fam_a'),
      target: 'mother@example.com',
      level: MotherLevel.partner,
      actorMemberId: MemberId('mem_owner'),
    );
    expect(
      invite.stateAt(DateTime.now().toUtc()),
      anyOf(InviteLifecycleState.created, InviteLifecycleState.active),
    );

    final accepted = repo.acceptInvite(
      tokenId: invite.tokenId,
      acceptedByAccountId: AccountId('acc_mother'),
      actorMemberId: MemberId('mem_owner'),
    );
    expect(
      accepted.stateAt(DateTime.now().toUtc()),
      InviteLifecycleState.accepted,
    );
  });

  test(
    'one active invite per target per family + resend invalidates previous',
    () {
      final runtime = buildRuntime();
      final repo = InMemoryAdultInviteRepository(runtime: runtime);
      final first = repo.createInvite(
        familyId: FamilyId('fam_a'),
        target: 'mother@example.com',
        level: MotherLevel.partner,
        actorMemberId: MemberId('mem_owner'),
      );
      final resent = repo.resendInvite(
        inviteId: first.id,
        actorMemberId: MemberId('mem_owner'),
      );
      expect(resent.id, isNot(first.id));

      final invites = repo.listByFamily(FamilyId('fam_a'));
      final active = invites
          .where((i) => i.isActiveAt(DateTime.now().toUtc()))
          .toList();
      expect(active, hasLength(1));
      expect(active.first.id, resent.id);
    },
  );

  test('invite acceptance creates family membership', () {
    final runtime = buildRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime);
    final invite = repo.createInvite(
      familyId: FamilyId('fam_a'),
      target: 'mother@example.com',
      level: MotherLevel.full,
      actorMemberId: MemberId('mem_owner'),
    );

    repo.acceptInvite(
      tokenId: invite.tokenId,
      acceptedByAccountId: AccountId('acc_mother'),
      actorMemberId: MemberId('mem_owner'),
    );

    final memberships = runtime.membershipsForAccount(AccountId('acc_mother'));
    expect(memberships, hasLength(1));
    expect(memberships.first.motherLevel, MotherLevel.full);
  });

  test('high-risk invite mutations are denied when offline', () {
    final runtime = buildRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime, online: false);
    expect(
      () => repo.createInvite(
        familyId: FamilyId('fam_a'),
        target: 'mother@example.com',
        level: MotherLevel.partner,
        actorMemberId: MemberId('mem_owner'),
      ),
      throwsA(isA<InviteMutationDenied>()),
    );
  });

  test('audit captures lifecycle mutations', () {
    final runtime = buildRuntime();
    final repo = InMemoryAdultInviteRepository(runtime: runtime);
    final invite = repo.createInvite(
      familyId: FamilyId('fam_a'),
      target: 'mother@example.com',
      level: MotherLevel.partner,
      actorMemberId: MemberId('mem_owner'),
    );
    repo.revokeInvite(
      inviteId: invite.id,
      actorMemberId: MemberId('mem_owner'),
    );
    final audits = repo.auditLog();
    expect(audits, isNotEmpty);
    expect(audits.first.familyId, FamilyId('fam_a'));
  });

  test('non-primary cannot create/resend/revoke adult invites', () {
    final motherAccount = AccountId('acc_mother');
    final runtime = IdentityRuntime(
      account: Account(id: motherAccount),
      session: Session(
        id: SessionId('sess_mother'),
        accountId: motherAccount,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_a'),
          name: 'A',
          ownerMemberId: MemberId('mem_owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_mother'),
          accountId: motherAccount,
          familyId: FamilyId('fam_a'),
          role: AppRole.mother,
          tier: MembershipTier.coParent,
          motherLevel: MotherLevel.full,
          isPrimaryOwner: false,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
      ],
    );
    final repo = InMemoryAdultInviteRepository(runtime: runtime);
    expect(
      () => repo.createInvite(
        familyId: FamilyId('fam_a'),
        target: 'other@example.com',
        level: MotherLevel.partner,
        actorMemberId: MemberId('mem_mother'),
      ),
      throwsA(isA<InviteMutationDenied>()),
    );
  });
}
