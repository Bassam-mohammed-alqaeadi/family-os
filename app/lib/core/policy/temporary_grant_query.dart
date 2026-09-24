import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/minutes.dart';
import 'screen_time_policy.dart';
import 'time_request.dart';

/// Active Temporary Grant remaining for a child (G-A / ST-OD-004).
///
/// Does **not** touch WalletLedger. Hard schedules/modes/locks still deny
/// via TimeEngine — grants only extend countable remaining under P4.
abstract final class TemporaryGrantQuery {
  /// Sum of active (non-expired, non-exhausted) grant remaining.
  static Minutes activeRemaining({
    required ChildId childId,
    required List<TimeGrant> grants,
    DateTime? now,
  }) {
    final clock = (now ?? DateTime.now()).toUtc();
    var total = 0;
    for (final g in grants) {
      if (g.childId != childId) continue;
      if (!g.isActiveAt(clock)) continue;
      total += g.activeRemaining;
    }
    return Minutes(total);
  }

  /// End-of-day in local clock (Stage-1 stand-in for family TZ — ST-OD-008).
  static DateTime endOfLocalDay(DateTime now) {
    final local = now.toLocal();
    final eod = DateTime(local.year, local.month, local.day, 23, 59, 59);
    return eod.toUtc();
  }

  /// ST-OD-007: min(12 hours from [createdAt], local end-of-day).
  static DateTime requestOrGrantExpiresAt(DateTime createdAt) {
    final created = createdAt.toUtc();
    final twelve = created.add(const Duration(hours: 12));
    final eod = endOfLocalDay(created);
    return twelve.isBefore(eod) ? twelve : eod;
  }

  /// Marks expired grants; returns updated list (caller persists).
  static List<TimeGrant> sweepExpired(
    List<TimeGrant> grants, {
    DateTime? now,
  }) {
    final clock = (now ?? DateTime.now()).toUtc();
    return [
      for (final g in grants)
        if (g.status == TimeGrantStatus.active &&
            !clock.isBefore(g.expiresAt.toUtc()))
          g.copyWith(status: TimeGrantStatus.expired, remainingMinutes: 0)
        else
          g,
    ];
  }
}

/// Three independently visible Screen Time budgets (ST-ADD-004).
@immutable
final class ScreenTimeRemaining {
  const ScreenTimeRemaining({
    required this.dailyRemaining,
    required this.temporaryGrantRemaining,
    required this.earnedWalletTotal,
  });

  /// max(0, dailyCap − used).
  final Minutes dailyRemaining;

  /// Σ active Temporary Grant remaining (G-A).
  final Minutes temporaryGrantRemaining;

  /// Sum of per-app earned wallets (display); not free wallet.
  final Minutes earnedWalletTotal;

  /// Effective entertainment remaining for warning/expiry UX
  /// (daily + grant). Wallet open-past-cap is a separate TimeEngine path.
  Minutes get effectiveEntertainmentRemaining =>
      dailyRemaining + temporaryGrantRemaining;

  bool get isWarning =>
      !effectiveEntertainmentRemaining.isZero &&
      effectiveEntertainmentRemaining.inMinutes <= 5;

  bool get isExpired => effectiveEntertainmentRemaining.isZero;

  static ScreenTimeRemaining fromPolicy({
    required ScreenTimePolicy policy,
    required Minutes grantRemaining,
  }) {
    final daily = policy.dailyCapMinutes - policy.usedMinutesToday;
    var walletSum = Minutes.zero;
    for (final w in policy.wallets) {
      walletSum = walletSum + w.earnedMinutes;
    }
    return ScreenTimeRemaining(
      dailyRemaining: Minutes(daily < 0 ? 0 : daily),
      temporaryGrantRemaining: grantRemaining,
      earnedWalletTotal: walletSum,
    );
  }
}
