import 'package:family_os/features/n15_calendar/family_calendar_models.dart';

/// Rule 25 seam — Stage-1 mock family calendar (no backend).
abstract class FamilyCalendarRepository {
  Future<FamilyCalendarSnapshot> load();
}

/// In-memory mock — prototype FAT-052 shape by default.
final class InMemoryFamilyCalendarRepository
    implements FamilyCalendarRepository {
  InMemoryFamilyCalendarRepository({FamilyCalendarSnapshot? seed})
    : _snap = seed ?? familyCalendarPrototypeFixture();

  FamilyCalendarSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<FamilyCalendarSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return FamilyCalendarSnapshot(
      events: List<FamilyCalendarEvent>.from(_snap.events),
      month: _snap.month,
    );
  }

  void seed(FamilyCalendarSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryFamilyCalendarRepository stage1FamilyCalendarRepository =
    InMemoryFamilyCalendarRepository();

/// Empty — Rule 23 empty-state coverage → SCR-FAT-003.
FamilyCalendarSnapshot familyCalendarEmptyFixture() {
  return const FamilyCalendarSnapshot(
    month: FamilyCalendarMonthGrid(
      monthTitleKey: 'sep2026',
      firstDayOffset: 6,
      daysInMonth: 30,
      todayDay: 14,
      eventDays: {},
    ),
  );
}

/// One event — Rule 23 one-item coverage.
FamilyCalendarSnapshot familyCalendarOneFixture() {
  return const FamilyCalendarSnapshot(
    events: [
      FamilyCalendarEvent(
        id: 'ev-1',
        titleKey: 'memorizationReview',
        whenKey: 'todayAfterMaghrib',
        day: 14,
        category: FamilyCalendarEventCategory.din,
        whoNameKey: 'one',
        colorKey: 'purple',
      ),
    ],
    month: FamilyCalendarMonthGrid(
      monthTitleKey: 'sep2026',
      firstDayOffset: 6,
      daysInMonth: 30,
      todayDay: 14,
      eventDays: {14},
    ),
  );
}

/// Prototype FAT-052 — six events across four categories.
///
/// Rule 23: titleKey / whenKey / whoNameKey only (no planted person names).
FamilyCalendarSnapshot familyCalendarPrototypeFixture() {
  return const FamilyCalendarSnapshot(
    events: [
      FamilyCalendarEvent(
        id: 'ev-1',
        titleKey: 'memorizationReview',
        whenKey: 'todayAfterMaghrib',
        day: 14,
        category: FamilyCalendarEventCategory.din,
        whoNameKey: 'one',
        colorKey: 'purple',
      ),
      FamilyCalendarEvent(
        id: 'ev-2',
        titleKey: 'swimPractice',
        whenKey: 'today430pm',
        day: 14,
        category: FamilyCalendarEventCategory.act,
        whoNameKey: 'two',
        colorKey: 'sky',
      ),
      FamilyCalendarEvent(
        id: 'ev-3',
        titleKey: 'grandpaDinner',
        whenKey: 'today730pm',
        day: 14,
        category: FamilyCalendarEventCategory.occ,
        whoNameKey: 'everyone',
        colorKey: 'mint',
      ),
      FamilyCalendarEvent(
        id: 'ev-4',
        titleKey: 'quranTest',
        whenKey: 'tuesday',
        day: 16,
        category: FamilyCalendarEventCategory.sch,
        whoNameKey: 'three',
        colorKey: 'amber',
      ),
      FamilyCalendarEvent(
        id: 'ev-5',
        titleKey: 'anniversary',
        whenKey: 'thursday26',
        day: 18,
        category: FamilyCalendarEventCategory.occ,
        whoNameKey: 'parents',
        colorKey: 'lavender',
      ),
      FamilyCalendarEvent(
        id: 'ev-6',
        titleKey: 'dentalAppointment',
        whenKey: 'thursday10am',
        day: 18,
        category: FamilyCalendarEventCategory.occ,
        whoNameKey: 'two',
        colorKey: 'sky',
      ),
    ],
    month: FamilyCalendarMonthGrid(
      monthTitleKey: 'sep2026',
      firstDayOffset: 6,
      daysInMonth: 30,
      todayDay: 14,
      eventDays: {14, 16, 18},
    ),
  );
}
