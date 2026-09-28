import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n12_devices/family_members_identity_repository.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_identity_repository.dart';
import 'package:family_os/features/n12_devices/mother_permission_level_repository.dart';

void main() {
  tearDown(() {
    resetStage1IdentityRuntimeForTest();
    resetStage1MotherPermissionLevelRepositoryForTest();
    resetStage1ChildrenListRepositoryForTest();
  });

  test('Identity mother level write projects to FAT-027 roster tag', () async {
    resetStage1IdentityRuntimeForTest();
    final stage = stage1IdentityRuntime;
    expect(stage.activeFamilyId.value, isNotEmpty);

    final motherId = MemberId(kStage1MotherMembershipId);
    expect(stage.motherPermissionLevel(motherId), MotherLevel.partner);

    final levelRepo = IdentityMotherPermissionLevelRepository(
      runtime: () => stage,
      membershipId: motherId,
    );
    expect(levelRepo.setLevel(MotherLevel.full), isTrue);
    expect(stage.motherPermissionLevel(motherId), MotherLevel.full);
    expect(levelRepo.level, MotherLevel.full);
    expect(levelRepo.auditLog, hasLength(1));

    final membersRepo = IdentityFamilyMembersRepository(runtime: () => stage);
    final members = await membersRepo.listMembers(
      familyId: stage.activeFamilyId.value,
    );
    final mother = members.singleWhere(
      (m) => m.id == kStage1MotherMembershipId,
    );
    expect(mother.motherLevel, MotherLevel.full);
  });

  test('stage1 rebind uses Identity-backed mother permission repo', () {
    rebindStage1MotherPermissionLevelRepository(
      IdentityMotherPermissionLevelRepository(),
    );
    final repo = stage1MotherPermissionLevelRepository;
    expect(repo, isA<IdentityMotherPermissionLevelRepository>());
    expect(repo.level, MotherLevel.partner);
    expect(repo.setLevel(MotherLevel.observer), isTrue);
    expect(
      stage1IdentityRuntime.motherPermissionLevel(
        MemberId(kStage1MotherMembershipId),
      ),
      MotherLevel.observer,
    );
  });
}
