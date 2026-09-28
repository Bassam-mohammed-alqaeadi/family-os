import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/minutes.dart';

enum ChildTaskItemStatus { assigned, pendingApproval, completed }

@immutable
final class ChildTaskItem {
  const ChildTaskItem({
    required this.id,
    required this.titleKey,
    required this.reward,
    required this.status,
  });

  final String id;
  final String titleKey;

  /// Father-set reward — Minutes VO (Q-CEX-003 / Rule 4).
  final Minutes reward;
  final ChildTaskItemStatus status;

  /// ARB helper only.
  int get rewardMinutes => reward.inMinutes;

  ChildTaskItem copyWith({ChildTaskItemStatus? status}) {
    return ChildTaskItem(
      id: id,
      titleKey: titleKey,
      reward: reward,
      status: status ?? this.status,
    );
  }
}

@immutable
final class ChildTasksSnapshot {
  const ChildTasksSnapshot({this.tasks = const []});

  final List<ChildTaskItem> tasks;

  bool get isEmpty => tasks.isEmpty;
}
