import 'monitoring_feature.dart';

/// User-desired monitoring toggles (independent of platform capability).
///
/// Effective state = min(desired, capability) via [effectiveMonitoring].
final class DesiredMonitoringPrefs {
  const DesiredMonitoringPrefs({
    this.childId = defaultChildId,
    this.webFilter = false,
    this.appLimits = false,
    this.notificationListen = false,
    this.locationAlways = false,
  });

  static const defaultChildId = 'child_1';

  final String childId;
  final bool webFilter;
  final bool appLimits;
  final bool notificationListen;
  final bool locationAlways;

  factory DesiredMonitoringPrefs.defaults({String childId = defaultChildId}) =>
      DesiredMonitoringPrefs(childId: childId);

  bool desiredFor(MonitoringFeature feature) => switch (feature) {
        MonitoringFeature.webFilter => webFilter,
        MonitoringFeature.appLimits => appLimits,
        MonitoringFeature.notificationListen => notificationListen,
        MonitoringFeature.locationAlways => locationAlways,
      };

  DesiredMonitoringPrefs copyWith({
    String? childId,
    bool? webFilter,
    bool? appLimits,
    bool? notificationListen,
    bool? locationAlways,
  }) {
    return DesiredMonitoringPrefs(
      childId: childId ?? this.childId,
      webFilter: webFilter ?? this.webFilter,
      appLimits: appLimits ?? this.appLimits,
      notificationListen: notificationListen ?? this.notificationListen,
      locationAlways: locationAlways ?? this.locationAlways,
    );
  }

  DesiredMonitoringPrefs withFeature(MonitoringFeature feature, bool value) {
    return switch (feature) {
      MonitoringFeature.webFilter => copyWith(webFilter: value),
      MonitoringFeature.appLimits => copyWith(appLimits: value),
      MonitoringFeature.notificationListen =>
        copyWith(notificationListen: value),
      MonitoringFeature.locationAlways => copyWith(locationAlways: value),
    };
  }

  Map<String, Object> toJson() => {
        'childId': childId,
        'webFilter': webFilter,
        'appLimits': appLimits,
        'notificationListen': notificationListen,
        'locationAlways': locationAlways,
      };

  factory DesiredMonitoringPrefs.fromJson(Map<String, Object?> json) {
    return DesiredMonitoringPrefs(
      childId: (json['childId'] as String?) ?? defaultChildId,
      webFilter: json['webFilter'] == true,
      appLimits: json['appLimits'] == true,
      notificationListen: json['notificationListen'] == true,
      locationAlways: json['locationAlways'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesiredMonitoringPrefs &&
          childId == other.childId &&
          webFilter == other.webFilter &&
          appLimits == other.appLimits &&
          notificationListen == other.notificationListen &&
          locationAlways == other.locationAlways;

  @override
  int get hashCode => Object.hash(
        childId,
        webFilter,
        appLimits,
        notificationListen,
        locationAlways,
      );
}
