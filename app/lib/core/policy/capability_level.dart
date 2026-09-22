/// Platform × feature monitoring strength (SET-016).
///
/// Ordered weak → strong so [effectiveMonitoring] can take min(desired, capability).
enum CapabilityLevel {
  /// Feature cannot run on this platform — must not look ON.
  unavailable,

  /// Partial / reports-only — limited honesty badge, not full control.
  reportsOnly,

  /// Full enforce + report.
  full,
}

extension CapabilityLevelX on CapabilityLevel {
  String get storageKey => switch (this) {
        CapabilityLevel.unavailable => 'unavailable',
        CapabilityLevel.reportsOnly => 'reports_only',
        CapabilityLevel.full => 'full',
      };

  /// Rank for min() — higher = stronger.
  int get rank => index;
}
