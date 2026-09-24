import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/audit_repository.dart';
import 'package:family_os/core/data/family_database.dart';

/// PERS-2d — the audit trail, and the one rule it lives by.
///
/// The contract says it in one line: "🔒 append-only — دليلنا عند أي مراجعة".
/// A trail that can be edited is not evidence, so the refusal is what is tested.
final DateTime _base = DateTime(2026, 9, 24, 12);

void main() {
  late FamilyDatabase db;
  late DriftAuditRepository repo;

  setUp(() {
    db = FamilyDatabase(NativeDatabase.memory());
    repo = DriftAuditRepository(db);
  });

  tearDown(() => db.close());

  Future<int> write({
    String? actorId = 'acc-parent',
    String action = 'MODE_UNLOCK',
    String? target,
    String detail = '{}',
    DateTime? at,
  }) =>
      repo.append(
        familyId: 'fam-1',
        action: action,
        actorId: actorId,
        target: target,
        detail: detail,
        at: at ?? _base,
      );

  test('an entry is appended with its actor, target and detail', () async {
    await write(target: 'child-1', detail: '{"reason":"forgot password"}');

    final trail = await repo.forFamily('fam-1');

    expect(trail, hasLength(1));
    expect(trail.single.action, 'MODE_UNLOCK');
    expect(trail.single.actor, 'acc-parent');
    expect(trail.single.target, 'child-1');
    expect(trail.single.detail, '{"reason":"forgot password"}');
    expect(trail.single.occurredAt, isNotNull);
  });

  test('a null actor means the system acted, not a person', () async {
    await write(actorId: null, action: 'AUTO_PRUNE');

    final trail = await repo.forFamily('fam-1');

    expect(trail.single.actor, isNull);
    expect(trail.single.action, 'AUTO_PRUNE');
  });

  test('the trail is newest-first', () async {
    await write(action: 'FIRST', at: _base);
    await write(action: 'SECOND', at: _base.add(const Duration(minutes: 1)));

    final trail = await repo.forFamily('fam-1');

    expect(trail.first.action, 'SECOND');
    expect(trail.last.action, 'FIRST');
  });

  test('entries are scoped by family and by actor', () async {
    await write();
    await write(actorId: 'acc-mother', action: 'FORGET_USED');
    await repo.append(
      familyId: 'fam-2',
      action: 'OTHER',
      actorId: 'acc-other',
    );

    expect(await repo.forFamily('fam-1'), hasLength(2));
    expect(await repo.forFamily('fam-2'), hasLength(1));

    final byMother = await repo.byActor('fam-1', 'acc-mother');
    expect(byMother, hasLength(1));
    expect(byMother.single.action, 'FORGET_USED');
  });

  test('malformed JSON is refused — the column is jsonb', () async {
    await expectLater(write(detail: 'not json'), throwsA(isA<ArgumentError>()));

    expect(await repo.forFamily('fam-1'), isEmpty);
  });

  group('append-only is enforced, not encouraged', () {
    test('update is refused and the entry is unchanged', () async {
      await write(action: 'ORIGINAL');

      await expectLater(
        repo.update(1, action: 'REWRITTEN'),
        throwsA(isA<UnsupportedError>()),
      );

      expect((await repo.forFamily('fam-1')).single.action, 'ORIGINAL');
    });

    test('delete is refused and the entry is still there', () async {
      await write(action: 'ORIGINAL');

      await expectLater(repo.delete(1), throwsA(isA<UnsupportedError>()));
      expect(await repo.forFamily('fam-1'), hasLength(1));
    });
  });

  group('acceptance — the trail survives a database reopen', () {
    test('append, close, reopen, read', () async {
      final dir = Directory.systemTemp.createTempSync('family_os_pers2d_audit');
      final file = File('${dir.path}/family_os.sqlite');

      try {
        var fileDb = FamilyDatabase(NativeDatabase(file));
        await DriftAuditRepository(fileDb).append(
          familyId: 'fam-1',
          action: 'PARENTAL_CONSENT',
          actorId: 'acc-parent',
          target: 'child-1',
          at: _base,
        );
        await fileDb.close();

        // A fresh handle over the same file — nothing shared in memory.
        fileDb = FamilyDatabase(NativeDatabase(file));
        final trail = await DriftAuditRepository(fileDb).forFamily('fam-1');

        expect(trail, hasLength(1));
        expect(trail.single.action, 'PARENTAL_CONSENT');
        await fileDb.close();
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
