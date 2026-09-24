import 'package:family_os/features/n02_day/child_call_play_models.dart';

abstract class ChildCallPlayRepository {
  Future<ChildCallPlaySnapshot> load();
  Future<ChildCallPlaySnapshot> openGame(String id);
}

final class InMemoryChildCallPlayRepository implements ChildCallPlayRepository {
  InMemoryChildCallPlayRepository({ChildCallPlaySnapshot? seed})
    : _snap = seed ?? childCallPlayPrototypeFixture();

  ChildCallPlaySnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<ChildCallPlaySnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _snap.copyWith();
  }

  @override
  Future<ChildCallPlaySnapshot> openGame(String id) async {
    _snap = _snap.copyWith(lastGameId: id);
    return _snap.copyWith();
  }

  void seed(ChildCallPlaySnapshot snap) => _snap = snap;

  String? get lastGameId => _snap.lastGameId;
}

final InMemoryChildCallPlayRepository stage1ChildCallPlayRepository =
    InMemoryChildCallPlayRepository();

ChildCallPlaySnapshot childCallPlayEmptyFixture() =>
    const ChildCallPlaySnapshot();

ChildCallPlaySnapshot childCallPlayOneFixture() {
  return const ChildCallPlaySnapshot(
    hasCall: true,
    games: [
      CallPlayGame(
        id: 'draw',
        titleKey: 'draw',
        subKey: 'drawSub',
        emoji: '🎨',
        toastKey: 'toastDraw',
        primary: true,
      ),
    ],
  );
}

ChildCallPlaySnapshot childCallPlayPrototypeFixture() {
  return const ChildCallPlaySnapshot(
    hasCall: true,
    games: [
      CallPlayGame(
        id: 'draw',
        titleKey: 'draw',
        subKey: 'drawSub',
        emoji: '🎨',
        toastKey: 'toastDraw',
        primary: true,
      ),
      CallPlayGame(
        id: 'xo',
        titleKey: 'xo',
        subKey: 'xoSub',
        emoji: '❌⭕',
        toastKey: 'toastXo',
      ),
      CallPlayGame(
        id: 'quiz',
        titleKey: 'quiz',
        subKey: 'quizSub',
        emoji: '🧠',
        toastKey: 'toastQuiz',
      ),
    ],
  );
}
