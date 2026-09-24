import 'package:family_os/features/n14_studio/materials_lessons_models.dart';

/// Rule 25 seam — Stage-1 mock materials & lessons (no backend).
abstract class MaterialsLessonsRepository {
  Future<MaterialsLessonsSnapshot> load();

  /// P15-EDU-007 — father/partner add subject persists a row (P11).
  Future<MaterialsSubject> addSubject();

  /// P15-EDU-007 — add lesson increments count on a subject (P11).
  Future<MaterialsSubject> addLesson({String? subjectId});
}

/// In-memory mock — prototype FAT-048 shape by default.
final class InMemoryMaterialsLessonsRepository
    implements MaterialsLessonsRepository {
  InMemoryMaterialsLessonsRepository({MaterialsLessonsSnapshot? seed})
    : _snap = seed ?? materialsLessonsPrototypeFixture();

  MaterialsLessonsSnapshot _snap;
  var _seq = 0;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<MaterialsLessonsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return MaterialsLessonsSnapshot(
      subjects: List<MaterialsSubject>.from(_snap.subjects),
    );
  }

  @override
  Future<MaterialsSubject> addSubject() async {
    _seq += 1;
    final row = MaterialsSubject(
      id: 'subj-custom-$_seq',
      kind: MaterialsSubjectKind.custom,
      titleKey: 'custom',
      subtitleKey: 'justAdded',
      lessons: 0,
    );
    _snap = MaterialsLessonsSnapshot(subjects: [..._snap.subjects, row]);
    return row;
  }

  @override
  Future<MaterialsSubject> addLesson({String? subjectId}) async {
    final subjects = List<MaterialsSubject>.from(_snap.subjects);
    if (subjects.isEmpty) {
      // No subject yet — create one then attach the first lesson.
      final created = await addSubject();
      return addLesson(subjectId: created.id);
    }
    final idx = subjectId == null
        ? 0
        : subjects.indexWhere((s) => s.id == subjectId);
    final i = idx < 0 ? 0 : idx;
    final prev = subjects[i];
    final updated = MaterialsSubject(
      id: prev.id,
      kind: prev.kind,
      titleKey: prev.titleKey,
      subtitleKey: prev.subtitleKey == 'justAdded'
          ? 'lessonCount'
          : prev.subtitleKey,
      lessons: prev.lessons + 1,
      quizzes: prev.quizzes,
      flashcards: prev.flashcards,
      hasActivePath: prev.hasActivePath,
    );
    subjects[i] = updated;
    _snap = MaterialsLessonsSnapshot(subjects: subjects);
    return updated;
  }

  void seed(MaterialsLessonsSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryMaterialsLessonsRepository stage1MaterialsLessonsRepository =
    InMemoryMaterialsLessonsRepository();

/// Empty — Rule 23 empty-state coverage.
MaterialsLessonsSnapshot materialsLessonsEmptyFixture() {
  return const MaterialsLessonsSnapshot();
}

/// One subject — Rule 23 one-item coverage.
MaterialsLessonsSnapshot materialsLessonsOneFixture() {
  return const MaterialsLessonsSnapshot(
    subjects: [
      MaterialsSubject(
        id: 'subj-math',
        kind: MaterialsSubjectKind.math,
        titleKey: 'math',
        subtitleKey: 'mathActive',
        lessons: 8,
        quizzes: 3,
        hasActivePath: true,
      ),
    ],
  );
}

/// Prototype FAT-048 — four subjects (math path · quran · english · science).
///
/// Rule 23: titleKey / subtitleKey only (no planted person names).
MaterialsLessonsSnapshot materialsLessonsPrototypeFixture() {
  return const MaterialsLessonsSnapshot(
    subjects: [
      MaterialsSubject(
        id: 'subj-math',
        kind: MaterialsSubjectKind.math,
        titleKey: 'math',
        subtitleKey: 'mathActive',
        lessons: 8,
        quizzes: 3,
        hasActivePath: true,
      ),
      MaterialsSubject(
        id: 'subj-quran',
        kind: MaterialsSubjectKind.quran,
        titleKey: 'quran',
        subtitleKey: 'quranWeekly',
      ),
      MaterialsSubject(
        id: 'subj-english',
        kind: MaterialsSubjectKind.english,
        titleKey: 'english',
        subtitleKey: 'englishCards',
        flashcards: 24,
      ),
      MaterialsSubject(
        id: 'subj-science',
        kind: MaterialsSubjectKind.science,
        titleKey: 'science',
        subtitleKey: 'scienceImported',
      ),
    ],
  );
}
