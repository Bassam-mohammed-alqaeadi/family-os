import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n12_devices/family_members_mock.dart';
import 'package:family_os/features/n12_devices/family_members_repository.dart';

/// Projects [IdentityRuntime] adults + [ChildrenListRepository] children
/// onto SCR-FAT-027 roster (FE-W1-FAT-027).
///
/// Fail-closed when [familyId] is null/empty. Never plants Register §10 names.
/// Role display labels come from [FamilyMembersIdentityLabels] (`*mock*.dart`).
final class IdentityFamilyMembersRepository implements FamilyMembersRepository {
  IdentityFamilyMembersRepository({
    IdentityRuntime Function()? runtime,
    ChildrenListRepository? children,
  }) : _runtime = runtime ?? (() => stage1IdentityRuntime),
       _children = children;

  final IdentityRuntime Function() _runtime;
  final ChildrenListRepository? _children;

  ChildrenListRepository get _roster =>
      _children ?? stage1ChildrenListRepository;

  @override
  Future<List<FamilyMemberEntry>> listMembers({String? familyId}) async {
    final id = familyId?.trim();
    if (id == null || id.isEmpty) return const [];

    final fid = FamilyId(id);
    final runtime = _runtime();
    final activeAccountId = runtime.account.id;
    final rows = <FamilyMemberEntry>[];

    for (final membership in runtime.adultMembershipsForFamily(fid)) {
      final isSelf = membership.accountId == activeAccountId;
      if (membership.role == AppRole.father && membership.isPrimaryOwner) {
        rows.add(
          FamilyMemberEntry(
            id: membership.id.value,
            familyId: id,
            displayName: FamilyMembersIdentityLabels.owner,
            kind: FamilyMemberKind.owner,
            monogram: FamilyMembersIdentityLabels.ownerMonogram,
            swatch: DayChildSwatch.purple,
            isSelf: isSelf,
          ),
        );
      } else if (membership.role == AppRole.mother) {
        rows.add(
          FamilyMemberEntry(
            id: membership.id.value,
            familyId: id,
            displayName: FamilyMembersIdentityLabels.mother,
            kind: FamilyMemberKind.mother,
            monogram: FamilyMembersIdentityLabels.motherMonogram,
            swatch: DayChildSwatch.sky,
            isSelf: isSelf,
            motherLevel: membership.motherLevel,
          ),
        );
      } else if (membership.role == AppRole.father) {
        // Non-primary father / co-guardian tier — locked observer posture.
        rows.add(
          FamilyMemberEntry(
            id: membership.id.value,
            familyId: id,
            displayName: FamilyMembersIdentityLabels.guardian,
            kind: FamilyMemberKind.guardian,
            monogram: FamilyMembersIdentityLabels.guardianMonogram,
            swatch: DayChildSwatch.amber,
            isSelf: isSelf,
            motherLevel: membership.motherLevel,
            levelLocked: true,
          ),
        );
      }
    }

    final kids = await _roster.listChildren(familyId: fid);
    for (final kid in kids) {
      rows.add(
        FamilyMemberEntry(
          id: kid.id,
          familyId: id,
          displayName: kid.displayName,
          kind: FamilyMemberKind.child,
          monogram: kid.emoji,
          swatch: kid.swatch,
        ),
      );
    }

    return List.unmodifiable(rows);
  }

  /// Delegates to children roster envelope provenance (LOCAL_DEMO_SEEDED).
  Future<String?> loadProvenance({FamilyId? familyId}) {
    return _roster.loadProvenance(familyId: familyId);
  }
}
