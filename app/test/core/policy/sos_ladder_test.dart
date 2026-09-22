import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';

void main() {
  group('SosLadder rung-1 parents (SET-020)', () {
    test('defaults include father and mother on rung 1', () {
      final ladder = SosLadder.defaults();
      expect(ladder.rung1MemberIds, ['father', 'mother']);
      expect(ladder.isRung1Parent('mother'), isTrue);
      expect(ladder.isRung1Parent('father'), isTrue);
    });

    test('cannot remove mother from rung 1 — validation error', () async {
      final repo = InMemorySosLadderRepository();
      await expectLater(
        repo.removeFromRung1('mother'),
        throwsA(
          isA<SosLadderValidationException>().having(
            (e) => e.code,
            'code',
            SosLadderValidationCode.rung1ParentImmovable,
          ),
        ),
      );
      final ladder = await repo.load();
      expect(ladder.rung1MemberIds, contains('mother'));
    });

    test('cannot remove father from rung 1 — validation error', () async {
      final repo = InMemorySosLadderRepository();
      await expectLater(
        repo.removeFromRung1('father'),
        throwsA(isA<SosLadderValidationException>()),
      );
    });

    test('API rejects disable emergency contact for parent', () async {
      final repo = InMemorySosLadderRepository();
      await expectLater(
        repo.setEmergencyContactEnabled('mother', false),
        throwsA(
          isA<SosLadderValidationException>().having(
            (e) => e.code,
            'code',
            SosLadderValidationCode.rung1ParentDisableForbidden,
          ),
        ),
      );
      await expectLater(
        repo.setEmergencyContactEnabled('father', false),
        throwsA(isA<SosLadderValidationException>()),
      );
    });

    test('backups editable on lower rung — toggle + remove', () async {
      final repo = InMemorySosLadderRepository();
      await repo.upsertBackup(
        const SosBackupContact(
          id: 'uncle',
          name: 'عم',
          delaySeconds: 60,
        ),
      );

      var ladder = await repo.load();
      expect(ladder.backups, hasLength(1));
      expect(ladder.backups.first.enabled, isTrue);

      ladder = await repo.setEmergencyContactEnabled('uncle', false);
      expect(ladder.backups.single.enabled, isFalse);

      ladder = await repo.removeBackup('uncle');
      expect(ladder.backups, isEmpty);
      expect(ladder.rung1MemberIds, ['father', 'mother']);
    });

    test('PrefsSosLadderRepository round-trip + reject remove mother', () async {
      final store = MemorySosLadderStore();
      final repo = PrefsSosLadderRepository(store);
      await repo.upsertBackup(
        const SosBackupContact(id: 'ec1', name: 'Backup'),
      );
      final loaded = await PrefsSosLadderRepository(store).load();
      expect(loaded.backups.single.id, 'ec1');
      expect(loaded.rung1MemberIds, containsAll(['father', 'mother']));

      await expectLater(
        repo.removeFromRung1('mother'),
        throwsA(isA<SosLadderValidationException>()),
      );
    });
  });
}
