import '../domain/minutes.dart';
import 'screen_time_policy.dart';
import 'screen_time_policy_repository.dart';
import 'time_engine.dart';

/// Builds [TimeContext] from stored policy + wallet for one app (SET-002).
///
/// Cap exhaustion uses [ScreenTimePolicy.usedMinutesToday] vs
/// [ScreenTimePolicy.dailyCapMinutes]. Non-countable education apps (S-1)
/// do not exhaust the daily entertainment cap.
abstract final class ScreenTimePolicyQuery {
  /// Merges [policy] wallet/cap flags into [base] for [appId].
  static TimeContext timeContextFromPolicy({
    required TimeContext base,
    required ScreenTimePolicy policy,
    required String appId,
  }) {
    final wallet = policy.walletFor(appId) ??
        AppWallet(appId: appId, earnedMinutes: Minutes.zero);
    final countable = wallet.countable;
    final dailyLimitExhausted =
        countable ? policy.isCapExhausted : false;

    return TimeContext(
      childId: base.childId,
      instantLock: base.instantLock,
      permanentlyBlocked: base.permanentlyBlocked,
      modeActive: base.modeActive,
      appAllowedInMode: base.appAllowedInMode,
      hasModeException: base.hasModeException,
      dailyLimitExhausted: dailyLimitExhausted,
      earnedBalance: wallet.earnedMinutes,
      dailyCapIncludesWallet: base.dailyCapIncludesWallet,
      allowWalletOverflow: policy.allowWalletOverflow,
    );
  }

  /// Convenience over a [ScreenTimePolicySnapshot].
  static TimeContext timeContextFromSnapshot({
    required TimeContext base,
    required ScreenTimePolicySnapshot snapshot,
    required String appId,
  }) =>
      timeContextFromPolicy(
        base: base,
        policy: snapshot.policy,
        appId: appId,
      );
}
