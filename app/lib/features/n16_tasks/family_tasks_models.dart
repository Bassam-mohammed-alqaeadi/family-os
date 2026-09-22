import 'package:flutter/foundation.dart';

/// Child task lifecycle on SCR-FAT-054 (prototype FAT-054).
enum FamilyTaskStatus { assigned, pendingApproval, completed }

/// Mother help-request lifecycle — no reward minutes (prototype §7).
enum MotherHelpTaskStatus { open, done }

@immutable
final class FamilyChildTask {
  const FamilyChildTask({
    required this.id,
    required this.titleKey,
    required this.assigneeNameKey,
    required this.avatarKey,
    required this.rewardMinutes,
    required this.status,
    this.proofKey,
    required this.timeKey,
  });

  final String id;

  /// ARB discriminator for title (Rule 23 — no planted person names).
  final String titleKey;

  /// childOne / childTwo / childThree (Rule 23).
  final String assigneeNameKey;

  /// Emoji avatar key — lion / cat / panda.
  final String avatarKey;
  final int rewardMinutes;
  final FamilyTaskStatus status;

  /// Optional proof line for pending approval rows.
  final String? proofKey;

  /// ARB discriminator for when line.
  final String timeKey;

  FamilyChildTask copyWith({
    FamilyTaskStatus? status,
  }) {
    return FamilyChildTask(
      id: id,
      titleKey: titleKey,
      assigneeNameKey: assigneeNameKey,
      avatarKey: avatarKey,
      rewardMinutes: rewardMinutes,
      status: status ?? this.status,
      proofKey: proofKey,
      timeKey: timeKey,
    );
  }
}

@immutable
final class MotherHelpTask {
  const MotherHelpTask({
    required this.id,
    required this.titleKey,
    required this.status,
    required this.timeKey,
  });

  final String id;
  final String titleKey;
  final MotherHelpTaskStatus status;
  final String timeKey;
}

@immutable
final class FamilyTasksSnapshot {
  const FamilyTasksSnapshot({
    this.childTasks = const [],
    this.motherHelpTasks = const [],
  });

  final List<FamilyChildTask> childTasks;
  final List<MotherHelpTask> motherHelpTasks;

  bool get isEmpty => childTasks.isEmpty && motherHelpTasks.isEmpty;

  List<FamilyChildTask> get pendingApproval => childTasks
      .where((t) => t.status == FamilyTaskStatus.pendingApproval)
      .toList();
}
