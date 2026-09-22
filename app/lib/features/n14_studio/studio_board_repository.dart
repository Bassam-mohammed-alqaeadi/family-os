import 'package:family_os/features/n14_studio/studio_board_models.dart';

/// Rule 25 seam — Stage-1 mock studio hub (no AI / camera / upload).
abstract class StudioBoardRepository {
  Future<StudioBoardSnapshot> load();
}

/// In-memory mock — empty by default (Rule 23); tests inject fixtures.
final class InMemoryStudioBoardRepository implements StudioBoardRepository {
  InMemoryStudioBoardRepository({StudioBoardSnapshot? seed})
    : _snap = seed ?? const StudioBoardSnapshot();

  StudioBoardSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<StudioBoardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return StudioBoardSnapshot(
      suggestions: List<StudioSuggestion>.from(_snap.suggestions),
      recent: List<StudioContentItem>.from(_snap.recent),
    );
  }

  void seed(StudioBoardSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (empty until a screen/test seeds).
final InMemoryStudioBoardRepository stage1StudioBoardRepository =
    InMemoryStudioBoardRepository();

/// One suggestion + one recent item.
StudioBoardSnapshot studioBoardOneFixture() {
  return const StudioBoardSnapshot(
    suggestions: [
      StudioSuggestion(id: 'sug-fractions', kind: StudioSuggestionKind.fractions),
    ],
    recent: [
      StudioContentItem(
        id: 'cnt-quiz-1',
        kind: StudioContentKind.quiz,
        status: StudioContentStatus.active,
      ),
    ],
  );
}

/// Prototype FAT-040 shape — two suggestions + three recent rows.
StudioBoardSnapshot studioBoardManyFixture() {
  return const StudioBoardSnapshot(
    suggestions: [
      StudioSuggestion(id: 'sug-fractions', kind: StudioSuggestionKind.fractions),
      StudioSuggestion(id: 'sug-wird', kind: StudioSuggestionKind.quranWird),
    ],
    recent: [
      StudioContentItem(
        id: 'cnt-quiz-1',
        kind: StudioContentKind.quiz,
        status: StudioContentStatus.active,
      ),
      StudioContentItem(
        id: 'cnt-cards-1',
        kind: StudioContentKind.flashcards,
        status: StudioContentStatus.progress,
      ),
      StudioContentItem(
        id: 'cnt-wird-1',
        kind: StudioContentKind.quranWird,
        status: StudioContentStatus.excellent,
      ),
    ],
  );
}
