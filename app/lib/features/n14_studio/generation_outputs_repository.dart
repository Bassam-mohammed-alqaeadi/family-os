import 'package:family_os/features/n14_studio/generation_outputs_models.dart';

/// Rule 25 seam — Stage-1 mock generation outputs (no AI).
abstract class GenerationOutputsRepository {
  Future<GenerationOutputsSnapshot> load();
}

/// In-memory mock — prototype FAT-043 shape by default.
final class InMemoryGenerationOutputsRepository
    implements GenerationOutputsRepository {
  InMemoryGenerationOutputsRepository({GenerationOutputsSnapshot? seed})
    : _snap = seed ?? generationOutputsEmptyFixture();

  GenerationOutputsSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<GenerationOutputsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return GenerationOutputsSnapshot(
      source: _snap.source,
      outputs: List<GenerationOutputItem>.from(_snap.outputs),
      sources: List<NotebookSourceItem>.from(_snap.sources),
      flexibility: _snap.flexibility,
    );
  }

  void seed(GenerationOutputsSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton — empty (LDR-B5 / Owner 1C: no planted AI outputs).
final InMemoryGenerationOutputsRepository stage1GenerationOutputsRepository =
    InMemoryGenerationOutputsRepository();

/// Empty list — Rule 23 empty-state coverage.
GenerationOutputsSnapshot generationOutputsEmptyFixture() {
  return const GenerationOutputsSnapshot(outputs: []);
}

/// Prototype FAT-043 — five on + review game P1 locked off + NotebookLM outputs.
GenerationOutputsSnapshot generationOutputsPrototypeFixture() {
  return const GenerationOutputsSnapshot(
    source: GenerationSourceLabel.fractionsPage47,
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
        id: 'out-study-guide',
        kind: GenerationOutputKind.studyGuideFaq,
        selected: false,
      ),
      GenerationOutputItem(
        id: 'out-audio-overview',
        kind: GenerationOutputKind.audioOverview,
        selected: false,
      ),
      GenerationOutputItem(
        id: 'out-mind-map',
        kind: GenerationOutputKind.conceptMindMap,
        selected: false,
      ),
      GenerationOutputItem(
        id: 'out-timeline',
        kind: GenerationOutputKind.timeline,
        selected: false,
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
