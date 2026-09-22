import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'schedule_window.dart';
import 'smart_modes.dart';

/// One built-in smart mode row (schedule + activation) — SET-018 / MODE tables.
///
/// Host screen: **SCR-FAT-085** (S-SEC-058 schedule · S-SEC-059 activation).
/// Tombstone SCR-FAT-039 must never host these ops (ADR-034 / T-1).
@immutable
final class SmartModeRow {
  const SmartModeRow({
    required this.modeId,
    this.active = false,
    this.scheduleStart,
    this.scheduleEnd,
  });

  final BuiltInModeId modeId;
  final bool active;
  final TimeOfDay? scheduleStart;
  final TimeOfDay? scheduleEnd;

  /// Prototype school default: Sun–Thu 07:00–13:45 (Stage-1 same-day window).
  static const TimeOfDay defaultSchoolStart = TimeOfDay(hour: 7, minute: 0);
  static const TimeOfDay defaultSchoolEnd = TimeOfDay(hour: 13, minute: 45);

  SmartModeRow copyWith({
    BuiltInModeId? modeId,
    bool? active,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return SmartModeRow(
      modeId: modeId ?? this.modeId,
      active: active ?? this.active,
      scheduleStart: clearStart ? null : (scheduleStart ?? this.scheduleStart),
      scheduleEnd: clearEnd ? null : (scheduleEnd ?? this.scheduleEnd),
    );
  }

  /// Seeds school defaults when activating with unset times.
  SmartModeRow seedSchoolScheduleIfNeeded() {
    if (modeId != BuiltInModeId.school) return this;
    if (scheduleStart != null && scheduleEnd != null) return this;
    return copyWith(
      scheduleStart: scheduleStart ?? defaultSchoolStart,
      scheduleEnd: scheduleEnd ?? defaultSchoolEnd,
    );
  }

  Map<String, Object?> toJson() => {
        'modeId': modeId.name,
        'active': active,
        'startMinutes': ScheduleWindow.toMinutes(scheduleStart),
        'endMinutes': ScheduleWindow.toMinutes(scheduleEnd),
      };

  factory SmartModeRow.fromJson(Map<String, Object?> json) {
    final name = json['modeId'] as String? ?? BuiltInModeId.custom.name;
    final modeId = BuiltInModeId.values.firstWhere(
      (m) => m.name == name,
      orElse: () => BuiltInModeId.custom,
    );
    return SmartModeRow(
      modeId: modeId,
      active: json['active'] as bool? ?? false,
      scheduleStart: ScheduleWindow.fromMinutes(
        (json['startMinutes'] as num?)?.toInt(),
      ),
      scheduleEnd: ScheduleWindow.fromMinutes(
        (json['endMinutes'] as num?)?.toInt(),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SmartModeRow &&
      other.modeId == modeId &&
      other.active == active &&
      ScheduleWindow.toMinutes(other.scheduleStart) ==
          ScheduleWindow.toMinutes(scheduleStart) &&
      ScheduleWindow.toMinutes(other.scheduleEnd) ==
          ScheduleWindow.toMinutes(scheduleEnd);

  @override
  int get hashCode => Object.hash(
        modeId,
        active,
        ScheduleWindow.toMinutes(scheduleStart),
        ScheduleWindow.toMinutes(scheduleEnd),
      );
}

/// Family-level smart modes snapshot (SET-018 mock MODE store).
@immutable
final class SmartModePrefs {
  const SmartModePrefs({
    required this.childId,
    required this.modes,
  });

  static const String defaultChildId = 'child_demo';

  final String childId;
  final List<SmartModeRow> modes;

  /// Defaults: all built-ins inactive; school has prototype schedule.
  factory SmartModePrefs.defaults({String childId = defaultChildId}) {
    return SmartModePrefs(
      childId: childId,
      modes: [
        for (final id in BuiltInModeId.values)
          SmartModeRow(
            modeId: id,
            scheduleStart:
                id == BuiltInModeId.school ? SmartModeRow.defaultSchoolStart : null,
            scheduleEnd:
                id == BuiltInModeId.school ? SmartModeRow.defaultSchoolEnd : null,
          ),
      ],
    );
  }

  SmartModeRow row(BuiltInModeId id) {
    for (final m in modes) {
      if (m.modeId == id) return m;
    }
    return SmartModeRow(modeId: id);
  }

  BuiltInModeId? get activeModeId {
    for (final m in modes) {
      if (m.active) return m.modeId;
    }
    return null;
  }

  SmartModePrefs withRow(SmartModeRow next) {
    final list = <SmartModeRow>[];
    var found = false;
    for (final m in modes) {
      if (m.modeId == next.modeId) {
        list.add(next);
        found = true;
      } else if (next.active) {
        // Single active mode at a time (prototype setFamilyMode semantics).
        list.add(m.copyWith(active: false));
      } else {
        list.add(m);
      }
    }
    if (!found) list.add(next);
    return SmartModePrefs(childId: childId, modes: list);
  }

  Map<String, Object?> toJson() => {
        'childId': childId,
        'modes': modes.map((m) => m.toJson()).toList(),
      };

  factory SmartModePrefs.fromJson(Map<String, Object?> json) {
    final childId = json['childId'] as String? ?? defaultChildId;
    final raw = json['modes'];
    if (raw is! List) return SmartModePrefs.defaults(childId: childId);
    final byId = <BuiltInModeId, SmartModeRow>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final row = SmartModeRow.fromJson(
        item.map((k, v) => MapEntry(k.toString(), v)),
      );
      byId[row.modeId] = row;
    }
    return SmartModePrefs(
      childId: childId,
      modes: [
        for (final id in BuiltInModeId.values)
          byId[id] ??
              (id == BuiltInModeId.school
                  ? const SmartModeRow(
                      modeId: BuiltInModeId.school,
                      scheduleStart: SmartModeRow.defaultSchoolStart,
                      scheduleEnd: SmartModeRow.defaultSchoolEnd,
                    )
                  : SmartModeRow(modeId: id)),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SmartModePrefs &&
      other.childId == childId &&
      listEquals(other.modes, modes);

  @override
  int get hashCode => Object.hash(childId, Object.hashAll(modes));
}
