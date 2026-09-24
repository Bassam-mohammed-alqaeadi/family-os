import 'package:family_os/features/n14_studio/staged_project_models.dart';

abstract class StagedProjectRepository {
  Future<StagedProjectSnapshot> load();
  Future<StagedProjectSnapshot> confirmActiveStage();
  Future<void> openTemplatePicker();
}

final class InMemoryStagedProjectRepository implements StagedProjectRepository {
  InMemoryStagedProjectRepository({StagedProjectSnapshot? seed})
    : _snap = seed ?? stagedProjectPrototypeFixture();

  StagedProjectSnapshot _snap;
  Future<void> Function()? loadGate;
  var templateOpens = 0;
  var confirmed = false;

  @override
  Future<StagedProjectSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith(stages: List.of(_snap.stages));
  }

  @override
  Future<StagedProjectSnapshot> confirmActiveStage() async {
    confirmed = true;
    final next = <StagedProjectStage>[];
    for (final s in _snap.stages) {
      if (s.status == ProjectStageStatus.active) {
        next.add(
          StagedProjectStage(
            id: s.id,
            titleKey: s.titleKey,
            subKey: s.subKey,
            status: ProjectStageStatus.done,
            rewardMinutes: s.rewardMinutes,
          ),
        );
      } else {
        next.add(s);
      }
    }
    _snap = _snap.copyWith(stages: next);
    return _snap.copyWith(stages: List.of(_snap.stages));
  }

  @override
  Future<void> openTemplatePicker() async {
    templateOpens++;
  }

  void seed(StagedProjectSnapshot snap) => _snap = snap;
}

final InMemoryStagedProjectRepository stage1StagedProjectRepository =
    InMemoryStagedProjectRepository();

StagedProjectSnapshot stagedProjectEmptyFixture() =>
    const StagedProjectSnapshot();

StagedProjectSnapshot stagedProjectOneFixture() {
  return const StagedProjectSnapshot(
    hasProject: true,
    stages: [
      StagedProjectStage(
        id: 's1',
        titleKey: 'research',
        subKey: 'researchSub',
        status: ProjectStageStatus.done,
        rewardMinutes: 30,
      ),
      StagedProjectStage(
        id: 's2',
        titleKey: 'plant',
        subKey: 'plantSub',
        status: ProjectStageStatus.active,
        rewardMinutes: 40,
      ),
    ],
  );
}

StagedProjectSnapshot stagedProjectPrototypeFixture() {
  return const StagedProjectSnapshot(
    hasProject: true,
    stages: [
      StagedProjectStage(
        id: 's1',
        titleKey: 'research',
        subKey: 'researchSub',
        status: ProjectStageStatus.done,
        rewardMinutes: 30,
      ),
      StagedProjectStage(
        id: 's2',
        titleKey: 'plant',
        subKey: 'plantSub',
        status: ProjectStageStatus.active,
        rewardMinutes: 40,
      ),
      StagedProjectStage(
        id: 's3',
        titleKey: 'water',
        subKey: 'waterSub',
        status: ProjectStageStatus.locked,
        rewardMinutes: 50,
      ),
      StagedProjectStage(
        id: 's4',
        titleKey: 'harvest',
        subKey: 'harvestSub',
        status: ProjectStageStatus.locked,
        rewardMinutes: 80,
      ),
    ],
  );
}
