import 'package:flutter/foundation.dart';

/// Generation output kinds for SCR-FAT-043 (prototype FAT-043 + NotebookLM studio forms).
enum GenerationOutputKind {
  lesson,
  homework,
  quiz,
  flashcards,
  challenge,
  reviewGame,
  studyGuideFaq,
  audioOverview,
  conceptMindMap,
  timeline,
}

/// Mock source label (Rule 23 — discrete; copy lives in ARB).
enum GenerationSourceLabel { fractionsPage47 }

/// Multi-source grounding notebook item keys.
enum NotebookSourceKey { cameraPage47, teacherPdf, fatherVoice }

/// NotebookLM flexibility depth levels.
enum NotebookDepthLevel { quickBriefing, standardLesson, examCrunch }

/// NotebookLM explanation & audio tone styles.
enum NotebookToneStyle { simpleFusha, gulfWarm, bilingualStem }

@immutable
final class NotebookSourceItem {
  const NotebookSourceItem({
    required this.id,
    required this.sourceKey,
    required this.passageCount,
    this.includedInGrounding = true,
  });

  final String id;
  final NotebookSourceKey sourceKey;
  final int passageCount;
  final bool includedInGrounding;

  NotebookSourceItem copyWith({bool? includedInGrounding}) {
    return NotebookSourceItem(
      id: id,
      sourceKey: sourceKey,
      passageCount: passageCount,
      includedInGrounding: includedInGrounding ?? this.includedInGrounding,
    );
  }
}

const List<NotebookSourceItem> defaultNotebookSources = [
  NotebookSourceItem(
    id: 'src-cam-47',
    sourceKey: NotebookSourceKey.cameraPage47,
    passageCount: 4,
  ),
  NotebookSourceItem(
    id: 'src-pdf-denom',
    sourceKey: NotebookSourceKey.teacherPdf,
    passageCount: 3,
  ),
  NotebookSourceItem(
    id: 'src-voice-father',
    sourceKey: NotebookSourceKey.fatherVoice,
    passageCount: 2,
  ),
];

@immutable
final class NotebookFlexibilityConfig {
  const NotebookFlexibilityConfig({
    this.depth = NotebookDepthLevel.standardLesson,
    this.tone = NotebookToneStyle.simpleFusha,
    this.strictGrounding = true,
  });

  final NotebookDepthLevel depth;
  final NotebookToneStyle tone;
  final bool strictGrounding;

  NotebookFlexibilityConfig copyWith({
    NotebookDepthLevel? depth,
    NotebookToneStyle? tone,
    bool? strictGrounding,
  }) {
    return NotebookFlexibilityConfig(
      depth: depth ?? this.depth,
      tone: tone ?? this.tone,
      strictGrounding: strictGrounding ?? this.strictGrounding,
    );
  }
}

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
    this.sources = defaultNotebookSources,
    this.flexibility = const NotebookFlexibilityConfig(),
  });

  final GenerationSourceLabel source;
  final List<GenerationOutputItem> outputs;
  final List<NotebookSourceItem> sources;
  final NotebookFlexibilityConfig flexibility;

  bool get isEmpty => outputs.isEmpty;

  int get selectedCount =>
      outputs.where((o) => o.selected && !o.phaseLocked).length;

  int get activeSourceCount =>
      sources.where((s) => s.includedInGrounding).length;

  GenerationOutputsSnapshot withToggled(String id, bool selected) {
    return GenerationOutputsSnapshot(
      source: source,
      sources: sources,
      flexibility: flexibility,
      outputs: [
        for (final o in outputs)
          if (o.id == id && !o.phaseLocked)
            o.copyWith(selected: selected)
          else
            o,
      ],
    );
  }

  GenerationOutputsSnapshot withSourceToggled(String id, bool included) {
    return GenerationOutputsSnapshot(
      source: source,
      outputs: outputs,
      flexibility: flexibility,
      sources: [
        for (final s in sources)
          if (s.id == id) s.copyWith(includedInGrounding: included) else s,
      ],
    );
  }

  GenerationOutputsSnapshot withFlexibility(NotebookFlexibilityConfig next) {
    return GenerationOutputsSnapshot(
      source: source,
      outputs: outputs,
      sources: sources,
      flexibility: next,
    );
  }
}
