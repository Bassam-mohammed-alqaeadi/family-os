import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';

/// CE-B3 — control spine: empty-first apps + honesty defaults.
void main() {
  test('stage1 child apps inventory is empty-first (CE-G024)', () {
    final repo = InMemoryChildAppsRepository();
    expect(repo.appsFor(ChildId(kDefaultChildAppsChildKey)), isEmpty);
  });

  test('prototype fixture still available for LOCAL_DEMO / tests', () {
    final repo = InMemoryChildAppsRepository(seed: kDefaultChildAppsByChild);
    expect(repo.appsFor(ChildId(kDefaultChildAppsChildKey)), isNotEmpty);
  });
}
