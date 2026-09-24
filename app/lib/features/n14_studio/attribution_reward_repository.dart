import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/screen_time_policy_repository.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n03_screen_time/child_screen_time_screen.dart'
    show stage1PolicyPrefsStore;
import 'package:family_os/features/n14_studio/attribution_reward_models.dart';

/// App wallet ids for Studio attribution rewards (minutes-only · ع-١).
abstract final class AttributionWalletApps {
  static const education = 'education';
  static const play = 'play';
}

/// Rule 25 seam — Stage-1 mock attribution/reward (no backend).
abstract class AttributionRewardRepository {
  Future<AttributionRewardSnapshot> load();

  /// Publishes LearningAssignment + deposits Minutes via [WalletLedger]
  /// (P15-EDU-002 · P15-EDU-005 · Rule 5).
  Future<AttributionRewardSnapshot> assign();
}

/// In-memory mock — prototype FAT-045 shape by default.
final class InMemoryAttributionRewardRepository
    implements AttributionRewardRepository {
  InMemoryAttributionRewardRepository({
    AttributionRewardSnapshot? seed,
    LearningAssignmentRepository? assignments,
    WalletLedger? wallet,
  }) : _snap = seed ?? attributionRewardPrototypeFixture(),
       _assignments = assignments ?? stage1LearningAssignmentRepository,
       _wallet =
           wallet ??
           WalletLedger(
             PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore),
           );

  AttributionRewardSnapshot _snap;
  final LearningAssignmentRepository _assignments;
  final WalletLedger _wallet;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<AttributionRewardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy();
  }

  @override
  Future<AttributionRewardSnapshot> assign() async {
    if (!_snap.canAssign) return _copy();
    final child = _snap.selectedChild!;
    final childId = ChildId(child.id);

    for (final reward in _snap.rewards) {
      if (!reward.enabled || reward.minutes <= 0) continue;
      final appId = switch (reward.kind) {
        AttributionRewardKind.wallet => AttributionWalletApps.education,
        AttributionRewardKind.play => AttributionWalletApps.play,
      };
      await _wallet.earn(
        childId: childId,
        appId: appId,
        assignee: AppRole.child,
        fatherSetReward: Minutes(reward.minutes),
      );
    }

    await _assignments.publish(
      LearningAssignmentPublishRequest(
        childId: childId,
        titleKey: 'assignedChallenge',
        rewardMinutes: Minutes(_snap.totalEnabledMinutes),
        source: LearningAssignmentSource.attribution,
        ctaScreenId: 'SCR-CHD-015',
        materialKindKey: 'math',
      ),
    );
    _snap = _snap.withAssigned();
    return _copy();
  }

  void seed(AttributionRewardSnapshot snap) {
    _snap = snap;
  }

  AttributionRewardSnapshot _copy() {
    return AttributionRewardSnapshot(
      children: List<AttributionChild>.from(_snap.children),
      selectedChildId: _snap.selectedChildId,
      schedule: _snap.schedule,
      rewards: List<AttributionRewardToggle>.from(_snap.rewards),
      masteryPercent: _snap.masteryPercent,
      assigned: _snap.assigned,
    );
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryAttributionRewardRepository stage1AttributionRewardRepository =
    InMemoryAttributionRewardRepository();

/// Empty — Rule 23 empty-state coverage.
AttributionRewardSnapshot attributionRewardEmptyFixture() {
  return const AttributionRewardSnapshot();
}

/// Prototype FAT-045 — three children · schedule · wallet 20 + play 15 minutes.
///
/// Rule 23: generic nameKeys only (no planted person names).
AttributionRewardSnapshot attributionRewardPrototypeFixture() {
  return const AttributionRewardSnapshot(
    children: [
      AttributionChild(
        id: 'child_a',
        nameKey: 'one',
        emoji: '🦁',
        swatch: AttributionChildSwatch.purple,
      ),
      AttributionChild(
        id: 'child_b',
        nameKey: 'two',
        emoji: '🐱',
        swatch: AttributionChildSwatch.sky,
      ),
      AttributionChild(
        id: 'child_c',
        nameKey: 'three',
        emoji: '🐼',
        swatch: AttributionChildSwatch.amber,
      ),
    ],
    selectedChildId: 'child_a',
    schedule: AttributionSchedule.tomorrowAfterSchool,
    rewards: [
      AttributionRewardToggle(
        id: 'wallet',
        kind: AttributionRewardKind.wallet,
        minutes: 20,
        enabled: true,
      ),
      AttributionRewardToggle(
        id: 'play',
        kind: AttributionRewardKind.play,
        minutes: 15,
        enabled: true,
        autoAdded: true,
      ),
    ],
    masteryPercent: 80,
  );
}
