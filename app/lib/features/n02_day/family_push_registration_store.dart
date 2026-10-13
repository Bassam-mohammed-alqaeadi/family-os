import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

/// The non-secret address needed to delete one server registration.
///
/// FCM tokens and account credentials are deliberately not stored here.
final class FamilyPushRegistrationRecord {
  const FamilyPushRegistrationRecord({
    required this.familyId,
    required this.registrationId,
  });

  final String familyId;
  final String registrationId;
}

/// Durable knowledge about registrations this installation may still own.
///
/// A missing row (or a row written by the pre-ledger release) is **unknown**, not
/// known-empty: that older client could have registered an FCM token without writing
/// its server UUID to disk. The token-scoped cleanup route intentionally returns the
/// same response for an absent token and a token owned by another guardian, so its 204
/// cannot clear this uncertainty. A successful registration POST durably records the UUID
/// for the submitted current token, but an inherited unknown marker remains because the
/// legacy row may have used a token FCM has since rotated. Known UUIDs are kept separately
/// so a token rotation cannot overwrite a prior cleanup address. An empty, non-unknown
/// snapshot is the only trusted "nothing to remove" state.
final class FamilyPushRegistrationSnapshot {
  const FamilyPushRegistrationSnapshot({
    required this.hasUntrackedRegistration,
    required this.registrations,
  });

  static const unknown = FamilyPushRegistrationSnapshot(
    hasUntrackedRegistration: true,
    registrations: <FamilyPushRegistrationRecord>[],
  );

  static const knownNone = FamilyPushRegistrationSnapshot(
    hasUntrackedRegistration: false,
    registrations: <FamilyPushRegistrationRecord>[],
  );

  final bool hasUntrackedRegistration;
  final List<FamilyPushRegistrationRecord> registrations;

  bool get hasAnythingToClean =>
      hasUntrackedRegistration || registrations.isNotEmpty;

  FamilyPushRegistrationSnapshot copyWith({
    bool? hasUntrackedRegistration,
    List<FamilyPushRegistrationRecord>? registrations,
  }) =>
      FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration:
            hasUntrackedRegistration ?? this.hasUntrackedRegistration,
        registrations: registrations ?? this.registrations,
      );
}

/// Durable cache for the push registrations this app installation may have created.
abstract interface class FamilyPushRegistrationStore {
  /// False for Memory fallback: callers must not create server state they cannot recover.
  bool get isRestartSafe;

  /// Absence means [FamilyPushRegistrationSnapshot.unknown], never known-empty.
  Future<FamilyPushRegistrationSnapshot> read();
  Future<void> save(FamilyPushRegistrationSnapshot snapshot);
}

/// Stores non-secret registration state in the app's established SQLite `kv_store`.
///
/// No table/schema migration is needed. The FCM token and account token are excluded.
final class LocalKvFamilyPushRegistrationStore
    implements FamilyPushRegistrationStore {
  LocalKvFamilyPushRegistrationStore(
    this._database, {
    required this.isRestartSafe,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _namespace = 'family_push_registration_v1';
  static const _key = 'guardian_registration';
  static const _table = 'kv_store';
  static const _version = 2;
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final FamilyLocalDatabase _database;
  final DateTime Function() _clock;

  @override
  final bool isRestartSafe;

  @override
  Future<FamilyPushRegistrationSnapshot> read() async {
    final rows = await _database.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: const [_namespace, _key],
      limit: 1,
    );
    if (rows.isEmpty) return FamilyPushRegistrationSnapshot.unknown;

    final raw = rows.single['value'];
    if (raw is! String || raw.isEmpty) {
      return FamilyPushRegistrationSnapshot.unknown;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return FamilyPushRegistrationSnapshot.unknown;
    }
    if (decoded is! Map) return FamilyPushRegistrationSnapshot.unknown;

    // Preserve the UUID written by the first durable-persistence revision, but do not
    // infer that it was the only row an older process ever created.
    if (!decoded.containsKey('version')) {
      final legacyRecord = _recordFromJson(decoded);
      return FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration: true,
        registrations: legacyRecord == null
            ? const <FamilyPushRegistrationRecord>[]
            : <FamilyPushRegistrationRecord>[legacyRecord],
      );
    }

    if (decoded['version'] != _version ||
        decoded['hasUntrackedRegistration'] is! bool ||
        decoded['registrations'] is! List) {
      return FamilyPushRegistrationSnapshot.unknown;
    }

    final records = <FamilyPushRegistrationRecord>[];
    var malformedRecord = false;
    for (final rawRecord in decoded['registrations'] as List) {
      if (rawRecord is! Map) {
        malformedRecord = true;
        continue;
      }
      final record = _recordFromJson(rawRecord);
      if (record == null) {
        malformedRecord = true;
        continue;
      }
      if (!records.any((existing) =>
          existing.familyId == record.familyId &&
          existing.registrationId == record.registrationId)) {
        records.add(record);
      }
    }

    return FamilyPushRegistrationSnapshot(
      hasUntrackedRegistration:
          decoded['hasUntrackedRegistration'] == true || malformedRecord,
      registrations: List<FamilyPushRegistrationRecord>.unmodifiable(records),
    );
  }

  @override
  Future<void> save(FamilyPushRegistrationSnapshot snapshot) async {
    if (snapshot.registrations.any(
      (record) =>
          !_uuid.hasMatch(record.familyId) ||
          !_uuid.hasMatch(record.registrationId),
    )) {
      throw ArgumentError('Push registration identifiers must be UUIDs.');
    }
    await _database.insert(
      _table,
      {
        'namespace': _namespace,
        'key': _key,
        'value': jsonEncode({
          'version': _version,
          'hasUntrackedRegistration':
              snapshot.hasUntrackedRegistration,
          'registrations': snapshot.registrations
              .map(
                (record) => {
                  'familyId': record.familyId,
                  'registrationId': record.registrationId,
                },
              )
              .toList(growable: false),
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  FamilyPushRegistrationRecord? _recordFromJson(Map value) {
    final familyId = value['familyId'];
    final registrationId = value['registrationId'];
    if (familyId is! String ||
        registrationId is! String ||
        !_uuid.hasMatch(familyId) ||
        !_uuid.hasMatch(registrationId)) {
      return null;
    }
    return FamilyPushRegistrationRecord(
      familyId: familyId,
      registrationId: registrationId,
    );
  }
}

/// Opens the push-registration store on the shared app database.
abstract final class FamilyPushRegistrationLocalPersistence {
  FamilyPushRegistrationLocalPersistence._();

  static Future<FamilyPushRegistrationStore> openStore() async {
    await FsSessionKernel.ensureOpen(preferSqlite: true);
    return LocalKvFamilyPushRegistrationStore(
      FsSessionKernel.db,
      isRestartSafe:
          FsSessionKernel.usingSqlite && !FsSessionKernel.sqliteFallbackToMemory,
    );
  }
}
