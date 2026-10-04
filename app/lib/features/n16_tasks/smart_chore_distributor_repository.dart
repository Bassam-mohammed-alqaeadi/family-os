import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/features/n16_tasks/family_tasks_models.dart';
import 'package:family_os/features/n16_tasks/family_tasks_repository.dart';
import 'package:family_os/features/n16_tasks/smart_chore_distributor_models.dart';

abstract class SmartChoreDistributorRepository {
  Future<SmartChoreDistributorSnapshot> load();
  Future<SmartChoreDistributorSnapshot> approve();
  Future<SmartChoreDistributorSnapshot> shuffle();
}

/// Suggest-only ChoreAI — approve writes into [FamilyTasksRepository] (Rule 7).
final class InMemorySmartChoreDistributorRepository
    implements SmartChoreDistributorRepository {
  InMemorySmartChoreDistributorRepository({
    SmartChoreDistributorSnapshot? seed,
    FamilyTasksRepository? familyTasks,
  }) : _snap = seed ?? smartChoreDistributorEmptyFixture(),
       _familyOverride = familyTasks;

  SmartChoreDistributorSnapshot _snap;
  final FamilyTasksRepository? _familyOverride;

  FamilyTasksRepository get _family =>
      _familyOverride ?? stage1FamilyTasksRepository;
  Future<void> Function()? loadGate;
  Object? loadError;

  /// Father-set minutes at approve (ع-١) — proposal default until edit UX exists.
  static final Minutes defaultReward = Minutes(15);

  @override
  Future<SmartChoreDistributorSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final err = loadError;
    if (err != null) {
      loadError = null;
      throw err;
    }
    return _snap.copyWith();
  }

  @override
  Future<SmartChoreDistributorSnapshot> approve() async {
    final tasks = _snap.assignments.map(_toFamilyTask).toList();
    await _family.applyChoreAssignments(tasks);
    _snap = _snap.copyWith(approved: true);
    return _snap.copyWith();
  }

  @override
  Future<SmartChoreDistributorSnapshot> shuffle() async {
    final flipped = _snap.assignments.reversed.toList();
    _snap = _snap.copyWith(
      assignments: flipped,
      altReady: true,
      approved: false,
    );
    return _snap.copyWith();
  }

  void seed(SmartChoreDistributorSnapshot snap) => _snap = snap;

  FamilyChildTask _toFamilyTask(ChoreAssignment a) {
    return FamilyChildTask(
      id: 'chore-${a.id}',
      titleKey: a.choresKey,
      assigneeNameKey: a.childLabelKey,
      avatarKey: switch (a.childLabelKey) {
        'childTwo' => 'cat',
        'childThree' => 'panda',
        _ => 'lion',
      },
      reward: defaultReward,
      status: FamilyTaskStatus.assigned,
      timeKey: 'today',
    );
  }
}

final InMemorySmartChoreDistributorRepository
stage1SmartChoreDistributorRepository =
    InMemorySmartChoreDistributorRepository();

SmartChoreDistributorSnapshot smartChoreDistributorEmptyFixture() =>
    const SmartChoreDistributorSnapshot();

SmartChoreDistributorSnapshot smartChoreDistributorOneFixture() {
  return const SmartChoreDistributorSnapshot(
    hasFamily: true,
    assignments: [
      ChoreAssignment(
        id: 'a1',
        childLabelKey: 'childOne',
        choresKey: 'dishesPlants',
        noteKey: 'examTue',
      ),
    ],
  );
}

SmartChoreDistributorSnapshot smartChoreDistributorPrototypeFixture() {
  return const SmartChoreDistributorSnapshot(
    hasFamily: true,
    assignments: [
      ChoreAssignment(
        id: 'a1',
        childLabelKey: 'childOne',
        choresKey: 'dishesPlants',
        noteKey: 'examTue',
      ),
      ChoreAssignment(
        id: 'a2',
        childLabelKey: 'childTwo',
        choresKey: 'livingLaundry',
        noteKey: 'rotated',
      ),
      ChoreAssignment(
        id: 'a3',
        childLabelKey: 'childThree',
        choresKey: 'trashWater',
        noteKey: 'age8',
      ),
    ],
  );
}
