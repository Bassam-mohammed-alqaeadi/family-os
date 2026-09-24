import 'package:flutter/foundation.dart';

/// Subject kinds on SCR-FAT-048 (prototype FAT-048 rows).
enum MaterialsSubjectKind { math, quran, english, science, custom }

@immutable
final class MaterialsSubject {
  const MaterialsSubject({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.subtitleKey,
    this.lessons = 0,
    this.quizzes = 0,
    this.flashcards = 0,
    this.hasActivePath = false,
  });

  final String id;
  final MaterialsSubjectKind kind;

  /// ARB discriminator for title (Rule 23 — no planted person names).
  final String titleKey;

  /// ARB discriminator for subtitle.
  final String subtitleKey;
  final int lessons;
  final int quizzes;
  final int flashcards;

  /// Prototype: Math row navigates to FAT-047 learning path.
  final bool hasActivePath;
}

@immutable
final class MaterialsLessonsSnapshot {
  const MaterialsLessonsSnapshot({this.subjects = const []});

  final List<MaterialsSubject> subjects;

  bool get isEmpty => subjects.isEmpty;
}
