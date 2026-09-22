import 'package:family_os/features/n14_studio/results_followup_models.dart';

/// Rule 25 seam — Stage-1 mock results follow-up (no backend).
abstract class ResultsFollowupRepository {
  Future<ResultsFollowupSnapshot> load();
}

/// In-memory mock — prototype FAT-050 shape by default.
final class InMemoryResultsFollowupRepository
    implements ResultsFollowupRepository {
  InMemoryResultsFollowupRepository({ResultsFollowupSnapshot? seed})
    : _snap = seed ?? resultsFollowupPrototypeFixture();

  ResultsFollowupSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<ResultsFollowupSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  void seed(ResultsFollowupSnapshot snap) {
    _snap = snap;
  }

  ResultsFollowupSnapshot _copy(ResultsFollowupSnapshot s) {
    return ResultsFollowupSnapshot(
      child: s.child,
      mastery: s.mastery,
      skillGap: s.skillGap,
      activities: List<ResultsFollowupActivity>.from(s.activities),
    );
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryResultsFollowupRepository stage1ResultsFollowupRepository =
    InMemoryResultsFollowupRepository();

/// Empty — Rule 23 empty-state coverage (no child linked).
ResultsFollowupSnapshot resultsFollowupEmptyFixture() {
  return const ResultsFollowupSnapshot();
}

/// One child · mastery only — no skill gap or activity log.
ResultsFollowupSnapshot resultsFollowupOneFixture() {
  return const ResultsFollowupSnapshot(
    child: ResultsFollowupChild(id: 'child_a', nameKey: 'one'),
    mastery: ResultsFollowupMastery(
      subjectKey: 'math',
      percent: 75,
    ),
  );
}

/// Prototype FAT-050 — child + mastery + pending gap + activity log.
///
/// Rule 23: nameKey / titleKey only (no planted person names).
/// ع-١: minutes-only family reward (+30).
ResultsFollowupSnapshot resultsFollowupPrototypeFixture() {
  return const ResultsFollowupSnapshot(
    child: ResultsFollowupChild(id: 'child_a', nameKey: 'one'),
    mastery: ResultsFollowupMastery(
      subjectKey: 'math',
      percent: 82,
    ),
    skillGap: ResultsFollowupSkillGap(
      id: 'gap-fractions',
      titleKey: 'fractionDivision',
      status: ResultsFollowupSkillGapStatus.pending,
      missed: 3,
      total: 4,
    ),
    activities: [
      ResultsFollowupActivity(
        id: 'act-hw-fractions',
        kind: ResultsFollowupActivityKind.homework,
        titleKey: 'schoolFractions',
        subtitleKey: 'onTimePhoto',
        statusKey: 'complete',
      ),
      ResultsFollowupActivity(
        id: 'act-family-daily',
        kind: ResultsFollowupActivityKind.familyChallenge,
        titleKey: 'dailyChallenge',
        subtitleKey: 'earnedMinutes',
        statusKey: 'approved',
        minutes: 30,
      ),
    ],
  );
}
