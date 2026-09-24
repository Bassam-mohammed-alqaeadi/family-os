import 'package:family_os/features/n17_child_learn/child_daily_review_models.dart';

abstract class ChildDailyReviewRepository {
  Future<ChildDailyReviewSnapshot> load();
  Future<ChildDailyReviewSnapshot> completeSession();
}

final class InMemoryChildDailyReviewRepository
    implements ChildDailyReviewRepository {
  InMemoryChildDailyReviewRepository({ChildDailyReviewSnapshot? seed})
    : _snap = seed ?? childDailyReviewPrototypeFixture();

  ChildDailyReviewSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildDailyReviewSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildDailyReviewSnapshot> completeSession() async {
    _snap = _snap.copyWith(sessionDone: true);
    return _snap.copyWith();
  }

  void seed(ChildDailyReviewSnapshot snap) => _snap = snap;
}

final InMemoryChildDailyReviewRepository stage1ChildDailyReviewRepository =
    InMemoryChildDailyReviewRepository();

ChildDailyReviewSnapshot childDailyReviewEmptyFixture() =>
    const ChildDailyReviewSnapshot();

ChildDailyReviewSnapshot childDailyReviewOneFixture() {
  return const ChildDailyReviewSnapshot(
    hasCards: true,
    cards: [
      ChildReviewCard(id: 'c1', titleKey: 'fractions', metaKey: 'threeDays'),
    ],
  );
}

ChildDailyReviewSnapshot childDailyReviewPrototypeFixture() {
  return const ChildDailyReviewSnapshot(
    hasCards: true,
    rewardMinutes: 10,
    cards: [
      ChildReviewCard(id: 'c1', titleKey: 'fractions', metaKey: 'threeDays'),
      ChildReviewCard(id: 'c2', titleKey: 'unit4', metaKey: 'oneWeek'),
      ChildReviewCard(
        id: 'c3',
        titleKey: 'waterCycle',
        metaKey: 'twiceStrong',
        strong: true,
      ),
    ],
  );
}
