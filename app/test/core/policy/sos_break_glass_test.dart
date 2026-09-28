import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/sos_break_glass.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_ladder_repository.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';

void main() {
  group('SosBreakGlass', () {
    test('Primary can start; Partner denied', () async {
      final store = InMemorySosBreakGlassStore();
      final now = DateTime.now().toUtc();
      final session = await store.start(
        actor: SosActor.primary(),
        capabilityKey: 'sos_response_override',
        reason: 'device offline test',
        duration: const Duration(minutes: 30),
        now: now,
      );
      expect(session.phase, SosBreakGlassPhase.overrideActive);
      expect(store.active, isNotNull);

      await expectLater(
        store.start(
          actor: SosActor.mother(MotherLevel.partner),
          capabilityKey: 'sos_response_override',
          reason: 'nope',
          duration: const Duration(minutes: 5),
          now: now,
        ),
        throwsStateError,
      );
    });

    test('Mother Full allowed; Observer denied', () async {
      final store = InMemorySosBreakGlassStore();
      await expectLater(
        store.start(
          actor: SosActor.mother(MotherLevel.full),
          capabilityKey: 'sos_response_override',
          reason: 'ok',
          duration: const Duration(minutes: 10),
        ),
        completes,
      );
      await expectLater(
        InMemorySosBreakGlassStore().start(
          actor: SosActor.mother(MotherLevel.observer),
          capabilityKey: 'x',
          reason: 'no',
          duration: const Duration(minutes: 1),
        ),
        throwsStateError,
      );
    });

    test('expiry clears active without mutating ladder policy', () async {
      final store = InMemorySosBreakGlassStore();
      final ladderRepo = InMemorySosLadderRepository();
      final before = await ladderRepo.load();

      final now = DateTime.now().toUtc();
      await store.start(
        actor: SosActor.primary(),
        capabilityKey: 'sos_response_override',
        reason: 'temp',
        duration: const Duration(minutes: 5),
        now: now,
      );

      // Force expiry by checking after expiresAt.
      final expiredCheck = store.active;
      // Manually age: start with past expiry
      store.clear();
      await store.start(
        actor: SosActor.primary(),
        capabilityKey: 'sos_response_override',
        reason: 'temp',
        duration: const Duration(milliseconds: 1),
        now: DateTime.utc(2020, 1, 1),
      );
      expect(store.active, isNull); // expired on read
      expect(expiredCheck, isNotNull); // prior session was active at create time

      final after = await ladderRepo.load();
      expect(after, before); // permanent policy untouched
      expect(before.backups, isEmpty);
    });

    test('revoke ends override; audit retained', () async {
      final store = InMemorySosBreakGlassStore();
      await store.start(
        actor: SosActor.primary(),
        capabilityKey: 'sos_response_override',
        reason: 'temp',
        duration: const Duration(minutes: 5),
      );
      await store.revoke(note: 'manual');
      expect(store.active, isNull);
      expect(store.auditLog, isNotEmpty);
      expect(
        store.auditLog.last.phase,
        SosBreakGlassPhase.revoked,
      );
    });

    test('break-glass does not add national emergency numbers', () {
      // Structural: ladder model has no national number field.
      const ladder = SosLadder(familyId: 'default');
      final json = ladder.toJson();
      expect(json.containsKey('nationalEmergencyNumber'), isFalse);
      expect(json.containsKey('audioVideo'), isFalse);
    });
  });
}
