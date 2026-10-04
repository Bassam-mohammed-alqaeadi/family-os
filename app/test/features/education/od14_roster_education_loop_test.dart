import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';
import 'package:family_os/features/n14_studio/create_assignment_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';

/// OD-14 — education loops follow the real active roster child.
void main() {
  late InMemoryLearningAssignmentRepository assignments;

  setUp(() {
    resetStage1IdentityRuntimeForTest();
    rebindStage1IdentityRuntime(familyContextStore: MemoryFamilyContextStore());
    stage1IdentityRuntime.setActiveChild(ChildId('demo-child'));
    assignments = InMemoryLearningAssignmentRepository();
    rebindStage1LearningAssignmentRepository(assignments);
  });

  tearDown(() {
    rebindStage1LearningAssignmentRepository(
      InMemoryLearningAssignmentRepository(),
    );
    resetStage1IdentityRuntimeForTest();
  });

  test(
    'roster lists only active-family children (not child_a / other family)',
    () {
      final roster = activeFamilyRosterChildren();
      final ids = roster.map((c) => c.id.value).toList();
      expect(ids, containsAll(['demo-child', 'child_b']));
      expect(ids, isNot(contains('child_a')));
      expect(ids, isNot(contains('child_c'))); // second family
    },
  );

  test('create assignment publishes to the active roster child', () async {
    final repo = InMemoryCreateAssignmentRepository(assignments: assignments);
    final snap = await repo.load();
    expect(snap.child?.id, 'demo-child');
    expect(snap.child?.id, isNot('child_a'));

    await repo.assignHomework('Roster homework');
    final latest = await assignments.latestForChild(ChildId('demo-child'));
    expect(latest, isNotNull);
    expect(latest!.rewardMinutes, Minutes(30));

    final orphan = await assignments.latestForChild(ChildId('child_a'));
    expect(orphan, isNull);
  });

  test('child learn home merges father assignment for active child', () async {
    await assignments.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId('demo-child'),
        titleKey: 'assignedHomework',
        rewardMinutes: Minutes(30),
        source: LearningAssignmentSource.homework,
      ),
    );
    final learn = InMemoryChildLearnHomeRepository(
      assignments: assignments,
      childId: ChildId('demo-child'),
    );
    final snap = await learn.load();
    expect(snap.challenge?.titleKey, 'assignedHomework');
  });

  test('switching active child retargets learn home merge', () async {
    await assignments.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId('child_b'),
        titleKey: 'assignedSkillGap',
        rewardMinutes: Minutes(50),
        source: LearningAssignmentSource.skillGap,
      ),
    );
    stage1IdentityRuntime.setActiveChild(ChildId('child_b'));
    final learn = InMemoryChildLearnHomeRepository(assignments: assignments);
    final snap = await learn.load();
    expect(snap.challenge?.titleKey, 'assignedSkillGap');
  });

  test('attribution picker lists roster children and selects active', () async {
    final repo = InMemoryAttributionRewardRepository(assignments: assignments);
    final snap = await repo.load();
    final ids = snap.children.map((c) => c.id).toList();
    expect(ids, containsAll(['demo-child', 'child_b']));
    expect(ids, isNot(contains('child_a')));
    expect(snap.selectedChildId, 'demo-child');
  });
}
