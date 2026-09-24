import 'dart:convert';

import 'sos_ladder.dart';

/// Rule 25 seam — SOS escalation ladder for SET-020 (Drift deferred).
///
/// Rung-1 parents ([kSosLadderFixedParentIds]) are immovable / always-on.
abstract class SosLadderRepository {
  Future<SosLadder> load([String familyId = SosLadder.defaultFamilyId]);

  Future<void> save(SosLadder ladder);

  /// Rejects removal of rung-1 parents (P-5 / SET-020).
  Future<SosLadder> removeFromRung1(
    String memberId, {
    String familyId = SosLadder.defaultFamilyId,
  });

  /// Rejects disabling emergency contact for rung-1 parents.
  Future<SosLadder> setEmergencyContactEnabled(
    String memberId,
    bool enabled, {
    String familyId = SosLadder.defaultFamilyId,
  });

  /// Removes a backup on rung 2+ (parents rejected via [removeFromRung1] path).
  Future<SosLadder> removeBackup(
    String backupId, {
    String familyId = SosLadder.defaultFamilyId,
  });

  /// Adds / replaces a backup contact on rung 2+.
  Future<SosLadder> upsertBackup(
    SosBackupContact contact, {
    String familyId = SosLadder.defaultFamilyId,
  });
}

/// String KV used by [PrefsSosLadderRepository].
abstract class SosLadderStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class MemorySosLadderStore implements SosLadderStore {
  MemorySosLadderStore([Map<String, String>? data]) : data = data ?? {};

  final Map<String, String> data;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

/// Stage-1 shared mock prefs (process lifetime).
SosLadderStore stage1SosLadderStore = MemorySosLadderStore();

Never _rejectRemove(String memberId) => throw SosLadderValidationException(
      SosLadderValidationCode.rung1ParentImmovable,
      memberId: memberId,
    );

Never _rejectDisable(String memberId) => throw SosLadderValidationException(
      SosLadderValidationCode.rung1ParentDisableForbidden,
      memberId: memberId,
    );

/// Prefs/JSON-backed repository (SharedPreferences adapter-ready).
final class PrefsSosLadderRepository implements SosLadderRepository {
  PrefsSosLadderRepository(this._store);

  final SosLadderStore _store;

  static String _key(String familyId) => 'sos_ladder:$familyId';

  @override
  Future<SosLadder> load([String familyId = SosLadder.defaultFamilyId]) async {
    final raw = await _store.read(_key(familyId));
    if (raw == null || raw.isEmpty) {
      return SosLadder.defaults(familyId: familyId);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return SosLadder.defaults(familyId: familyId);
      }
      final ladder = SosLadder.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
      return ladder.familyId == familyId
          ? ladder
          : ladder.copyWith(familyId: familyId);
    } on FormatException {
      return SosLadder.defaults(familyId: familyId);
    }
  }

  @override
  Future<void> save(SosLadder ladder) async {
    final normalized = ladder.normalized();
    // Guard: cannot persist a ladder that dropped fixed parents when present.
    for (final id in kSosLadderFixedParentIds) {
      if (ladder.presentParentIds.contains(id) &&
          !normalized.presentParentIds.contains(id)) {
        _rejectRemove(id);
      }
    }
    await _store.write(
      _key(normalized.familyId),
      jsonEncode(normalized.toJson()),
    );
  }

  @override
  Future<SosLadder> removeFromRung1(
    String memberId, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final ladder = await load(familyId);
    if (ladder.isRung1Parent(memberId) || SosLadder.isFixedParentId(memberId)) {
      _rejectRemove(memberId);
    }
    return removeBackup(memberId, familyId: familyId);
  }

  @override
  Future<SosLadder> setEmergencyContactEnabled(
    String memberId,
    bool enabled, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final ladder = await load(familyId);
    if (!enabled &&
        (ladder.isRung1Parent(memberId) ||
            SosLadder.isFixedParentId(memberId))) {
      _rejectDisable(memberId);
    }
    final idx = ladder.backups.indexWhere((b) => b.id == memberId);
    if (idx < 0) {
      // Unknown non-parent id — no-op return current.
      if (SosLadder.isFixedParentId(memberId)) {
        _rejectDisable(memberId);
      }
      return ladder;
    }
    final next = ladder.copyWith(
      backups: [
        for (var i = 0; i < ladder.backups.length; i++)
          if (i == idx)
            ladder.backups[i].copyWith(enabled: enabled)
          else
            ladder.backups[i],
      ],
    );
    await save(next);
    return next;
  }

