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

/// Mock source label (Rule 23 — discrete; copy lives in ARB).
enum GenerationSourceLabel { fractionsPage47 }

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
    this.source = GenerationSourceLabel.fractionsPage47,
    this.outputs = const [],
  });

  final GenerationSourceLabel source;
  final List<GenerationOutputItem> outputs;

  bool get isEmpty => outputs.isEmpty;

  int get selectedCount =>
      outputs.where((o) => o.selected && !o.phaseLocked).length;

  GenerationOutputsSnapshot withToggled(String id, bool selected) {
    return GenerationOutputsSnapshot(
      source: source,
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
