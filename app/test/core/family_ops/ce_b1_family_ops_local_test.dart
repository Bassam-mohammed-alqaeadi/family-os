import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n02_day/child_arrival_local_repository.dart';
import 'package:family_os/features/n02_day/child_arrival_models.dart';
import 'package:family_os/features/n02_day/child_media_share_local_repository.dart';
import 'package:family_os/features/n02_day/child_media_share_models.dart';
import 'package:family_os/features/n02_day/outer_circle_local_repository.dart';
import 'package:family_os/features/n15_calendar/add_event_models.dart';
import 'package:family_os/features/n15_calendar/add_event_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_local_repository.dart';
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/features/n17_child_learn/child_focus_sounds_local_repository.dart';

/// CE-B1 remainder — calendar / circle / media / arrival / focus Local proofs.
void main() {
  test('calendar empty-first + addEvent restart proof', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalFamilyCalendarRepository(db);
    expect((await a.load()).isEmpty, isTrue);

    await a.addEvent(
      const FamilyCalendarEvent(
        id: 'ev-x',
        titleKey: 'custom:Park',
        whenKey: 'afterMaghrib',
        day: 14,
        category: FamilyCalendarEventCategory.act,
        whoNameKey: 'one',
        colorKey: 'sky',
      ),
    );

    final b = LocalFamilyCalendarRepository(db);
    final snap = await b.load();
    expect(snap.events, hasLength(1));
    expect(snap.events.single.titleKey, 'custom:Park');
    expect(snap.month.eventDays, contains(14));
  });

  test('AddEvent → FamilyCalendar shared authority', () async {
    final calendar = InMemoryFamilyCalendarRepository(
      seed: familyCalendarEmptyFixture(),
    );
    final add = InMemoryAddEventRepository(
      seed: addEventPrototypeFixture(),
      calendar: calendar,
    );
    await add.saveEvent(
      const AddEventDraft(
        title: 'Library hour',
        category: AddEventCategory.sch,
        whoNameKey: 'childOne',
      ),
    );
    final snap = await calendar.load();
    expect(snap.events, hasLength(1));
    expect(snap.events.single.titleKey, 'custom:Library hour');
  });

  test('outer circle request→approve restart proof', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalOuterCircleRepository(db);
    await a.requestFriend(nameKey: 'pendingFriend', metaKey: 'classmate');
    var snap = await a.load();
    expect(snap.pending, hasLength(1));

    await a.approvePending(snap.pending.single.id);
    final b = LocalOuterCircleRepository(db);
    snap = await b.load();
    expect(snap.pending, isEmpty);
    expect(snap.friends, hasLength(1));
    expect(snap.friends.single.nameKey, 'pendingFriend');
  });

  test('media share intent journal restart proof', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalChildMediaShareRepository(db);
    await a.queueShareIntent(ChildMediaShareType.photo);
    await a.queueShareIntent(ChildMediaShareType.voice);

    final b = LocalChildMediaShareRepository(db);
    final snap = await b.load();
    expect(snap.intentJournal, ['photo', 'voice']);
  });

  test('arrival check-in journal restart proof', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalChildArrivalRepository(db);
    // Seed zones via raw write path: check-in still journals even if empty zones.
    await a.checkIn('z1');
    await a.checkIn('z2');

    final b = LocalChildArrivalRepository(db);
    final snap = await b.load();
    expect(snap.checkInJournal, ['z1', 'z2']);
  });

  test('focus sounds prefs restart proof', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final a = LocalChildFocusSoundsRepository(db);
    await a.playSound('rain');
    await a.setAutoWithFocus(false);

    final b = LocalChildFocusSoundsRepository(db);
    final snap = await b.load();
    expect(snap.activeSoundId, 'rain');
    expect(snap.autoWithFocus, isFalse);
    expect(snap.hasSounds, isTrue);
    expect(snap.sounds, isNotEmpty);
  });

  test('arrival zones JSON round-trip', () {
    final snap = ChildArrivalSnapshot(
      zones: const [
        ChildArrivalZone(
          id: 'z1',
          nameKey: 'school',
          descKey: 'schoolDesc',
          iconKey: 'school',
        ),
      ],
      checkInJournal: const ['z1'],
    );
    final round = ChildArrivalSnapshot.fromJson(snap.toJson());
    expect(round.zones.single.id, 'z1');
    expect(round.checkInJournal, ['z1']);
  });
}
