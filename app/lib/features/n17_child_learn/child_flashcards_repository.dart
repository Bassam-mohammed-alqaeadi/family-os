import 'package:family_os/features/n17_child_learn/child_flashcards_models.dart';

abstract class ChildFlashcardsRepository {
  Future<ChildFlashcardsSnapshot> load();
  Future<ChildFlashcardsSnapshot> flip();
  Future<ChildFlashcardsSnapshot> next();
  Future<ChildFlashcardsSnapshot> previous();
  Future<ChildFlashcardsSnapshot> markKnown();
  Future<ChildFlashcardsSnapshot> markReview();
}

final class InMemoryChildFlashcardsRepository
    implements ChildFlashcardsRepository {
  InMemoryChildFlashcardsRepository({ChildFlashcardsSnapshot? seed})
    : _snap = seed ?? childFlashcardsPrototypeFixture();

  ChildFlashcardsSnapshot _snap;
  Future<void> Function()? loadGate;

  ChildFlashcardsSnapshot _copy() {
    return ChildFlashcardsSnapshot(
      lessonTitleKey: _snap.lessonTitleKey,
      sourceNameKey: _snap.sourceNameKey,
      cards: List<ChildFlashcard>.from(_snap.cards),
      currentIndex: _snap.currentIndex,
      flipped: _snap.flipped,
      quizScreenId: _snap.quizScreenId,
      quizRewardMinutes: _snap.quizRewardMinutes,
    );
  }

  void _set({int? currentIndex, bool? flipped}) {
    _snap = ChildFlashcardsSnapshot(
      lessonTitleKey: _snap.lessonTitleKey,
      sourceNameKey: _snap.sourceNameKey,
      cards: _snap.cards,
      currentIndex: currentIndex ?? _snap.currentIndex,
      flipped: flipped ?? _snap.flipped,
      quizScreenId: _snap.quizScreenId,
      quizRewardMinutes: _snap.quizRewardMinutes,
    );
  }

  @override
  Future<ChildFlashcardsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy();
  }

  @override
  Future<ChildFlashcardsSnapshot> flip() async {
    _set(flipped: !_snap.flipped);
    return _copy();
  }

  @override
  Future<ChildFlashcardsSnapshot> next() async {
    if (_snap.cards.isEmpty) return _copy();
    final next = (_snap.currentIndex + 1).clamp(0, _snap.cards.length - 1);
    _set(currentIndex: next, flipped: false);
    return _copy();
  }

  @override
  Future<ChildFlashcardsSnapshot> previous() async {
    if (_snap.cards.isEmpty) return _copy();
    final prev = (_snap.currentIndex - 1).clamp(0, _snap.cards.length - 1);
    _set(currentIndex: prev, flipped: false);
    return _copy();
  }

  @override
  Future<ChildFlashcardsSnapshot> markKnown() async {
    if (_snap.currentIndex < _snap.cards.length - 1) {
      _set(currentIndex: _snap.currentIndex + 1, flipped: false);
    } else {
      _set(flipped: false);
    }
    return _copy();
  }

  @override
  Future<ChildFlashcardsSnapshot> markReview() async {
    _set(flipped: false);
    return _copy();
  }

  void seed(ChildFlashcardsSnapshot snap) => _snap = snap;
}

final InMemoryChildFlashcardsRepository stage1ChildFlashcardsRepository =
    InMemoryChildFlashcardsRepository();

ChildFlashcardsSnapshot childFlashcardsEmptyFixture() {
  return const ChildFlashcardsSnapshot();
}

ChildFlashcardsSnapshot childFlashcardsOneFixture() {
  return const ChildFlashcardsSnapshot(
    lessonTitleKey: 'fractionsOps',
    sourceNameKey: 'mathPdf',
    cards: [
      ChildFlashcard(
        id: 'c1',
        questionKey: 'qOrdinaryFraction',
        answerKey: 'aOrdinaryFraction',
        hintKey: 'hPizza',
      ),
    ],
  );
}

ChildFlashcardsSnapshot childFlashcardsPrototypeFixture() {
  return const ChildFlashcardsSnapshot(
    lessonTitleKey: 'fractionsOps',
    sourceNameKey: 'mathPdf',
    cards: [
      ChildFlashcard(
        id: 'c1',
        questionKey: 'qOrdinaryFraction',
        answerKey: 'aOrdinaryFraction',
        hintKey: 'hPizza',
      ),
      ChildFlashcard(
        id: 'c2',
        questionKey: 'qAddNumerators',
        answerKey: 'aAddNumerators',
        hintKey: 'hSameDenom',
      ),
    ],
  );
}
