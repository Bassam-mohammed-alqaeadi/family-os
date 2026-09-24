import 'package:family_os/features/n17_child_learn/child_tutor_models.dart';

abstract class ChildTutorRepository {
  Future<ChildTutorSnapshot> load();
}

final class InMemoryChildTutorRepository implements ChildTutorRepository {
  InMemoryChildTutorRepository({ChildTutorSnapshot? seed})
    : _snap = seed ?? childTutorPrototypeFixture();

  ChildTutorSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildTutorSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return ChildTutorSnapshot(
      bubbles: List<ChildTutorBubble>.from(_snap.bubbles),
      choices: List<ChildTutorChoice>.from(_snap.choices),
      hasThread: _snap.hasThread,
    );
  }

  void seed(ChildTutorSnapshot snap) => _snap = snap;
}

final InMemoryChildTutorRepository stage1ChildTutorRepository =
    InMemoryChildTutorRepository();

ChildTutorSnapshot childTutorEmptyFixture() => const ChildTutorSnapshot();

ChildTutorSnapshot childTutorOneFixture() {
  return const ChildTutorSnapshot(
    hasThread: true,
    bubbles: [
      ChildTutorBubble(
        id: 'b1',
        kind: ChildTutorBubbleKind.tutor,
        textKey: 'greetStuck',
      ),
    ],
    choices: [
      ChildTutorChoice(id: 'c10', labelKey: 'ten', replyKey: 'replyTen'),
    ],
  );
}

ChildTutorSnapshot childTutorPrototypeFixture() {
  return const ChildTutorSnapshot(
    hasThread: true,
    bubbles: [
      ChildTutorBubble(
        id: 'b1',
        kind: ChildTutorBubbleKind.tutor,
        textKey: 'greetStuck',
      ),
      ChildTutorBubble(
        id: 'b2',
        kind: ChildTutorBubbleKind.child,
        textKey: 'childDifferentDenom',
      ),
      ChildTutorBubble(
        id: 'b3',
        kind: ChildTutorBubbleKind.tutor,
        textKey: 'tutorLcmPrompt',
      ),
    ],
    choices: [
      ChildTutorChoice(id: 'c10', labelKey: 'ten', replyKey: 'replyTen'),
      ChildTutorChoice(id: 'c7', labelKey: 'seven', replyKey: 'replySeven'),
    ],
  );
}
