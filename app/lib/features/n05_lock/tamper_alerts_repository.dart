import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n05_lock/tamper_alerts_models.dart';

/// Rule 25 seam — Stage-1 mock list of tamper alerts (no FCM).
abstract class TamperAlertsRepository {
  Future<List<TamperAlertEntry>> load(ChildId childId);
}

/// In-memory mock — empty by default (Rule 23); tests inject fixtures.
final class InMemoryTamperAlertsRepository implements TamperAlertsRepository {
  InMemoryTamperAlertsRepository({Map<String, List<TamperAlertEntry>>? seed})
    : _byChild = {
        for (final e in (seed ?? const {}).entries)
          e.key: List<TamperAlertEntry>.from(e.value),
      };

  final Map<String, List<TamperAlertEntry>> _byChild;

  @override
  Future<List<TamperAlertEntry>> load(ChildId childId) async {
    final list = _byChild[childId.value] ?? const <TamperAlertEntry>[];
    final copy = List<TamperAlertEntry>.from(list)
      ..sort((a, b) => b.at.compareTo(a.at));
    return copy;
  }

  void seed(ChildId childId, List<TamperAlertEntry> alerts) {
    _byChild[childId.value] = List<TamperAlertEntry>.from(alerts);
  }
}

/// Shared Stage-1 singleton (empty until a screen/test seeds).
final InMemoryTamperAlertsRepository stage1TamperAlertsRepository =
    InMemoryTamperAlertsRepository();

/// Rule 23 — opaque demo child key (not a planted display name).
const String kDefaultTamperAlertsChildKey = 'demo-child';

/// Single active VPN attempt (prototype FAT-038 active card shape).
List<TamperAlertEntry> tamperAlertsOneFixture({
  ChildId? childId,
  DateTime? at,
}) {
  final id = childId ?? ChildId(kDefaultTamperAlertsChildKey);
  final when = at ?? DateTime.utc(2026, 9, 21, 14, 20);
  return [
    TamperAlertEntry(
      id: 'ta-vpn-1',
      childId: id,
      kind: TamperAlertKind.vpn,
      status: TamperAlertStatus.active,
      at: when,
      detailKey: 'TurboVPN',
    ),
  ];
}

/// Active + history (VPN + clock handled) — empty/one/many many-case.
List<TamperAlertEntry> tamperAlertsManyFixture({
  ChildId? childId,
  DateTime? base,
}) {
  final id = childId ?? ChildId(kDefaultTamperAlertsChildKey);
  final t0 = base ?? DateTime.utc(2026, 9, 21, 14, 20);
  return [
    TamperAlertEntry(
      id: 'ta-vpn-1',
      childId: id,
      kind: TamperAlertKind.vpn,
      status: TamperAlertStatus.active,
      at: t0,
      detailKey: 'TurboVPN',
    ),
    TamperAlertEntry(
      id: 'ta-perm-1',
      childId: id,
      kind: TamperAlertKind.permissionDisable,
      status: TamperAlertStatus.active,
      at: t0.subtract(const Duration(hours: 2)),
    ),
    TamperAlertEntry(
      id: 'ta-clock-1',
      childId: id,
      kind: TamperAlertKind.clockChange,
      status: TamperAlertStatus.handled,
      at: t0.subtract(const Duration(days: 1)),
    ),
    TamperAlertEntry(
      id: 'ta-safe-1',
      childId: id,
      kind: TamperAlertKind.safeMode,
      status: TamperAlertStatus.handled,
      at: t0.subtract(const Duration(days: 3)),
    ),
    TamperAlertEntry(
      id: 'ta-sim-1',
      childId: id,
      kind: TamperAlertKind.simChange,
      status: TamperAlertStatus.handled,
      at: t0.subtract(const Duration(days: 5)),
    ),
  ];
}

@immutable
final class TamperAlertsSnapshot {
  const TamperAlertsSnapshot({this.active = const [], this.handled = const []});

  final List<TamperAlertEntry> active;
  final List<TamperAlertEntry> handled;

  bool get isEmpty => active.isEmpty && handled.isEmpty;

  int get totalCount => active.length + handled.length;

  factory TamperAlertsSnapshot.fromList(List<TamperAlertEntry> all) {
    final active = <TamperAlertEntry>[];
    final handled = <TamperAlertEntry>[];
    for (final a in all) {
      if (a.isActive) {
        active.add(a);
      } else {
        handled.add(a);
      }
    }
    return TamperAlertsSnapshot(active: active, handled: handled);
  }
}
