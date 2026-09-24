import 'package:flutter/foundation.dart';

@immutable
final class UsageCategoryRow {
  const UsageCategoryRow({
    required this.id,
    required this.labelKey,
    required this.hours,
    required this.progress,
    this.giftMinutes = false,
  });

  final String id;
  final String labelKey;
  final double hours;
  final double progress;
  final bool giftMinutes;
}

@immutable
final class ChildUsageReportSnapshot {
  const ChildUsageReportSnapshot({
    this.childNameKey,
    this.weekHours = 0,
    this.weekMinutes = 0,
    this.dayHeights = const [],
    this.categories = const [],
    this.retentionDays = 30,
  });

  /// Rule 23 — childOne / childTwo / childThree.
  final String? childNameKey;
  final int weekHours;
  final int weekMinutes;

  /// 0–100 bar heights for Sat…Fri.
  final List<int> dayHeights;
  final List<UsageCategoryRow> categories;
  final int retentionDays;

  bool get isEmpty => childNameKey == null;
}
