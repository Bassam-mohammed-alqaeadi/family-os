import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// Schedule kinds persisted for SET-001 (D-1b).
enum ScheduleKind { sleep, prayer, study }

/// One enabled time window for a child × kind (same-day; end > start).
@immutable
final class ScheduleWindow {
  const ScheduleWindow({
    required this.kind,
    required this.enabled,
    this.start,
    this.end,
  });

  final ScheduleKind kind;
  final bool enabled;
  final TimeOfDay? start;
  final TimeOfDay? end;

  /// Minutes from midnight for [tod], or null.
  static int? toMinutes(TimeOfDay? tod) {
    if (tod == null) return null;
    return tod.hour * 60 + tod.minute;
  }

  static TimeOfDay? fromMinutes(int? minutes) {
    if (minutes == null) return null;
    final clamped = minutes.clamp(0, 24 * 60 - 1);
    return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  /// Same-day rule: when enabled with both ends set, [end] must be after [start].
  bool get isValid {
    if (!enabled) return true;
    final s = toMinutes(start);
    final e = toMinutes(end);
    if (s == null || e == null) return false;
    return e > s;
  }

  /// Whether [now] falls inside this enabled window (same-day).
  bool contains(TimeOfDay now) {
    if (!enabled || !isValid) return false;
    final n = toMinutes(now)!;
    final s = toMinutes(start)!;
    final e = toMinutes(end)!;
    return n >= s && n < e;
  }

  ScheduleWindow copyWith({
    ScheduleKind? kind,
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return ScheduleWindow(
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
    );
  }

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'enabled': enabled,
        'startMinutes': toMinutes(start),
        'endMinutes': toMinutes(end),
      };

  factory ScheduleWindow.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String? ?? ScheduleKind.sleep.name;
    final kind = ScheduleKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => ScheduleKind.sleep,
    );
    return ScheduleWindow(
      kind: kind,
      enabled: json['enabled'] as bool? ?? false,
      start: fromMinutes(json['startMinutes'] as int?),
      end: fromMinutes(json['endMinutes'] as int?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleWindow &&
          kind == other.kind &&
          enabled == other.enabled &&
          toMinutes(start) == toMinutes(other.start) &&
          toMinutes(end) == toMinutes(other.end);

  @override
  int get hashCode => Object.hash(kind, enabled, toMinutes(start), toMinutes(end));
}

/// Defaults applied when a kind is first enabled with unset times.
abstract final class ScheduleWindowDefaults {
  /// Sleep default: 21:00–22:30 (same-day Stage-1 rule).
  static const TimeOfDay sleepStart = TimeOfDay(hour: 21, minute: 0);
  static const TimeOfDay sleepEnd = TimeOfDay(hour: 22, minute: 30);

  /// Study default: 16:00–18:00.
  static const TimeOfDay studyStart = TimeOfDay(hour: 16, minute: 0);
  static const TimeOfDay studyEnd = TimeOfDay(hour: 18, minute: 0);

  /// Prayer default duration when first enabled (SET-001).
  static const int prayerDurationMinutes = 15;

  /// Prayer seed start when unset (noon) — deterministic for tests.
  static const TimeOfDay prayerSeedStart = TimeOfDay(hour: 12, minute: 0);

  /// Seeds missing times when enabling a window.
  static ScheduleWindow seedOnEnable(ScheduleWindow current) {
    if (!current.enabled) return current;
    if (current.start != null && current.end != null) return current;

    return switch (current.kind) {
      ScheduleKind.sleep => current.copyWith(
          start: current.start ?? sleepStart,
          end: current.end ?? sleepEnd,
        ),
      ScheduleKind.study => current.copyWith(
          start: current.start ?? studyStart,
          end: current.end ?? studyEnd,
        ),
      ScheduleKind.prayer => _seedPrayer(current),
    };
  }

  static ScheduleWindow _seedPrayer(ScheduleWindow current) {
    final start = current.start ?? prayerSeedStart;
    final endMinutes =
        (ScheduleWindow.toMinutes(start)! + prayerDurationMinutes)
            .clamp(0, 24 * 60 - 1);
    final end = current.end ?? ScheduleWindow.fromMinutes(endMinutes);
    return current.copyWith(start: start, end: end);
  }
}
