import 'package:flutter/foundation.dart';

import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';

/// App category buckets (prototype FAT-034 · S-SEC-009).
enum ChildAppCategory { games, social, edu, tools }

/// Allow / block / free / pending (S-SEC-008 · P-3 blocked stays blocked).
enum ChildAppStatus { allowed, free, blocked, pending }

/// One installed app on a child's device inventory (mock-first Rule 25).
@immutable
final class ChildAppEntry {
  const ChildAppEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.usedMins = 0,
    this.limitMins = 0,
    this.walletMins = 0,
    this.instantLocked = false,
    this.ageRating = '',
    this.unlimited = false,
  });

  final String id;
  final String name;
  final ChildAppCategory category;
  final ChildAppStatus status;
  final int usedMins;
  final int limitMins;
  final int walletMins;
  final bool instantLocked;
  final String ageRating;

  /// ST-OD-010: may bypass daily entertainment cap (games toggle) — not block.
  final bool unlimited;

  /// Remaining minutes under daily cap (allowed only).
  int get remainingMins {
    if (status != ChildAppStatus.allowed || limitMins <= 0) return 0;
    final left = limitMins - usedMins;
    return left < 0 ? 0 : left;
  }

  bool get isFreeOrEdu =>
      status == ChildAppStatus.free ||
      category == ChildAppCategory.edu ||
      EducationAppIds.isEducation(id);

  AppAccessRule toAccessRule() {
    return AppAccessRuleMapper.fromEntry(
      appId: id,
      blocked: status == ChildAppStatus.blocked,
      freeOrEdu: isFreeOrEdu,
      limitMinutes: limitMins > 0 ? limitMins : null,
      unlimited: unlimited,
    );
  }

  ChildAppEntry applyAccessRule(AppAccessRule rule) {
    var nextStatus = status;
    if (rule.blocked) {
      nextStatus = ChildAppStatus.blocked;
    } else if (!rule.countable && status != ChildAppStatus.pending) {
      nextStatus = ChildAppStatus.free;
    } else if (status == ChildAppStatus.blocked && !rule.blocked) {
      nextStatus = ChildAppStatus.allowed;
    }
    return copyWith(
      status: nextStatus,
      limitMins:
          rule.limitMinutes ??
          (nextStatus == ChildAppStatus.free ? -1 : limitMins),
      unlimited: rule.unlimited,
    );
  }

  ChildAppEntry copyWith({
    ChildAppStatus? status,
    int? usedMins,
    int? limitMins,
    int? walletMins,
    bool? instantLocked,
    bool? unlimited,
  }) {
    return ChildAppEntry(
      id: id,
      name: name,
      category: category,
      status: status ?? this.status,
      usedMins: usedMins ?? this.usedMins,
      limitMins: limitMins ?? this.limitMins,
      walletMins: walletMins ?? this.walletMins,
      instantLocked: instantLocked ?? this.instantLocked,
      ageRating: ageRating,
      unlimited: unlimited ?? this.unlimited,
    );
  }
}
