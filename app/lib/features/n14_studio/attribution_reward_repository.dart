import 'package:family_os/features/n14_studio/attribution_reward_models.dart';

/// Rule 25 seam — Stage-1 mock attribution/reward (no backend).
abstract class AttributionRewardRepository {
  Future<AttributionRewardSnapshot> load();
}

/// In-memory mock — prototype FAT-045 shape by default.
final class InMemoryAttributionRewardRepository
    implements AttributionRewardRepository {
  InMemoryAttributionRewardRepository({AttributionRewardSnapshot? seed})
    : _snap = seed ?? attributionRewardPrototypeFixture();

  AttributionRewardSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<AttributionRewardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return AttributionRewardSnapshot(
      children: List<AttributionChild>.from(_snap.children),
      selectedChildId: _snap.selectedChildId,
      schedule: _snap.schedule,
      rewards: List<AttributionRewardToggle>.from(_snap.rewards),
      masteryPercent: _snap.masteryPercent,
      assigned: _snap.assigned,
    );
  }

  void seed(AttributionRewardSnapshot snap) {
    _snap = snap;
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
