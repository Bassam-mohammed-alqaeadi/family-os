import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'notification_tier.dart';
import 'schedule_window.dart';

/// Forbidden JSON keys — SOS/critical receipt is never muteable (P-4 / doc 20).
const Set<String> kForbiddenSosMuteKeys = {
  'sosMuted',
  'sos_muted',
  'sos_enabled',
  'sosEnabled',
  'muteSos',
  'mute_sos',
  'muteSOS',
  'sosReceiptEnabled',
  'sos_receipt_enabled',
};

/// Thrown when prefs JSON / API attempts to mute SOS / disable critical receipt.
final class ForbiddenSosMuteFieldException implements Exception {
  ForbiddenSosMuteFieldException(this.field);

  final String field;

  @override
  String toString() =>
      'ForbiddenSosMuteFieldException: schema forbids "$field" (P-4 / SET-021)';
}

/// Per-member notification preferences (SET-010 / SET-011).
///
/// Rows are keyed by [memberId] (father owner vs mother parent).
/// Schema intentionally has **no** muteable SOS field — [sosReceiptAlwaysOn].
@immutable
final class NotificationPrefs {
  const NotificationPrefs({
    required this.memberId,
    this.quietHoursEnabled = false,
    this.quietStart,
    this.quietEnd,
    this.analysisNoticesEnabled = true,
  });

  /// Defaults: quiet hours off; analysis notices on (R-3); SOS always on.
  factory NotificationPrefs.defaults({required String memberId}) =>
      NotificationPrefs(memberId: memberId);

  final String memberId;
  final bool quietHoursEnabled;
  final TimeOfDay? quietStart;
  final TimeOfDay? quietEnd;

  /// R-3 / `S-AIC-029` analysis notices (non-critical). Default on; per-member.
  final bool analysisNoticesEnabled;

  /// Doc 20 / SET-011 / SET-021 — SOS receipt is ungradeable for guardians (and all members).
  static const bool sosReceiptAlwaysOn = true;

  /// Stage-1 guardian member ids that must never mute SOS (SET-021).
  static const Set<String> guardianMemberIds = {
    'father',
    'mother',
    'guardian',
  };

  /// Whether [memberId] is a guardian / parent row (SET-021).
  static bool isGuardianMemberId(String memberId) =>
      guardianMemberIds.contains(memberId);

  /// Default quiet window when enabling with unset times (22:00–07:00 overnight).
  static const TimeOfDay defaultQuietStart = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay defaultQuietEnd = TimeOfDay(hour: 7, minute: 0);

  /// Stage-1 member ids from [AppRole]-like names.
  static String memberIdForRoleName(String roleName) {
    switch (roleName) {
      case 'mother':
        return 'mother';
      case 'child':
        return 'child';
      case 'guardian':
        return 'guardian';
      case 'father':
      default:
        return 'father';
    }
  }

  /// Quiet hours apply only to [NotificationTier.nonCritical] (P-4).
  static bool quietHoursAppliesTo(NotificationTier tier) =>
      tier == NotificationTier.nonCritical;

  /// Tiers that quiet-hours prefs may filter (excludes critical).
  static Iterable<NotificationTier> filterableTiers() =>
      NotificationTier.values.where(quietHoursAppliesTo);

  /// Minutes from midnight helpers (reuse schedule encoding).
  static int? toMinutes(TimeOfDay? tod) => ScheduleWindow.toMinutes(tod);

  static TimeOfDay? fromMinutes(int? minutes) =>
      ScheduleWindow.fromMinutes(minutes);

  /// Valid when disabled, or when both ends are set and not equal.
  bool get isValid {
    if (!quietHoursEnabled) return true;
    final s = toMinutes(quietStart);
    final e = toMinutes(quietEnd);
    if (s == null || e == null) return false;
    return s != e;
  }

  /// Whether [now] falls inside the enabled quiet window.
  ///
  /// Supports overnight windows (start > end), e.g. 22:00–07:00.
  bool isInQuietWindow(TimeOfDay now) {
    if (!quietHoursEnabled || !isValid) return false;
    final n = toMinutes(now)!;
    final s = toMinutes(quietStart)!;
    final e = toMinutes(quietEnd)!;
    if (s < e) {
      // Same-day window: [start, end).
      return n >= s && n < e;
    }
    // Overnight: [start, midnight) ∪ [midnight, end).
    return n >= s || n < e;
  }

  /// Seeds default times when enabling with unset range.
  NotificationPrefs seedOnEnable() {
    if (!quietHoursEnabled) return this;
    if (quietStart != null && quietEnd != null) return this;
    return copyWith(
      quietStart: quietStart ?? defaultQuietStart,
      quietEnd: quietEnd ?? defaultQuietEnd,
    );
  }

  NotificationPrefs copyWith({
    String? memberId,
    bool? quietHoursEnabled,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    bool? analysisNoticesEnabled,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return NotificationPrefs(
      memberId: memberId ?? this.memberId,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: clearStart ? null : (quietStart ?? this.quietStart),
      quietEnd: clearEnd ? null : (quietEnd ?? this.quietEnd),
      analysisNoticesEnabled:
          analysisNoticesEnabled ?? this.analysisNoticesEnabled,
    );
  }

  Map<String, Object?> toJson() => {
        'memberId': memberId,
        'quietHoursEnabled': quietHoursEnabled,
        'quietStartMinutes': toMinutes(quietStart),
        'quietEndMinutes': toMinutes(quietEnd),
        'analysisNoticesEnabled': analysisNoticesEnabled,
        // Honesty marker only — never a mute control.
        'sosReceiptAlwaysOn': sosReceiptAlwaysOn,
      };

  /// Parses prefs; rejects any attempt to set SOS-mute fields.
  factory NotificationPrefs.fromJson(Map<String, Object?> json) {
    for (final key in json.keys) {
      if (kForbiddenSosMuteKeys.contains(key)) {
        throw ForbiddenSosMuteFieldException(key);
      }
    }
    final sosEnabled = json['sos_enabled'];
    if (sosEnabled == false) {
      throw ForbiddenSosMuteFieldException('sos_enabled');
    }
    // Reject attempts to turn SOS receipt off via honesty key.
    if (json.containsKey('sosReceiptAlwaysOn') &&
        json['sosReceiptAlwaysOn'] == false) {
      throw ForbiddenSosMuteFieldException('sosReceiptAlwaysOn');
    }

    final memberId = json['memberId'] as String? ??
        json['member_id'] as String? ??
        'unknown';
    return NotificationPrefs(
      memberId: memberId,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ??
          json['quiet_hours_enabled'] as bool? ??
          false,
      quietStart: fromMinutes(
        json['quietStartMinutes'] as int? ??
            json['quiet_start_minutes'] as int?,
      ),
      quietEnd: fromMinutes(
        json['quietEndMinutes'] as int? ?? json['quiet_end_minutes'] as int?,
      ),
      analysisNoticesEnabled: json['analysisNoticesEnabled'] as bool? ??
          json['analysis_notices_enabled'] as bool? ??
          true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPrefs &&
          memberId == other.memberId &&
          quietHoursEnabled == other.quietHoursEnabled &&
          toMinutes(quietStart) == toMinutes(other.quietStart) &&
          toMinutes(quietEnd) == toMinutes(other.quietEnd) &&
          analysisNoticesEnabled == other.analysisNoticesEnabled;

  @override
  int get hashCode => Object.hash(
        memberId,
        quietHoursEnabled,
        toMinutes(quietStart),
        toMinutes(quietEnd),
        analysisNoticesEnabled,
      );
}
