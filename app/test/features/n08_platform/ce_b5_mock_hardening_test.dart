import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n08_platform/smart_alerts_repository.dart';

/// CE-B5 — smart alerts empty-first (CE-G011).
void main() {
  test('stage1 smart alerts empty-first (no planted live alerts)', () async {
    final repo = InMemorySmartAlertsRepository();
    final snap = await repo.load();
    expect(snap.isEmpty, isTrue);
    expect(snap.alerts, isEmpty);
  });

  test('prototype fixture remains available for LOCAL_DEMO / tests', () async {
    final repo = InMemorySmartAlertsRepository(
      seed: smartAlertsPrototypeFixture(),
    );
    final snap = await repo.load();
    expect(snap.alerts, isNotEmpty);
  });
}
