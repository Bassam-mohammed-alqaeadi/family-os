import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Deterministic LOCAL DEMO display rows for [LocalChildrenListRepository].
///
/// Rule 12 allowlisted (`*mock*.dart`). Generic labels only (ابن 1/2/3) —
/// never planted Register §10 person names (Rule 23).
/// VX-B3 · D5 — Western digits in demo labels.
abstract final class ChildrenListLocalSeedMock {
  ChildrenListLocalSeedMock._();

  static final FamilyId famStage1 = FamilyId('fam_stage1');
  static final FamilyId famStage2 = FamilyId('fam_stage2');

  /// fam_stage1 — demo-child + child_b (IDs align with Stage-1 Identity).
  /// LDR-B1 / 1C — identity fields only; no fabricated GPS/battery/heartbeat.
  static const List<ChildrenListEntry> famStage1Children = [
    ChildrenListEntry(
      id: 'demo-child',
      displayName: 'ابن 1',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: '',
      lastSeenLabel: '',
      batteryLabel: '',
      timeLeftLabel: '',
      health: ChildListHealth.excellent,
    ),
    ChildrenListEntry(
      id: 'child_b',
      displayName: 'ابن 2',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: '',
      lastSeenLabel: '',
      batteryLabel: '',
      timeLeftLabel: '',
      health: ChildListHealth.excellent,
    ),
  ];

  /// fam_stage2 — child_c.
  static const List<ChildrenListEntry> famStage2Children = [
    ChildrenListEntry(
      id: 'child_c',
      displayName: 'ابن 3',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: '',
      lastSeenLabel: '',
      batteryLabel: '',
      timeLeftLabel: '',
      health: ChildListHealth.excellent,
    ),
  ];

  static const SharedChildrenPolicies defaultPolicies = SharedChildrenPolicies(
    bedtimeLabel: '9:30 م',
  );

  static List<ChildrenListEntry> forFamily(FamilyId familyId) {
    if (familyId.value == famStage1.value) return famStage1Children;
    if (familyId.value == famStage2.value) return famStage2Children;
    return const [];
  }
}
