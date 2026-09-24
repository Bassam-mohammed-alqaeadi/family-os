import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n15_calendar/add_event_models.dart';
import 'package:family_os/features/n15_calendar/add_event_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';

/// Stage-2 composition root for the calendar domain (ADR-054 §6 · §11.1).
final class Stage1CalendarRuntime {
  Stage1CalendarRuntime._();

  static FamilyDatabase? _db;
  static var _opened = false;

  /// Opens once. Pass [override] to inject a database (tests own its lifecycle).
  static Future<void> ensureOpen({FamilyDatabase? override}) async {
    if (_opened && override == null) return;
    _db = override ?? (_db ?? FamilyDatabase(NativeDatabase.memory()));
    _opened = true;
  }

  static FamilyDatabase get db {
    final value = _db;
    if (value == null) {
      throw StateError('Call Stage1CalendarRuntime.ensureOpen() first');
    }
    return value;
  }

  /// SCR-FAT-052 — the month card and its events over `calendar_event`.
  static FamilyCalendarRepository familyCalendar({String? familyId}) =>
      DriftFamilyCalendarRepository(db, familyId: familyId ?? '');

  /// SCR-FAT-053 — writing a real event row.
  static AddEventRepository addEvent({
    String? familyId,
    String? createdByAccount,
  }) => DriftAddEventRepository(
    db,
    familyId: familyId ?? '',
    createdByAccount: createdByAccount,
  );

  /// Clears this runtime only. An injected database is closed by its owner.
  static void resetForTest() {
    _opened = false;
    _db = null;
  }
}

/// SCR-FAT-052 over real rows.
///
/// The month card is computed from the clock — never a frozen «سبتمبر ٢٠٢٦» —
/// and the dots come from the events themselves. The list is the displayed
/// month's events, because the card has no month switch yet; when one lands,
/// the window widens here and nothing in the screen changes.
final class DriftFamilyCalendarRepository implements FamilyCalendarRepository {
  DriftFamilyCalendarRepository(
    this._db, {
    required String familyId,
    DateTime Function()? clock,
  }) : _familyId = familyId.trim(),
       clock = clock ?? DateTime.now;

  final FamilyDatabase _db;
  final String _familyId;
  final DateTime Function() clock;

  /// Token colours the screen already knows (it falls back to `p500` on
  /// anything else, so an unknown token is never a wrong colour).
  static const _colorTokens = <String>[
    'purple',
    'sky',
    'mint',
    'amber',
    'lavender',
  ];

  @override
  Future<FamilyCalendarSnapshot> load() async {
    final now = clock();
    final month = DateTime(now.year, now.month);
    if (_familyId.isEmpty) {
      // Fail closed — no events; the month itself is not family data.
      return FamilyCalendarSnapshot(month: _grid(now, const []));
    }
    final rows =
        await (_db.select(_db.calendarEvents)
              ..where((e) => e.familyId.equals(_familyId))
              ..orderBy([
                (e) => OrderingTerm.asc(e.startsAt),
                (e) => OrderingTerm.asc(e.id),
              ]))
            .get();
    final children = await _childrenInOrder();
    final childIds = [for (final c in children) c.id];

    final events = <FamilyCalendarEvent>[];
    for (final row in rows) {
      final startsAt = row.startsAt;
      if (startsAt.year != month.year || startsAt.month != month.month) {
        continue;
      }
      events.add(
        FamilyCalendarEvent(
          id: row.id,
          titleKey: row.titleRef,
          whenKey: Stage1RowVocabulary.whenKeyFor(startsAt, now),
          day: startsAt.day,
          category: _categoryOf(row.category),
          whoNameKey: Stage1RowVocabulary.whoKeyFor(
            row.whoRef ?? '',
            childIds,
          ),
          colorKey: _colorFor(row.whoRef ?? row.id),
        ),
      );
    }
    return FamilyCalendarSnapshot(events: events, month: _grid(now, rows));
  }

  /// The month the clock is in, with a dot for every stored day that falls in
  /// it — Sunday-first, matching the screen's grid maths.
  FamilyCalendarMonthGrid _grid(
    DateTime now,
    List<CalendarEvent> rows,
  ) {
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final eventDays = <int>{};
    for (final row in rows) {
      final when = row.startsAt;
      if (when.year == year && when.month == month) eventDays.add(when.day);
    }
    return FamilyCalendarMonthGrid(
      monthTitleKey: Stage1RowVocabulary.monthKeyFor(DateTime(year, month)),
      // Sunday-first blank count: Sunday is 7 → 0 leading cells.
      firstDayOffset: DateTime(year, month, 1).weekday % 7,
      daysInMonth: daysInMonth,
      todayDay: now.day,
      eventDays: eventDays,
    );
  }

