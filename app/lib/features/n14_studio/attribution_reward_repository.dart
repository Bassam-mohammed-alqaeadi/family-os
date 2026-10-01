import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/wallet_ledger.dart';
import 'package:family_os/core/screen_time/screen_time_local_persistence.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
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
  }) : _snap = seed ??
           (assignments == null && wallet == null
               ? attributionRewardEmptyFixture()
               : attributionRewardPrototypeFixture()),
       _assignments = assignments ?? stage1LearningAssignmentRepository,
       _injectedWallet = wallet;

  AttributionRewardSnapshot _snap;
  final LearningAssignmentRepository _assignments;
  final WalletLedger? _injectedWallet;
  WalletLedger? _resolvedWallet;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  Future<WalletLedger> _wallet() async {
    final injected = _injectedWallet;
    if (injected != null) return injected;
    return _resolvedWallet ??= WalletLedger(
      await ScreenTimeLocalPersistence.openPolicyRepository(),
    );
  }

  @override
  Future<AttributionRewardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindAttributionToRoster(_snap);
    return _copy();
  }

  @override
  Future<AttributionRewardSnapshot> assign() async {
    _snap = bindAttributionToRoster(_snap);
    if (!_snap.canAssign) return _copy();
    final child = _snap.selectedChild!;
    final childId = ChildId(child.id);
    final wallet = await _wallet();

    for (final reward in _snap.rewards) {
      if (!reward.enabled || reward.minutes <= 0) continue;
      final appId = switch (reward.kind) {
        AttributionRewardKind.wallet => AttributionWalletApps.education,
        AttributionRewardKind.play => AttributionWalletApps.play,
      };
      await wallet.earn(
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
  return AttributionRewardSnapshot(
    children: _rosterAttributionChildren(),
    selectedChildId: activeRosterChild()?.id.value,
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

List<AttributionChild> _rosterAttributionChildren() {
  const swatches = [
    AttributionChildSwatch.purple,
    AttributionChildSwatch.sky,
    AttributionChildSwatch.amber,
  ];
  const emojis = ['🦁', '🐱', '🐼', '🦊', '🐰'];
  final roster = activeFamilyRosterChildren();
  return [
    for (var i = 0; i < roster.length; i++)
      AttributionChild(
        id: roster[i].id.value,
        nameKey: roster[i].nameKey,
        emoji: emojis[i % emojis.length],
        swatch: swatches[i % swatches.length],
      ),
  ];
}

/// OD-14 — picker children = active family roster.
AttributionRewardSnapshot bindAttributionToRoster(
  AttributionRewardSnapshot snap,
) {
  final children = _rosterAttributionChildren();
  if (children.isEmpty) {
    return const AttributionRewardSnapshot();
  }
  if (snap.children.isEmpty &&
      snap.selectedChildId == null &&
      !snap.assigned &&
      snap.rewards.isEmpty) {
    return snap;
  }
  final activeId = activeRosterChild()!.id.value;
  final selected = snap.selectedChildId;
  final keep = selected != null && children.any((c) => c.id == selected)
      ? selected
      : activeId;
  return AttributionRewardSnapshot(
    children: children,
    selectedChildId: keep,
    schedule: snap.schedule,
    rewards: List<AttributionRewardToggle>.from(snap.rewards),
    masteryPercent: snap.masteryPercent,
    assigned: snap.assigned,
  );
}

