import 'package:flutter/foundation.dart';

/// Timeline stop kinds on SCR-FAT-063 (prototype FAT-063 thread).
enum IndividualTimelineStopKind {
  schoolMode,
  studyComplete,
  childMessage,
  sleep,
}

/// One chronological stop in today's thread.
@immutable
final class IndividualTimelineStop {
  const IndividualTimelineStop({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.timeKey,
    this.detailKey,
    this.isNow = false,
  });

  final String id;
  final IndividualTimelineStopKind kind;

  /// ARB discriminator for stop title (Rule 23 — no planted names).
  final String titleKey;

  /// ARB discriminator for time stamp.
  final String timeKey;

  /// Optional ARB discriminator for secondary detail (score, delta, etc.).
  final String? detailKey;

  /// Prototype «now» marker on active stop.
  final bool isNow;
}

/// Cross-domain insight card (S-AIC-016 — linking across domains).
@immutable
final class IndividualTimelineInsight {
  const IndividualTimelineInsight({
    required this.id,
    required this.badgeKey,
    required this.patternKey,
    required this.suggestionKey,
    required this.privacyNoteKey,
  });

  final String id;

  /// ARB discriminator for card badge (e.g. cross-domain link seal).
  final String badgeKey;

  /// ARB discriminator for discovered pattern body.
  final String patternKey;

  /// ARB discriminator for advisor suggestion box.
  final String suggestionKey;

  /// ARB discriminator for privacy / tri-domain note.
  final String privacyNoteKey;
}

/// Loaded snapshot for SCR-FAT-063.
@immutable
final class IndividualTimelineSnapshot {
  const IndividualTimelineSnapshot({
    this.nameKey,
    this.insight,
    this.todayStops = const [],
  });

  /// Opaque child token (e.g. `childOne`) — never a planted display name (Rule 23).
  final String? nameKey;
  final IndividualTimelineInsight? insight;
  final List<IndividualTimelineStop> todayStops;

  bool get isEmpty => nameKey == null || todayStops.isEmpty;
}
