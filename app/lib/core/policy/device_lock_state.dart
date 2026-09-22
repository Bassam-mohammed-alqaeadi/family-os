import 'package:flutter/foundation.dart';

import '../domain/child_id.dart';

/// Who last applied a successful lock (SET-009 / ADR-035).
enum DeviceLockedBy { father, mother }

/// Persisted device lock snapshot (D-5 `device_lock_state`).
@immutable
final class DeviceLockState {
  const DeviceLockState({
    required this.childId,
    required this.locked,
    required this.updatedAt,
    this.lockedBy,
  });

  final ChildId childId;
  final bool locked;

  /// Set when [locked] is true; null when unlocked.
  final DeviceLockedBy? lockedBy;
  final DateTime updatedAt;

  factory DeviceLockState.unlocked(ChildId childId, {DateTime? at}) {
    return DeviceLockState(
      childId: childId,
      locked: false,
      lockedBy: null,
      updatedAt: at ?? DateTime.now().toUtc(),
    );
  }

  DeviceLockState copyWith({
    ChildId? childId,
    bool? locked,
    DeviceLockedBy? lockedBy,
    DateTime? updatedAt,
    bool clearLockedBy = false,
  }) {
    return DeviceLockState(
      childId: childId ?? this.childId,
      locked: locked ?? this.locked,
      lockedBy: clearLockedBy ? null : (lockedBy ?? this.lockedBy),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'childId': childId.value,
        'locked': locked,
        'lockedBy': lockedBy?.name,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory DeviceLockState.fromJson(Map<String, Object?> json) {
    final childRaw = json['childId']?.toString() ?? '';
    final lockedByRaw = json['lockedBy']?.toString();
    DeviceLockedBy? lockedBy;
    if (lockedByRaw == DeviceLockedBy.father.name) {
      lockedBy = DeviceLockedBy.father;
    } else if (lockedByRaw == DeviceLockedBy.mother.name) {
      lockedBy = DeviceLockedBy.mother;
    }
    final locked = json['locked'] == true;
    final updatedRaw = json['updatedAt']?.toString();
    return DeviceLockState(
      childId: ChildId(childRaw.isEmpty ? 'unknown' : childRaw),
      locked: locked,
      lockedBy: locked ? lockedBy : null,
      updatedAt: updatedRaw == null || updatedRaw.isEmpty
          ? DateTime.now().toUtc()
          : DateTime.parse(updatedRaw).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceLockState &&
          childId == other.childId &&
          locked == other.locked &&
          lockedBy == other.lockedBy &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(childId, locked, lockedBy, updatedAt);
}
