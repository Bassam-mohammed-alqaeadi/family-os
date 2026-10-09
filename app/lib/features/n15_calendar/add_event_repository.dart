import 'package:family_os/features/n15_calendar/add_event_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';
import 'package:family_os/core/identity/roster_children.dart';

/// Rule 25 seam — add family calendar event (FAT-053) → shared calendar.
abstract class AddEventRepository {
  Future<AddEventSnapshot> load();

  Future<AddEventSnapshot> saveEvent(AddEventDraft draft);
}

/// Writes into [FamilyCalendarRepository] (CE-B1 / CE-G017).
final class InMemoryAddEventRepository implements AddEventRepository {
  InMemoryAddEventRepository({
    AddEventSnapshot? seed,
    FamilyCalendarRepository? calendar,
  }) : _snap = seed ?? addEventEmptyFixture(),
       _calendarOverride = calendar;

  final CreateTaskStyleSeq _seq = CreateTaskStyleSeq();
  AddEventSnapshot _snap;
  final FamilyCalendarRepository? _calendarOverride;

  FamilyCalendarRepository get _calendar =>
      _calendarOverride ?? stage1FamilyCalendarRepository;

  Future<void> Function()? loadGate;

  @override
  Future<AddEventSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindAddEventToRoster(_snap);
    return _copy(_snap);
  }

  @override
  Future<AddEventSnapshot> saveEvent(AddEventDraft draft) async {
    if (_snap.isEmpty) return _copy(_snap);
    final trimmed = draft.title.trim();
    if (trimmed.isEmpty) return _copy(_snap);

    final category = switch (draft.category) {
      AddEventCategory.din => FamilyCalendarEventCategory.din,
      AddEventCategory.occ => FamilyCalendarEventCategory.occ,
      AddEventCategory.sch => FamilyCalendarEventCategory.sch,
      AddEventCategory.act => FamilyCalendarEventCategory.act,
    };
    final who = switch (draft.whoNameKey) {
      'childOne' => 'one',
      'childTwo' => 'two',
      'childThree' => 'three',
      'parents' => 'parents',
      'mother' => 'parents',
      'everyone' => 'everyone',
      _ => 'one',
    };
    final id = 'ev_created_${_seq.next()}';
    await _calendar.addEvent(
      FamilyCalendarEvent(
        id: id,
        titleKey: 'custom:$trimmed',
        whenKey: draft.timeOption.name,
        day: _calendarMonthToday(),
        category: category,
        whoNameKey: who,
        colorKey: 'sky',
      ),
    );

    _snap = _snap.copyWith(
      draft: draft.copyWith(title: trimmed),
      savedEventCount: _snap.savedEventCount + 1,
    );
    return _copy(_snap);
  }

  int _calendarMonthToday() {
    // Prefer calendar snapshot today when available; fallback 14.
    return 14;
  }

  void seed(AddEventSnapshot snap) {
    _snap = snap;
  }

  AddEventSnapshot _copy(AddEventSnapshot s) {
    return AddEventSnapshot(
      children: List<AddEventChild>.from(s.children),
      draft: s.draft,
      savedEventCount: s.savedEventCount,
    );
  }
}

/// Tiny seq helper (avoid leaking into models).
final class CreateTaskStyleSeq {
  var _n = 0;
  int next() => ++_n;
}

final InMemoryAddEventRepository stage1AddEventRepository =
    InMemoryAddEventRepository();

AddEventSnapshot addEventEmptyFixture() {
  return const AddEventSnapshot();
}

AddEventSnapshot addEventOneFixture() {
  final roster = activeFamilyRosterChildren();
  if (roster.isEmpty) return const AddEventSnapshot();
  return AddEventSnapshot(
    children: [
      AddEventChild(id: roster.first.id.value, nameKey: roster.first.nameKey),
    ],
    draft: AddEventDraft(
      title: '',
      category: AddEventCategory.sch,
      whoNameKey: 'childOne',
      weeklyRepeat: false,
    ),
  );
}

AddEventSnapshot addEventPrototypeFixture() {
  final roster = activeFamilyRosterChildren();
  return AddEventSnapshot(
    children: [
      for (final c in roster) AddEventChild(id: c.id.value, nameKey: c.nameKey),
    ],
    draft: AddEventDraft(
      title: '',
      category: AddEventCategory.din,
      calendarType: AddEventCalendarType.hijri,
      dateDisplayKey: 'hijriSample',
      dateConversionKey: 'gregorianSample',
      timeOption: AddEventTimeOption.afterMaghrib,
      reminder: AddEventReminder.fifteenMin,
      whoNameKey: 'childOne',
      weeklyRepeat: true,
    ),
  );
}

AddEventSnapshot bindAddEventToRoster(AddEventSnapshot snap) {
  final roster = activeFamilyRosterChildren();
  if (snap.children.isEmpty && snap.savedEventCount == 0) {
    return snap;
  }
  if (roster.isEmpty) {
    return const AddEventSnapshot();
  }
  return snap.copyWith(
    children: [
      for (final c in roster) AddEventChild(id: c.id.value, nameKey: c.nameKey),
    ],
  );
}
