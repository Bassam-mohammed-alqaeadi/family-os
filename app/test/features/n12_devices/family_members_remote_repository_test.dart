import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_remote_repository.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';
import 'package:family_os/foundation_gate/family_membership_api_client.dart';

const familyId = '11111111-1111-4111-8111-111111111111';

FoundationGateMembership membership({
  required String id,
  required String role,
  required String status,
  bool isSelf = false,
}) {
  return FoundationGateMembership(
    id: id,
    role: role,
    status: status,
    statusReasonCode: null,
    version: 1,
    isSelf: isSelf,
    joinedAt: null,
    statusChangedAt: null,
    createdAt: DateTime.utc(2026, 10, 7),
  );
}

void main() {
  RemoteFamilyMembersRepository repositoryWith(
    List<FoundationGateMembership> memberships, {
    ChildrenListRepository? children,
  }) {
    return RemoteFamilyMembersRepository(
      loadMemberships: (FamilyId family) async => memberships,
      children: children ?? InMemoryChildrenListRepository(),
    );
  }

  test('the server roster becomes the guardian roster, self included', () async {
    final repository = repositoryWith([
      membership(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        role: 'primary_guardian',
        status: 'active',
        isSelf: true,
      ),
      membership(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        role: 'co_guardian',
        status: 'invited',
      ),
    ]);

    final rows = await repository.listMembers(familyId: familyId);

    expect(rows, hasLength(2));
    expect(rows.first.kind, FamilyMemberKind.owner);
    expect(rows.first.isSelf, isTrue);
    expect(rows.first.membershipStatus, FamilyMembershipStatus.active);
    expect(rows.last.kind, FamilyMemberKind.mother);
    expect(rows.last.isSelf, isFalse);
    expect(
      rows.last.membershipStatus,
      FamilyMembershipStatus.invited,
      reason: 'a pending invitation must be distinguishable from a member',
    );
    expect(
      rows.last.motherLevel,
      isNull,
      reason: 'the membership endpoint publishes no permission level, and inventing one '
          'would read as a privilege the owner never granted',
    );
  });

  test('a role this client cannot name is dropped, never relabelled', () async {
    final repository = repositoryWith([
      membership(
        id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        role: 'child',
        status: 'active',
      ),
      membership(
        id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        role: 'grandparent',
        status: 'active',
      ),
      membership(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        role: 'child',
        status: 'invited',
      ),
    ]);

    final rows = await repository.listMembers(familyId: familyId);

    // The unknown role is gone. The active child membership is represented by the child's
    // own profile row, which arrives from the children roster. The pending child
    // invitation has no profile yet, so it is the one that must still be visible.
    expect(rows, hasLength(1));
    expect(rows.single.id, 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee');
    expect(rows.single.kind, FamilyMemberKind.child);
    expect(rows.single.membershipStatus, FamilyMembershipStatus.invited);
  });

  test('children come from the children roster beside the memberships', () async {
    final repository = repositoryWith(
      [
        membership(
          id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
          role: 'primary_guardian',
          status: 'active',
          isSelf: true,
        ),
      ],
      children: InMemoryChildrenListRepository(
        children: const [
          ChildrenListEntry(
            id: 'child-1',
            displayName: 'أمانة',
            ageYears: 9,
            emoji: '🧒',
            swatch: DayChildSwatch.sky,
            locationLabel: 'البيت',
            lastSeenLabel: 'الآن',
            batteryLabel: '٨٠٪',
            timeLeftLabel: '١٤٠ د',
            health: ChildListHealth.excellent,
          ),
        ],
      ),
    );

    final rows = await repository.listMembers(familyId: familyId);

    expect(rows.map((row) => row.kind), [
      FamilyMemberKind.owner,
      FamilyMemberKind.child,
    ]);
    expect(rows.last.displayName, 'أمانة');
    expect(rows.last.membershipStatus, isNull);
  });

  test('an unscoped request is refused rather than answered', () async {
    final repository = repositoryWith([]);
    expect(await repository.listMembers(), isEmpty);
    expect(await repository.listMembers(familyId: '   '), isEmpty);
  });

  test('a server failure throws instead of reporting an empty family', () async {
    final repository = RemoteFamilyMembersRepository(
      loadMemberships: (FamilyId family) async => throw StateError('network'),
    );

    // This is the assertion that matters most on this screen: an error swallowed into an
    // empty list would tell a guardian their family has no members.
    await expectLater(
      () => repository.listMembers(familyId: familyId),
      throwsStateError,
    );
  });
}
