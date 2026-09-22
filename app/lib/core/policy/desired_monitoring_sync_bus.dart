import 'package:flutter/foundation.dart';

import 'desired_monitoring_prefs.dart';
import 'platform_id.dart';

/// Same-session father→child sync for platform monitoring (UI-018 / P12 / P-7).
///
/// Father [publish] on FAT-067/068 save → child transparency rebuilds to
/// **effective** levels (min(desired, capability)), never raw desired.
final class DesiredMonitoringSyncBus extends ChangeNotifier {
  DesiredMonitoringSyncBus();

  final Map<String, DesiredMonitoringPrefs> _byChild = {};
  final Map<String, PlatformId> _platformByChild = {};
  final Map<String, bool> _offlineByChild = {};

  DesiredMonitoringPrefs? prefsOf(String childId) => _byChild[childId];

  PlatformId platformOf(String childId) =>
      _platformByChild[childId] ?? PlatformId.android;

  /// Last-known offline honesty flag (UI-018 offline = last capability).
  bool offlineOf(String childId) => _offlineByChild[childId] ?? false;

  /// Seed without counting as a father save.
  void hydrate(
    DesiredMonitoringPrefs prefs, {
    PlatformId? platform,
    bool offline = false,
  }) {
    _byChild[prefs.childId] = prefs;
    if (platform != null) {
      _platformByChild[prefs.childId] = platform;
    }
    _offlineByChild[prefs.childId] = offline;
  }

  /// Father save / capability refresh → notify child mirror same session.
  void publish(
    DesiredMonitoringPrefs prefs, {
    PlatformId? platform,
    bool offline = false,
  }) {
    _byChild[prefs.childId] = prefs;
    if (platform != null) {
      _platformByChild[prefs.childId] = platform;
    }
    _offlineByChild[prefs.childId] = offline;
    notifyListeners();
  }
}

/// Stage-1 shared bus (survives within process).
final DesiredMonitoringSyncBus stage1DesiredMonitoringSyncBus =
    DesiredMonitoringSyncBus();
