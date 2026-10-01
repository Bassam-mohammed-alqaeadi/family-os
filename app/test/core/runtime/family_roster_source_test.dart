import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';

void main() {
  test('unavailable roster source never fabricates a family or child', () async {
    final source = UnavailableFamilyRosterSource();
    addTearDown(source.dispose);

    final snapshot = await source.load(FamilyId('fam_requested'));

    expect(snapshot.origin, RuntimeDataOrigin.unavailable);
    expect(snapshot.familyId, isNull);
    expect(snapshot.children, isEmpty);
    expect(snapshot.isAuthoritative, isFalse);
  });

  test('roster child distinguishes absent profile fields from zero/default data', () {
    const child = FamilyRosterChild(childId: ChildId('child_unknown'));

    expect(child.displayName, isNull);
    expect(child.ageYears, isNull);
    expect(child.hasCompleteDisplayProfile, isFalse);
  });
}
