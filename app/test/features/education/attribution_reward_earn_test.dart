import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';

void main() {
  test('assign publishes the challenge and writes no minutes (S3)', () async {
    final assignments = InMemoryLearningAssignmentRepository();
    addTearDown(assignments.dispose);

    final repo = InMemoryAttributionRewardRepository(assignments: assignments);

    final snap = await repo.assign();
    expect(snap.assigned, isTrue);

    final child = ChildId('demo-child');
    final published = await assignments.latestForChild(child);
    expect(published, isNotNull);
    expect(published!.rewardMinutes, Minutes(35));
  });

  test('disabled rewards are left out of the published challenge', () async {
    final assignments = InMemoryLearningAssignmentRepository();
    addTearDown(assignments.dispose);

    final seed = attributionRewardPrototypeFixture().withRewardEnabled(
      'play',
      false,
    );
    final repo = InMemoryAttributionRewardRepository(
      seed: seed,
      assignments: assignments,
    );

    await repo.assign();
    final published = await assignments.latestForChild(ChildId('demo-child'));
    expect(published!.rewardMinutes, Minutes(20));
  });
}
