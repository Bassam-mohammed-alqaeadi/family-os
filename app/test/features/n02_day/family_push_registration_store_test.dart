import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:family_os/core/fs_foundation/sqlite_local_database.dart';
import 'package:family_os/features/n02_day/family_push_registration_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('registration id and family survive closing and reopening app SQLite', () async {
    final directory = await Directory.systemTemp.createTemp('family_push_restart_');
    final path = p.join(directory.path, 'push-registration.db');
    final firstDatabase = await SqliteLocalDatabase.openAt(path);
    final firstStore = LocalKvFamilyPushRegistrationStore(
      firstDatabase,
      isRestartSafe: true,
    );
    const record = FamilyPushRegistrationRecord(
      familyId: '11111111-1111-4111-8111-111111111111',
      registrationId: '44444444-4444-4444-8444-444444444444',
    );

    await firstStore.save(record);
    await firstDatabase.close();

    final reopenedDatabase = await SqliteLocalDatabase.openAt(path);
    final reopenedStore = LocalKvFamilyPushRegistrationStore(
      reopenedDatabase,
      isRestartSafe: true,
    );
    final loaded = await reopenedStore.read();
    expect(loaded?.familyId, record.familyId);
    expect(loaded?.registrationId, record.registrationId);

    await reopenedStore.clear();
    expect(await reopenedStore.read(), isNull);
    await reopenedDatabase.close();
    await directory.delete(recursive: true);
  });
}
