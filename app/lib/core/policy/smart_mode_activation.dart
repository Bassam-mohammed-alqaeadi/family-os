import 'package:flutter/foundation.dart';

import 'smart_modes.dart';

/// Current smart-mode activation row per child (SET-019 / `smart_mode_activation`).
///
/// Parent FAT-085 publishes; child CHD-004 watches the same-session stream.
@immutable
final class SmartModeActivation {
  const SmartModeActivation({
    required this.childId,
    required this.active,
    required this.updatedAt,
    this.modeId,
    this.expiresAt,
  });

  final String childId;

  /// Active built-in mode when [active] is true; null when idle / cleared.
  final BuiltInModeId? modeId;

  final bool active;
  final DateTime updatedAt;

  /// Optional schedule end (mode + expiry together on CHD-004 / UI-005).
  final DateTime? expiresAt;

  /// Idle snapshot (no mode applied).
  factory SmartModeActivation.idle({
    required String childId,
    DateTime? updatedAt,
  }) {
    return SmartModeActivation(
      childId: childId,
      modeId: null,
      active: false,
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  SmartModeActivation copyWith({
    String? childId,
    BuiltInModeId? modeId,
    bool? active,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool clearModeId = false,
    bool clearExpiresAt = false,
  }) {
    return SmartModeActivation(
      childId: childId ?? this.childId,
      modeId: clearModeId ? null : (modeId ?? this.modeId),
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  Map<String, Object?> toJson() => {
        'childId': childId,
        'modeId': modeId?.name,
        'active': active,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
      };

  factory SmartModeActivation.fromJson(Map<String, Object?> json) {
    final name = json['modeId'] as String?;
    BuiltInModeId? modeId;
    if (name != null) {
      modeId = BuiltInModeId.values.firstWhere(
        (e) => e.name == name,
        orElse: () => BuiltInModeId.custom,
      );
    }
    final rawAt = json['updatedAt'] as String?;
    final rawExp = json['expiresAt'] as String?;
    return SmartModeActivation(
      childId: json['childId'] as String? ?? 'child_demo',
      modeId: modeId,
      active: json['active'] as bool? ?? false,
      updatedAt: rawAt != null
          ? DateTime.parse(rawAt).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: rawExp != null ? DateTime.parse(rawExp).toUtc() : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartModeActivation &&
          other.childId == childId &&
          other.modeId == modeId &&
          other.active == active &&
          other.updatedAt.isAtSameMomentAs(updatedAt) &&
          ((other.expiresAt == null && expiresAt == null) ||
              (other.expiresAt != null &&
                  expiresAt != null &&
                  other.expiresAt!.isAtSameMomentAs(expiresAt!)));

  @override
  int get hashCode =>
      Object.hash(childId, modeId, active, updatedAt, expiresAt);
}
