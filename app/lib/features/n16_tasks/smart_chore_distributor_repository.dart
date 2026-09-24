import 'package:family_os/features/n16_tasks/smart_chore_distributor_models.dart';

abstract class SmartChoreDistributorRepository {
  Future<SmartChoreDistributorSnapshot> load();
  Future<SmartChoreDistributorSnapshot> approve();
  Future<SmartChoreDistributorSnapshot> shuffle();
}

final class InMemorySmartChoreDistributorRepository
    implements SmartChoreDistributorRepository {
  InMemorySmartChoreDistributorRepository({SmartChoreDistributorSnapshot? seed})
    : _snap = seed ?? smartChoreDistributorPrototypeFixture();

  SmartChoreDistributorSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<SmartChoreDistributorSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<SmartChoreDistributorSnapshot> approve() async {
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
