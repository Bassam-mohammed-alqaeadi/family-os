import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'screen_time_policy.dart';
import 'time_engine.dart';

/// Per-app access axes for FAT-034 → TimeEngine (ST-OD-010).
///
/// Axes stay separate: allow/block · limit · countable · unlimited.
@immutable
final class AppAccessRule {
  const AppAccessRule({
    required this.appId,
    this.blocked = false,
    this.limitMinutes,
    this.countable = true,
    this.unlimited = false,
  });

  final String appId;

  /// Permanent block (P2) — wallet/grant never open.
  final bool blocked;

  /// Optional per-app daily limit (P5); null = no per-app limit.
  final int? limitMinutes;

  /// S-1 countable toward child daily entertainment cap.
  final bool countable;

  /// ST-OD-010: may bypass daily cap only — not block/lock/mode.
  final bool unlimited;

  AppAccessRule copyWith({
    bool? blocked,
    int? limitMinutes,
    bool? countable,
    bool? unlimited,
    bool clearLimit = false,
  }) {
    return AppAccessRule(
      appId: appId,
      blocked: blocked ?? this.blocked,
      limitMinutes: clearLimit ? null : (limitMinutes ?? this.limitMinutes),
      countable: countable ?? this.countable,
      unlimited: unlimited ?? this.unlimited,
    );
  }

  Map<String, Object?> toJson() => {
        'appId': appId,
        'blocked': blocked,
        'limitMinutes': limitMinutes,
        'countable': countable,
        'unlimited': unlimited,
      };

  factory AppAccessRule.fromJson(Map<String, Object?> json) {
    return AppAccessRule(
      appId: json['appId'] as String? ?? 'unknown',
      blocked: json['blocked'] as bool? ?? false,
      limitMinutes: (json['limitMinutes'] as num?)?.toInt(),
      countable: json['countable'] as bool? ?? true,
      unlimited: json['unlimited'] as bool? ?? false,
    );
  }
}

/// Child-scoped app rule set (Stage-1 in-memory / prefs).
@immutable
final class AppAccessRuleSet {
  const AppAccessRuleSet({required this.childId, this.rules = const []});

  final ChildId childId;
  final List<AppAccessRule> rules;

  AppAccessRule? ruleFor(String appId) {
    final id = appId.trim();
    for (final r in rules) {
      if (r.appId == id) return r;
    }
    return null;
  }

  AppAccessRuleSet upsert(AppAccessRule rule) {
    final next = <AppAccessRule>[];
    var found = false;
    for (final r in rules) {
      if (r.appId == rule.appId) {
        next.add(rule);
        found = true;
      } else {
        next.add(r);
      }
    }
    if (!found) next.add(rule);
    return AppAccessRuleSet(childId: childId, rules: next);
  }
}

/// Applies [AppAccessRule] into [TimeContext] without rewriting TimeEngine.
abstract final class AppAccessRuleQuery {
  static TimeContext applyRule({
    required TimeContext base,
    required AppAccessRule? rule,
    required ScreenTimePolicy policy,
    required int temporaryGrantRemaining,
    int appUsedMinutes = 0,
  }) {
    if (rule == null) return base;

    final permanentlyBlocked = base.permanentlyBlocked || rule.blocked;

    // Education apps stay non-countable (S-1).
    final effectiveCountable =
        EducationAppIds.isEducation(rule.appId) ? false : rule.countable;

    var dailyExhausted = base.dailyLimitExhausted;
    if (effectiveCountable && !rule.unlimited) {
      final capExhausted = policy.isCapExhausted && temporaryGrantRemaining <= 0;
      final perAppExhausted = rule.limitMinutes != null &&
          appUsedMinutes >= rule.limitMinutes!;
      dailyExhausted = capExhausted || perAppExhausted;
    } else if (rule.unlimited) {
      // Unlimited bypasses daily cap (P4) only — still subject to P0–P3.
      dailyExhausted = false;
    } else if (!effectiveCountable) {
      dailyExhausted = false;
    }

    return TimeContext(
      childId: base.childId,
      instantLock: base.instantLock,
      permanentlyBlocked: permanentlyBlocked,
      modeActive: base.modeActive,
      appAllowedInMode: base.appAllowedInMode,
      hasModeException: base.hasModeException,
      dailyLimitExhausted: dailyExhausted,
      earnedBalance: base.earnedBalance,
      dailyCapIncludesWallet: base.dailyCapIncludesWallet,
      allowWalletOverflow: base.allowWalletOverflow,
    );
  }
}
