import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/education/learning_assignment_models.dart';
import 'package:family_os/features/education/learning_assignment_repository.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_models.dart';

/// Rule 25 seam — Stage-1 mock child learn home (no backend).
abstract class ChildLearnHomeRepository {
  Future<ChildLearnHomeSnapshot> load();
}

/// In-memory mock — merges live father assignments (P15-EDU-002 · P12).
final class InMemoryChildLearnHomeRepository
    implements ChildLearnHomeRepository {
  InMemoryChildLearnHomeRepository({
    ChildLearnHomeSnapshot? seed,
    LearningAssignmentRepository? assignments,
    ChildId? childId,
  }) : _base = seed ?? childLearnHomePrototypeFixture(),
       _assignments = assignments ?? stage1LearningAssignmentRepository,
       _childId = childId ?? ChildId('child_a');

  ChildLearnHomeSnapshot _base;
  final LearningAssignmentRepository _assignments;
  final ChildId _childId;

  Future<void> Function()? loadGate;

  @override
  Future<ChildLearnHomeSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final latest = await _assignments.latestForChild(_childId);
    if (latest == null) {
      return _copyBase();
    }
    return _mergeAssignment(latest);
  }

  void seed(ChildLearnHomeSnapshot snap) {
    _base = snap;
  }

  ChildLearnHomeSnapshot _copyBase() {
    return ChildLearnHomeSnapshot(
      level: _base.level,
      levelTitleKey: _base.levelTitleKey,
      minutesEarnedThisMonth: _base.minutesEarnedThisMonth,
      levelProgressPercent: _base.levelProgressPercent,
      streakDays: _base.streakDays,
      freeTime: _base.freeTime,
      challenge: _base.challenge,
      materials: List<ChildLearnMaterialRow>.from(_base.materials),
    );
  }

  ChildLearnHomeSnapshot _mergeAssignment(LearningAssignment a) {
    final kind = switch (a.materialKindKey) {
      'quran' => ChildLearnSubjectKind.quran,
      'english' => ChildLearnSubjectKind.english,
      _ => ChildLearnSubjectKind.math,
    };
    final assignedMaterial = ChildLearnMaterialRow(
      id: 'assigned_${a.id}',
      kind: kind,
      titleKey: kind == ChildLearnSubjectKind.math ? 'math' : a.materialKindKey,
      subtitleKey: 'assignedFromFather',
      tag: ChildLearnMaterialTag.neu,
      ctaScreenId: a.ctaScreenId == 'SCR-CHD-015'
          ? 'SCR-CHD-013'
          : a.ctaScreenId,
    );
    final materials = [
      assignedMaterial,
      ..._base.materials.where((m) => m.id != assignedMaterial.id),
    ];
    return ChildLearnHomeSnapshot(
      level: _base.level,
      levelTitleKey: _base.levelTitleKey,
      minutesEarnedThisMonth: _base.minutesEarnedThisMonth,
      levelProgressPercent: _base.levelProgressPercent,
      streakDays: _base.streakDays,
      freeTime: _base.freeTime,
      challenge: ChildLearnChallenge(
        titleKey: a.titleKey,
        rewardMinutes: a.rewardMinutes.inMinutes,
        ctaScreenId: a.ctaScreenId,
      ),
      materials: materials,
    );
  }
}

final InMemoryChildLearnHomeRepository stage1ChildLearnHomeRepository =
    InMemoryChildLearnHomeRepository();

ChildLearnHomeSnapshot childLearnHomeEmptyFixture() {
  return const ChildLearnHomeSnapshot();
}

ChildLearnHomeSnapshot childLearnHomeOneFixture() {
  return const ChildLearnHomeSnapshot(
    level: 1,
    levelTitleKey: 'explorer',
    minutesEarnedThisMonth: 40,
    levelProgressPercent: 20,
    streakDays: 1,
    freeTime: false,
    materials: [
      ChildLearnMaterialRow(
        id: 'mat-math',
        kind: ChildLearnSubjectKind.math,
        titleKey: 'math',
        subtitleKey: 'mathNewLesson',
        tag: ChildLearnMaterialTag.neu,
        ctaScreenId: 'SCR-CHD-013',
      ),
    ],
  );
}

/// Prototype CHD-012 — level card, father challenge, three materials.
ChildLearnHomeSnapshot childLearnHomePrototypeFixture() {
  return const ChildLearnHomeSnapshot(
    level: 3,
    levelTitleKey: 'explorer',
    minutesEarnedThisMonth: 340,
    levelProgressPercent: 68,
    streakDays: 5,
    freeTime: true,
    challenge: ChildLearnChallenge(
      titleKey: 'fractionsQuiz',
      rewardMinutes: 35,
      ctaScreenId: 'SCR-CHD-015',
    ),
    materials: [
      ChildLearnMaterialRow(
        id: 'mat-math',
        kind: ChildLearnSubjectKind.math,
        titleKey: 'math',
        subtitleKey: 'mathNewLesson',
        tag: ChildLearnMaterialTag.neu,
        ctaScreenId: 'SCR-CHD-013',
      ),
      ChildLearnMaterialRow(
        id: 'mat-quran',
        kind: ChildLearnSubjectKind.quran,
        titleKey: 'quran',
        subtitleKey: 'quranWird',
        tag: ChildLearnMaterialTag.progress,
        progressPercent: 70,
      ),
      ChildLearnMaterialRow(
        id: 'mat-english',
        kind: ChildLearnSubjectKind.english,
        titleKey: 'english',
        subtitleKey: 'englishCardsLeft',
        tag: ChildLearnMaterialTag.chevron,
      ),
    ],
  );
}
