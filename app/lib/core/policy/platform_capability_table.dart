import 'capability_level.dart';
import 'monitoring_feature.dart';
import 'platform_id.dart';

/// Fixture capability matrix (platform × feature → level).
///
/// System truth for G1 platform honesty — UI must not claim more than this.
/// Examples: iOS [MonitoringFeature.notificationListen] → unavailable;
/// Android [MonitoringFeature.webFilter] → full.
abstract final class PlatformCapabilityTable {
  static const Map<PlatformId, Map<MonitoringFeature, CapabilityLevel>>
      fixture = {
    PlatformId.android: {
      MonitoringFeature.webFilter: CapabilityLevel.full,
      MonitoringFeature.appLimits: CapabilityLevel.full,
      MonitoringFeature.notificationListen: CapabilityLevel.full,
      MonitoringFeature.locationAlways: CapabilityLevel.full,
    },
    PlatformId.ios: {
      MonitoringFeature.webFilter: CapabilityLevel.reportsOnly,
      MonitoringFeature.appLimits: CapabilityLevel.full,
      MonitoringFeature.notificationListen: CapabilityLevel.unavailable,
      MonitoringFeature.locationAlways: CapabilityLevel.reportsOnly,
    },
  };

  static CapabilityLevel level(
    PlatformId platform,
    MonitoringFeature feature,
  ) {
    return fixture[platform]?[feature] ?? CapabilityLevel.unavailable;
  }
}

/// Desired bool as a level: true → full intent, false → off (unavailable rank).
CapabilityLevel desiredAsLevel(bool desired) =>
    desired ? CapabilityLevel.full : CapabilityLevel.unavailable;

/// effective = min(desired, capability) — never claims more than platform allows.
CapabilityLevel effectiveMonitoring({
  required bool desired,
  required CapabilityLevel capability,
}) {
  final want = desiredAsLevel(desired);
  return want.rank <= capability.rank ? want : capability;
}

/// Switch may look ON only when effective is full (Screen Time honesty).
bool switchLooksOn({
  required bool desired,
  required CapabilityLevel capability,
}) =>
    effectiveMonitoring(desired: desired, capability: capability) ==
    CapabilityLevel.full;

/// Interactive toggle only when platform can fully enforce.
bool switchInteractive(CapabilityLevel capability) =>
    capability == CapabilityLevel.full;
