import 'package:flutter/foundation.dart';

import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Three urgency tiers — S-ADM-028 / importance ladder (سلّم الأهمية).
enum AlertUrgency {
  /// 🔴 Needs action now — quiet hours never mute (P-4 adjacent).
  critical,

  /// 🟡 Deserves a look.
  attention,

  /// 🟢 Reassurance / peace-of-mind.
  reassurance,
}

/// Where a hub row navigates (prototype FAT-019 → 020 / 033 / 035).
enum HubAlertTarget {
  /// FAT-020 with `?alertKind=`.
  alertDetail,

  /// FAT-033 time-request inbox.
  timeRequests,

  /// FAT-035 new-app approval.
  appApproval,

  /// Informational row — no navigation.
  none,
}

/// One parent alert row in SCR-FAT-019 (excerpt only — S-AIC-006).
@immutable
final class HubAlert {
  const HubAlert({
    required this.id,
    required this.urgency,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.swatch,
    this.target = HubAlertTarget.alertDetail,
    this.alertKind,
  });

  final String id;
  final AlertUrgency urgency;
  final String title;
  final String subtitle;
  final String emoji;
  final DayChildSwatch swatch;

  /// Navigation target; [HubAlertTarget.none] = non-tappable.
  final HubAlertTarget target;

  /// Passed to FAT-020 as `alertKind` when [target] is [HubAlertTarget.alertDetail].
  final String? alertKind;

  bool get isTappable => target != HubAlertTarget.none;

  HubAlert copyWith({
    String? id,
    AlertUrgency? urgency,
    String? title,
    String? subtitle,
    String? emoji,
    DayChildSwatch? swatch,
    HubAlertTarget? target,
    String? alertKind,
  }) {
    return HubAlert(
      id: id ?? this.id,
      urgency: urgency ?? this.urgency,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      emoji: emoji ?? this.emoji,
      swatch: swatch ?? this.swatch,
      target: target ?? this.target,
      alertKind: alertKind ?? this.alertKind,
    );
  }
}

/// Grouped hub snapshot — counters derived from lists.
@immutable
final class AlertsHubSnapshot {
  const AlertsHubSnapshot({
    this.critical = const [],
    this.attention = const [],
    this.reassurance = const [],
  });

  final List<HubAlert> critical;
  final List<HubAlert> attention;
  final List<HubAlert> reassurance;

  int get criticalCount => critical.length;
  int get attentionCount => attention.length;
  int get reassuranceCount => reassurance.length;

  bool get isEmpty =>
      critical.isEmpty && attention.isEmpty && reassurance.isEmpty;

  List<HubAlert> get all => [...critical, ...attention, ...reassurance];
}

/// Rule 25 seam — alerts hub for SCR-FAT-019 (no Firebase; Drift later).
abstract class AlertsHubRepository {
  Future<AlertsHubSnapshot> load();
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryAlertsHubRepository implements AlertsHubRepository {
  InMemoryAlertsHubRepository({
    AlertsHubSnapshot? initial,
    this.failLoad = false,
  }) : _snapshot = initial ?? const AlertsHubSnapshot();

  AlertsHubSnapshot _snapshot;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(AlertsHubSnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  Future<AlertsHubSnapshot> load() async {
    if (failLoad) {
      throw StateError('mock alerts hub load failure');
    }
    return AlertsHubSnapshot(
      critical: List.unmodifiable(_snapshot.critical),
      attention: List.unmodifiable(_snapshot.attention),
      reassurance: List.unmodifiable(_snapshot.reassurance),
    );
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1AlertsHubRepository = InMemoryAlertsHubRepository();
