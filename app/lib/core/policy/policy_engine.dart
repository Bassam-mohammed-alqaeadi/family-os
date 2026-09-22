import '../domain/minutes.dart';
import '../domain/role.dart';

/// Pure economy policy for Register §1 (E-1…E-5).
///
/// Only currency is [Minutes] — no points/XP. Callers must supply
/// [fatherSetReward] (E-2); this engine never invents defaults.
abstract final class PolicyEngine {
  /// Resolves reward minutes for an assignee (E-4).
  ///
  /// - [AppRole.child] → returns [fatherSetReward] unchanged.
  /// - [AppRole.mother] → `null` (help-request path; no minutes).
  /// - [AppRole.father] → `null` (father is not an earning assignee).
  ///
  /// Returns `null` when no wallet deposit should occur.
  static Minutes? rewardForAssignee({
    required AppRole assignee,
    required Minutes fatherSetReward,
  }) {
    if (assignee == AppRole.child) {
      return fatherSetReward;
    }
    return null;
  }

  /// Instant deposit amount on father approval (E-5).
  ///
  /// Equals [reward] exactly — no delay factor, no points conversion.
  static Minutes depositOnApproval({required Minutes reward}) => reward;
}
