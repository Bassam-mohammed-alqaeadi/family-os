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

/// Per-member notification preferences (SET-010 / SET-011 · SCR-FAT-058).
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
    this.childRequestsEnabled = true,
    this.summaryDigestEnabled = true,
    this.eveningDigestEnabled = true,
    this.eveningDigestTime,
  });

  /// Defaults: quiet hours off; important/reassurance on; SOS always on.
  factory NotificationPrefs.defaults({required String memberId}) =>
      NotificationPrefs(
        memberId: memberId,
        eveningDigestTime: defaultEveningDigest,
      );

  final String memberId;
  final bool quietHoursEnabled;
  final TimeOfDay? quietStart;
  final TimeOfDay? quietEnd;

  /// Important lane — Advisor / analysis notices (non-critical). Default on.
  final bool analysisNoticesEnabled;

  /// Important lane — child time/app/friend requests. Default on.
  final bool childRequestsEnabled;

  /// Reassurance lane — one summary instead of repeated soft alerts.
  final bool summaryDigestEnabled;

  /// Reassurance lane — evening digest preference (local schedule later).
  final bool eveningDigestEnabled;

  /// Preferred evening digest clock (default 20:30).
  final TimeOfDay? eveningDigestTime;

  /// Doc 20 / SET-011 / SET-021 — SOS receipt is ungradeable for guardians.
  static const bool sosReceiptAlwaysOn = true;

  static const Set<String> guardianMemberIds = {'father', 'mother', 'guardian'};

  static bool isGuardianMemberId(String memberId) =>
      guardianMemberIds.contains(memberId);

  static const TimeOfDay defaultQuietStart = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay defaultQuietEnd = TimeOfDay(hour: 7, minute: 0);
  static const TimeOfDay defaultEveningDigest = TimeOfDay(hour: 20, minute: 30);

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

  static bool quietHoursAppliesTo(NotificationTier tier) =>
      tier == NotificationTier.nonCritical;

  static Iterable<NotificationTier> filterableTiers() =>
      NotificationTier.values.where(quietHoursAppliesTo);

  static int? toMinutes(TimeOfDay? tod) => ScheduleWindow.toMinutes(tod);

  static TimeOfDay? fromMinutes(int? minutes) =>
      ScheduleWindow.fromMinutes(minutes);

  bool get isValid {
    if (!quietHoursEnabled) return true;
    final s = toMinutes(quietStart);
    final e = toMinutes(quietEnd);
    if (s == null || e == null) return false;
    return s != e;
  }

  bool isInQuietWindow(TimeOfDay now) {
    if (!quietHoursEnabled || !isValid) return false;
    final n = toMinutes(now)!;
    final s = toMinutes(quietStart)!;
    final e = toMinutes(quietEnd)!;
    if (s < e) {
      return n >= s && n < e;
    }
    return n >= s || n < e;
  }

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
    bool? childRequestsEnabled,
    bool? summaryDigestEnabled,
    bool? eveningDigestEnabled,
    TimeOfDay? eveningDigestTime,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearEvening = false,
  }) {
    return NotificationPrefs(
      memberId: memberId ?? this.memberId,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: clearStart ? null : (quietStart ?? this.quietStart),
      quietEnd: clearEnd ? null : (quietEnd ?? this.quietEnd),
      analysisNoticesEnabled:
          analysisNoticesEnabled ?? this.analysisNoticesEnabled,
      childRequestsEnabled: childRequestsEnabled ?? this.childRequestsEnabled,
      summaryDigestEnabled: summaryDigestEnabled ?? this.summaryDigestEnabled,
      eveningDigestEnabled: eveningDigestEnabled ?? this.eveningDigestEnabled,
      eveningDigestTime: clearEvening
          ? null
          : (eveningDigestTime ?? this.eveningDigestTime),
    );
  }

  Map<String, Object?> toJson() => {
    'memberId': memberId,
    'quietHoursEnabled': quietHoursEnabled,
    'quietStartMinutes': toMinutes(quietStart),
    'quietEndMinutes': toMinutes(quietEnd),
    'analysisNoticesEnabled': analysisNoticesEnabled,
    'childRequestsEnabled': childRequestsEnabled,
    'summaryDigestEnabled': summaryDigestEnabled,
    'eveningDigestEnabled': eveningDigestEnabled,
    'eveningDigestMinutes': toMinutes(eveningDigestTime),
    'sosReceiptAlwaysOn': sosReceiptAlwaysOn,
  };

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
    if (json.containsKey('sosReceiptAlwaysOn') &&
        json['sosReceiptAlwaysOn'] == false) {
      throw ForbiddenSosMuteFieldException('sosReceiptAlwaysOn');
    }

    final memberId =
        json['memberId'] as String? ??
        json['member_id'] as String? ??
        'unknown';
    return NotificationPrefs(
      memberId: memberId,
      quietHoursEnabled:
          json['quietHoursEnabled'] as bool? ??
          json['quiet_hours_enabled'] as bool? ??
          false,
      quietStart: fromMinutes(
        json['quietStartMinutes'] as int? ??
            json['quiet_start_minutes'] as int?,
      ),
      quietEnd: fromMinutes(
        json['quietEndMinutes'] as int? ?? json['quiet_end_minutes'] as int?,
      ),
      analysisNoticesEnabled:
          json['analysisNoticesEnabled'] as bool? ??
          json['analysis_notices_enabled'] as bool? ??
          true,
      childRequestsEnabled:
          json['childRequestsEnabled'] as bool? ??
          json['child_requests_enabled'] as bool? ??
          true,
      summaryDigestEnabled:
          json['summaryDigestEnabled'] as bool? ??
          json['summary_digest_enabled'] as bool? ??
          true,
      eveningDigestEnabled:
          json['eveningDigestEnabled'] as bool? ??
          json['evening_digest_enabled'] as bool? ??
          true,
      // Preserve null through round-trip; [defaults] seeds evening digest time.
      eveningDigestTime: fromMinutes(
        json['eveningDigestMinutes'] as int? ??
            json['evening_digest_minutes'] as int?,
      ),
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
          analysisNoticesEnabled == other.analysisNoticesEnabled &&
          childRequestsEnabled == other.childRequestsEnabled &&
          summaryDigestEnabled == other.summaryDigestEnabled &&
          eveningDigestEnabled == other.eveningDigestEnabled &&
          toMinutes(eveningDigestTime) == toMinutes(other.eveningDigestTime);

  @override
  int get hashCode => Object.hash(
    memberId,
    quietHoursEnabled,
    toMinutes(quietStart),
    toMinutes(quietEnd),
    analysisNoticesEnabled,
    childRequestsEnabled,
    summaryDigestEnabled,
    eveningDigestEnabled,
    toMinutes(eveningDigestTime),
  );
}
