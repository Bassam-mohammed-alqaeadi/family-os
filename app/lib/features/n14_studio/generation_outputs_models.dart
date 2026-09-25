import 'package:flutter/foundation.dart';

/// Generation output kinds for SCR-FAT-043 (prototype FAT-043 · studio forms).
enum GenerationOutputKind {
  lesson,
  homework,
  quiz,
  flashcards,
  challenge,
  reviewGame,
}

/// The source's ARB key, not its copy: rows carry the mechanical ref in
/// `content_pack.source_ref` and the screen maps this key to its own line
/// (Rule 23 — copy lives in ARB, never in lib/features).
const kGenerationSourceFractionsKey = 'generationOutputsSourceFractions';

@immutable
final class GenerationOutputItem {
  const GenerationOutputItem({
    required this.id,
    required this.kind,
    this.selected = true,
    this.phaseLocked = false,
  });

  final String id;
  final GenerationOutputKind kind;

  /// Parent toggle — selected outputs feed FAT-044.
  final bool selected;

  /// P1 / not-yet — switch stays off and cannot enable (prototype review game).
  final bool phaseLocked;

  GenerationOutputItem copyWith({bool? selected}) {
    return GenerationOutputItem(
      id: id,
      kind: kind,
      selected: selected ?? this.selected,
      phaseLocked: phaseLocked,
    );
  }
}

@immutable
final class GenerationOutputsSnapshot {
  const GenerationOutputsSnapshot({
    this.sourceKey = kGenerationSourceFractionsKey,
    this.outputs = const [],
  });

  final String sourceKey;
  final List<GenerationOutputItem> outputs;

  bool get isEmpty => outputs.isEmpty;

  int get selectedCount =>
      outputs.where((o) => o.selected && !o.phaseLocked).length;

  GenerationOutputsSnapshot withToggled(String id, bool selected) {
    return GenerationOutputsSnapshot(
      sourceKey: sourceKey,
      outputs: [
        for (final o in outputs)
          if (o.id == id && !o.phaseLocked)
            o.copyWith(selected: selected)
          else
            o,
      ],
    );
  }
}
