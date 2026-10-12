import 'dart:convert';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';

/// The non-secret address needed to delete this app install's server registration.
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

/// Durable cache for the one guardian push registration owned by this installation.
abstract interface class FamilyPushRegistrationStore {
  /// False for Memory fallback: callers must not create server state they cannot recover.
  bool get isRestartSafe;

  Future<FamilyPushRegistrationRecord?> read();
  Future<void> save(FamilyPushRegistrationRecord record);
  Future<void> clear();
}

/// Stores registration identity in the app's established SQLite `kv_store`.
///
/// The UUIDs are not bearer credentials. The FCM token and account token are intentionally
/// excluded. An honest Memory fallback is readable during this process but is never described
/// as restart-safe and is not allowed to create a new remote registration.
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
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final FamilyLocalDatabase _database;
  final DateTime Function() _clock;

  @override
  final bool isRestartSafe;

  @override
  Future<FamilyPushRegistrationRecord?> read() async {
    final rows = await _database.query(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: const [_namespace, _key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.single['value'];
    if (raw is! String || raw.isEmpty) {
      throw StateError('Persisted guardian push registration is malformed.');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Persisted guardian push registration is malformed.');
    }
    final familyId = decoded['familyId'];
    final registrationId = decoded['registrationId'];
    if (familyId is! String ||
        registrationId is! String ||
        !_uuid.hasMatch(familyId) ||
        !_uuid.hasMatch(registrationId)) {
      throw StateError('Persisted guardian push registration is malformed.');
    }
    return FamilyPushRegistrationRecord(
      familyId: familyId,
      registrationId: registrationId,
    );
  }

  @override
  Future<void> save(FamilyPushRegistrationRecord record) async {
    if (!_uuid.hasMatch(record.familyId) ||
        !_uuid.hasMatch(record.registrationId)) {
      throw ArgumentError('Push registration identifiers must be UUIDs.');
    }
    await _database.insert(
      _table,
      {
        'namespace': _namespace,
        'key': _key,
        'value': jsonEncode({
          'familyId': record.familyId,
          'registrationId': record.registrationId,
        }),
        'updated_at': _clock().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    await _database.delete(
      _table,
      where: 'namespace = ? AND key = ?',
      whereArgs: const [_namespace, _key],
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
