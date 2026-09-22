import 'package:family_os/features/n14_studio/focus_report_models.dart';

/// Rule 25 seam — Stage-1 mock focus report (no backend).
abstract class FocusReportRepository {
  Future<FocusReportSnapshot> load();

  Future<FocusReportSnapshot> sendPraise();

  Future<FocusReportSnapshot> rewardSelfDiscipline();

  Future<FocusReportSnapshot> toggleSchedule(String id, bool enabled);
}

/// In-memory mock — prototype FAT-051 shape by default.
final class InMemoryFocusReportRepository implements FocusReportRepository {
  InMemoryFocusReportRepository({FocusReportSnapshot? seed})
    : _snap = seed ?? focusReportPrototypeFixture();

  FocusReportSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<FocusReportSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  @override
  Future<FocusReportSnapshot> sendPraise() async {
    final note = _snap.advisorNote;
    if (_snap.child == null || note == null || note.praiseSent) {
      return _copy(_snap);
    }
    _snap = _snap.copyWith(
      advisorNote: note.copyWith(
        praiseSent: true,
        praiseQuoteKey: 'resistDistraction',
      ),
    );
    return _copy(_snap);
  }

  @override
  Future<FocusReportSnapshot> rewardSelfDiscipline() async {
    final note = _snap.advisorNote;
    if (_snap.child == null || note == null) return _copy(_snap);
    _snap = _snap.copyWith(
      advisorNote: note.copyWith(rewardSent: true),
    );
    return _copy(_snap);
  }

  @override
  Future<FocusReportSnapshot> toggleSchedule(String id, bool enabled) async {
    if (_snap.child == null) return _copy(_snap);
    _snap = _snap.withScheduleToggled(id, enabled);
    return _copy(_snap);
  }

  void seed(FocusReportSnapshot snap) {
    _snap = snap;
  }

  FocusReportSnapshot _copy(FocusReportSnapshot s) {
    return FocusReportSnapshot(
      child: s.child,
      weeklySummary: s.weeklySummary,
      advisorNote: s.advisorNote,
      schedules: List<FocusScheduleItem>.from(s.schedules),
      rewardMinutes: s.rewardMinutes,
    );
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryFocusReportRepository stage1FocusReportRepository =
    InMemoryFocusReportRepository();

/// Empty — Rule 23 empty-state coverage (no child focus data).
FocusReportSnapshot focusReportEmptyFixture() {
  return const FocusReportSnapshot();
}

/// One child · one schedule · advisor note not yet praised.
FocusReportSnapshot focusReportOneFixture() {
  return const FocusReportSnapshot(
    child: FocusReportChild(id: 'child_a', nameKey: 'one'),
    weeklySummary: FocusWeeklySummary(
      sessionsCount: 2,
      totalDurationMinutes: 95,
      longestSessionMinutes: 50,
      goalStatus: FocusReportGoalStatus.inProgress,
    ),
    advisorNote: FocusAdvisorNote(
      id: 'note-a',
      titleKey: 'selfDiscipline',
      bodyKey: 'scienceResist',
    ),
    schedules: [
      FocusScheduleItem(
        id: 'sched-a',
        nameKey: 'afternoonStudy',
        childNameKey: 'one',
        timeKey: 'afternoonSlot',
        daysKey: 'schoolDays',
        blockedAppKeys: ['youtube', 'games'],
        enabled: true,
      ),
    ],
    rewardMinutes: 15,
  );
}

/// Prototype FAT-051 — weekly summary + advisor note + parent schedule.
///
/// Rule 23: nameKey / titleKey only (no planted person names).
/// ع-١: minutes-only reward (+15).
FocusReportSnapshot focusReportPrototypeFixture() {
  return const FocusReportSnapshot(
    child: FocusReportChild(id: 'child_a', nameKey: 'one'),
    weeklySummary: FocusWeeklySummary(
      sessionsCount: 5,
      totalDurationMinutes: 220,
      longestSessionMinutes: 55,
      goalStatus: FocusReportGoalStatus.complete,
    ),
    advisorNote: FocusAdvisorNote(
      id: 'note-self',
      titleKey: 'selfDiscipline',
      bodyKey: 'scienceResist',
    ),
    schedules: [
      FocusScheduleItem(
        id: 'sched-1',
        nameKey: 'afternoonStudy',
        childNameKey: 'one',
        timeKey: 'afternoonSlot',
        daysKey: 'schoolDays',
        blockedAppKeys: ['youtube', 'games'],
        enabled: true,
      ),
    ],
    rewardMinutes: 15,
  );
}
