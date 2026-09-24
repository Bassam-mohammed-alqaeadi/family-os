import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';

void main() {
  test(
    'father assign publishes; child learn home merges challenge+material',
    () async {
      final bus = InMemoryLearningAssignmentRepository();
      final father = InMemoryAttributionRewardRepository(assignments: bus);
      final child = InMemoryChildLearnHomeRepository(assignments: bus);

      final before = await child.load();
      expect(before.challenge?.titleKey, 'fractionsQuiz');
      expect(before.challenge?.rewardMinutes, 35);

      final assigned = await father.assign();
      expect(assigned.assigned, isTrue);

      final latest = await bus.latestForChild(ChildId('child_a'));
      expect(latest, isNotNull);
      expect(latest!.rewardMinutes, Minutes(35));
      expect(latest.source, LearningAssignmentSource.attribution);

      final after = await child.load();
      expect(after.challenge?.titleKey, 'assignedChallenge');
      expect(after.challenge?.rewardMinutes, 35);
      expect(after.materials.first.subtitleKey, 'assignedFromFather');
      expect(after.materials.first.id, startsWith('assigned_'));

      bus.dispose();
    },
  );

  test('assignments stream emits on publish', () async {
    final bus = InMemoryLearningAssignmentRepository();
    final events = <LearningAssignment>[];
    final sub = bus.assignments.listen(events.add);

    await bus.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId('child_b'),
        titleKey: 'assignedHomework',
        rewardMinutes: Minutes(30),
        source: LearningAssignmentSource.homework,
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    expect(events.single.childId, ChildId('child_b'));
    await sub.cancel();
    bus.dispose();
  });
}
