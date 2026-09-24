import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

void main() {
  ChildrenListEntry entry(String id, String name) {
    return ChildrenListEntry(
      id: id,
      displayName: name,
      emoji: '🧒',
      swatch: DayChildSwatch.purple,
      ageYears: 10,
      locationLabel: 'loc',
      lastSeenLabel: 'now',
      batteryLabel: '80%',
      timeLeftLabel: '30m',
      health: ChildListHealth.excellent,
    );
  }

  test('family-bound children listing isolates families', () async {
    final repo = InMemoryChildrenListRepository(
      byFamily: {
        'fam_a': [entry('a1', 'A1')],
        'fam_b': [entry('b1', 'B1')],
      },
    );

    final a = await repo.listChildren(familyId: FamilyId('fam_a'));
    final b = await repo.listChildren(familyId: FamilyId('fam_b'));
    expect(a.map((it) => it.id), ['a1']);
    expect(b.map((it) => it.id), ['b1']);
  });
}
