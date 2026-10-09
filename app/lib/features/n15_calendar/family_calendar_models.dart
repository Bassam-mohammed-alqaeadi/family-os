import 'package:flutter/foundation.dart';

/// Event categories on SCR-FAT-052 (prototype FAT-052 chips).
enum FamilyCalendarEventCategory { din, occ, sch, act }

/// Filter selection — all or a single category.
enum FamilyCalendarFilter { all, din, occ, sch, act }

@immutable
final class FamilyCalendarEvent {
  const FamilyCalendarEvent({
    required this.id,
    required this.titleKey,
    required this.whenKey,
    required this.day,
    required this.category,
    required this.whoNameKey,
    required this.colorKey,
  });

  final String id;
  final String titleKey;
  final String whenKey;
  final int day;
  final FamilyCalendarEventCategory category;
  final String whoNameKey;
  final String colorKey;

  Map<String, Object?> toJson() => {
    'id': id,
    'titleKey': titleKey,
    'whenKey': whenKey,
    'day': day,
    'category': category.name,
    'whoNameKey': whoNameKey,
    'colorKey': colorKey,
  };

  static FamilyCalendarEvent fromJson(Map<String, Object?> json) {
    final catRaw = json['category']?.toString() ?? 'sch';
    final category = FamilyCalendarEventCategory.values.firstWhere(
      (c) => c.name == catRaw,
      orElse: () => FamilyCalendarEventCategory.sch,
    );
    final dayRaw = json['day'];
    final day = dayRaw is int
        ? dayRaw
        : int.tryParse(dayRaw?.toString() ?? '') ?? 1;
    return FamilyCalendarEvent(
      id: json['id']?.toString() ?? '',
      titleKey: json['titleKey']?.toString() ?? '',
      whenKey: json['whenKey']?.toString() ?? 'today',
      day: day,
      category: category,
      whoNameKey: json['whoNameKey']?.toString() ?? 'one',
      colorKey: json['colorKey']?.toString() ?? 'sky',
    );
  }
}

@immutable
final class FamilyCalendarMonthGrid {
  const FamilyCalendarMonthGrid({
    required this.monthTitleKey,
    required this.firstDayOffset,
    required this.daysInMonth,
    required this.todayDay,
    required this.eventDays,
  });

  final String monthTitleKey;
  final int firstDayOffset;
  final int daysInMonth;
  final int todayDay;
  final Set<int> eventDays;

  Map<String, Object?> toJson() => {
    'monthTitleKey': monthTitleKey,
    'firstDayOffset': firstDayOffset,
    'daysInMonth': daysInMonth,
    'todayDay': todayDay,
    'eventDays': eventDays.toList(),
  };

  static FamilyCalendarMonthGrid fromJson(Map<String, Object?> json) {
    final daysRaw = json['eventDays'];
    final days = <int>{};
    if (daysRaw is List) {
      for (final e in daysRaw) {
        if (e is int) {
          days.add(e);
        } else {
          final parsed = int.tryParse(e.toString());
          if (parsed != null) days.add(parsed);
        }
      }
    }
    int asInt(Object? v, int fallback) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;
    return FamilyCalendarMonthGrid(
      monthTitleKey: json['monthTitleKey']?.toString() ?? 'sep2026',
      firstDayOffset: asInt(json['firstDayOffset'], 6),
      daysInMonth: asInt(json['daysInMonth'], 30),
      todayDay: asInt(json['todayDay'], 14),
      eventDays: days,
    );
  }
}

@immutable
final class FamilyCalendarSnapshot {
  const FamilyCalendarSnapshot({
    this.events = const [],
    this.month = const FamilyCalendarMonthGrid(
      monthTitleKey: 'sep2026',
      firstDayOffset: 6,
      daysInMonth: 30,
      todayDay: 14,
      eventDays: {},
    ),
  });

  final List<FamilyCalendarEvent> events;
  final FamilyCalendarMonthGrid month;

  bool get isEmpty => events.isEmpty;

  FamilyCalendarSnapshot withEvents(List<FamilyCalendarEvent> next) {
    final days = {for (final e in next) e.day};
    return FamilyCalendarSnapshot(
      events: next,
      month: FamilyCalendarMonthGrid(
        monthTitleKey: month.monthTitleKey,
        firstDayOffset: month.firstDayOffset,
        daysInMonth: month.daysInMonth,
        todayDay: month.todayDay,
        eventDays: days,
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'month': month.toJson(),
  };

  static FamilyCalendarSnapshot fromJson(Map<String, Object?> json) {
    final eventsRaw = json['events'];
    final events = <FamilyCalendarEvent>[];
    if (eventsRaw is List) {
      for (final e in eventsRaw) {
        if (e is Map) {
          events.add(
            FamilyCalendarEvent.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    final monthRaw = json['month'];
    final month = monthRaw is Map
        ? FamilyCalendarMonthGrid.fromJson(
            monthRaw.map((k, v) => MapEntry(k.toString(), v)),
          )
        : const FamilyCalendarMonthGrid(
            monthTitleKey: 'sep2026',
            firstDayOffset: 6,
            daysInMonth: 30,
            todayDay: 14,
            eventDays: {},
          );
    return FamilyCalendarSnapshot(events: events, month: month);
  }
}
