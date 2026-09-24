import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

void main() {
  IdentityRuntime buildRuntime({
    AppRole role = AppRole.father,
    MotherLevel? motherLevel,
    bool primary = true,
  }) {
    final accountId = AccountId('acc_owner');
    final familyId = FamilyId('fam_a');
    return IdentityRuntime(
      account: Account(id: accountId),
      session: Session(
        id: SessionId('sess_owner'),
        accountId: accountId,
        startedAt: DateTime.utc(2026, 1, 1),
      ),
      families: [
        Family(id: familyId, name: 'A', ownerMemberId: MemberId('mem_owner')),
      ],
      memberships: [
        FamilyMembership(
          id: MemberId('mem_owner'),
          accountId: accountId,
          familyId: familyId,
          role: role,
          tier: primary ? MembershipTier.primary : MembershipTier.coParent,
          motherLevel: motherLevel,
          isPrimaryOwner: primary,
        ),
      ],
      activeFamilyId: familyId,
      activeChildScope: ChildScope(familyId: familyId, childId: ChildId('child_a')),
      children: [
        ChildIdentity(id: ChildId('child_a'), familyId: familyId),
      ],
      devices: [
        DeviceIdentity(
          id: DeviceId('dev_1'),
          familyId: familyId,
          childId: ChildId('child_a'),
        ),
      ],
      enrollments: [
        Enrollment(
          id: EnrollmentId('enr_1'),
          deviceId: DeviceId('dev_1'),
          familyId: familyId,
          childId: ChildId('child_a'),
          createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
          state: EnrollmentState.enrolled,
        ),
      ],
    );
  }

  test('primary and mother full can create child; observer/partner cannot', () {
    final primary = buildRuntime();
    final created = primary.createChild(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_new_primary'),
    );
    expect(created.familyId, FamilyId('fam_a'));

    final motherFull = buildRuntime(
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
      primary: false,
    );
    final createdByFull = motherFull.createChild(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_new_full'),
    );
    expect(createdByFull.id, ChildId('child_new_full'));

    final motherPartner = buildRuntime(
      role: AppRole.mother,
      motherLevel: MotherLevel.partner,
      primary: false,
    );
    expect(
      () => motherPartner.createChild(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_blocked_partner'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );

    final motherObserver = buildRuntime(
      role: AppRole.mother,
      motherLevel: MotherLevel.observer,
      primary: false,
    );
    expect(
      () => motherObserver.createChild(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_blocked_observer'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test('only primary can delete child', () {
    final primary = buildRuntime();
    primary.revokeEnrollment(EnrollmentId('enr_1'));
    final ok = primary.deleteChild(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
    );
    expect(ok, isTrue);

    final nonPrimary = buildRuntime(
      role: AppRole.mother,
      motherLevel: MotherLevel.full,
      primary: false,
    );
    expect(
      () => nonPrimary.deleteChild(
        familyId: FamilyId('fam_a'),
        childId: ChildId('child_a'),
      ),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test('enrollment lifecycle supports pairing -> enrolled -> revoked', () {
    final runtime = buildRuntime();
    runtime.revokeEnrollment(EnrollmentId('enr_1'));
    final pending = runtime.startPairing(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_1'),
    );
    expect(pending.state, EnrollmentState.pairingPending);
    expect(pending.pairingTokenId, isNotNull);

    final enrolled = runtime.finalizeEnrollment(pending.id);
    expect(enrolled.state, EnrollmentState.enrolled);

    runtime.revokeEnrollment(enrolled.id);
    final updated = runtime.enrollments.firstWhere((e) => e.id == enrolled.id);
    expect(updated.state, EnrollmentState.revoked);
  });

  test('re-enrollment creates new EnrollmentId distinct from DeviceId', () {
    final runtime = buildRuntime();
    runtime.revokeEnrollment(EnrollmentId('enr_1'));
    final next = runtime.createEnrollment(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_1'),
    );
    expect(next.id, isNot(EnrollmentId('enr_1')));
    expect(next.id.value, isNot(next.deviceId.value));
  });

  test('max 3 active enrolled devices per child', () {
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

  test('lost/decommissioned enrollment cannot regain authority automatically', () {
    final runtime = buildRuntime();
    runtime.markEnrollmentLost(EnrollmentId('enr_1'));
    expect(
      () => runtime.finalizeEnrollment(EnrollmentId('enr_1')),
      throwsA(isA<IdentityInvariantViolation>()),
    );

    runtime.revokeEnrollment(EnrollmentId('enr_1'));
    final pending = runtime.startPairing(
      familyId: FamilyId('fam_a'),
      childId: ChildId('child_a'),
      deviceId: DeviceId('dev_1'),
    );
    runtime.decommissionEnrollment(pending.id);
    expect(
      () => runtime.finalizeEnrollment(pending.id),
      throwsA(isA<IdentityInvariantViolation>()),
    );
  });

  test('child logout is enrollment-scoped OFF/ON and remote end is separate', () {
    final runtime = buildRuntime();
    expect(runtime.canChildLogout(EnrollmentId('enr_1')), isFalse);

    final changed = runtime.setChildLogoutAllowedForEnrollment(
      enrollmentId: EnrollmentId('enr_1'),
      allowed: true,
    );
    expect(changed, isTrue);
    expect(runtime.canChildLogout(EnrollmentId('enr_1')), isTrue);

    expect(runtime.isChildSessionEnded(EnrollmentId('enr_1')), isFalse);
    expect(runtime.endChildSessionRemotely(EnrollmentId('enr_1')), isTrue);
    expect(runtime.isChildSessionEnded(EnrollmentId('enr_1')), isTrue);
    // Logout permission toggle does not revoke enrollment.
    final enrollment =
        runtime.enrollments.firstWhere((e) => e.id == EnrollmentId('enr_1'));
    expect(enrollment.state, EnrollmentState.enrolled);
  });
}
