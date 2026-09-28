import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/minutes.dart';
import 'package:family_os/core/identity/roster_children.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n14_studio/create_assignment_models.dart';

/// Rule 25 seam — Stage-1 mock create assignment/quiz (no backend).
abstract class CreateAssignmentRepository {
  Future<CreateAssignmentSnapshot> load();

  Future<CreateAssignmentSnapshot> assignHomework(String title);

  Future<CreateAssignmentSnapshot> assignSkillGap();

  Future<CreateAssignmentSnapshot> assignFamilyChallenge(String question);
}

/// In-memory mock — prototype FAT-049 shape by default.
///
/// OD-14: [load] rebinds the target child to the active family roster.
final class InMemoryCreateAssignmentRepository
    implements CreateAssignmentRepository {
  InMemoryCreateAssignmentRepository({
    CreateAssignmentSnapshot? seed,
    LearningAssignmentRepository? assignments,
  })  : _snap = seed ?? createAssignmentEmptyFixture(),
        _assignmentsOverride = assignments;

  CreateAssignmentSnapshot _snap;
  final LearningAssignmentRepository? _assignmentsOverride;

  /// Resolve at call time so Local LearningAssignment rebind is visible (CE-G062).
  LearningAssignmentRepository get _assignments =>
      _assignmentsOverride ?? stage1LearningAssignmentRepository;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<CreateAssignmentSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindCreateAssignmentToRoster(_snap);
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignHomework(String title) async {
    final trimmed = title.trim();
    _snap = bindCreateAssignmentToRoster(_snap);
    final child = _snap.child;
    if (child == null || trimmed.isEmpty) return _copy(_snap);
    _snap = _snap.copyWith(
      homeworkTitle: trimmed,
      lastAssignedPath: CreateAssignmentPath.homework,
    );
    await _assignments.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId(child.id),
        titleKey: 'assignedHomework',
        rewardMinutes: Minutes(_snap.homeworkRewardMinutes),
        source: LearningAssignmentSource.homework,
      ),
    );
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignSkillGap() async {
    _snap = bindCreateAssignmentToRoster(_snap);
    final child = _snap.child;
    final gap = _snap.skillGap;
    if (child == null || gap == null) return _copy(_snap);
    _snap = _snap.copyWith(lastAssignedPath: CreateAssignmentPath.skillGap);
    await _assignments.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId(child.id),
        titleKey: 'assignedSkillGap',
        rewardMinutes: Minutes(gap.rewardMinutes),
        source: LearningAssignmentSource.skillGap,
      ),
    );
    return _copy(_snap);
  }

  @override
  Future<CreateAssignmentSnapshot> assignFamilyChallenge(
    String question,
  ) async {
    final trimmed = question.trim();
    _snap = bindCreateAssignmentToRoster(_snap);
    final child = _snap.child;
    if (child == null || trimmed.isEmpty) return _copy(_snap);
    _snap = _snap.copyWith(
      familyQuestion: trimmed,
      lastAssignedPath: CreateAssignmentPath.familyChallenge,
    );
    await _assignments.publish(
      LearningAssignmentPublishRequest(
        childId: ChildId(child.id),
        titleKey: 'assignedFamily',
        rewardMinutes: Minutes(_snap.familyRewardMinutes),
        source: LearningAssignmentSource.familyChallenge,
      ),
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
  final child = activeRosterChild();
  if (child == null) return const CreateAssignmentSnapshot();
  return CreateAssignmentSnapshot(
    child: CreateAssignmentChild(id: child.id.value, nameKey: child.nameKey),
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
/// OD-14: child id comes from the active roster (never `child_a`).
CreateAssignmentSnapshot createAssignmentPrototypeFixture() {
  final child = activeRosterChild();
  if (child == null) return const CreateAssignmentSnapshot();
  return CreateAssignmentSnapshot(
    child: CreateAssignmentChild(id: child.id.value, nameKey: child.nameKey),
    homeworkTitle: 'Solve page 45 in the math notebook (exercises 1–6)',
    homeworkRewardMinutes: 30,
    skillGap: const CreateAssignmentSkillGap(
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

/// Rebinds a snapshot's child to the active family roster (OD-14).
///
/// Leaves intentional empty fixtures untouched.
CreateAssignmentSnapshot bindCreateAssignmentToRoster(
  CreateAssignmentSnapshot snap,
) {
  if (snap.isEmpty &&
      snap.homeworkTitle.isEmpty &&
      !snap.hasSkillGap &&
      snap.familyQuestion.isEmpty) {
    return snap;
  }
  final selected = activeRosterChild();
  if (selected == null) {
    return const CreateAssignmentSnapshot();
  }
  final current = snap.child;
  if (current != null && current.id == selected.id.value) {
    return snap;
  }
  return snap.copyWith(
    child: CreateAssignmentChild(
      id: selected.id.value,
      nameKey: selected.nameKey,
    ),
  );
}
