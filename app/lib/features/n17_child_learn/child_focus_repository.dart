import 'package:family_os/features/n17_child_learn/child_focus_models.dart';

abstract class ChildFocusRepository {
  Future<ChildFocusSnapshot> load();
  Future<ChildFocusSnapshot> startSession();
}

final class InMemoryChildFocusRepository implements ChildFocusRepository {
  InMemoryChildFocusRepository({ChildFocusSnapshot? seed})
    : _snap = seed ?? childFocusPrototypeFixture();

  ChildFocusSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildFocusSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildFocusSnapshot> startSession() async {
    _snap = _snap.copyWith(sessionActive: true);
    return _snap.copyWith();
  }

  void seed(ChildFocusSnapshot snap) => _snap = snap;
}

final InMemoryChildFocusRepository stage1ChildFocusRepository =
    InMemoryChildFocusRepository();

ChildFocusSnapshot childFocusEmptyFixture() =>
    const ChildFocusSnapshot(sessionMinutes: 0);

ChildFocusSnapshot childFocusOneFixture() =>
    const ChildFocusSnapshot(sessionMinutes: 25);

ChildFocusSnapshot childFocusPrototypeFixture() => const ChildFocusSnapshot(
  sessionMinutes: 25,
  praiseMessageKey: 'resistDistraction',
);
