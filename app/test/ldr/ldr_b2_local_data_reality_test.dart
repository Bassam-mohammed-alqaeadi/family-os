import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_real_local_seed_mock.dart';
import 'package:family_os/features/n03_screen_time/child_apps_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    rebindStage1ChildAppsRepository(InMemoryChildAppsRepository());
  });

  test('LDR-B2 managed app catalog has zero usedMins (no fake OS usage)', () {
    for (final app in ChildAppsRealLocalSeedMock.managedCatalog) {
      expect(app.usedMins, 0);
    }
    expect(ChildAppsRealLocalSeedMock.managedCatalog, isNotEmpty);
  });

  test('LDR-B2 child apps seed via InMemory with managed catalog', () {
    final repo = InMemoryChildAppsRepository(
      seed: ChildAppsRealLocalSeedMock.forChildren([ChildId('demo-child')]),
    );
    final apps = repo.appsFor(ChildId('demo-child'));
    expect(apps.length, ChildAppsRealLocalSeedMock.managedCatalog.length);
    expect(apps.every((a) => a.usedMins == 0), isTrue);
  });
}
