import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/sos_repository.dart';

/// PERS-2c — the emergency alarm.
///
/// The contract's two promises are measured here: "منع الازدواج عند إعادة
/// الإرسال" and "🚨 لا يُحذف أبدًا". An alarm system that loses an alarm, or
/// that depends on a subscription row being present, is not an alarm system.
void main() {
  late FamilyDatabase db;
  late DriftSosRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftSosRepository(db);
  });

  tearDown(() => db.close());

  Future<SosAlert> raiseAlarm({
    String id = 'sos-1',
    String requestId = 'req-1',
    DateTime? at,
  }) =>
      repo.trigger(
        id: id,
        familyId: 'fam-1',
        childId: 'child-1',
        requestId: requestId,
        at: at ?? DateTime(2026, 9, 24, 12),
        lat: 24.7136,
        lon: 46.6753,
      );

  group('raising an alarm', () {
    test('a press creates one ACTIVE alarm carrying its location', () async {
      final alert = await raiseAlarm();

      expect(alert.status, SosStatus.active);
      expect(alert.familyId, 'fam-1');
      expect(alert.childId, 'child-1');
      expect(alert.requestId, 'req-1');
      expect(alert.lat, 24.7136);
      expect(alert.receivedAt, isNotNull, reason: 'contract DEFAULT now()');
      expect(alert.resolvedAt, isNull);
    });

    test('re-sending the same request is the same alarm, not a second one', () async {
      final first = await raiseAlarm();
      final again = await raiseAlarm(id: 'sos-2');

      expect(again.id, first.id, reason: 'منع الازدواج عند إعادة الإرسال');
      expect(await repo.historyInFamily('fam-1'), hasLength(1));
    });

    test('a different request is a different alarm', () async {
      await raiseAlarm();
      await raiseAlarm(id: 'sos-2', requestId: 'req-2');

      expect(await repo.historyInFamily('fam-1'), hasLength(2));
    });
  });

  group('lifecycle', () {
    test('acknowledging records who saw it, and is idempotent', () async {
      await raiseAlarm();

      final ack = await repo.acknowledge(
        'sos-1',
        byAccountId: 'parent-1',
        at: DateTime(2026, 9, 24, 12, 5),
      );

      expect(ack.status, SosStatus.acknowledged);
      expect(ack.acknowledgedBy, 'parent-1');
      expect(ack.acknowledgedAt, DateTime(2026, 9, 24, 12, 5));
      expect(ack.resolvedAt, isNull);

      final again = await repo.acknowledge(
        'sos-1',
        byAccountId: 'parent-2',
        at: DateTime(2026, 9, 24, 12, 30),
      );

      expect(again.status, SosStatus.acknowledged);
      expect(again.acknowledgedBy, 'parent-1',
          reason: 'a second tap does not rewrite who saw it first');
    });

    test('resolving closes the alarm and keeps the acknowledgement', () async {
      await raiseAlarm();
      await repo.acknowledge(
        'sos-1',
        byAccountId: 'parent-1',
        at: DateTime(2026, 9, 24, 12, 5),
      );

      final done = await repo.resolve(
        'sos-1',
        byAccountId: 'parent-1',
        at: DateTime(2026, 9, 24, 12, 20),
      );

      expect(done.status, SosStatus.resolved);
      expect(done.resolvedBy, 'parent-1');
      expect(done.resolvedAt, DateTime(2026, 9, 24, 12, 20));
      expect(done.acknowledgedBy, 'parent-1');
      expect(await repo.activeInFamily('fam-1'), isEmpty);
    });

    test('resolving twice changes nothing', () async {
      await raiseAlarm();

      await repo.resolve('sos-1',
          byAccountId: 'parent-1', at: DateTime(2026, 9, 24, 12, 20));
      final again = await repo.resolve('sos-1',
          byAccountId: 'parent-2', at: DateTime(2026, 9, 24, 12, 40));

      expect(again.resolvedBy, 'parent-1');
      expect(again.resolvedAt, DateTime(2026, 9, 24, 12, 20));
    });

    test('acknowledging a resolved alarm is refused', () async {
      await raiseAlarm();
      await repo.resolve('sos-1', byAccountId: 'parent-1');

      await expectLater(
        repo.acknowledge('sos-1', byAccountId: 'parent-2'),
        throwsA(isA<SosStateException>()),
      );
    });

    test('only ACTIVE alarms count as active', () async {
      await raiseAlarm();
      await raiseAlarm(id: 'sos-2', requestId: 'req-2');
      await repo.resolve('sos-1', byAccountId: 'parent-1');

      final active = await repo.activeInFamily('fam-1');

      expect(active, hasLength(1));
      expect(active.single.id, 'sos-2');
      expect(await repo.historyInFamily('fam-1'), hasLength(2));
    });

    test('an unknown alarm is refused rather than silently ignored', () async {
      await expectLater(
        repo.resolve('nope', byAccountId: 'parent-1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('the contract red line', () {
    test('an alarm cannot be deleted', () async {
      await raiseAlarm();

      await expectLater(repo.remove('sos-1'), throwsA(isA<UnsupportedError>()));
      expect(await repo.byId('sos-1'), isNotNull,
          reason: '«لا يُحذف أبدًا» — the refusal is the feature');
    });

    test('an alarm depends on no other row existing', () async {
      // No account, no family, no device, no permission — only the alarm.
      final alert = await raiseAlarm();

      expect(alert.status, SosStatus.active);
      expect(await repo.activeInFamily('fam-1'), hasLength(1));
    });
  });

  group('acceptance — an alarm survives a database reopen', () {
    test('trigger, close, reopen, still ACTIVE', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2c_sos');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        await DriftSosRepository(fileDb).trigger(
          id: 'sos-9',
          familyId: 'fam-1',
          childId: 'child-1',
          requestId: 'req-9',
          at: DateTime(2026, 9, 24, 12),
          lat: 24.7136,
          lon: 46.6753,
        );
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        final alert = await DriftSosRepository(fileDb).byId('sos-9');

        expect(alert, isNotNull);
        expect(alert!.status, SosStatus.active);
        expect(alert.requestId, 'req-9');
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
