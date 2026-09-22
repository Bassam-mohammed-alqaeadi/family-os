import '../domain/child_id.dart';
import '../domain/minutes.dart';
import '../domain/role.dart';
import 'policy_engine.dart';
import 'screen_time_policy.dart';
import 'screen_time_policy_repository.dart';

/// Wallet balance mutations — only via earn/deposit (Rule 5).
///
/// Father sets cap/overflow through [ScreenTimePolicyRepository.save];
/// UI must not write arbitrary balances.
///
/// SET-024 / Ruling B: deposits are **not** clamped against the daily cap.
/// [TimeEngine] denies use past the cap when `allowWalletOverflow` is false.
final class WalletLedger {
  WalletLedger(this._repository);

  final ScreenTimePolicyRepository _repository;

  /// Resolves father reward via [PolicyEngine] then deposits for child.
  ///
  /// Returns deposited amount ([Minutes.zero] when assignee earns nothing).
  Future<Minutes> earn({
    required ChildId childId,
    required String appId,
    required AppRole assignee,
    required Minutes fatherSetReward,
  }) async {
    final reward = PolicyEngine.rewardForAssignee(
      assignee: assignee,
      fatherSetReward: fatherSetReward,
    );
    if (reward == null || reward.isZero) {
      return Minutes.zero;
    }
    final deposited = PolicyEngine.depositOnApproval(reward: reward);
    await deposit(
      childId: childId,
      appId: appId,
      amount: deposited,
    );
    return deposited;
  }

  /// Adds [amount] to the app wallet (creates wallet if missing).
  ///
  /// Returns the new balance. Zero [amount] is a no-op.
  Future<Minutes> deposit({
    required ChildId childId,
    required String appId,
    required Minutes amount,
  }) async {
    if (amount.isZero) {
      final policy = await _repository.load(childId);
      return policy.walletFor(appId)?.earnedMinutes ?? Minutes.zero;
    }
    final policy = await _repository.load(childId);
    final existing = policy.walletFor(appId);
    final nextWallet = AppWallet(
      appId: appId,
      earnedMinutes: (existing?.earnedMinutes ?? Minutes.zero) + amount,
      countable: existing?.countable ?? true,
    );
    await _repository.save(childId, policy.upsertWallet(nextWallet));
    return nextWallet.earnedMinutes;
  }

  /// Current balance for [appId] (zero if missing).
  Future<Minutes> balance({
    required ChildId childId,
    required String appId,
  }) async {
    final policy = await _repository.load(childId);
    return policy.walletFor(appId)?.earnedMinutes ?? Minutes.zero;
  }
}
