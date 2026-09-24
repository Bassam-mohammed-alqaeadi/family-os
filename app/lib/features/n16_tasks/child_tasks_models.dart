import 'package:flutter/foundation.dart';

enum ChildTaskItemStatus { assigned, pendingApproval, completed }

@immutable
final class ChildTaskItem {
  const ChildTaskItem({
    required this.id,
    required this.titleKey,
    required this.rewardMinutes,
    required this.status,
  });

  final String id;
  final String titleKey;

  /// Minutes-only reward set by father (ع-١ / ق-٢).
  final int rewardMinutes;
  final ChildTaskItemStatus status;

  ChildTaskItem copyWith({ChildTaskItemStatus? status}) {
    return ChildTaskItem(
      id: id,
      titleKey: titleKey,
      rewardMinutes: rewardMinutes,
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
