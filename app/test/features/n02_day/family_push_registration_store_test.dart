import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/features/n02_day/family_push_registration_store.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _registrationId = '44444444-4444-4444-8444-444444444444';
const _legacyFcmToken = 'fcm-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _accountBearer = 'never-persist-this-account-token';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('unknown, known-empty, UUIDs and pending cleanup survive SQLite reopen', () async {
    final directory = await Directory.systemTemp.createTemp('family_push_restart_');
    final path = p.join(directory.path, 'push-registration.db');
    var database = await SqliteLocalDatabase.openAt(path);
    var store = LocalKvFamilyPushRegistrationStore(
      database,
      isRestartSafe: true,
    );

    // No row is not proof of no remote registration: this is an app upgraded from the
    // process-local implementation, so it starts in the conservative unknown state.
    final absent = await store.read();
    expect(absent.hasUntrackedRegistration, isTrue);
    expect(absent.registrations, isEmpty);

    await store.save(FamilyPushRegistrationSnapshot.knownNone);
    await database.close();

    database = await SqliteLocalDatabase.openAt(path);
    store = LocalKvFamilyPushRegistrationStore(database, isRestartSafe: true);
    final knownNone = await store.read();
    expect(knownNone.hasUntrackedRegistration, isFalse);
    expect(knownNone.registrations, isEmpty);

    const record = FamilyPushRegistrationRecord(
      familyId: _familyId,
      registrationId: _registrationId,
    );
    await store.save(
      const FamilyPushRegistrationSnapshot(
        hasUntrackedRegistration: false,
        registrations: <FamilyPushRegistrationRecord>[record],
      ),
    );
    await database.close();

    database = await SqliteLocalDatabase.openAt(path);
    store = LocalKvFamilyPushRegistrationStore(database, isRestartSafe: true);
    final pending = await store.read();
    expect(pending.hasUntrackedRegistration, isFalse);
    expect(pending.registrations, hasLength(1));
    expect(pending.registrations.single.familyId, _familyId);
    expect(pending.registrations.single.registrationId, _registrationId);

    final rows = await database.query(
      'kv_store',
      where: 'namespace = ? AND key = ?',
      whereArgs: const ['family_push_registration_v1', 'guardian_registration'],
      limit: 1,
    );
    final serialized = rows.single['value']! as String;
    expect(serialized, isNot(contains(_legacyFcmToken)));
    expect(serialized, isNot(contains(_accountBearer)));
    await database.close();
    await directory.delete(recursive: true);
  });

  test('the pre-ledger UUID row migrates as known plus legacy-unknown', () async {
    final directory = await Directory.systemTemp.createTemp('family_push_legacy_');
    final path = p.join(directory.path, 'push-registration.db');
    final database = await SqliteLocalDatabase.openAt(path);
    await database.insert(
      'kv_store',
      {
        'namespace': 'family_push_registration_v1',
        'key': 'guardian_registration',
        'value': jsonEncode({
          'familyId': _familyId,
          'registrationId': _registrationId,
        }),
        'updated_at': DateTime.utc(2026).millisecondsSinceEpoch,
      },
      conflictAlgorithm: LocalConflictAlgorithm.replace,
    );

    final store = LocalKvFamilyPushRegistrationStore(
      database,
      isRestartSafe: true,
    );
    final migrated = await store.read();
    expect(migrated.hasUntrackedRegistration, isTrue);
    expect(migrated.registrations, hasLength(1));
    expect(migrated.registrations.single.registrationId, _registrationId);

    await database.close();
    await directory.delete(recursive: true);
  });
}
