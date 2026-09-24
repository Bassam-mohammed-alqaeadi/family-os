import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';
import 'schedule_window.dart';
import 'screen_time_policy.dart';

/// Parent→child sync kind (SET-003).
enum PolicySyncKind { schedule, policy }

/// Honest sync ack status for parent UI (Family Link–style).
enum PolicySyncStatus { pending, delivered, offlineQueued }

/// Event emitted after parent save of schedules or screen-time policy.
@immutable
final class PolicySyncEvent {
  const PolicySyncEvent({
    required this.childId,
    required this.updatedAt,
    required this.kind,
    this.policy,
    this.schedules,
  });

  final ChildId childId;
  final DateTime updatedAt;
  final PolicySyncKind kind;

  /// Policy snapshot when [kind] == [PolicySyncKind.policy].
  final ScreenTimePolicy? policy;

  /// Schedule snapshot when [kind] == [PolicySyncKind.schedule].
  final List<ScheduleWindow>? schedules;
}

/// Child-side applied mirror (last delivered snapshot).
@immutable
final class ChildPolicyMirror {
  const ChildPolicyMirror({
    required this.childId,
    required this.policy,
    required this.schedules,
    required this.lastAppliedAt,
    required this.applyCount,
    this.sleepActiveNotice = false,
    this.temporaryGrantRemaining = 0,
  });

  final ChildId childId;
  final ScreenTimePolicy policy;
  final List<ScheduleWindow> schedules;

  /// Last successfully applied [PolicySyncEvent.updatedAt] (idempotency cursor).
  final DateTime? lastAppliedAt;

  /// Increments only when a new [updatedAt] is applied (not on re-delivery).
  final int applyCount;

  /// Soft notice flag when sleep window became enabled/active on apply.
  final bool sleepActiveNotice;

  /// Remaining entertainment minutes: `max(0, dailyCap − used) + active grants`.
  ///
  /// Prefer [dailyRemaining] / [temporaryGrantRemaining] for labeled UI.
  int get remainingMinutes {
    final rem = dailyRemaining + temporaryGrantRemaining;
    return rem < 0 ? 0 : rem;
  }

  /// max(0, dailyCap − used) — Daily Allowance leftover.
  int get dailyRemaining {
    final rem = policy.dailyCapMinutes - policy.usedMinutesToday;
    return rem < 0 ? 0 : rem;
  }

  /// Active Temporary Grant leftover (G-A) — not earned wallet.
  final int temporaryGrantRemaining;

  ChildPolicyMirror copyWith({
    ScreenTimePolicy? policy,
    List<ScheduleWindow>? schedules,
    DateTime? lastAppliedAt,
    int? applyCount,
    bool? sleepActiveNotice,
    int? temporaryGrantRemaining,
  }) {
    return ChildPolicyMirror(
      childId: childId,
      policy: policy ?? this.policy,
      schedules: schedules ?? this.schedules,
      lastAppliedAt: lastAppliedAt ?? this.lastAppliedAt,
      applyCount: applyCount ?? this.applyCount,
      sleepActiveNotice: sleepActiveNotice ?? this.sleepActiveNotice,
      temporaryGrantRemaining:
          temporaryGrantRemaining ?? this.temporaryGrantRemaining,
    );
  }
}

/// Stage-1 in-process sync bus — simulates push ack without Firebase/FCM.
///
/// Parent [publish] → if child online, apply to [watch] stream same isolate;
/// if offline, hold as [PolicySyncStatus.offlineQueued] until [markChildOnline].
final class PolicySyncBus {
  PolicySyncBus();

  final Set<String> _offline = {};
  final Map<String, PolicySyncStatus> _status = {};
  final Map<String, ChildPolicyMirror> _mirrors = {};
  final Map<String, List<PolicySyncEvent>> _queue = {};

  final _statusControllers =
      <String, StreamController<PolicySyncStatus>>{};
  final _mirrorControllers =
      <String, StreamController<ChildPolicyMirror>>{};

  /// Parent-visible status for [childId] (defaults to delivered = idle).
  PolicySyncStatus statusOf(ChildId childId) =>
      _status[childId.value] ?? PolicySyncStatus.delivered;

  /// Current child mirror (seeded on first watch/publish).
  ChildPolicyMirror mirrorOf(ChildId childId) =>
      _mirrors[childId.value] ?? _seedMirror(childId);

