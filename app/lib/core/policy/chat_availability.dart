/// Family chat reachability — billing-free (UI-007 / P-4 / Rule 9).
///
/// This library must never import billing entitlement modules.
/// Expired / cancelled plans must leave chat usable.
abstract class ChatAvailability {
  /// Whether family chat may be opened / messaged.
  bool get isUsable;

  /// Whether a new message may be sent (same as [isUsable] in Stage-1).
  bool get canSend;
}

/// Always-on chat — plan state is intentionally out of scope.
final class AlwaysOnChatAvailability implements ChatAvailability {
  const AlwaysOnChatAvailability();

  @override
  bool get isUsable => true;

  @override
  bool get canSend => true;
}

/// Stage-1 shared chat availability (ignores billing forever).
const AlwaysOnChatAvailability stage1ChatAvailability =
    AlwaysOnChatAvailability();
