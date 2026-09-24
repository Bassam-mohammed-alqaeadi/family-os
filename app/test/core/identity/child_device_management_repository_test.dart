import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

void main() {
  IdentityRuntime buildRuntime({
    AppRole role = AppRole.father,
    bool primary = true,
    MotherLevel? motherLevel,
  }) {
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
        Family(
          id: FamilyId('fam_b'),
          name: 'B',
          ownerMemberId: MemberId('mem_b'),
        ),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: FamilyId('fam_a'),
          role: role,
          tier: primary ? MembershipTier.primary : MembershipTier.coParent,
          motherLevel: motherLevel,
          isPrimaryOwner: primary,
        ),
      ],
      activeFamilyId: FamilyId('fam_a'),
      activeChildScope: ChildScope(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
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
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
          createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
          state: EnrollmentState.enrolled,
        ),
      ],
    );
  }

  test('repository scoping isolates children by family', () {
    final repo = RuntimeChildDeviceManagementRepository(
      runtime: buildRuntime(),
    );
    final a = repo.listChildren(FamilyId('fam_a'));
    final b = repo.listChildren(FamilyId('fam_b'));
    expect(a.map((it) => it.childId.value), ['child_a']);
    expect(b.map((it) => it.childId.value), ['child_b']);
  });

  test(
    'create/delete child authorization reflects primary and mother full',
    () {
      final primaryRepo = RuntimeChildDeviceManagementRepository(
        runtime: buildRuntime(),
      );
      final capPrimary = primaryRepo.capabilitiesFor(FamilyId('fam_a'));
      expect(capPrimary.canCreateChild, isTrue);
      expect(capPrimary.canDeleteChild, isTrue);

      final motherFullRepo = RuntimeChildDeviceManagementRepository(
        runtime: buildRuntime(
          role: AppRole.mother,
          primary: false,
          motherLevel: MotherLevel.full,
        ),
      );
      final capFull = motherFullRepo.capabilitiesFor(FamilyId('fam_a'));
      expect(capFull.canCreateChild, isTrue);
      expect(capFull.canDeleteChild, isFalse);
    },
  );

  test('re-enroll creates new enrollment id and keeps device identity', () {
    final runtime = buildRuntime();
    final repo = RuntimeChildDeviceManagementRepository(runtime: runtime);
    repo.closeEnrollment(
      enrollmentId: EnrollmentId('enr_1'),
      reason: EnrollmentCloseReason.revoked,
    );
    final reenrolled = repo.reEnroll(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_1'),
    );
    expect(reenrolled.id, isNot(EnrollmentId('enr_1')));
    expect(reenrolled.deviceId, DeviceId('dev_1'));
  });

  test('primary device switch does not mutate enrollment ids', () {
    final runtime = buildRuntime();
    final repo = RuntimeChildDeviceManagementRepository(runtime: runtime);
    runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_2'),
      enrollmentId: EnrollmentId('enr_2'),
    );
    final before = runtime.enrollments.map((it) => it.id).toSet();
    final switched = repo.setPrimaryDevice(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_2'),
    );
    final after = runtime.enrollments.map((it) => it.id).toSet();
    expect(switched, isTrue);
    expect(after, before);
  });

  test('observer/partner denied device mutations even via repository API', () {
    final observerRepo = RuntimeChildDeviceManagementRepository(
      runtime: buildRuntime(
        role: AppRole.mother,
        primary: false,
        motherLevel: MotherLevel.observer,
      ),
    );
    expect(
      () => observerRepo.startPairing(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
        deviceId: DeviceId('dev_obs'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
    expect(
      observerRepo.setPrimaryDevice(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
        deviceId: DeviceId('dev_1'),
      ),
      isFalse,
    );

    final partnerRepo = RuntimeChildDeviceManagementRepository(
      runtime: buildRuntime(
        role: AppRole.mother,
        primary: false,
        motherLevel: MotherLevel.partner,
      ),
    );
    expect(
      () => partnerRepo.closeEnrollment(
        enrollmentId: EnrollmentId('enr_1'),
        reason: EnrollmentCloseReason.revoked,
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test(
    'mother full can manage devices but not primary switch or remote end',
    () {
      final repo = RuntimeChildDeviceManagementRepository(
        runtime: buildRuntime(
          role: AppRole.mother,
          primary: false,
          motherLevel: MotherLevel.full,
        ),
      );
      final caps = repo.capabilitiesFor(FamilyId('fam_a'));
      expect(caps.canManageDevices, isTrue);
      expect(caps.canCloseNuclearEnrollment, isFalse);
      expect(caps.canChangePrimaryDevice, isFalse);
      expect(caps.canEndChildSession, isFalse);
      expect(
        repo.setPrimaryDevice(
          familyId: FamilyId('fam_a'),
          childId: ChildId('child_a'),
          deviceId: DeviceId('dev_1'),
        ),
        isFalse,
      );
      expect(repo.remoteEndChildSession(EnrollmentId('enr_1')), isFalse);
    },
  );

  test(
    'mother full denied mark-lost and revoke enrolled; primary succeeds',
    () {
      final motherFullRepo = RuntimeChildDeviceManagementRepository(
        runtime: buildRuntime(
          role: AppRole.mother,
          primary: false,
          motherLevel: MotherLevel.full,
        ),
      );
      expect(
        () => motherFullRepo.closeEnrollment(
          enrollmentId: EnrollmentId('enr_1'),
          reason: EnrollmentCloseReason.revoked,
        ),
        throwsA(isA<IdentityInvariantViolation>()),
      );
      expect(
        () => motherFullRepo.closeEnrollment(
          enrollmentId: EnrollmentId('enr_1'),
          reason: EnrollmentCloseReason.lost,
        ),
        throwsA(isA<IdentityInvariantViolation>()),
      );

      final primaryRuntime = buildRuntime();
      final primaryRepo = RuntimeChildDeviceManagementRepository(
        runtime: primaryRuntime,
      );
      primaryRepo.closeEnrollment(
        enrollmentId: EnrollmentId('enr_1'),
        reason: EnrollmentCloseReason.lost,
      );
      expect(
        primaryRuntime.enrollments
            .singleWhere((e) => e.id == EnrollmentId('enr_1'))
            .state,
        EnrollmentState.lost,
      );

      final primaryRuntime2 = buildRuntime();
      final primaryRepo2 = RuntimeChildDeviceManagementRepository(
        runtime: primaryRuntime2,
      );
      primaryRepo2.closeEnrollment(
        enrollmentId: EnrollmentId('enr_1'),
        reason: EnrollmentCloseReason.revoked,
      );
      expect(
        primaryRuntime2.enrollments
            .singleWhere((e) => e.id == EnrollmentId('enr_1'))
            .state,
        EnrollmentState.revoked,
      );
    },
  );

  test('mother full may cancel pending pairing token (renew path)', () {
    final runtime = buildRuntime(
      role: AppRole.mother,
      primary: false,
      motherLevel: MotherLevel.full,
    );
    final repo = RuntimeChildDeviceManagementRepository(runtime: runtime);
    final pending = repo.startPairing(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_pending'),
    );
    expect(pending.state, EnrollmentState.pairingPending);
    repo.closeEnrollment(
      enrollmentId: pending.id,
      reason: EnrollmentCloseReason.revoked,
    );
    expect(
      runtime.enrollments.singleWhere((e) => e.id == pending.id).state,
      EnrollmentState.revoked,
    );
  });
}
