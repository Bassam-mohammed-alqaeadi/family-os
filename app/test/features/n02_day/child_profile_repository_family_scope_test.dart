import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/child_profile_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
  test('child profile lookup is constrained by family scope', () async {
    final children = InMemoryChildrenListRepository(
      byFamily: {
        'fam_a': [
          const ChildrenListEntry(
            id: 'child_1',
            displayName: 'A Child',
            emoji: '🧒',
            swatch: DayChildSwatch.purple,
            ageYears: 11,
            locationLabel: 'A',
            lastSeenLabel: 'now',
            batteryLabel: '75%',
            timeLeftLabel: '20m',
            health: ChildListHealth.excellent,
          ),
        ],
        'fam_b': [
          const ChildrenListEntry(
            id: 'child_1',
            displayName: 'B Child',
            emoji: '🧒',
            swatch: DayChildSwatch.sky,
            ageYears: 9,
            locationLabel: 'B',
            lastSeenLabel: 'now',
            batteryLabel: '65%',
            timeLeftLabel: '40m',
            health: ChildListHealth.atRisk,
          ),
        ],
      },
    );
    final repo = InMemoryChildProfileRepository(childrenList: children);

    final a = await repo.loadById('child_1', familyId: FamilyId('fam_a'));
    final b = await repo.loadById('child_1', familyId: FamilyId('fam_b'));

    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(a!.displayName, isNot(b!.displayName));
  });
}
