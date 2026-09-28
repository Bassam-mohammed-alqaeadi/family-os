import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_repository.dart';
import 'package:family_os/features/n07_advisor/family_moments_repository.dart';
import 'package:family_os/features/n07_advisor/peer_compare_repository.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';

/// CE-B2 — report surfaces empty-first + Local moments derivation.
void main() {
  test('usage report stage1 empty-first (no prototype weekHours)', () async {
    final repo = InMemoryChildUsageReportRepository();
    final snap = await repo.load();
    expect(snap.isEmpty, isTrue);
    expect(snap.weekHours, 0);
    expect(snap.categories, isEmpty);
  });

  test('peer compare stage1 empty-first (no sample cohort age)', () async {
    final repo = InMemoryPeerCompareRepository();
    final snap = await repo.load();
    expect(snap.isEmpty, isTrue);
    expect(snap.metrics, isEmpty);
  });

  test('family moments empty when roster empty', () async {
    final moments = LocalFactsFamilyMomentsRepository(
      familyTasks: InMemoryFamilyTasksRepository(
        seed: familyTasksEmptyFixture(),
      ),
      children: InMemoryChildrenListRepository(),
    );
    expect((await moments.load()).isEmpty, isTrue);
  });

  test('family moments tasksDone from Local completed tasks', () async {
    final family = InMemoryFamilyTasksRepository(
      seed: FamilyTasksSnapshot(
        childTasks: [
          FamilyChildTask(
            id: 't1',
            titleKey: 'tidyRoom',
            assigneeNameKey: 'childOne',
            avatarKey: 'lion',
            reward: Minutes(15),
            status: FamilyTaskStatus.completed,
            timeKey: 'today',
          ),
          FamilyChildTask(
            id: 't2',
            titleKey: 'custom:Wash',
            assigneeNameKey: 'childOne',
            avatarKey: 'lion',
            reward: Minutes(10),
            status: FamilyTaskStatus.assigned,
            timeKey: 'today',
          ),
        ],
      ),
    );
    final children = InMemoryChildrenListRepository(
      children: [
        ChildrenListEntry(
          id: 'child_a',
          displayName: 'One',
          emoji: '🦁',
          swatch: DayChildSwatch.purple,
          ageYears: 10,
          locationLabel: 'home',
          lastSeenLabel: 'now',
          batteryLabel: '80%',
          timeLeftLabel: '1h',
          health: ChildListHealth.excellent,
        ),
      ],
    );
    final moments = LocalFactsFamilyMomentsRepository(
      familyTasks: family,
      children: children,
    );
    final snap = await moments.load();
    expect(snap.isEmpty, isFalse);
    expect(snap.tasksDone, 1);
    expect(snap.learnHours, 0);
    expect(snap.versesMemorized, 0);
  });
}