  @override
  Future<SosLadder> removeBackup(
    String backupId, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    if (SosLadder.isFixedParentId(backupId)) {
      _rejectRemove(backupId);
    }
    final ladder = await load(familyId);
    final next = ladder.copyWith(
      backups: ladder.backups.where((b) => b.id != backupId).toList(),
    );
    await save(next);
    return next;
  }

  @override
  Future<SosLadder> upsertBackup(
    SosBackupContact contact, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    if (SosLadder.isFixedParentId(contact.id)) {
      _rejectRemove(contact.id);
    }
    final ladder = await load(familyId);
    final others = ladder.backups.where((b) => b.id != contact.id).toList();
    final next = ladder.copyWith(backups: [...others, contact]);
    await save(next);
    return next;
  }
}

/// Pure in-memory alternate for unit / widget tests (Rule 25 fake).
final class InMemorySosLadderRepository implements SosLadderRepository {
  InMemorySosLadderRepository([Map<String, SosLadder>? seed])
      : _byFamily = {
          if (seed != null)
            for (final e in seed.entries) e.key: e.value.normalized(),
        };

  final Map<String, SosLadder> _byFamily;

  @override
  Future<SosLadder> load([String familyId = SosLadder.defaultFamilyId]) async {
    return _byFamily[familyId] ?? SosLadder.defaults(familyId: familyId);
  }

  @override
  Future<void> save(SosLadder ladder) async {
    final normalized = ladder.normalized();
    for (final id in kSosLadderFixedParentIds) {
      if (ladder.presentParentIds.contains(id) &&
          !normalized.presentParentIds.contains(id)) {
        _rejectRemove(id);
      }
    }
    _byFamily[normalized.familyId] = normalized;
  }

  @override
  Future<SosLadder> removeFromRung1(
    String memberId, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final ladder = await load(familyId);
    if (ladder.isRung1Parent(memberId) || SosLadder.isFixedParentId(memberId)) {
      _rejectRemove(memberId);
    }
    return removeBackup(memberId, familyId: familyId);
  }

  @override
  Future<SosLadder> setEmergencyContactEnabled(
    String memberId,
    bool enabled, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    final ladder = await load(familyId);
    if (!enabled &&
        (ladder.isRung1Parent(memberId) ||
            SosLadder.isFixedParentId(memberId))) {
      _rejectDisable(memberId);
    }
    final idx = ladder.backups.indexWhere((b) => b.id == memberId);
    if (idx < 0) {
      if (SosLadder.isFixedParentId(memberId)) {
        _rejectDisable(memberId);
      }
      return ladder;
    }
    final next = ladder.copyWith(
      backups: [
        for (var i = 0; i < ladder.backups.length; i++)
          if (i == idx)
            ladder.backups[i].copyWith(enabled: enabled)
          else
            ladder.backups[i],
      ],
    );
    await save(next);
    return next;
  }

  @override
  Future<SosLadder> removeBackup(
    String backupId, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    if (SosLadder.isFixedParentId(backupId)) {
      _rejectRemove(backupId);
    }
    final ladder = await load(familyId);
    final next = ladder.copyWith(
      backups: ladder.backups.where((b) => b.id != backupId).toList(),
    );
    await save(next);
    return next;
  }

  @override
  Future<SosLadder> upsertBackup(
    SosBackupContact contact, {
    String familyId = SosLadder.defaultFamilyId,
  }) async {
    if (SosLadder.isFixedParentId(contact.id)) {
      _rejectRemove(contact.id);
    }
    final ladder = await load(familyId);
    final others = ladder.backups.where((b) => b.id != contact.id).toList();
    final next = ladder.copyWith(backups: [...others, contact]);
    await save(next);
    return next;
  }

  Map<String, SosLadder> get debugSnapshot => Map.unmodifiable(_byFamily);
}
