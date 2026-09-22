import 'package:family_os/features/n14_studio/create_assignment_models.dart';

/// Rule 25 seam — Stage-1 mock create assignment/quiz (no backend).
abstract class CreateAssignmentRepository {
  Future<CreateAssignmentSnapshot> load();

  Future<CreateAssignmentSnapshot> assignHomework(String title);

  Future<CreateAssignmentSnapshot> assignSkillGap();

  Future<CreateAssignmentSnapshot> assignFamilyChallenge(String question);
}

/// In-memory mock — prototype FAT-049 shape by default.
final class InMemoryCreateAssignmentRepository
    implements CreateAssignmentRepository {
  InMemoryCreateAssignmentRepository({CreateAssignmentSnapshot? seed})
    : _snap = seed ?? createAssignmentPrototypeFixture();

  CreateAssignmentSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<CreateAssignmentSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignHomework(String title) async {
    final trimmed = title.trim();
    if (_snap.child == null || trimmed.isEmpty) return _copy(_snap);
    _snap = _snap.copyWith(
      homeworkTitle: trimmed,
      lastAssignedPath: CreateAssignmentPath.homework,
    );
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignSkillGap() async {
    if (_snap.child == null || _snap.skillGap == null) return _copy(_snap);
    _snap = _snap.copyWith(lastAssignedPath: CreateAssignmentPath.skillGap);
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignFamilyChallenge(
    String question,
  ) async {
    final trimmed = question.trim();
    if (_snap.child == null || trimmed.isEmpty) return _copy(_snap);
    _snap = _snap.copyWith(
      familyQuestion: trimmed,
      lastAssignedPath: CreateAssignmentPath.familyChallenge,
    );
    return _copy(_snap);
  }

  void seed(CreateAssignmentSnapshot snap) {
    _snap = snap;
  }

  CreateAssignmentSnapshot _copy(CreateAssignmentSnapshot s) {
    return CreateAssignmentSnapshot(
      child: s.child,
      homeworkTitle: s.homeworkTitle,
      homeworkRewardMinutes: s.homeworkRewardMinutes,
      skillGap: s.skillGap,
      familyQuestion: s.familyQuestion,
      familyRewardMinutes: s.familyRewardMinutes,
      lastAssignedPath: s.lastAssignedPath,
    );
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryCreateAssignmentRepository stage1CreateAssignmentRepository =
    InMemoryCreateAssignmentRepository();

/// Empty — Rule 23 empty-state coverage (no child to assign).
CreateAssignmentSnapshot createAssignmentEmptyFixture() {
  return const CreateAssignmentSnapshot();
}

/// One child · no skill gap — homework + family paths only.
CreateAssignmentSnapshot createAssignmentOneFixture() {
  return const CreateAssignmentSnapshot(
    child: CreateAssignmentChild(id: 'child_a', nameKey: 'one'),
    homeworkTitle: 'Solve page 45 in the math notebook (exercises 1–6)',
    homeworkRewardMinutes: 30,
    familyQuestion: 'What is 6 × 7, and what is the smallest continent?',
    familyRewardMinutes: 30,
  );
}

/// Prototype FAT-049 — child + homework + skill gap + family challenge.
///
/// Rule 23: nameKey / titleKey only (no planted person names).
/// ع-١: minutes-only rewards (30 / 50 / 30).
CreateAssignmentSnapshot createAssignmentPrototypeFixture() {
  return const CreateAssignmentSnapshot(
    child: CreateAssignmentChild(id: 'child_a', nameKey: 'one'),
    homeworkTitle: 'Solve page 45 in the math notebook (exercises 1–6)',
    homeworkRewardMinutes: 30,
    skillGap: CreateAssignmentSkillGap(
      id: 'gap-fractions',
      titleKey: 'fractionDivision',
      missed: 3,
      total: 4,
      quizQuestions: 3,
      rewardMinutes: 50,
    ),
    familyQuestion: 'What is 6 × 7, and what is the smallest continent?',
    familyRewardMinutes: 30,
  );
}
