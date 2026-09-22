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

  /// ARB discriminator for title (Rule 23 — no planted person names).
  final String titleKey;

  /// ARB discriminator for when line.
  final String whenKey;

  /// Day-of-month (1–30) for grid dots.
  final int day;
  final FamilyCalendarEventCategory category;

  /// ARB discriminator for who (child one/two/three/parents/everyone).
  final String whoNameKey;

  /// Token color key — maps to [FamilyColors] (prototype per-person colors).
  final String colorKey;
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

  /// ARB key for month card heading (e.g. September · Rabi al-Awwal).
  final String monthTitleKey;

  /// Prototype grid: `day = index - firstDayOffset` (day 1 at index 7 when 6).
  final int firstDayOffset;
  final int daysInMonth;
  final int todayDay;

  /// Days that have at least one event (for dots).
  final Set<int> eventDays;
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
}
