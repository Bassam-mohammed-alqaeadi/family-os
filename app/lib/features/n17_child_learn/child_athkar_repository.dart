import 'package:family_os/features/n17_child_learn/child_athkar_models.dart';

abstract class ChildAthkarRepository {
  Future<ChildAthkarSnapshot> load();
  Future<ChildAthkarSnapshot> markSaid();
}

final class InMemoryChildAthkarRepository implements ChildAthkarRepository {
  InMemoryChildAthkarRepository({ChildAthkarSnapshot? seed})
    : _snap = seed ?? childAthkarPrototypeFixture();

  ChildAthkarSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildAthkarSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildAthkarSnapshot> markSaid() async {
    final next = (_snap.done + 1).clamp(0, _snap.total);
    _snap = _snap.copyWith(done: next);
    return _snap.copyWith();
  }

  void seed(ChildAthkarSnapshot snap) => _snap = snap;
}

final InMemoryChildAthkarRepository stage1ChildAthkarRepository =
    InMemoryChildAthkarRepository();

ChildAthkarSnapshot childAthkarEmptyFixture() => const ChildAthkarSnapshot();

ChildAthkarSnapshot childAthkarOneFixture() {
  return const ChildAthkarSnapshot(hasSession: true, done: 0, total: 3);
}

ChildAthkarSnapshot childAthkarPrototypeFixture() {
  return const ChildAthkarSnapshot(hasSession: true, done: 4, total: 10);
}
