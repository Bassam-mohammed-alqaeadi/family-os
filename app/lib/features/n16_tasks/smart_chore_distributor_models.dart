import 'package:flutter/foundation.dart';

@immutable
final class ChoreAssignment {
  const ChoreAssignment({
    required this.id,
    required this.childLabelKey,
    required this.choresKey,
    required this.noteKey,
  });
  final String id;
  final String childLabelKey;
  final String choresKey;
  final String noteKey;
}

@immutable
final class SmartChoreDistributorSnapshot {
  const SmartChoreDistributorSnapshot({
    this.hasFamily = false,
    this.assignments = const [],
    this.approved = false,
    this.altReady = false,
  });

  final bool hasFamily;
  final List<ChoreAssignment> assignments;
  final bool approved;
  final bool altReady;

  bool get isEmpty => !hasFamily;

  SmartChoreDistributorSnapshot copyWith({
    bool? approved,
    bool? altReady,
    List<ChoreAssignment>? assignments,
  }) {
    return SmartChoreDistributorSnapshot(
      hasFamily: hasFamily,
      assignments: assignments ?? this.assignments,
      approved: approved ?? this.approved,
      altReady: altReady ?? this.altReady,
    );
  }
}