  Future<List<ChildrenData>> _childrenInOrder() {
    return (_db.select(_db.children)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  static FamilyCalendarEventCategory _categoryOf(String category) =>
      switch (category) {
        Stage1RowVocabulary.categoryOcc => FamilyCalendarEventCategory.occ,
        Stage1RowVocabulary.categorySch => FamilyCalendarEventCategory.sch,
        Stage1RowVocabulary.categoryAct => FamilyCalendarEventCategory.act,
        _ => FamilyCalendarEventCategory.din,
      };

  /// Deterministic from the stored reference — presentation only, and stable
  /// across reads so a family member's dots keep one colour.
  static String _colorFor(String ref) {
    var sum = 0;
    for (final unit in ref.codeUnits) {
      sum += unit;
    }
    return _colorTokens[sum % _colorTokens.length];
  }
}

/// SCR-FAT-053 over real rows: the children come from `child` and saving writes
/// a real `calendar_event`.
///
/// Honest limit: the form's date field is a fixture sample and its time choices
/// are prayer-relative («بعد المغرب» · «بعد العشاء»), and the contract has no
/// column for a prayer-relative time — so stage-1 stores the event on today's
/// date at the option's **nominal** clock hour (19:30 · 21:00) and the reminder
/// lead in `reminder_minutes`. The real conversion needs a date/time picker and
/// the backend's prayer times; until then nothing here pretends to know them.
final class DriftAddEventRepository implements AddEventRepository {
  DriftAddEventRepository(
    this._db, {
    required String familyId,
    String? createdByAccount,
    DateTime Function()? clock,
  }) : _familyId = familyId.trim(),
       _createdBy = (createdByAccount ?? '').trim(),
       clock = clock ?? DateTime.now;

  final FamilyDatabase _db;
  final String _familyId;
  final String _createdBy;
  final DateTime Function() clock;

  /// `calendar_event.created_by_account` is NOT NULL in the contract.
  static const _unattributed = 'unattributed';

  @override
  Future<AddEventSnapshot> load() async {
    if (_familyId.isEmpty) {
      // Fail closed — no family, no children to schedule for.
      return const AddEventSnapshot();
    }
    final children = await _childrenInOrder();
    final stored =
        await (_db.selectOnly(_db.calendarEvents)
              ..addColumns([_db.calendarEvents.id.count()])
              ..where(_db.calendarEvents.familyId.equals(_familyId)))
            .getSingle();
    return AddEventSnapshot(
      children: [
        for (var i = 0; i < children.length; i++)
          AddEventChild(
            id: children[i].id,
            nameKey: Stage1RowVocabulary.childKeyFor(i),
          ),
      ],
      draft: const AddEventDraft(),
      savedEventCount: stored.read(_db.calendarEvents.id.count()) ?? 0,
    );
  }

  @override
  Future<AddEventSnapshot> saveEvent(AddEventDraft draft) async {
    final snapshot = await load();
    if (snapshot.isEmpty) return snapshot;
    final title = draft.title.trim();
    if (title.isEmpty) return snapshot;

    final now = clock();
    final children = await _childrenInOrder();
    final childIds = [for (final c in children) c.id];
    final place = draft.place.trim();
    final (hour, minute) = _nominalTime(draft.timeOption);

    await _db
        .into(_db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            id: stage1RowId('ev', now),
            familyId: _familyId,
            titleRef: title,
            category: _categoryOf(draft.category),
            calendarType: _typeOf(draft.calendarType),
            startsAt: DateTime(now.year, now.month, now.day, hour, minute),
            placeRef: Value(place.isEmpty ? null : place),
            reminderMinutes: Value(_reminderMinutes(draft.reminder)),
            whoRef: Value(
              Stage1RowVocabulary.whoRefFor(draft.whoNameKey, childIds),
            ),
            weeklyRepeat: Value(draft.weeklyRepeat),
            createdByAccount: _createdBy.isEmpty ? _unattributed : _createdBy,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return load();
  }

  Future<List<ChildrenData>> _childrenInOrder() {
    return (_db.select(_db.children)
          ..where((c) => c.familyId.equals(_familyId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .get();
  }

  static (int, int) _nominalTime(AddEventTimeOption option) => switch (option) {
    AddEventTimeOption.afterMaghrib => (19, 30),
    AddEventTimeOption.afterIsha => (21, 0),
    AddEventTimeOption.specific => (19, 30),
  };

  static int _reminderMinutes(AddEventReminder reminder) => switch (reminder) {
    AddEventReminder.atTime => 0,
    AddEventReminder.fifteenMin => 15,
    AddEventReminder.oneHour => 60,
    AddEventReminder.oneDay => 24 * 60,
  };

  static String _categoryOf(AddEventCategory category) => switch (category) {
    AddEventCategory.din => Stage1RowVocabulary.categoryDin,
    AddEventCategory.occ => Stage1RowVocabulary.categoryOcc,
    AddEventCategory.sch => Stage1RowVocabulary.categorySch,
    AddEventCategory.act => Stage1RowVocabulary.categoryAct,
  };

  static String _typeOf(AddEventCalendarType type) => switch (type) {
    AddEventCalendarType.hijri => Stage1RowVocabulary.calendarHijri,
    AddEventCalendarType.gregorian => Stage1RowVocabulary.calendarGregorian,
  };
}
