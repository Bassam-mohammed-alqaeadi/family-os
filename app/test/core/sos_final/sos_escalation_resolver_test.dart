import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/core/sos_final/sos_escalation_resolver.dart';

void main() {
  group('SosEscalationResolver', () {
    const childId = 'kid_alpha';

    SosLadder ladderWith({
      required List<SosBackupContact> backups,
    }) =>
        SosLadder.defaults().copyWith(backups: backups);

    test('disabled prefs → empty plan (no outside contacts)', () {
      final plan = SosEscalationResolver.resolve(
        childId: childId,
        ladder: ladderWith(
          backups: const [
            SosBackupContact(
              id: 'uncle',
              name: 'Uncle',
              enabled: true,
              phoneE164: '+966555000111',
              verification: SosVerificationStatus.verified,
            ),
          ],
        ),
        settings: const SosLocalSettings(),
      );
      expect(plan.enabled, isFalse);
      expect(plan.contacts, isEmpty);
      expect(plan.willEscalateOutside, isFalse);
    });

    test('hard-skips unverified even when notifyTrustedBackups is on', () {
      final plan = SosEscalationResolver.resolve(
        childId: childId,
        ladder: ladderWith(
          backups: const [
            SosBackupContact(
              id: 'uncle',
              name: 'Uncle',
              enabled: true,
              phoneE164: '+966555000111',
              verification: SosVerificationStatus.unverified,
              priority: 1,
            ),
            SosBackupContact(
              id: 'aunt',
              name: 'Aunt',
              enabled: true,
              phoneE164: '+966555000222',
              verification: SosVerificationStatus.verified,
              priority: 2,
            ),
          ],
        ),
        settings: SosLocalSettings(
          childEscalation: {
            childId: const ChildSosEscalationPrefs(
              enabled: true,
              delaySeconds: 120,
              notifyTrustedBackups: true,
              prepareSmsFallback: true,
            ),
          },
        ),
      );
      expect(plan.enabled, isTrue);
      expect(plan.delaySeconds, 120);
      expect(plan.prepareSmsFallback, isTrue);
      expect(plan.contacts.map((c) => c.id), ['aunt']);
      expect(plan.willEscalateOutside, isTrue);
    });

    test('notifyTrustedBackups false → no contacts; SMS intent flag kept', () {
      final plan = SosEscalationResolver.resolve(
        childId: childId,
        ladder: ladderWith(
          backups: const [
            SosBackupContact(
              id: 'uncle',
              name: 'Uncle',
              enabled: true,
              verification: SosVerificationStatus.verified,
            ),
          ],
        ),
        settings: SosLocalSettings(
          childEscalation: {
            childId: const ChildSosEscalationPrefs(
              enabled: true,
              notifyTrustedBackups: false,
              prepareSmsFallback: true,
            ),
          },
        ),
      );
      expect(plan.contacts, isEmpty);
      expect(plan.prepareSmsFallback, isTrue);
      expect(plan.willEscalateOutside, isTrue);
    });
  });

  group('SosLadder priority reorder', () {
    test('movedBackup swaps priorities 1↔2', () {
      final ladder = SosLadder.defaults().copyWith(
        backups: const [
          SosBackupContact(id: 'a', name: 'A', priority: 1),
          SosBackupContact(id: 'b', name: 'B', priority: 2),
        ],
      );
      final next = ladder.movedBackup('b', -1);
      expect(next, isNotNull);
      expect(next!.backupsByPriority.map((c) => c.id), ['b', 'a']);
      expect(next.backupsByPriority.map((c) => c.priority), [1, 2]);
    });

    test('moveBackupPriority persists via InMemory repo', () async {
      final repo = InMemorySosLadderRepository({
        SosLadder.defaultFamilyId: SosLadder.defaults().copyWith(
          backups: const [
            SosBackupContact(id: 'a', name: 'A', priority: 1),
            SosBackupContact(id: 'b', name: 'B', priority: 2),
          ],
        ),
      });
      final next = await repo.moveBackupPriority('a', 1);
      expect(next.backupsByPriority.map((c) => c.id), ['b', 'a']);
    });
  });

  group('escalate consumes resolver plan', () {
    test('unverified hard-skipped on escalateEmergencyContacts', () async {
      final alert = InMemorySosAlertRepository.demoActive(
        id: 'a1',
        childId: 'kid_alpha',
        deliveries: const [],
      );
      final repo = InMemorySosAlertRepository(initialActive: alert);
      repo.bindEscalationSources(
        ladderLoader: () async => SosLadder.defaults().copyWith(
          backups: const [
            SosBackupContact(
              id: 'skip_me',
              name: 'Skip',
              enabled: true,
              verification: SosVerificationStatus.pending,
              priority: 1,
            ),
            SosBackupContact(
              id: 'ok',
              name: 'OK',
              enabled: true,
              verification: SosVerificationStatus.verified,
              priority: 2,
            ),
          ],
        ),
        settingsLoader: () => SosLocalSettings(
          childEscalation: {
            'kid_alpha': const ChildSosEscalationPrefs(
              enabled: true,
              notifyTrustedBackups: true,
              prepareSmsFallback: false,
            ),
          },
        ),
      );

      final next = await repo.escalateEmergencyContacts(
        'a1',
        actor: SosActor.primary(),
      );
      expect(next.status, SosAlertStatus.escalating);
      final ids = next.deliveries.map((d) => d.recipientId).toList();
      expect(ids, contains('ok'));
      expect(ids, isNot(contains('skip_me')));
      expect(repo.lastEscalationPlan?.contacts.map((c) => c.id), ['ok']);
    });
  });
}
