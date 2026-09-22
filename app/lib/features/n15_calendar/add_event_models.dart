import 'package:flutter/foundation.dart';

/// Event category on SCR-FAT-053 (prototype FAT-053 four tracks).
enum AddEventCategory { din, occ, sch, act }

/// Calendar display mode — Stage-1 mock toggle with toast only.
enum AddEventCalendarType { hijri, gregorian }

/// Prayer-relative or fixed time (prototype select).
enum AddEventTimeOption { afterMaghrib, afterIsha, specific }

/// Reminder lead time before event (prototype «تذكير قبل»).
enum AddEventReminder { atTime, fifteenMin, oneHour, oneDay }

@immutable
final class AddEventChild {
  const AddEventChild({
    required this.id,
    required this.nameKey,
  });

  final String id;

  /// ARB discriminator — screen maps to localized generic label (Rule 23).
  final String nameKey;
}

@immutable
final class AddEventDraft {
  const AddEventDraft({
    this.title = '',
    this.category = AddEventCategory.din,
    this.calendarType = AddEventCalendarType.hijri,
    this.dateDisplayKey = 'hijriSample',
    this.dateConversionKey = 'gregorianSample',
    this.timeOption = AddEventTimeOption.afterMaghrib,
    this.place = '',
    this.reminder = AddEventReminder.fifteenMin,
    this.whoNameKey = 'childOne',
    this.weeklyRepeat = true,
  });

  final String title;
  final AddEventCategory category;
  final AddEventCalendarType calendarType;

  /// ARB key for mock hijri/gregorian date line (Rule 23).
  final String dateDisplayKey;
  final String dateConversionKey;
  final AddEventTimeOption timeOption;
  final String place;
  final AddEventReminder reminder;

  /// Who the event applies to — childOne/childTwo/childThree/mother/everyone.
  final String whoNameKey;
  final bool weeklyRepeat;

  AddEventDraft copyWith({
    String? title,
    AddEventCategory? category,
    AddEventCalendarType? calendarType,
    String? dateDisplayKey,
    String? dateConversionKey,
    AddEventTimeOption? timeOption,
    String? place,
    AddEventReminder? reminder,
    String? whoNameKey,
    bool? weeklyRepeat,
  }) {
    return AddEventDraft(
      title: title ?? this.title,
      category: category ?? this.category,
      calendarType: calendarType ?? this.calendarType,
      dateDisplayKey: dateDisplayKey ?? this.dateDisplayKey,
      dateConversionKey: dateConversionKey ?? this.dateConversionKey,
      timeOption: timeOption ?? this.timeOption,
      place: place ?? this.place,
      reminder: reminder ?? this.reminder,
      whoNameKey: whoNameKey ?? this.whoNameKey,
      weeklyRepeat: weeklyRepeat ?? this.weeklyRepeat,
    );
  }
}

@immutable
final class AddEventSnapshot {
  const AddEventSnapshot({
    this.children = const [],
    this.draft = const AddEventDraft(),
    this.savedEventCount = 0,
  });

  final List<AddEventChild> children;
  final AddEventDraft draft;
  final int savedEventCount;

  bool get isEmpty => children.isEmpty;

  AddEventSnapshot copyWith({
    List<AddEventChild>? children,
    AddEventDraft? draft,
    int? savedEventCount,
  }) {
    return AddEventSnapshot(
      children: children ?? this.children,
      draft: draft ?? this.draft,
      savedEventCount: savedEventCount ?? this.savedEventCount,
    );
  }
}
