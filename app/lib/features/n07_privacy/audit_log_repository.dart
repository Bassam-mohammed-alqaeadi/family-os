import 'package:family_os/features/n07_privacy/audit_log_models.dart';

/// Rule 25 seam — Stage-1 mock audit log (no Drift).
///
/// **R10:** this interface exposes **only** [load] + [append].
/// There is intentionally **no** `update` / `delete` / `clear` / `remove`.
abstract class AuditLogRepository {
  Future<List<AuditLogEntry>> load();

  /// Append-only write. Never replaces or removes prior rows.
  void append(AuditLogEntry entry);
}

/// In-memory mock — empty by default (Rule 23); tests inject fixtures.
final class InMemoryAuditLogRepository implements AuditLogRepository {
  InMemoryAuditLogRepository({List<AuditLogEntry>? seed})
    : _entries = List<AuditLogEntry>.from(seed ?? const []);

  final List<AuditLogEntry> _entries;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<List<AuditLogEntry>> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    final copy = List<AuditLogEntry>.from(_entries)
      ..sort((a, b) => b.at.compareTo(a.at));
    return copy;
  }

  @override
  void append(AuditLogEntry entry) {
    _entries.insert(0, entry);
  }

  void seed(List<AuditLogEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
  }

  /// Test-only reset — **not** part of [AuditLogRepository] (R10 product API).
  void resetForTests() {
    _entries.clear();
    loadGate = null;
  }

  /// Snapshot length for tests (read-only).
  int get lengthForTests => _entries.length;
}

/// Shared Stage-1 singleton (empty until a screen/test seeds).
final InMemoryAuditLogRepository stage1AuditLogRepository =
    InMemoryAuditLogRepository();

/// Empty — Rule 23 empty-state / first-time family.
List<AuditLogEntry> auditLogEmptyFixture() => const [];

/// One row — minimal consequential action.
List<AuditLogEntry> auditLogOneFixture({DateTime? at}) {
  final when = at ?? DateTime.utc(2026, 9, 1, 10, 0);
  return [
    AuditLogEntry(
      id: 'audit-consent-1',
      kind: AuditLogEntryKind.parentalConsentPair,
      actor: AuditLogActor.father,
      at: when,
      subjectKey: 'childThree',
      detailKey: 'timestamped',
    ),
  ];
}

/// Prototype FAT-060 — five append-only rows (newest first by [at]).
///
/// Rule 23: subjectKey only (no planted person names).
List<AuditLogEntry> auditLogPrototypeFixture() {
  return [
    AuditLogEntry(
      id: 'audit-sos-1',
      kind: AuditLogEntryKind.sosAlert,
      actor: AuditLogActor.system,
      at: DateTime.utc(2026, 9, 22, 12, 47),
      subjectKey: 'childOne',
      detailKey: 'closedAfter6m',
    ),
    AuditLogEntry(
      id: 'audit-level-1',
      kind: AuditLogEntryKind.motherLevelUpgrade,
      actor: AuditLogActor.father,
      at: DateTime.utc(2026, 9, 10, 9, 0),
      subjectKey: 'mother',
      detailKey: 'observerToPartner',
    ),
    AuditLogEntry(
      id: 'audit-unlock-1',
      kind: AuditLogEntryKind.parentModeUnlockAttempt,
      actor: AuditLogActor.childDevice,
      at: DateTime.utc(2026, 9, 22, 8, 15),
      subjectKey: 'childOne',
      detailKey: 'rejectedX2',
    ),
    AuditLogEntry(
      id: 'audit-forget-1',
      kind: AuditLogEntryKind.forgetUsed,
      actor: AuditLogActor.father,
      at: DateTime.utc(2026, 9, 19, 16, 0),
      detailKey: 'friday',
    ),
    AuditLogEntry(
      id: 'audit-consent-1',
      kind: AuditLogEntryKind.parentalConsentPair,
      actor: AuditLogActor.father,
      at: DateTime.utc(2026, 9, 1, 10, 0),
      subjectKey: 'childThree',
      detailKey: 'timestamped',
    ),
  ];
}
