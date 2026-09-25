import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/features/n15_calendar/add_event_models.dart';
import 'package:family_os/features/n15_calendar/calendar_ux_bridge.dart';
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';

/// DEV-3b — the calendar domain (SCR-FAT-052 · FAT-053) over the ADR-054 v6
/// row `calendar_event`, with the month card computed from the clock.
void main() {
  group('calendar over real rows', () {
    late Directory dir;
    late File file;
    late FamilyDatabase db;
    late DateTime now;
    var dbClosed = false;

    setUp(() async {
      dbClosed = false;
      // Thursday, 24 September 2026 — the month card must say so itself.
      now = DateTime(2026, 9, 24, 12);
      dir = await Directory.systemTemp.createTemp('dev3c_');
      file = File('${dir.path}/dev3c.sqlite');
      db = FamilyDatabase(NativeDatabase(file));
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await dir.delete(recursive: true);
    });

    Future<void> child({
      required String id,
      required String alias,
      required DateTime createdAt,
      String familyId = 'fam_1',
    }) => db.into(db.children).insert(
      ChildrenCompanion.insert(
        id: id,
        familyId: familyId,
        displayName: alias,
        alias: alias,
        createdAt: Value(createdAt),
      ),
    );

    Future<void> event({
      required String id,
      required String titleRef,
      required DateTime startsAt,
      String familyId = 'fam_1',
      String category = Stage1RowVocabulary.categoryDin,
      String calendarType = Stage1RowVocabulary.calendarHijri,
      String? placeRef,
      int? reminderMinutes,
      String? whoRef,
      bool weeklyRepeat = false,
      String createdByAccount = 'acc_father',
    }) => db.into(db.calendarEvents).insert(
      CalendarEventsCompanion.insert(
        id: id,
        familyId: familyId,
        titleRef: titleRef,
        category: category,
        calendarType: calendarType,
        startsAt: startsAt,
        placeRef: Value(placeRef),
        reminderMinutes: Value(reminderMinutes),
        whoRef: Value(whoRef),
        weeklyRepeat: Value(weeklyRepeat),
        createdByAccount: createdByAccount,
      ),
    );

    Future<void> seed() async {
      await child(
        id: 'chi_1',
        alias: 'child_1',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await child(
        id: 'chi_2',
        alias: 'child_2',
        createdAt: DateTime.utc(2026, 1, 2),
      );
      await event(
        id: 'ev_today',
        titleRef: 'dentalAppointment',
        startsAt: DateTime(2026, 9, 24, 10),
        category: Stage1RowVocabulary.categoryOcc,
        whoRef: 'chi_2',
      );
      await event(
        id: 'ev_later',
        titleRef: 'quranTest',
        startsAt: DateTime(2026, 9, 30, 8, 15),
        category: Stage1RowVocabulary.categorySch,
        whoRef: 'chi_1',
        reminderMinutes: 60,
      );
      // Another month, and another family — neither may appear in this card.
      await event(
        id: 'ev_next_month',
        titleRef: 'winterTrip',
        startsAt: DateTime(2026, 10, 3, 9),
      );
      await event(
        id: 'ev_other_family',
        titleRef: 'otherFamilyEvent',
        startsAt: DateTime(2026, 9, 25, 9),
        familyId: 'fam_2',
      );
    }

    DriftFamilyCalendarRepository calendar({String familyId = 'fam_1'}) =>
        DriftFamilyCalendarRepository(db, familyId: familyId, clock: () => now);

    DriftAddEventRepository form({String familyId = 'fam_1'}) =>
        DriftAddEventRepository(
          db,
          familyId: familyId,
          createdByAccount: 'acc_father',
          clock: () => now,
        );

    test('the month card is the clock\u2019s month, dotted from the rows',
        () async {
      await seed();

      final snap = await calendar().load();

      expect(snap.month.monthTitleKey, '2026-09-01');
      expect(snap.month.daysInMonth, 30);
      expect(snap.month.todayDay, 24);
      // Sunday-first blanks: 1 September 2026 is a Tuesday → two blanks.
      expect(snap.month.firstDayOffset, 2);
      expect(snap.month.eventDays, {24, 30});
      expect(snap.events.map((e) => e.id), ['ev_today', 'ev_later']);
      expect(snap.events.first.whenKey, '10:00');
      expect(snap.events.last.whenKey, '2026-09-30 08:15');
      expect(snap.events.last.category, FamilyCalendarEventCategory.sch);
      // The stored reference resolves through the family's own child order.
      expect(snap.events.first.whoNameKey, 'childTwo');
      expect(snap.events.first.colorKey, isNotEmpty);
    });

    test('an unscoped or unknown family fails closed', () async {
      await seed();

      expect((await calendar(familyId: '').load()).events, isEmpty);
      expect((await calendar(familyId: '   ').load()).events, isEmpty);
      final unknown = await calendar(familyId: 'fam_none').load();
      expect(unknown.events, isEmpty);
      // The month itself is the clock's, not family data.
      expect(unknown.month.monthTitleKey, '2026-09-01');
    });

    test('saving writes a real event row, and the card reads it back',
        () async {
      await seed();
      final repo = form();
      final loaded = await repo.load();
      expect(loaded.children.map((c) => c.id), ['chi_1', 'chi_2']);
      // Every stored row of the family counts, including the months the card
      // does not display yet.
      expect(loaded.savedEventCount, 3);

      await repo.saveEvent(
        const AddEventDraft(
          title: 'تدريب السباحة',
          category: AddEventCategory.act,
          calendarType: AddEventCalendarType.gregorian,
          timeOption: AddEventTimeOption.afterIsha,
          place: 'نادي السباحة',
          reminder: AddEventReminder.fifteenMin,
          whoNameKey: 'childTwo',
          weeklyRepeat: true,
        ),
      );

      final stored =
          await (db.select(db.calendarEvents)
                ..where((e) => e.titleRef.equals('تدريب السباحة')))
              .getSingle();
      expect(stored.category, Stage1RowVocabulary.categoryAct);
      expect(stored.calendarType, Stage1RowVocabulary.calendarGregorian);
      expect(stored.whoRef, 'chi_2');
      expect(stored.placeRef, 'نادي السباحة');
      expect(stored.reminderMinutes, 15);
      expect(stored.weeklyRepeat, isTrue);
      expect(stored.createdByAccount, 'acc_father');
      // Prayer-relative time has no column: stored at the nominal 21:00.
      expect(stored.startsAt, DateTime(2026, 9, 24, 21));

      final snap = await calendar().load();
      final shown = snap.events.firstWhere((e) => e.id == stored.id);
      expect(shown.titleKey, 'تدريب السباحة');
      expect(shown.day, 24);
      expect(shown.whenKey, '21:00');
      expect(shown.whoNameKey, 'childTwo');
      expect(shown.category, FamilyCalendarEventCategory.act);
    });

    test('the shared lanes round-trip: mother and everyone', () async {
      await seed();
      final repo = form();

      await repo.saveEvent(
        const AddEventDraft(
          title: 'قائمة التسوق',
          whoNameKey: 'mother',
          weeklyRepeat: false,
        ),
      );
      await repo.saveEvent(
        const AddEventDraft(title: 'عشاء العائلة', whoNameKey: 'everyone'),
      );

      final stored = await (db.select(db.calendarEvents)
            ..where((e) => e.titleRef.equals('قائمة التسوق')))
          .get();
      expect(stored.single.whoRef, 'mother');
      final familyWide = await (db.select(db.calendarEvents)
            ..where((e) => e.titleRef.equals('عشاء العائلة')))
          .get();
      expect(familyWide.single.whoRef, Stage1RowVocabulary.whoFamily);

      final snap = await calendar().load();
      expect(
        snap.events.firstWhere((e) => e.id == stored.single.id).whoNameKey,
        'mother',
      );
      expect(
        snap.events.firstWhere((e) => e.id == familyWide.single.id).whoNameKey,
        'everyone',
      );

      // An empty title writes nothing.
      final before = (await db.select(db.calendarEvents).get()).length;
      await repo.saveEvent(const AddEventDraft(title: '  '));
      expect((await db.select(db.calendarEvents).get()).length, before);
    });

    test('ADR-042 \u2014 the event survives close + reopen', () async {
      await seed();
      await form().saveEvent(
        const AddEventDraft(
          title: 'موعد طبيب الأسنان',
          category: AddEventCategory.occ,
        ),
      );
      await db.close();
      dbClosed = true;

      final reopened = FamilyDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final snap = await DriftFamilyCalendarRepository(
        reopened,
        familyId: 'fam_1',
        clock: () => now,
      ).load();

      expect(
        snap.events.where((e) => e.titleKey == 'موعد طبيب الأسنان'),
        hasLength(1),
      );
      expect(snap.month.eventDays, contains(24));
    });
  });
}
