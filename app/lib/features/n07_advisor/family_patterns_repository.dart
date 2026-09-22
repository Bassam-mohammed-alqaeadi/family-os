import 'package:family_os/features/n07_advisor/family_patterns_models.dart';

/// Rule 25 seam — Stage-1 mock family patterns (no backend).
abstract class FamilyPatternsRepository {
  Future<FamilyPatternsSnapshot> load();
}

/// In-memory mock — prototype FAT-062 shape by default.
final class InMemoryFamilyPatternsRepository implements FamilyPatternsRepository {
  InMemoryFamilyPatternsRepository({FamilyPatternsSnapshot? seed})
    : _snap = seed ?? familyPatternsPrototypeFixture();

  FamilyPatternsSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<FamilyPatternsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return FamilyPatternsSnapshot(
      children: List<FamilyPatternChildCard>.from(_snap.children),
      advisorConfidencePercent: _snap.advisorConfidencePercent,
    );
  }

  void seed(FamilyPatternsSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryFamilyPatternsRepository stage1FamilyPatternsRepository =
    InMemoryFamilyPatternsRepository();

/// Empty — Rule 23 empty-state coverage (no children / baseline yet).
FamilyPatternsSnapshot familyPatternsEmptyFixture() {
  return const FamilyPatternsSnapshot();
}

/// One child · one pattern row — minimal non-empty.
FamilyPatternsSnapshot familyPatternsOneFixture() {
  return const FamilyPatternsSnapshot(
    advisorConfidencePercent: 68,
    children: [
      FamilyPatternChildCard(
        id: 'child_card_a',
        nameKey: 'childOne',
        confidencePercent: 72,
        patterns: [
          FamilyPatternRow(
            id: 'pat-a1',
            domain: FamilyPatternDomain.communication,
            titleKey: 'communicationStable',
            tag: FamilyPatternTag.ok,
          ),
        ],
      ),
    ],
  );
}

/// Prototype FAT-062 — two children, mixed pattern tags, trust seals.
///
/// Rule 23: nameKey only (no planted person names).
FamilyPatternsSnapshot familyPatternsPrototypeFixture() {
  return const FamilyPatternsSnapshot(
    advisorConfidencePercent: 79,
    children: [
      FamilyPatternChildCard(
        id: 'child_card_one',
        nameKey: 'childOne',
        confidencePercent: 85,
        patterns: [
          FamilyPatternRow(
            id: 'pat-sleep-one',
            domain: FamilyPatternDomain.sleep,
            titleKey: 'sleepDelay',
            subtitleKey: 'sleepBaseline',
            tag: FamilyPatternTag.anomaly,
          ),
          FamilyPatternRow(
            id: 'pat-comm-one',
            domain: FamilyPatternDomain.communication,
            titleKey: 'communicationStable',
            tag: FamilyPatternTag.ok,
          ),
          FamilyPatternRow(
            id: 'pat-edu-one',
            domain: FamilyPatternDomain.education,
            titleKey: 'educationImprove',
            tag: FamilyPatternTag.improve,
          ),
        ],
      ),
      FamilyPatternChildCard(
        id: 'child_card_two',
        nameKey: 'childTwo',
        confidencePercent: 72,
        patterns: [
          FamilyPatternRow(
            id: 'pat-morning-two',
            domain: FamilyPatternDomain.morningActivity,
            titleKey: 'morningActivityDrop',
            subtitleKey: 'morningActivityHint',
            tag: FamilyPatternTag.watch,
          ),
        ],
      ),
    ],
  );
}
