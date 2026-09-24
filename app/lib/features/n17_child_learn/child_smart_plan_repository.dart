import 'package:family_os/features/n17_child_learn/child_smart_plan_models.dart';

abstract class ChildSmartPlanRepository {
  Future<ChildSmartPlanSnapshot> load();
  Future<ChildSmartPlanSnapshot> startRepairPlan();
  Future<ChildSmartPlanSnapshot> completeProjectStage();
}

final class InMemoryChildSmartPlanRepository
    implements ChildSmartPlanRepository {
  InMemoryChildSmartPlanRepository({ChildSmartPlanSnapshot? seed})
    : _snap = seed ?? childSmartPlanPrototypeFixture();

  ChildSmartPlanSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildSmartPlanSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildSmartPlanSnapshot> startRepairPlan() async {
    _snap = _snap.copyWith(planStarted: true);
    return _snap.copyWith();
  }

  @override
  Future<ChildSmartPlanSnapshot> completeProjectStage() async {
    _snap = _snap.copyWith(projectDone: true);
    return _snap.copyWith();
  }

  void seed(ChildSmartPlanSnapshot snap) => _snap = snap;
}

final InMemoryChildSmartPlanRepository stage1ChildSmartPlanRepository =
    InMemoryChildSmartPlanRepository();

ChildSmartPlanSnapshot childSmartPlanEmptyFixture() =>
    const ChildSmartPlanSnapshot();

ChildSmartPlanSnapshot childSmartPlanOneFixture() {
  return const ChildSmartPlanSnapshot(hasPlan: true, pathDone: 1);
}

ChildSmartPlanSnapshot childSmartPlanPrototypeFixture() {
  return const ChildSmartPlanSnapshot(hasPlan: true);
}
