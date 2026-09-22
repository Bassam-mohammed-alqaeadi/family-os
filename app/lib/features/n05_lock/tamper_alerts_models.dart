import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';

/// Tamper / bypass alert kinds — screens.csv SCR-FAT-038 + SET-008.
///
/// VPN · permission disable · clock change · safe mode · bypass · SIM.
enum TamperAlertKind {
  vpn,
  permissionDisable,
  clockChange,
  safeMode,
  bypass,
  simChange,
}

/// Active = needs parental dialogue; handled = auto-mitigated / acknowledged.
enum TamperAlertStatus { active, handled }

/// One father-facing tamper signal (Bark alert-first · dialogue not judgment).
@immutable
final class TamperAlertEntry {
  const TamperAlertEntry({
    required this.id,
    required this.childId,
    required this.kind,
    required this.status,
    required this.at,
    this.detailKey,
  });

  final String id;
  final ChildId childId;
  final TamperAlertKind kind;
  final TamperAlertStatus status;
  final DateTime at;

  /// Optional opaque product/detail token for fixtures (e.g. `TurboVPN`).
  /// Never a planted child display name (Rule 23).
  final String? detailKey;

  bool get isActive => status == TamperAlertStatus.active;

  TamperAlertEntry copyWith({
    String? id,
    ChildId? childId,
    TamperAlertKind? kind,
    TamperAlertStatus? status,
    DateTime? at,
    String? detailKey,
  }) {
    return TamperAlertEntry(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      at: at ?? this.at,
      detailKey: detailKey ?? this.detailKey,
    );
  }
}
