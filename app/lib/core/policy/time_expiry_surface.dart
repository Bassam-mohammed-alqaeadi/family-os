import '../domain/child_id.dart';
import '../domain/minutes.dart';
import 'chat_availability.dart';
import 'screen_time_policy.dart';
import 'screen_time_policy_query.dart';
import 'time_engine.dart';

/// Surfaces that stay reachable when entertainment time expires
/// (Rules 9/11 · C-1 · UI-011 / S4).
const List<String> kTimeExpiryExemptSurfaces = ['chat', 'quran', 'sos'];

/// Time-expiry lock helpers — entertainment uses [TimeEngine]; chat/Quran/SOS
/// never consult the countable ladder.
abstract final class TimeExpirySurface {
  /// True when [surface] is chat / quran / sos (always open at expiry).
  static bool isExempt(String surface) {
    final normalized = surface.trim().toLowerCase();
    return kTimeExpiryExemptSurfaces.contains(normalized);
  }

  /// Reachable when entertainment is not expired, or when [surface] is exempt.
  static bool isReachable(String surface, {required bool entertainmentExpired}) {
    if (!entertainmentExpired) return true;
    return isExempt(surface);
  }

  /// Entertainment app access under an exhausted daily cap (SET-002 TimeEngine).
  ///
  /// Defaults: no overflow, empty wallet → [AppAccess.deniedCap].
  static AppAccess entertainmentAccess({
    required ChildId childId,
    required ScreenTimePolicy policy,
    String appId = 'games',
    TimeContext? base,
  }) {
    final ctx = ScreenTimePolicyQuery.timeContextFromPolicy(
      base: base ??
          TimeContext(
            childId: childId,
            dailyCapIncludesWallet: true,
          ),
      policy: policy,
      appId: appId,
    );
    return TimeEngine.resolve(ctx);
  }

  /// Chat stays usable at expiry (C-1) — never reads TimeEngine.
  static bool chatUsable({ChatAvailability? availability}) {
    return (availability ?? stage1ChatAvailability).isUsable;
  }

  /// Quran is non-countable (S-1) — TimeEngine does not deny education ids
  /// via the daily entertainment cap when wallet.countable is false.
  static AppAccess quranAccess({
    required ChildId childId,
    required ScreenTimePolicy policy,
  }) {
    return entertainmentAccess(
      childId: childId,
      policy: policy,
      appId: 'quran',
      base: TimeContext(childId: childId),
    );
  }

  /// Stage-1 exhausted entertainment policy snapshot for CHD-021 demos/tests.
  static ScreenTimePolicy exhaustedPolicy({
    int dailyCapMinutes = 60,
    bool allowWalletOverflow = false,
  }) {
    return ScreenTimePolicy(
      dailyCapMinutes: dailyCapMinutes,
      usedMinutesToday: dailyCapMinutes,
      allowWalletOverflow: allowWalletOverflow,
      wallets: [
        AppWallet(
          appId: 'game',
          earnedMinutes: Minutes.zero,
        ),
        AppWallet(
          appId: 'quran',
          earnedMinutes: Minutes.zero,
          countable: false,
        ),
      ],
    );
  }
}
