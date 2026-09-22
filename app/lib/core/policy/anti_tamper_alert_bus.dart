import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'anti_tamper_policy.dart';

/// Father-facing anti-tamper alert kind (SET-008 / P-6).
enum AntiTamperAlertKind { bypassAttempt, simChange }

/// Notification event delivered to the father channel (mock Stage-1).
@immutable
final class AntiTamperFatherAlert {
  const AntiTamperFatherAlert({
    required this.childId,
    required this.kind,
    required this.at,
  });

  final ChildId childId;
  final AntiTamperAlertKind kind;
  final DateTime at;
}

/// Stage-1 in-process alert bus — simulates father notifications without FCM.
///
/// Emits only when the matching policy flag is ON (`bypassAlert` / `simAlert`).
final class AntiTamperAlertBus {
  AntiTamperAlertBus();

  final List<AntiTamperFatherAlert> delivered = [];
  final _controller = StreamController<AntiTamperFatherAlert>.broadcast();

  Stream<AntiTamperFatherAlert> get fatherAlerts => _controller.stream;

  /// Simulated bypass/tamper attempt on the child device.
  ///
  /// Returns `true` when a father alert was emitted (`bypassAlert` enabled).
  bool simulateBypassAttempt(
    ChildId childId,
    AntiTamperPolicy policy, {
    DateTime? at,
  }) {
    if (!policy.bypassAlert) return false;
    return _emit(
      AntiTamperFatherAlert(
        childId: childId,
        kind: AntiTamperAlertKind.bypassAttempt,
        at: at ?? DateTime.now().toUtc(),
      ),
    );
  }

  /// Simulated SIM remove/swap on the child device (lean optional path).
  ///
  /// Returns `true` when a father alert was emitted (`simAlert` enabled).
  bool simulateSimChange(
    ChildId childId,
    AntiTamperPolicy policy, {
    DateTime? at,
  }) {
    if (!policy.simAlert) return false;
    return _emit(
      AntiTamperFatherAlert(
        childId: childId,
        kind: AntiTamperAlertKind.simChange,
        at: at ?? DateTime.now().toUtc(),
      ),
    );
  }

  bool _emit(AntiTamperFatherAlert alert) {
    delivered.add(alert);
    if (!_controller.isClosed) {
      _controller.add(alert);
    }
    return true;
  }

  void dispose() {
    _controller.close();
  }
}

/// Shared Stage-1 singleton (tests inject their own [AntiTamperAlertBus]).
final AntiTamperAlertBus stage1AntiTamperAlertBus = AntiTamperAlertBus();
