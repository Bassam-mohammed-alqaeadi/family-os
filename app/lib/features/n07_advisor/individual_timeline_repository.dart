import 'package:family_os/features/n07_advisor/individual_timeline_models.dart';

/// Rule 25 seam — Stage-1 mock individual timeline (no backend).
abstract class IndividualTimelineRepository {
  Future<IndividualTimelineSnapshot> load();
}

/// In-memory mock — prototype FAT-063 shape by default.
final class InMemoryIndividualTimelineRepository
    implements IndividualTimelineRepository {
  InMemoryIndividualTimelineRepository({IndividualTimelineSnapshot? seed})
    : _snap = seed ?? individualTimelinePrototypeFixture();

  IndividualTimelineSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<IndividualTimelineSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return IndividualTimelineSnapshot(
      nameKey: _snap.nameKey,
      insight: _snap.insight,
      todayStops: List<IndividualTimelineStop>.from(_snap.todayStops),
    );
  }

  void seed(IndividualTimelineSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryIndividualTimelineRepository stage1IndividualTimelineRepository =
    InMemoryIndividualTimelineRepository();

/// Empty — Rule 23 empty-state → SCR-FAT-003.
IndividualTimelineSnapshot individualTimelineEmptyFixture() {
  return const IndividualTimelineSnapshot();
}

/// One stop — minimal today thread.
IndividualTimelineSnapshot individualTimelineOneFixture() {
  return const IndividualTimelineSnapshot(
    nameKey: 'childOne',
    todayStops: [
      IndividualTimelineStop(
        id: 'stop-school',
        kind: IndividualTimelineStopKind.schoolMode,
        titleKey: 'schoolModeActive',
        timeKey: 'since7am',
        isNow: true,
      ),
    ],
  );
}

/// Prototype FAT-063 — cross-domain insight + four today stops.
///
/// Rule 23: nameKey / *Key only (no planted person names).
IndividualTimelineSnapshot individualTimelinePrototypeFixture() {
  return const IndividualTimelineSnapshot(
    nameKey: 'childOne',
    insight: IndividualTimelineInsight(
      id: 'insight-cross-domain',
      badgeKey: 'crossDomainLink',
      patternKey: 'footballSleepStudy',
      suggestionKey: 'testsAfterPractice',
      privacyNoteKey: 'triDomainUnique',
    ),
    todayStops: [
      IndividualTimelineStop(
        id: 'stop-school',
        kind: IndividualTimelineStopKind.schoolMode,
        titleKey: 'schoolModeActive',
        timeKey: 'since7am',
        isNow: true,
      ),
      IndividualTimelineStop(
        id: 'stop-fractions',
        kind: IndividualTimelineStopKind.studyComplete,
        titleKey: 'finishedFractionsReview',
        timeKey: 'at840am',
        detailKey: 'score90',
      ),
      IndividualTimelineStop(
        id: 'stop-arrived',
        kind: IndividualTimelineStopKind.childMessage,
        titleKey: 'arrivedSchoolMessage',
        timeKey: 'at714am',
      ),
      IndividualTimelineStop(
        id: 'stop-sleep',
        kind: IndividualTimelineStopKind.sleep,
        titleKey: 'lateSleep',
        timeKey: 'at1110pmYesterday',
        detailKey: 'late40minBaseline',
      ),
    ],
  );
}
