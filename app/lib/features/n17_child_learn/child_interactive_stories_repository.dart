import 'package:family_os/features/n17_child_learn/child_interactive_stories_models.dart';

abstract class ChildInteractiveStoriesRepository {
  Future<ChildInteractiveStoriesSnapshot> load();
  Future<ChildInteractiveStoriesSnapshot> choose(String choiceId);
}

final class InMemoryChildInteractiveStoriesRepository
    implements ChildInteractiveStoriesRepository {
  InMemoryChildInteractiveStoriesRepository({
    ChildInteractiveStoriesSnapshot? seed,
  }) : _snap = seed ?? childInteractiveStoriesPrototypeFixture();

  ChildInteractiveStoriesSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildInteractiveStoriesSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildInteractiveStoriesSnapshot> choose(String choiceId) async {
    _snap = _snap.copyWith(lastChoiceId: choiceId);
    return _snap.copyWith();
  }

  void seed(ChildInteractiveStoriesSnapshot snap) => _snap = snap;

  String? get lastChoiceId => _snap.lastChoiceId;
}

final InMemoryChildInteractiveStoriesRepository
stage1ChildInteractiveStoriesRepository =
    InMemoryChildInteractiveStoriesRepository();

ChildInteractiveStoriesSnapshot childInteractiveStoriesEmptyFixture() =>
    const ChildInteractiveStoriesSnapshot();

ChildInteractiveStoriesSnapshot childInteractiveStoriesOneFixture() {
  return const ChildInteractiveStoriesSnapshot(
    hasStory: true,
    choices: [
      ChildStoryChoice(
        id: 'return',
        labelKey: 'returnBag',
        toastKey: 'toastReturn',
      ),
    ],
  );
}

ChildInteractiveStoriesSnapshot childInteractiveStoriesPrototypeFixture() {
  return const ChildInteractiveStoriesSnapshot(
    hasStory: true,
    choices: [
      ChildStoryChoice(
        id: 'return',
        labelKey: 'returnBag',
        toastKey: 'toastReturn',
      ),
      ChildStoryChoice(id: 'take', labelKey: 'takeBag', toastKey: 'toastTake'),
      ChildStoryChoice(id: 'ask', labelKey: 'askParent', toastKey: 'toastAsk'),
    ],
  );
}
