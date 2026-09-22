/// Notification urgency tiers (SET-010 / P-4).
///
/// SOS uses [critical] — quiet hours never mute this tier.
enum NotificationTier {
  /// Digest / soft alerts — quiet hours may suppress.
  nonCritical,

  /// SOS and other critical alerts — always pierce quiet hours.
  critical,
}
