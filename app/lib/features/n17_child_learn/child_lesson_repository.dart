import 'package:family_os/features/n17_child_learn/child_lesson_models.dart';

abstract class ChildLessonRepository {
  Future<ChildLessonSnapshot> load();
}

final class InMemoryChildLessonRepository implements ChildLessonRepository {
  InMemoryChildLessonRepository({ChildLessonSnapshot? seed})
    : _snap = seed ?? childLessonPrototypeFixture();

  ChildLessonSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildLessonSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildLessonSnapshot(
      titleKey: _snap.titleKey,
      hookKey: _snap.hookKey,
      bodyKey: _snap.bodyKey,
      progressPercent: _snap.progressPercent,
      pizzaFilled: List<bool>.from(_snap.pizzaFilled),
      nextScreenId: _snap.nextScreenId,
      tutorScreenId: _snap.tutorScreenId,
      rewardMinutes: _snap.rewardMinutes,
    );
  }

  void seed(ChildLessonSnapshot snap) => _snap = snap;
}

final InMemoryChildLessonRepository stage1ChildLessonRepository =
    InMemoryChildLessonRepository();

ChildLessonSnapshot childLessonEmptyFixture() => const ChildLessonSnapshot();

ChildLessonSnapshot childLessonOneFixture() {
  return const ChildLessonSnapshot(
    titleKey: 'addingFractions',
    hookKey: 'imaginePizza',
    bodyKey: 'pizzaFractionsBody',
    progressPercent: 40,
    pizzaFilled: [true, true, true, false, false, false, false],
    rewardMinutes: 10,
  );
}

ChildLessonSnapshot childLessonPrototypeFixture() {
  return const ChildLessonSnapshot(
    titleKey: 'addingFractions',
    hookKey: 'imaginePizza',
    bodyKey: 'pizzaFractionsBody',
    progressPercent: 60,
    pizzaFilled: [true, true, true, true, true, false, false],
    rewardMinutes: 10,
  );
}
