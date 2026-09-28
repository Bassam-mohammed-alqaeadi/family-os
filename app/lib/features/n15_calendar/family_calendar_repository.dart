import 'package:family_os/features/n15_calendar/family_calendar_models.dart';

/// Rule 25 seam — Stage-1 local family calendar (CE-B1).
abstract class FamilyCalendarRepository {
  Future<FamilyCalendarSnapshot> load();

  /// FAT-053 save → shared calendar authority.
  Future<void> addEvent(FamilyCalendarEvent event);
}

/// In-memory — empty-first (Rule 23). Tests seed explicitly.
final class InMemoryFamilyCalendarRepository
    implements FamilyCalendarRepository {
  InMemoryFamilyCalendarRepository({FamilyCalendarSnapshot? seed})
    : _snap = seed ?? familyCalendarEmptyFixture();

  FamilyCalendarSnapshot _snap;
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

  @override
  Future<void> addEvent(FamilyCalendarEvent event) async {
    _snap = _snap.withEvents([..._snap.events, event]);
  }

  void seed(FamilyCalendarSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton — empty until Local bind / test seed.
FamilyCalendarRepository stage1FamilyCalendarRepository =
    InMemoryFamilyCalendarRepository(seed: familyCalendarEmptyFixture());

void rebindStage1FamilyCalendarRepository(FamilyCalendarRepository repository) {
  stage1FamilyCalendarRepository = repository;
}

FamilyCalendarSnapshot familyCalendarEmptyFixture() {
  return const FamilyCalendarSnapshot();
}

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

/// LOCAL_DEMO / tests only — not production stage1 default.
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
