import 'package:flutter/foundation.dart';

/// Courage-minute reward options (prototype FAT-055).
enum CreateTaskCourageMinutes { ten, fifteen, twentyFive }

/// Extra playtime reward options (prototype FAT-055).
enum CreateTaskPlaytimeMinutes { ten, fifteen, thirty }

extension CreateTaskCourageMinutesX on CreateTaskCourageMinutes {
  int get value => switch (this) {
    CreateTaskCourageMinutes.ten => 10,
    CreateTaskCourageMinutes.fifteen => 15,
    CreateTaskCourageMinutes.twentyFive => 25,
  };
}

extension CreateTaskPlaytimeMinutesX on CreateTaskPlaytimeMinutes {
  int get value => switch (this) {
    CreateTaskPlaytimeMinutes.ten => 10,
    CreateTaskPlaytimeMinutes.fifteen => 15,
    CreateTaskPlaytimeMinutes.thirty => 30,
  };
}

@immutable
final class CreateTaskChild {
  const CreateTaskChild({
    required this.id,
    required this.nameKey,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
}

@immutable
final class CreateTaskDraft {
  const CreateTaskDraft({
    this.title = '',
    this.assigneeNameKey = 'childOne',
    this.courageMinutes = CreateTaskCourageMinutes.fifteen,
    this.playtimeMinutes = CreateTaskPlaytimeMinutes.fifteen,
  });

  final String title;

  /// childOne / childTwo / childThree / mother — Rule 23 nameKeys only.
  final String assigneeNameKey;
  final CreateTaskCourageMinutes courageMinutes;
  final CreateTaskPlaytimeMinutes playtimeMinutes;

  bool get isMotherAssignee => assigneeNameKey == 'mother';

  CreateTaskDraft copyWith({
    String? title,
    String? assigneeNameKey,
    CreateTaskCourageMinutes? courageMinutes,
    CreateTaskPlaytimeMinutes? playtimeMinutes,
  }) {
    return CreateTaskDraft(
      title: title ?? this.title,
      assigneeNameKey: assigneeNameKey ?? this.assigneeNameKey,
      courageMinutes: courageMinutes ?? this.courageMinutes,
      playtimeMinutes: playtimeMinutes ?? this.playtimeMinutes,
    );
  }
}

@immutable
final class CreateTaskSnapshot {
  const CreateTaskSnapshot({
    this.children = const [],
    this.draft = const CreateTaskDraft(),
    this.submittedCount = 0,
  });

  final List<CreateTaskChild> children;
  final CreateTaskDraft draft;
  final int submittedCount;

  bool get isEmpty => children.isEmpty;

  CreateTaskSnapshot copyWith({
    List<CreateTaskChild>? children,
    CreateTaskDraft? draft,
    int? submittedCount,
  }) {
    return CreateTaskSnapshot(
      children: children ?? this.children,
      draft: draft ?? this.draft,
      submittedCount: submittedCount ?? this.submittedCount,
    );
  }
}
