import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_policy_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/children_list_runtime_sources.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
  final familyId = FamilyId('fam_a');

  test('local roster keeps a managed child without manufacturing a profile', () async {
    final source = LocalFamilyRosterSource(
      repository: InMemoryChildrenListRepository(
        byFamily: {
          familyId.value: const [
            ChildrenListEntry(
              id: 'child_profiled',
              displayName: 'Nora',
              emoji: '🙂',
              swatch: DayChildSwatch.purple,
              ageYears: 9,
              locationLabel: '',
              lastSeenLabel: '',
              batteryLabel: '',
              timeLeftLabel: '',
              health: ChildListHealth.excellent,
            ),
          ],
        },
      ),
      managementRepository: _ManagementFake(
        children: [
          ManagedChildRecord(
            familyId: familyId,
            childId: ChildId('child_profiled'),
          ),
          ManagedChildRecord(
            familyId: familyId,
            childId: ChildId('child_needs_profile'),
          ),
        ],
      ),
      clock: () => DateTime.utc(2026, 10, 2),
    );
    addTearDown(source.dispose);

    final snapshot = await source.load(familyId);
    final profiled = snapshot.children.firstWhere(
      (it) => it.childId == ChildId('child_profiled'),
    );
    final incomplete = snapshot.children.firstWhere(
      (it) => it.childId == ChildId('child_needs_profile'),
    );

    expect(snapshot.origin, RuntimeDataOrigin.localOnly);
    expect(profiled.displayName, 'Nora');
    expect(profiled.ageYears, 9);
    expect(incomplete.displayName, isNull);
    expect(incomplete.ageYears, isNull);
    expect(incomplete.hasCompleteDisplayProfile, isFalse);
  });

  test('local policy source reports local persistence rather than enforcement', () async {
    final repository = InMemoryChildrenListRepository();
    final source = LocalFamilyPolicySource(
      repository: repository,
      clock: () => DateTime.utc(2026, 10, 2),
    );
    addTearDown(source.dispose);

    final saved = await source.saveSharedPolicy(
      familyId,
      const FamilySharedPolicy(dailyCapHours: 2, webFilterOn: false),
    );

    expect(saved.origin, RuntimeDataOrigin.localOnly);
    expect(saved.sharedPolicy!.dailyCapHours, 2);
    expect(saved.canMutateLocally, isTrue);
    expect((await repository.loadSharedPolicies(familyId: familyId)).webFilterOn, isFalse);
  });

  test('local device source only reports registered device truth', () async {
    final source = LocalFamilyDeviceSource(
      managementRepository: _ManagementFake(
        children: [
          ManagedChildRecord(familyId: familyId, childId: ChildId('child_a')),
        ],
      ),
      clock: () => DateTime.utc(2026, 10, 2),
    );
    addTearDown(source.dispose);

    final snapshot = await source.load(familyId);

    expect(snapshot.origin, RuntimeDataOrigin.localOnly);
    expect(snapshot.forChild(ChildId('child_a'))!.connectionState,
        ChildDeviceConnectionState.noDevice);
    expect(snapshot.forChild(ChildId('unknown')), isNull);
  });
}

final class _ManagementFake implements ChildDeviceManagementRepository {
  _ManagementFake({this.children = const []});

  final List<ManagedChildRecord> children;

  @override
  List<ManagedChildRecord> listChildren(FamilyId familyId) => children;

  @override
  List<ManagedDeviceRecord> listDevices({
    required FamilyId familyId,
    required ChildId childId,
  }) => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
