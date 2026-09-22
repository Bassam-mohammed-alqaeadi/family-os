import 'package:flutter/foundation.dart';

/// Consequential audit kinds — prototype FAT-060 card rows.
enum AuditLogEntryKind {
  /// SOS alert opened / closed.
  sosAlert,

  /// Mother permission level change (immutable audit spirit from FAT-031).
  motherLevelUpgrade,

  /// Parent-mode unlock attempt rejected.
  parentModeUnlockAttempt,

  /// Advisor forget button used (never deletes audit — R10).
  forgetUsed,

  /// Parental consent for device pairing.
  parentalConsentPair,
}

/// Who performed or triggered the action (identity on every row — ن٥٢).
enum AuditLogActor {
  father,
  mother,
  system,
  childDevice,
}

/// One append-only audit row (R10 — never mutated after create).
@immutable
final class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.kind,
    required this.actor,
    required this.at,
    this.subjectKey,
    this.detailKey,
  });

  final String id;
  final AuditLogEntryKind kind;
  final AuditLogActor actor;
  final DateTime at;

  /// Opaque subject token (e.g. `childOne`) — never a planted display name (Rule 23).
  final String? subjectKey;

  /// Opaque detail token (e.g. `closedAfter6m`, `notified`).
  final String? detailKey;
}
