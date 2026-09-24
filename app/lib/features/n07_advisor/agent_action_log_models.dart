import 'package:flutter/foundation.dart';

enum AgentActionState { pending, blessed, undone }

@immutable
final class AgentWeeklyStat {
  const AgentWeeklyStat({
    required this.id,
    required this.titleKey,
    required this.metaKey,
    required this.ruleKey,
  });
  final String id;
  final String titleKey;
  final String metaKey;
  final String ruleKey;
}

@immutable
final class AgentActionLogSnapshot {
  const AgentActionLogSnapshot({
    this.hasFamily = false,
    this.hasLiveAction = false,
    this.ruleKey = 'autoReward',
    this.childLabelKey = 'childOne',
    this.minutesGranted = 15,
    this.taskKeys = const ['mathHw', 'room'],
    this.appTargetKey = 'blocksApp',
    this.secondsLeft = 342,
    this.state = AgentActionState.pending,
    this.undoMsgKey = 'gentleUndo',
    this.weekly = const [],
  });

  final bool hasFamily;
  final bool hasLiveAction;
  final String ruleKey;
  final String childLabelKey;
  final int minutesGranted;
  final List<String> taskKeys;
  final String appTargetKey;
  final int secondsLeft;
  final AgentActionState state;
  final String undoMsgKey;
  final List<AgentWeeklyStat> weekly;

  bool get isEmpty => !hasFamily;

  AgentActionLogSnapshot copyWith({AgentActionState? state, int? secondsLeft}) {
    return AgentActionLogSnapshot(
      hasFamily: hasFamily,
      hasLiveAction: hasLiveAction,
      ruleKey: ruleKey,
      childLabelKey: childLabelKey,
      minutesGranted: minutesGranted,
      taskKeys: taskKeys,
      appTargetKey: appTargetKey,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      state: state ?? this.state,
      undoMsgKey: undoMsgKey,
      weekly: weekly,
    );
  }
}
