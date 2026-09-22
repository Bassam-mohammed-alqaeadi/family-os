import 'package:flutter/foundation.dart';

import 'smart_mode_activation.dart';

/// Same-session father→child smart-mode activation stream (SET-019 / P12).
///
/// Mirrors [PolicySyncBus] / [PrivacyCollectionSyncBus] spirit: parent
/// [publish] → child [watch]/[activationOf] update in-process (no cold restart).
///
/// Offline (lean): last published activation is retained locally until reconnect;
/// reconnect does not wipe the last known value.
final class SmartModeActivationBus extends ChangeNotifier {
  SmartModeActivationBus();

  final Map<String, SmartModeActivation> _byChild = {};
  final Set<String> _offline = {};
  final Map<String, SmartModeActivation> _queued = {};

  /// Last published / hydrated activation for [childId], or idle seed.
  SmartModeActivation activationOf(String childId) =>
      _byChild[childId] ?? SmartModeActivation.idle(childId: childId);

  /// Seed without counting as a father toggle (hydrate from prefs / offline cache).
  void hydrate(SmartModeActivation activation) {
    _byChild[activation.childId] = activation;
  }

  bool isChildOnline(String childId) => !_offline.contains(childId);

  void markChildOffline(String childId) {
    _offline.add(childId);
  }

  /// Reconnect: deliver any queued publish; keep last local value if none queued.
  void markChildOnline(String childId) {
    _offline.remove(childId);
    final queued = _queued.remove(childId);
    if (queued != null) {
      _byChild[childId] = queued;
      notifyListeners();
    }
  }

  /// Father activate/deactivate after prefs save.
  ///
  /// When child is offline, stores as last-queued (lean) without notifying until
  /// [markChildOnline] — child UI keeps previous local value.
  void publish(SmartModeActivation activation) {
    final id = activation.childId;
    if (_offline.contains(id)) {
      _queued[id] = activation;
      // Still remember as "last known on parent side"; child keeps prior local.
      return;
    }
    _byChild[id] = activation;
    notifyListeners();
  }
}

/// Stage-1 shared bus (survives within process).
final SmartModeActivationBus stage1SmartModeActivationBus =
    SmartModeActivationBus();