  /// Seed last-synced values without counting as a sync apply (hydrate).
  void hydrate(
    ChildId childId, {
    ScreenTimePolicy? policy,
    List<ScheduleWindow>? schedules,
    int? temporaryGrantRemaining,
  }) {
    final current = mirrorOf(childId);
    final next = current.copyWith(
      policy: policy,
      schedules: schedules,
      temporaryGrantRemaining: temporaryGrantRemaining,
    );
    _mirrors[childId.value] = next;
    final ctrl = _mirrorControllers[childId.value];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(next);
    }
  }

  bool isChildOnline(ChildId childId) => !_offline.contains(childId.value);

  void markChildOffline(ChildId childId) {
    _offline.add(childId.value);
  }

  /// Reconnect: drain queue and deliver (no false “applied” while offline).
  void markChildOnline(ChildId childId) {
    _offline.remove(childId.value);
    final queued = _queue.remove(childId.value) ?? const [];
    for (final event in queued) {
      _deliver(event);
    }
    if (queued.isEmpty &&
        (_status[childId.value] == PolicySyncStatus.pending ||
            _status[childId.value] == PolicySyncStatus.offlineQueued)) {
      _setStatus(childId, PolicySyncStatus.delivered);
    }
  }

  /// Parent publishes after successful repo save.
  PolicySyncStatus publish(PolicySyncEvent event) {
    final id = event.childId.value;
    if (_offline.contains(id)) {
      final q = _queue.putIfAbsent(id, () => <PolicySyncEvent>[]);
      q.add(event);
      _setStatus(event.childId, PolicySyncStatus.offlineQueued);
      return PolicySyncStatus.offlineQueued;
    }
    _setStatus(event.childId, PolicySyncStatus.pending);
    _deliver(event);
    return PolicySyncStatus.delivered;
  }

  /// Child-side stream of applied snapshots (same-session live reflect).
  Stream<ChildPolicyMirror> watch(ChildId childId) async* {
    yield mirrorOf(childId);
    yield* _mirrorController(childId).stream;
  }

  /// Parent-side status stream.
  Stream<PolicySyncStatus> watchStatus(ChildId childId) async* {
    yield statusOf(childId);
    yield* _statusController(childId).stream;
  }

  StreamController<ChildPolicyMirror> _mirrorController(ChildId childId) {
    return _mirrorControllers.putIfAbsent(
      childId.value,
      () => StreamController<ChildPolicyMirror>.broadcast(),
    );
  }

  StreamController<PolicySyncStatus> _statusController(ChildId childId) {
    return _statusControllers.putIfAbsent(
      childId.value,
      () => StreamController<PolicySyncStatus>.broadcast(),
    );
  }

  void dispose() {
    for (final c in _statusControllers.values) {
      c.close();
    }
    for (final c in _mirrorControllers.values) {
      c.close();
    }
    _statusControllers.clear();
    _mirrorControllers.clear();
  }

  ChildPolicyMirror _seedMirror(ChildId childId) {
    final mirror = ChildPolicyMirror(
      childId: childId,
      policy: ScreenTimePolicy.defaults(),
      schedules: [
        for (final kind in ScheduleKind.values)
          ScheduleWindow(kind: kind, enabled: false),
      ],
      lastAppliedAt: null,
      applyCount: 0,
    );
    _mirrors[childId.value] = mirror;
    return mirror;
  }

  void _setStatus(ChildId childId, PolicySyncStatus status) {
    _status[childId.value] = status;
    final ctrl = _statusControllers[childId.value];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(status);
    }
  }

  void _deliver(PolicySyncEvent event) {
    final current = mirrorOf(event.childId);

    // Idempotent: same updatedAt must not re-apply / bump applyCount.
    if (current.lastAppliedAt != null &&
        current.lastAppliedAt!.isAtSameMomentAs(event.updatedAt)) {
      _setStatus(event.childId, PolicySyncStatus.delivered);
      return;
    }

    var nextPolicy = current.policy;
    var nextSchedules = current.schedules;
    var sleepNotice = false;

    if (event.kind == PolicySyncKind.policy && event.policy != null) {
      nextPolicy = event.policy!;
    }
    if (event.kind == PolicySyncKind.schedule && event.schedules != null) {
      nextSchedules = List<ScheduleWindow>.from(event.schedules!);
      ScheduleWindow? sleep;
      for (final w in nextSchedules) {
        if (w.kind == ScheduleKind.sleep) {
          sleep = w;
          break;
        }
      }
      var wasEnabled = false;
      for (final w in current.schedules) {
        if (w.kind == ScheduleKind.sleep) {
          wasEnabled = w.enabled;
          break;
        }
      }
      if (sleep != null && sleep.enabled && !wasEnabled) {
        sleepNotice = true;
      }
    }

    final next = ChildPolicyMirror(
      childId: event.childId,
      policy: nextPolicy,
      schedules: nextSchedules,
      lastAppliedAt: event.updatedAt,
      applyCount: current.applyCount + 1,
      sleepActiveNotice: sleepNotice,
      temporaryGrantRemaining: current.temporaryGrantRemaining,
    );
    _mirrors[event.childId.value] = next;

    final ctrl = _mirrorControllers[event.childId.value];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(next);
    }
    _setStatus(event.childId, PolicySyncStatus.delivered);
  }
}

/// Process-wide Stage-1 bus (tests may inject their own).
final PolicySyncBus stage1PolicySyncBus = PolicySyncBus();
