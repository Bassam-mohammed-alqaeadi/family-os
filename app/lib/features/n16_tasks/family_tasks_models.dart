import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/minutes.dart';

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
    required this.reward,
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

  /// Father-set reward — Minutes VO only (Q-CEX-003 / Rule 4).
  final Minutes reward;

  final FamilyTaskStatus status;

  /// Optional proof line for pending approval rows.
  final String? proofKey;

  /// ARB discriminator for when line.
  final String timeKey;

  /// ARB / toast helper — never use as economy authority.
  int get rewardMinutes => reward.inMinutes;

  FamilyChildTask copyWith({
    FamilyTaskStatus? status,
    String? proofKey,
    bool clearProofKey = false,
    Minutes? reward,
  }) {
    return FamilyChildTask(
      id: id,
      titleKey: titleKey,
      assigneeNameKey: assigneeNameKey,
      avatarKey: avatarKey,
      reward: reward ?? this.reward,
      status: status ?? this.status,
      proofKey: clearProofKey ? null : (proofKey ?? this.proofKey),
      timeKey: timeKey,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'titleKey': titleKey,
    'assigneeNameKey': assigneeNameKey,
    'avatarKey': avatarKey,
    'rewardMinutes': reward.inMinutes,
    'status': status.name,
    'proofKey': proofKey,
    'timeKey': timeKey,
  };

  static FamilyChildTask fromJson(Map<String, Object?> json) {
    final statusRaw = json['status']?.toString() ?? 'assigned';
    final status = FamilyTaskStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => FamilyTaskStatus.assigned,
    );
    final mins = json['rewardMinutes'];
    final rewardInt = mins is int
        ? mins
        : int.tryParse(mins?.toString() ?? '') ?? 0;
    return FamilyChildTask(
      id: json['id']?.toString() ?? '',
      titleKey: json['titleKey']?.toString() ?? '',
      assigneeNameKey: json['assigneeNameKey']?.toString() ?? 'childOne',
      avatarKey: json['avatarKey']?.toString() ?? 'lion',
      reward: Minutes(rewardInt < 0 ? 0 : rewardInt),
      status: status,
      proofKey: json['proofKey']?.toString(),
      timeKey: json['timeKey']?.toString() ?? 'today',
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

  Map<String, Object?> toJson() => {
    'id': id,
    'titleKey': titleKey,
    'status': status.name,
    'timeKey': timeKey,
  };

  static MotherHelpTask fromJson(Map<String, Object?> json) {
    final statusRaw = json['status']?.toString() ?? 'open';
    final status = MotherHelpTaskStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => MotherHelpTaskStatus.open,
    );
    return MotherHelpTask(
      id: json['id']?.toString() ?? '',
      titleKey: json['titleKey']?.toString() ?? '',
      status: status,
      timeKey: json['timeKey']?.toString() ?? 'today',
    );
  }
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

  /// Tasks awaiting father/mother approve (FAT-054 pending card).
  List<FamilyChildTask> get pendingApproval => childTasks
      .where((t) => t.status == FamilyTaskStatus.pendingApproval)
      .toList(growable: false);

  Map<String, Object?> toJson() => {
    'childTasks': childTasks.map((t) => t.toJson()).toList(),
    'motherHelpTasks': motherHelpTasks.map((t) => t.toJson()).toList(),
  };

  static FamilyTasksSnapshot fromJson(Map<String, Object?> json) {
    final kidsRaw = json['childTasks'];
    final helpRaw = json['motherHelpTasks'];
    final kids = <FamilyChildTask>[];
    if (kidsRaw is List) {
      for (final e in kidsRaw) {
        if (e is Map) {
          kids.add(
            FamilyChildTask.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    final help = <MotherHelpTask>[];
    if (helpRaw is List) {
      for (final e in helpRaw) {
        if (e is Map) {
          help.add(
            MotherHelpTask.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
      }
    }
    return FamilyTasksSnapshot(childTasks: kids, motherHelpTasks: help);
  }
}
