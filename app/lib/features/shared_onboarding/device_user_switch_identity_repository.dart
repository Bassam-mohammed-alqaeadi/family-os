import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n12_devices/family_members_mock.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_repository.dart';

/// Projects [IdentityRuntime] adults (+ children roster) onto SHR-008.
///
/// Adult labels from [FamilyMembersIdentityLabels] (`*mock*.dart`); child
/// display names from the Local roster (VX-B6 / FVX-S-04). Never plants
/// Register §10 person names for adults.
final class IdentityDeviceUserSwitchRepository
    implements DeviceUserSwitchRepository {
  IdentityDeviceUserSwitchRepository({
    IdentityRuntime Function()? runtime,
    ChildrenListRepository? children,
  }) : _runtime = runtime ?? (() => stage1IdentityRuntime),
       _children = children;

  final IdentityRuntime Function() _runtime;
  final ChildrenListRepository? _children;

  ChildrenListRepository get _roster =>
      _children ?? stage1ChildrenListRepository;

  @override
  Future<List<DeviceUserProfile>> listProfiles() async {
    final runtime = _runtime();
    final familyId = runtime.activeFamilyId;
    final rows = <DeviceUserProfile>[];

    for (final membership in runtime.adultMembershipsForFamily(familyId)) {
      if (membership.role == AppRole.father && membership.isPrimaryOwner) {
        rows.add(
          DeviceUserProfile(
            id: membership.id.value,
            displayName: FamilyMembersIdentityLabels.owner,
            role: AppRole.father,
            accountId: membership.accountId,
            monogram: FamilyMembersIdentityLabels.ownerMonogram,
          ),
        );
      } else if (membership.role == AppRole.mother) {
        rows.add(
          DeviceUserProfile(
            id: membership.id.value,
            displayName: FamilyMembersIdentityLabels.mother,
            role: AppRole.mother,
            accountId: membership.accountId,
            motherLevel: membership.motherLevel,
            monogram: FamilyMembersIdentityLabels.motherMonogram,
            avatarColorHex: '#FF8FA3',
          ),
        );
      } else if (membership.role == AppRole.father) {
        rows.add(
          DeviceUserProfile(
            id: membership.id.value,
            displayName: FamilyMembersIdentityLabels.guardian,
            role: AppRole.father,
            accountId: membership.accountId,
            monogram: FamilyMembersIdentityLabels.guardianMonogram,
          ),
        );
      }
    }

    final children = await _roster.listChildren(familyId: familyId);
    for (final child in children) {
      final name = child.displayName.trim();
      rows.add(
        DeviceUserProfile(
          id: child.id,
          displayName: name.isEmpty ? child.id : name,
          role: AppRole.child,
          monogram: name.isNotEmpty
              ? String.fromCharCode(name.runes.first).toUpperCase()
              : 'C',
        ),
      );
    }
    return List.unmodifiable(rows);
  }
}
