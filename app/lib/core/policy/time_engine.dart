import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import '../domain/minutes.dart';

/// Outcome of [TimeEngine.resolve] (Register §2 priority ladder).
enum AppAccess {
  /// App may open under current policy.
  allowed,

  /// Father's instant lock (top of ladder).
  deniedLock,

  /// Permanent block — balance never opens (Ruling A).
  deniedBlocked,

  /// Active mode forbids the app and no father exception.
  deniedMode,

  /// Daily cap exhausted and wallet cannot overflow (Ruling B).
  deniedCap,

  /// Cap path requires earned balance but wallet is empty.
  deniedNoBalance,
}

/// Immutable query inputs for [TimeEngine] (flags resolved for one child×app).
@immutable
final class TimeContext {
  const TimeContext({
    required this.childId,
    this.instantLock = false,
    this.permanentlyBlocked = false,
    this.modeActive = false,
    this.appAllowedInMode = true,
    this.hasModeException = false,
    this.dailyLimitExhausted = false,
    this.earnedBalance = Minutes.zero,
    this.dailyCapIncludesWallet = true,
    this.allowWalletOverflow = false,
  });

  final ChildId childId;

  /// Father's instant lock — short-circuits everything.
  final bool instantLock;

  /// Permanent block list — never opened by balance (Ruling A).
  final bool permanentlyBlocked;

  /// A smart mode is currently active for this child.
  final bool modeActive;

  /// App is on the mode's allowed list.
  final bool appAllowedInMode;

  /// Explicit father exception (child × app × mode) — Ruling A.
  final bool hasModeException;

  /// Daily countable limit for this app is exhausted.
  final bool dailyLimitExhausted;

  /// Child's earned wallet balance for this app (S-2).
  final Minutes earnedBalance;

  /// Wallet counts inside the daily cap (Ruling B default: true).
  final bool dailyCapIncludesWallet;

  /// Father switch: allow exceeding cap with earned balance (default: false).
  final bool allowWalletOverflow;
}

/// Alias for availability queries (same shape as [TimeContext]).
typedef AppAvailabilityQuery = TimeContext;

/// Setting resolution order: per-child > shared > default (Ruling D).
abstract final class SettingSpecificity {
  /// Returns the most specific non-null value.
  static T resolve<T>({T? perChild, T? shared, required T defaultValue}) {
    if (perChild != null) {
      return perChild;
    }
    if (shared != null) {
      return shared;
    }
    return defaultValue;
  }
}

/// Time availability engine — Register §2 ladder (literal order).
///
/// instantLock → permanentBlock → activeMode (+ exceptions) →
/// dailyLimit → earnedBalance.
abstract final class TimeEngine {
  /// Full resolve with denial reason.
  static AppAccess resolve(TimeContext ctx) {
    // 1. Instant lock above everything.
    if (ctx.instantLock) {
      return AppAccess.deniedLock;
    }

    // 2. Permanent block — NEVER opens via balance (Ruling A).
    if (ctx.permanentlyBlocked) {
      return AppAccess.deniedBlocked;
    }

    // 3. Active mode — allowed list, or explicit exception.
    if (ctx.modeActive) {
      final permittedByMode = ctx.appAllowedInMode || ctx.hasModeException;
      if (!permittedByMode) {
        return AppAccess.deniedMode;
      }
      // Exception / allowed still governed by remaining time below.
    }

    // 4–5. Daily limit, then earned balance (Rulings A/B).
    if (!ctx.dailyLimitExhausted) {
      return AppAccess.allowed;
    }

    // Cap exhausted: balance opens only what exhausted its daily limit,
    // and only when overflow policy allows (or wallet is outside the cap).
    final walletMayOpen = _walletMayOpenPastCap(ctx);
    if (!walletMayOpen) {
      return AppAccess.deniedCap;
    }
    if (ctx.earnedBalance.isZero) {
      return AppAccess.deniedNoBalance;
    }
    return AppAccess.allowed;
  }

  /// Convenience: true iff [resolve] is [AppAccess.allowed].
  static bool canUse(TimeContext ctx) => resolve(ctx) == AppAccess.allowed;

  /// Ruling B / SET-024: default wallet is inside the cap; overflow is opt-in.
  ///
  /// When overflow is off and the wallet counts inside the cap, access is
  /// [AppAccess.deniedCap] — deposits are not clamped; use past the cap is.
  static bool _walletMayOpenPastCap(TimeContext ctx) {
    if (ctx.allowWalletOverflow) {
      return true;
    }
    // When wallet is NOT included in the cap, earned balance can open
    // past the countable daily limit without the overflow switch.
    if (!ctx.dailyCapIncludesWallet) {
      return true;
    }
    return false;
  }
}
