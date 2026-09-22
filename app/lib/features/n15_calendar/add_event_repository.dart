import 'package:family_os/features/n15_calendar/add_event_models.dart';

/// Rule 25 seam — Stage-1 mock add family calendar event (no backend).
abstract class AddEventRepository {
  Future<AddEventSnapshot> load();

  Future<AddEventSnapshot> saveEvent(AddEventDraft draft);
}

/// In-memory mock — prototype FAT-053 shape by default.
final class InMemoryAddEventRepository implements AddEventRepository {
  InMemoryAddEventRepository({AddEventSnapshot? seed})
    : _snap = seed ?? addEventPrototypeFixture();

  AddEventSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<AddEventSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }

  @override
  Future<AddEventSnapshot> saveEvent(AddEventDraft draft) async {
    if (_snap.isEmpty) return _copy(_snap);
    final trimmed = draft.title.trim();
    if (trimmed.isEmpty) return _copy(_snap);
    _snap = _snap.copyWith(
      draft: draft.copyWith(title: trimmed),
      savedEventCount: _snap.savedEventCount + 1,
    );
    return _copy(_snap);
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

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryAddEventRepository stage1AddEventRepository =
    InMemoryAddEventRepository();

/// Empty — Rule 23 empty-state coverage (no children to schedule for).
AddEventSnapshot addEventEmptyFixture() {
  return const AddEventSnapshot();
}

/// One child — minimal family for single-target events.
AddEventSnapshot addEventOneFixture() {
  return const AddEventSnapshot(
    children: [
      AddEventChild(id: 'child_a', nameKey: 'one'),
    ],
    draft: AddEventDraft(
      title: '',
      category: AddEventCategory.sch,
      whoNameKey: 'childOne',
      weeklyRepeat: false,
    ),
  );
}

/// Prototype FAT-053 — three children + full form defaults.
///
/// Rule 23: nameKey only (no planted person names).
AddEventSnapshot addEventPrototypeFixture() {
  return const AddEventSnapshot(
    children: [
      AddEventChild(id: 'child_a', nameKey: 'one'),
      AddEventChild(id: 'child_b', nameKey: 'two'),
      AddEventChild(id: 'child_c', nameKey: 'three'),
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
