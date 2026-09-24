import 'package:family_os/features/n17_child_learn/child_result_models.dart';

abstract class ChildResultRepository {
  Future<ChildResultSnapshot> load();
}

final class InMemoryChildResultRepository implements ChildResultRepository {
  InMemoryChildResultRepository({ChildResultSnapshot? seed})
    : _snap = seed ?? childResultPrototypeFixture();

  ChildResultSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildResultSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildResultSnapshot(
      scoreCorrect: _snap.scoreCorrect,
      scoreTotal: _snap.scoreTotal,
      praiseKey: _snap.praiseKey,
      missedTitleKey: _snap.missedTitleKey,
      missedBodyKey: _snap.missedBodyKey,
      rewards: List<ChildResultRewardRow>.from(_snap.rewards),
      reviewScreenId: _snap.reviewScreenId,
      learnHomeScreenId: _snap.learnHomeScreenId,
    );
  }

  void seed(ChildResultSnapshot snap) => _snap = snap;
}

final InMemoryChildResultRepository stage1ChildResultRepository =
    InMemoryChildResultRepository();

ChildResultSnapshot childResultEmptyFixture() => const ChildResultSnapshot();

ChildResultSnapshot childResultOneFixture() {
  return const ChildResultSnapshot(
    scoreCorrect: 1,
    scoreTotal: 1,
    praiseKey: 'masteredAdd',
    rewards: [
      ChildResultRewardRow(id: 'r1', titleKey: 'wallet20', tagKey: 'arrived'),
    ],
  );
}

ChildResultSnapshot childResultPrototypeFixture() {
  return const ChildResultSnapshot(
    scoreCorrect: 9,
    scoreTotal: 10,
    praiseKey: 'masteredAdd',
    missedTitleKey: 'missedQ7',
    missedBodyKey: 'missedDivisionOk',
    rewards: [
      ChildResultRewardRow(id: 'r1', titleKey: 'wallet20', tagKey: 'arrived'),
      ChildResultRewardRow(id: 'r2', titleKey: 'play15', tagKey: 'added'),
      ChildResultRewardRow(
        id: 'r3',
        titleKey: 'bonus30',
        subtitleKey: 'nearLevel4',
        tagKey: 'progress370',
      ),
    ],
  );
}
