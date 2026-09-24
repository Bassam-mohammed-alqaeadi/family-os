import 'package:flutter/foundation.dart';

@immutable
final class ChildSmartPlanSnapshot {
  const ChildSmartPlanSnapshot({
    this.hasPlan = false,
    this.gapKey = 'times7',
    this.projectKey = 'homeGarden',
    this.projectStageKey = 'stage2',
    this.projectDone = false,
    this.pathDone = 3,
    this.pathTotal = 6,
    this.planStarted = false,
  });

  final bool hasPlan;
  final String gapKey;
  final String projectKey;
  final String projectStageKey;
  final bool projectDone;
  final int pathDone;
  final int pathTotal;
  final bool planStarted;

  bool get isEmpty => !hasPlan;

  ChildSmartPlanSnapshot copyWith({bool? planStarted, bool? projectDone}) {
    return ChildSmartPlanSnapshot(
      hasPlan: hasPlan,
      gapKey: gapKey,
      projectKey: projectKey,
      projectStageKey: projectStageKey,
      projectDone: projectDone ?? this.projectDone,
      pathDone: pathDone,
      pathTotal: pathTotal,
      planStarted: planStarted ?? this.planStarted,
    );
  }
}
