import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/mother_level.dart';

/// One immutable audit row for mother-level changes (never deleted).
@immutable
final class MotherLevelAuditEntry {
  const MotherLevelAuditEntry({
    required this.from,
    required this.to,
    required this.at,
    this.motherNotified = true,
  });

  final MotherLevel from;
  final MotherLevel to;
  final DateTime at;
  final bool motherNotified;
}

/// Rule 25 seam — mother permission level for SCR-FAT-031 (Drift later).
abstract class MotherPermissionLevelRepository extends ChangeNotifier {
  MotherLevel get level;
  List<MotherLevelAuditEntry> get auditLog;

  /// Persist [next]. Returns false when unchanged. Always appends audit.
  bool setLevel(MotherLevel next, {DateTime? at});
}

/// In-memory mock — default [MotherLevel.partner] (doc 20 · ADR-035).
final class InMemoryMotherPermissionLevelRepository
    extends MotherPermissionLevelRepository {
  InMemoryMotherPermissionLevelRepository({
    MotherLevel initial = MotherLevel.partner,
    List<MotherLevelAuditEntry> audit = const [],
  })  : _level = initial,
        _audit = List.of(audit);

  MotherLevel _level;
  final List<MotherLevelAuditEntry> _audit;

  @override
  MotherLevel get level => _level;

  @override
  List<MotherLevelAuditEntry> get auditLog => List.unmodifiable(_audit);

  void seed({
    MotherLevel? level,
    List<MotherLevelAuditEntry>? audit,
  }) {
    if (level != null) _level = level;
    if (audit != null) {
      _audit
        ..clear()
        ..addAll(audit);
    }
    notifyListeners();
  }

  void resetForTests() {
    _level = MotherLevel.partner;
    _audit.clear();
    notifyListeners();
  }

  @override
  bool setLevel(MotherLevel next, {DateTime? at}) {
    if (next == _level) return false;
    final previous = _level;
    _level = next;
    _audit.insert(
      0,
      MotherLevelAuditEntry(
        from: previous,
        to: next,
        at: at ?? DateTime.now(),
        motherNotified: true,
      ),
    );
    notifyListeners();
    return true;
  }
}

/// Stage-1 singleton — partner default · empty audit (Rule 23).
final stage1MotherPermissionLevelRepository =
    InMemoryMotherPermissionLevelRepository();

/// Ordinal for upgrade / downgrade detection (observer < partner < full).
int motherLevelRank(MotherLevel level) => switch (level) {
      MotherLevel.observer => 0,
      MotherLevel.partner => 1,
      MotherLevel.full => 2,
    };

bool isMotherLevelDowngrade(MotherLevel from, MotherLevel to) =>
    motherLevelRank(to) < motherLevelRank(from);

bool isMotherLevelUpgrade(MotherLevel from, MotherLevel to) =>
    motherLevelRank(to) > motherLevelRank(from);
