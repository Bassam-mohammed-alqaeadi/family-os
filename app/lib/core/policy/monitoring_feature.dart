/// Lean monitoring feature set for SCR-FAT-067 / SET-016.
enum MonitoringFeature {
  webFilter,
  appLimits,
  notificationListen,
  locationAlways,
}

extension MonitoringFeatureX on MonitoringFeature {
  String get storageKey => name;
}
