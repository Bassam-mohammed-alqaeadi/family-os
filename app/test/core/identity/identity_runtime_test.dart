import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

void main() {
  IdentityRuntime buildRuntime() {
    final accountId = AccountId('acc_1');
    final famA = FamilyId('fam_a');
    final famB = FamilyId('fam_b');
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_1'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(id: famA, name: 'A', ownerMemberId: MemberId('mem_a')),
        Family(id: famB, name: 'B', ownerMemberId: MemberId('mem_b')),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_a'),
          accountId: accountId,
          familyId: famA,
          role: AppRole.father,
          isPrimaryOwner: true,
        ),
        FamilyMembership(
          id: MemberId('mem_b'),
          accountId: accountId,
          familyId: famB,
          role: AppRole.mother,
          motherLevel: MotherLevel.partner,
        ),
      ],
      activeFamilyId: famA,
      activeChildScope: ChildScope(familyId: famA, childId: ChildId('child_a')),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: FamilyId('fam_a')),
        ChildIdentity(id: ChildId('child_b'), familyId: FamilyId('fam_b')),
      ],
      devices: [
        DeviceIdentity(
          id: DeviceId('dev_1'),
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
        ),
      ],
      enrollments: [
        Enrollment(
          id: EnrollmentId('enr_1'),
          deviceId: DeviceId('dev_1'),
          familyId: famA,
          childId: ChildId('child_a'),
          createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
        ),
      ],
    );
  }

  test('resolves Session -> Membership -> Role authority chain', () {
    final runtime = buildRuntime();
    final auth = runtime.authorizationContext;
    expect(auth.activeFamily.sessionId, SessionId('sess_1'));
    expect(auth.activeFamily.accountId, AccountId('acc_1'));
    expect(auth.activeFamily.membershipId, MemberId('mem_a'));
    expect(auth.role, AppRole.father);
    expect(auth.canSetFamilyRules, isTrue);
  });

  test('supports multiple families per account and active family switching', () {
    final runtime = buildRuntime();
    expect(runtime.membershipsForAccount(AccountId('acc_1')), hasLength(2));
    runtime.switchActiveFamily(FamilyId('fam_b'));
    final auth = runtime.authorizationContext;
    expect(auth.activeFamily.familyId, FamilyId('fam_b'));
    expect(auth.role, AppRole.mother);
    expect(auth.motherLevel, MotherLevel.partner);
    expect(auth.canApproveChildRequests, isTrue);
    expect(auth.canSetFamilyRules, isFalse);
  });

  test('child identity cannot exist across multiple families', () {
    expect(
      () => IdentityRuntime(
        account: Account(id: AccountId('acc_2')),
        session: Session(
          id: SessionId('sess_2'),
          accountId: AccountId('acc_2'),
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        families: [
          Family(id: FamilyId('fam_1'), name: '1', ownerMemberId: MemberId('m1')),
          Family(id: FamilyId('fam_2'), name: '2', ownerMemberId: MemberId('m2')),
        ],
        memberships: [
          FamilyMembership(
            id: MemberId('m1'),
            accountId: AccountId('acc_2'),
            familyId: FamilyId('fam_1'),
            role: AppRole.father,
          ),
        ],
        activeFamilyId: FamilyId('fam_1'),
        activeChildScope: ChildScope(
          familyId: FamilyId('fam_1'),
          childId: ChildId('child_dup'),
        ),
        children: [
          ChildIdentity(id: ChildId('child_dup'), familyId: FamilyId('fam_1')),
          ChildIdentity(id: ChildId('child_dup'), familyId: FamilyId('fam_2')),
        ],
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test('enforces max 3 active devices per child', () {
    final runtime = buildRuntime();
    runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_2'),
      enrollmentId: EnrollmentId('enr_2'),
    );
    runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_3'),
      enrollmentId: EnrollmentId('enr_3'),
    );
    expect(
      () => runtime.createEnrollment(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
        deviceId: DeviceId('dev_4'),
        enrollmentId: EnrollmentId('enr_4'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test('device transfer requires revoke then re-enroll', () {
    final runtime = buildRuntime();
    expect(
      () => runtime.createEnrollment(
        familyId: FamilyId('fam_b'),
        childId: ChildId('child_b'),
        deviceId: DeviceId('dev_1'),
        enrollmentId: EnrollmentId('enr_x'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
    runtime.revokeEnrollment(EnrollmentId('enr_1'));
    final next = runtime.createEnrollment(
      familyId: FamilyId('fam_b'),
      childId: ChildId('child_b'),
      deviceId: DeviceId('dev_1'),
      enrollmentId: EnrollmentId('enr_2'),
    );
    expect(next.id, EnrollmentId('enr_2'));
  });

  test('enrollment identity remains distinct from device identity', () {
    final runtime = buildRuntime();
    runtime.revokeEnrollment(EnrollmentId('enr_1'));
    final reenrolled = runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_1'),
      enrollmentId: EnrollmentId('enr_new'),
    );
    expect(reenrolled.deviceId, DeviceId('dev_1'));
    expect(reenrolled.id, isNot(EnrollmentId('enr_1')));
  });

  test('child logout permission toggles OFF/ON', () {
    final runtime = buildRuntime();
    final scope = ChildScope(familyId: FamilyId('fam_a'), childId: ChildId('child_a'));
    expect(runtime.childLogoutAllowed(scope), isFalse);
    runtime.setChildLogoutAllowed(
      childId: ChildId('child_a'),
      familyId: FamilyId('fam_a'),
      allowed: true,
    );
    expect(runtime.childLogoutAllowed(scope), isTrue);
  });

  test('mother observer/partner/full permissions resolve correctly', () {
    final runtime = buildRuntime();
    runtime.switchActiveFamily(FamilyId('fam_b'));
    expect(runtime.authorizationContext.canApproveChildRequests, isTrue);
    expect(runtime.authorizationContext.canSetFamilyRules, isFalse);

    runtime.setLegacyRoleFallback(AppRole.mother);
    expect(runtime.authorizationContext.role, AppRole.mother);
  });

  test('blocks accidental cross-family child access', () {
    final runtime = buildRuntime();
    expect(
      runtime.canAccessChild(
        ChildScope(familyId: FamilyId('fam_a'), childId: ChildId('child_b')),
      ),
      isFalse,
    );
  });

  test('supports multiple sessions and switching active session', () {
    final runtime = buildRuntime();
    final nextId = runtime.startSession(accountId: AccountId('acc_1'));
    expect(runtime.sessions.length, greaterThanOrEqualTo(2));
    runtime.switchSession(nextId);
    expect(runtime.activeSessionId, nextId);
    expect(runtime.hasActiveSession, isTrue);
  });

  test('logout current session rotates to another active session', () {
    final runtime = buildRuntime();
    final first = runtime.activeSessionId;
    final nextId = runtime.startSession(accountId: AccountId('acc_1'));
    runtime.switchSession(nextId);
    final ok = runtime.logoutCurrentSession();
    expect(ok, isTrue);
    expect(runtime.activeSessionId, isNot(nextId));
    expect(runtime.activeSessionId, first);
  });

  test('logout all ends all sessions', () {
    final runtime = buildRuntime();
    runtime.startSession(accountId: AccountId('acc_1'));
    runtime.logoutAll();
    final allEnded = runtime.sessions.every((s) => s.endedAt != null);
    expect(allEnded, isTrue);
  });

  test('session expiry and restore flow', () {
    final runtime = buildRuntime();
    final id = runtime.startSession(accountId: AccountId('acc_1'));
    runtime.expireSession(id, at: DateTime.utc(2027, 1, 1));
    final restored = runtime.restoreSession(id);
    expect(restored, isTrue);
  });

  test('single-family account auto-opens family context', () {
    final account = AccountId('acc_single');
    final runtime = IdentityRuntime(
      account: Account(id: account),
      session: Session(
        id: SessionId('sess_single'),
        accountId: account,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_only'),
          name: 'Only',
          ownerMemberId: MemberId('owner_only'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('owner_only'),
          accountId: account,
          familyId: FamilyId('fam_only'),
          role: AppRole.father,
          tier: MembershipTier.primary,
          isPrimaryOwner: true,
        ),
      ],
      activeFamilyId: FamilyId('fam_only'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_only'),
        childId: ChildId('child_only'),
      ),
      children: [
        ChildIdentity(
          id: ChildId('child_only'),
          familyId: FamilyId('fam_only'),
        ),
      ],
    );
    expect(runtime.activeFamilyId, FamilyId('fam_only'));
    expect(runtime.needsFamilySelector, isFalse);
  });

  test('family switching persists active context and replaces child scope', () {
    final store = MemoryFamilyContextStore();
    final runtime = buildRuntime();
    final runtime2 = IdentityRuntime(
      account: runtime.account,
      session: runtime.session,
      families: runtime.families,
      memberships: runtime.membershipsForAccount(runtime.account.id),
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      children: runtime.children,
      familyContextStore: store,
    );
    runtime2.switchActiveFamily(FamilyId('fam_b'));
    expect(runtime2.activeFamilyId, FamilyId('fam_b'));
    expect(runtime2.activeChildScope.familyId, FamilyId('fam_b'));
  });

  test('membership-derived authorization boundaries observer/partner/full', () {
    final accountId = AccountId('acc_mother');
    IdentityRuntime runtimeFor(MotherLevel level) => IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_mother_${level.name}'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(
          id: FamilyId('fam_m'),
          name: 'F',
          ownerMemberId: MemberId('owner'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('m_obs'),
          accountId: accountId,
          familyId: FamilyId('fam_m'),
          role: AppRole.mother,
          tier: MembershipTier.coParent,
          motherLevel: level,
        ),
      ],
      activeFamilyId: FamilyId('fam_m'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_m'),
        childId: ChildId('child'),
      ),
      children: [
        ChildIdentity(id: ChildId('child'), familyId: FamilyId('fam_m')),
      ],
    );
    final observer = runtimeFor(MotherLevel.observer).authorizationContext;
    final partner = runtimeFor(MotherLevel.partner).authorizationContext;
    final full = runtimeFor(MotherLevel.full).authorizationContext;

    expect(observer.canApproveChildRequests, isFalse);
    expect(observer.canSetFamilyRules, isFalse);
    expect(partner.canApproveChildRequests, isTrue);
    expect(partner.canSetFamilyRules, isFalse);
    expect(full.canApproveChildRequests, isTrue);
    expect(full.canSetFamilyRules, isTrue);
  });
}
