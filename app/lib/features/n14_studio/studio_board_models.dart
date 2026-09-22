import 'package:flutter/foundation.dart';

/// Advisor suggestion kinds on SCR-FAT-040 (S-EDU-064).
enum StudioSuggestionKind { fractions, quranWird }

/// Recent content kinds matching prototype FAT-040 rows.
enum StudioContentKind { quiz, flashcards, quranWird }

/// Status chip for recent content (Rule 23 — discrete tags).
enum StudioContentStatus { active, progress, excellent }

@immutable
final class StudioSuggestion {
  const StudioSuggestion({
    required this.id,
    required this.kind,
    this.targetScreenId = 'SCR-FAT-041',
  });

  final String id;
  final StudioSuggestionKind kind;

  /// Destinations not yet built stay as route placeholders (FAT-041+).
  final String targetScreenId;
}

@immutable
final class StudioContentItem {
  const StudioContentItem({
    required this.id,
    required this.kind,
    required this.status,
  });

  final String id;
  final StudioContentKind kind;
  final StudioContentStatus status;
}

@immutable
final class StudioBoardSnapshot {
  const StudioBoardSnapshot({
    this.suggestions = const [],
    this.recent = const [],
  });

  final List<StudioSuggestion> suggestions;
  final List<StudioContentItem> recent;

  bool get isEmpty => suggestions.isEmpty && recent.isEmpty;
}
