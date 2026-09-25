import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/device_repository.dart';
import 'package:family_os/core/data/family_database.dart';

/// PERS-2b — devices, their health and the triple lock are real rows.
///
/// The contract's two rules are measured here, not assumed:
///  · `mode_owner_xor` — a bad owner/child pairing never reaches the store;
///  · "٣ محاولات ⇒ ٢٤ ساعة" — the lock is computed from persisted attempts.
DevicesCompanion _parentDevice({String id = 'dev-1'}) {
  return DevicesCompanion.insert(
    id: id,
    familyId: 'fam-1',
    accountId: const Value('acc-1'),
    mode: DeviceMode.parent,
    platform: 'android',
  );
}

DevicesCompanion _childDevice({String id = 'dev-2'}) {
  return DevicesCompanion.insert(
    id: id,
    familyId: 'fam-1',
    childId: const Value('child-1'),
    mode: DeviceMode.childLocked,
    platform: 'android',
    manufacturer: const Value('Samsung'),
  );
}

void main() {
  late FamilyDatabase db;
  late DriftDeviceRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftDeviceRepository(db);
  });

  tearDown(() => db.close());

  group('device rows', () {
    test('insert then read back with contract defaults', () async {
      await repo.upsert(_childDevice());

      final row = await repo.byId('dev-2');

      expect(row, isNotNull);
      expect(row!.mode, DeviceMode.childLocked);
      expect(row.platform, 'android');
      expect(row.childId, 'child-1');
      expect(row.accountId, isNull);
      expect(row.manufacturer, 'Samsung');
      expect(row.pairedAt, isNotNull, reason: 'contract DEFAULT now()');
    });

    test('rows are scoped to their family', () async {
      await repo.upsert(_parentDevice());
      await repo.upsert(
        DevicesCompanion.insert(
          id: 'dev-9',
          familyId: 'fam-2',
          accountId: const Value('acc-2'),
          mode: DeviceMode.parent,
          platform: 'ios',
        ),
      );

      expect(await repo.allInFamily('fam-1'), hasLength(1));
      expect(await repo.allInFamily('fam-2'), hasLength(1));
    });

    group('mode_owner_xor is enforced at write time', () {
      test('PARENT must not carry a child', () async {
        await expectLater(
          repo.upsert(
            DevicesCompanion.insert(
              id: 'bad-1',
              familyId: 'fam-1',
              accountId: const Value('acc-1'),
              childId: const Value('child-1'),
              mode: DeviceMode.parent,
              platform: 'android',
            ),
          ),
          throwsA(isA<DeviceModeOwnershipException>()),
        );
      });

      test('CHILD_LOCKED must not carry an account', () async {
        await expectLater(
          repo.upsert(
            DevicesCompanion.insert(
              id: 'bad-2',
              familyId: 'fam-1',
              accountId: const Value('acc-1'),
              childId: const Value('child-1'),
              mode: DeviceMode.childLocked,
              platform: 'android',
            ),
          ),
          throwsA(isA<DeviceModeOwnershipException>()),
        );
      });

      test('CHILD_PREVIEW requires an account', () async {
        await expectLater(
          repo.upsert(
            DevicesCompanion.insert(
              id: 'bad-3',
              familyId: 'fam-1',
              mode: DeviceMode.childPreview,
              platform: 'android',
            ),
          ),
          throwsA(isA<DeviceModeOwnershipException>()),
        );
      });

      test('a rejected row is not written', () async {
        try {
          await repo.upsert(
            DevicesCompanion.insert(
              id: 'bad-4',
              familyId: 'fam-1',
              mode: DeviceMode.parent,
              platform: 'android',
            ),
          );
        } on DeviceModeOwnershipException {
          // expected
        }

        expect(await repo.byId('bad-4'), isNull);
      });
    });
  });

  group('device health', () {
    test('score defaults to GOOD when the caller does not set one', () async {
      await repo.upsert(_childDevice());
      await repo.saveHealth(
        DeviceHealthsCompanion.insert(deviceId: 'dev-2'),
      );

      final health = await repo.healthFor('dev-2');

      expect(health, isNotNull);
      expect(health!.score, kHealthGood);
      expect(health.reason, isNull);
    });

    test('health is one row per device and updates in place', () async {
      await repo.upsert(_childDevice());
      await repo.saveHealth(
        DeviceHealthsCompanion.insert(
          deviceId: 'dev-2',
          batteryLevel: const Value(12),
          score: const Value(kHealthAtRisk),
          reason: const Value(kReasonBatteryOptimizer),
        ),
      );
      await repo.saveHealth(
        DeviceHealthsCompanion.insert(
          deviceId: 'dev-2',
          batteryLevel: const Value(80),
          score: const Value(kHealthGood),
        ),
      );

      final health = await repo.healthFor('dev-2');

      expect(health!.batteryLevel, 80);
      expect(health.score, kHealthGood);
    });

    test('an unknown score or reason is refused', () async {
      await repo.upsert(_childDevice());

      await expectLater(
        repo.saveHealth(
          DeviceHealthsCompanion.insert(
            deviceId: 'dev-2',
            score: const Value('PERFECT'),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repo.saveHealth(
          DeviceHealthsCompanion.insert(
            deviceId: 'dev-2',
            reason: const Value('ALIENS'),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('battery outside 0..100 is refused', () async {
      await repo.upsert(_childDevice());

      await expectLater(
        repo.saveHealth(
          DeviceHealthsCompanion.insert(
            deviceId: 'dev-2',
            batteryLevel: const Value(140),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('triple lock', () {
    test('two failures do not lock', () async {
      await repo.upsert(_childDevice());

      await repo.recordUnlockAttempt(
        id: 'a1',
        deviceId: 'dev-2',
        passwordOk: false,
      );
      final second = await repo.recordUnlockAttempt(
        id: 'a2',
        deviceId: 'dev-2',
        passwordOk: false,
      );

      expect(second.lockedUntil, isNull);
      expect(await repo.isLocked('dev-2'), isFalse);
    });

    test('three consecutive failures lock for 24 hours', () async {
      await repo.upsert(_childDevice());
      final at = DateTime(2026, 9, 24, 10);

      await repo.recordUnlockAttempt(
        id: 'a1',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at,
      );
      await repo.recordUnlockAttempt(
        id: 'a2',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at.add(const Duration(minutes: 1)),
      );
      final third = await repo.recordUnlockAttempt(
        id: 'a3',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at.add(const Duration(minutes: 2)),
      );

      expect(
        third.lockedUntil,
        at.add(const Duration(minutes: 2)).add(kUnlockLockDuration),
        reason: 'contract: ٣ محاولات ⇒ ٢٤ ساعة',
      );
      expect(await repo.isLocked('dev-2', now: at), isTrue);
      expect(
        await repo.isLocked('dev-2', now: at.add(const Duration(hours: 25))),
        isFalse,
      );
    });

    test('a correct password resets the failure streak', () async {
      await repo.upsert(_childDevice());
      final at = DateTime(2026, 9, 24, 11);

      await repo.recordUnlockAttempt(
        id: 'a1',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at,
      );
      await repo.recordUnlockAttempt(
        id: 'a2',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at.add(const Duration(minutes: 1)),
      );
      await repo.recordUnlockAttempt(
        id: 'a3',
        deviceId: 'dev-2',
        passwordOk: true,
        at: at.add(const Duration(minutes: 2)),
      );
      final afterSuccess = await repo.recordUnlockAttempt(
        id: 'a4',
        deviceId: 'dev-2',
        passwordOk: false,
        at: at.add(const Duration(minutes: 3)),
      );

      expect(
        afterSuccess.lockedUntil,
        isNull,
        reason: 'the streak restarted, so this is the first failure again',
      );
    });
  });

  group('acceptance — a device survives a database reopen', () {
    test('write device + permission + health, close, reopen, read', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2b');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var db = FamilyDatabase(NativeDatabase(file));
        var repo = DriftDeviceRepository(db);
        await repo.upsert(_childDevice());
        await repo.saveHealth(
          DeviceHealthsCompanion.insert(
            deviceId: 'dev-2',
            score: const Value(kHealthOffline),
            reason: const Value(kReasonNoNetwork),
          ),
        );
        await db.close();

        // A fresh handle over the same file — nothing shared in memory.
        db = FamilyDatabase(NativeDatabase(file));
        repo = DriftDeviceRepository(db);
        final device = await repo.byId('dev-2');
        final health = await repo.healthFor('dev-2');

        expect(device, isNotNull);
        expect(device!.mode, DeviceMode.childLocked);
        expect(health!.score, kHealthOffline);
        expect(health.reason, kReasonNoNetwork);
        await db.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
