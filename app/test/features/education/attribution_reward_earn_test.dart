import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/attribution_reward_repository.dart';

void main() {
  test('assign deposits wallet+play via PolicyEngine/WalletLedger', () async {
    final policy = InMemoryScreenTimePolicyRepository();
    final ledger = WalletLedger(policy);
    final assignments = InMemoryLearningAssignmentRepository();
    addTearDown(assignments.dispose);

    final repo = InMemoryAttributionRewardRepository(
      assignments: assignments,
      wallet: ledger,
    );

    final child = ChildId('child_a');
    expect(
      await ledger.balance(
        childId: child,
        appId: AttributionWalletApps.education,
      ),
      Minutes.zero,
    );

    final snap = await repo.assign();
    expect(snap.assigned, isTrue);

    expect(
      await ledger.balance(
        childId: child,
        appId: AttributionWalletApps.education,
      ),
      Minutes(20),
    );
    expect(
      await ledger.balance(childId: child, appId: AttributionWalletApps.play),
      Minutes(15),
    );

    final published = await assignments.latestForChild(child);
    expect(published, isNotNull);
    expect(published!.rewardMinutes, Minutes(35));
  });

  test('disabled rewards skip deposit', () async {
    final policy = InMemoryScreenTimePolicyRepository();
    final ledger = WalletLedger(policy);
    final assignments = InMemoryLearningAssignmentRepository();
    addTearDown(assignments.dispose);

    final seed = attributionRewardPrototypeFixture().withRewardEnabled(
      'play',
      false,
    );
    final repo = InMemoryAttributionRewardRepository(
      seed: seed,
      assignments: assignments,
      wallet: ledger,
    );

    await repo.assign();
    final child = ChildId('child_a');
    expect(
      await ledger.balance(
        childId: child,
        appId: AttributionWalletApps.education,
      ),
      Minutes(20),
    );
    expect(
      await ledger.balance(childId: child, appId: AttributionWalletApps.play),
      Minutes.zero,
    );
  });
}
