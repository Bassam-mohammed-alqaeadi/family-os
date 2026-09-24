import 'package:flutter/foundation.dart';

enum ProjectStageStatus { done, active, locked }

@immutable
final class StagedProjectStage {
  const StagedProjectStage({
    required this.id,
    required this.titleKey,
    required this.subKey,
    required this.status,
    this.rewardMinutes = 0,
  });
  final String id;
  final String titleKey;
  final String subKey;
  final ProjectStageStatus status;
  final int rewardMinutes;
}

@immutable
final class StagedProjectSnapshot {
  const StagedProjectSnapshot({
    this.hasProject = false,
    this.titleKey = 'homeGarden',
    this.childLabelKey = 'childOne',
    this.stageCount = 4,
    this.weeks = 6,
    this.currentStage = 2,
    this.progress = 0.4,
    this.stages = const [],
  });

  final bool hasProject;
  final String titleKey;
  final String childLabelKey;
  final int stageCount;
  final int weeks;
  final int currentStage;
  final double progress;
  final List<StagedProjectStage> stages;

  bool get isEmpty => !hasProject;

  StagedProjectSnapshot copyWith({List<StagedProjectStage>? stages}) {
    return StagedProjectSnapshot(
      hasProject: hasProject,
      titleKey: titleKey,
      childLabelKey: childLabelKey,
      stageCount: stageCount,
      weeks: weeks,
      currentStage: currentStage,
      progress: progress,
      stages: stages ?? this.stages,
    );
  }
}
