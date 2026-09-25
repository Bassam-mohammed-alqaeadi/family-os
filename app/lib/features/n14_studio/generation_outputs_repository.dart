import 'package:family_os/features/n14_studio/generation_outputs_models.dart';

/// Rule 25 seam — Stage-1 mock generation outputs (no AI).
abstract class GenerationOutputsRepository {
  Future<GenerationOutputsSnapshot> load();
}

/// In-memory mock — prototype FAT-043 shape by default.
final class InMemoryGenerationOutputsRepository
    implements GenerationOutputsRepository {
  InMemoryGenerationOutputsRepository({GenerationOutputsSnapshot? seed})
    : _snap = seed ?? generationOutputsPrototypeFixture();

  GenerationOutputsSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<GenerationOutputsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return GenerationOutputsSnapshot(
      sourceKey: _snap.sourceKey,
      outputs: List<GenerationOutputItem>.from(_snap.outputs),
    );
  }

  void seed(GenerationOutputsSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryGenerationOutputsRepository stage1GenerationOutputsRepository =
    InMemoryGenerationOutputsRepository();

/// Empty list — Rule 23 empty-state coverage.
GenerationOutputsSnapshot generationOutputsEmptyFixture() {
  return const GenerationOutputsSnapshot(outputs: []);
}

/// Prototype FAT-043 — five on + review game P1 locked off.
GenerationOutputsSnapshot generationOutputsPrototypeFixture() {
  return const GenerationOutputsSnapshot(
    sourceKey: kGenerationSourceFractionsKey,
    outputs: [
      GenerationOutputItem(id: 'out-lesson', kind: GenerationOutputKind.lesson),
      GenerationOutputItem(
        id: 'out-homework',
        kind: GenerationOutputKind.homework,
      ),
      GenerationOutputItem(id: 'out-quiz', kind: GenerationOutputKind.quiz),
      GenerationOutputItem(
        id: 'out-flashcards',
        kind: GenerationOutputKind.flashcards,
      ),
      GenerationOutputItem(
        id: 'out-challenge',
        kind: GenerationOutputKind.challenge,
      ),
      GenerationOutputItem(
        id: 'out-review',
        kind: GenerationOutputKind.reviewGame,
        selected: false,
        phaseLocked: true,
      ),
    ],
  );
}
