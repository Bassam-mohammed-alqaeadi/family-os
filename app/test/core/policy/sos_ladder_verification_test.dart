import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';

void main() {
  group('Sos ladder verification / max 5 / priority', () {
    test('rejects more than 5 backups', () async {
      final repo = InMemorySosLadderRepository();
      for (var i = 1; i <= 5; i++) {
        await repo.upsertBackup(
          SosBackupContact(
            id: 'b$i',
            name: 'Backup $i',
            priority: i,
            verification: SosVerificationStatus.verified,
          ),
        );
      }
      expect(
        () => repo.upsertBackup(
          const SosBackupContact(
            id: 'b6',
            name: 'Too many',
            priority: 1,
          ),
        ),
        throwsA(
          isA<SosLadderValidationException>().having(
            (e) => e.code,
            'code',
            SosLadderValidationCode.backupLimitExceeded,
          ),
        ),
      );
    });

    test('rejects priority outside 1..5', () async {
      final repo = InMemorySosLadderRepository();
      expect(
        () => repo.upsertBackup(
          const SosBackupContact(
            id: 'bad',
            name: 'Bad',
            priority: 9,
          ),
        ),
        throwsA(
          isA<SosLadderValidationException>().having(
            (e) => e.code,
            'code',
            SosLadderValidationCode.priorityOutOfRange,
          ),
        ),
      );
    });

    test('phone change forces UNVERIFIED', () {
      const c = SosBackupContact(
        id: 'b1',
        name: 'Aunt',
        phoneE164: '+966500000001',
        verification: SosVerificationStatus.verified,
        priority: 1,
      );
      final next = c.withPhoneChanged('+966500000002');
      expect(next.verification, SosVerificationStatus.unverified);
      expect(next.phoneE164, '+966500000002');
    });

    test('verified-only escalation helper', () async {
      final repo = InMemorySosLadderRepository();
      await repo.upsertBackup(
        const SosBackupContact(
          id: 'v1',
          name: 'Verified',
          priority: 1,
          verification: SosVerificationStatus.verified,
        ),
      );
      await repo.upsertBackup(
        const SosBackupContact(
          id: 'u1',
          name: 'Unverified',
          priority: 2,
          verification: SosVerificationStatus.unverified,
        ),
      );
      final ladder = await repo.load();
      expect(ladder.verifiedEscalationBackups.map((b) => b.id), ['v1']);
    });

    test('verification lifecycle values exist', () {
      expect(SosVerificationStatus.values, containsAll([
        SosVerificationStatus.unverified,
        SosVerificationStatus.pending,
        SosVerificationStatus.verified,
        SosVerificationStatus.revoked,
        SosVerificationStatus.failed,
      ]));
    });
  });
}
