import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/family_database.dart';
import 'package:family_os/core/data/permission_policy.dart';
import 'package:family_os/core/data/permission_repository.dart';

/// PERS-2b — ADR-050 as observable behaviour.
///
/// Two halves: the rows keep the *observed* state (and keep the two denials
/// apart), and the policy turns that state into a decision.
void main() {
  group('permission rows (observed state, never assumed)', () {
    late FamilyDatabase db;
    late DriftPermissionRepository repo;

    setUp(() {
      db = FamilyDatabase(NativeDatabase.memory());
      repo = DriftPermissionRepository(db);
    });

    tearDown(() => db.close());

    test('every contract status round-trips as its own label', () async {
      const expected = {
        PermStatus.notAsked: 'NOT_ASKED',
        PermStatus.granted: 'GRANTED',
        PermStatus.deniedSoft: 'DENIED_SOFT',
        PermStatus.deniedPermanent: 'DENIED_PERMANENT',
        PermStatus.restrictedByOs: 'RESTRICTED_BY_OS',
        PermStatus.notApplicable: 'NOT_APPLICABLE',
      };

      for (final entry in expected.entries) {
        await repo.setStatus(
          deviceId: 'dev-1',
          key: PermKey.usageStats,
          status: entry.key,
        );
        final row = await repo.get('dev-1', PermKey.usageStats);
        expect(row!.status, entry.key);
        expect(
          PermStatusConverter().toSql(entry.key),
          entry.value,
          reason: 'ADR-050 added the two denial states to the SQL type',
        );
      }
    });

    test('a soft denial and a permanent denial stay distinct', () async {
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.accessibility,
        status: PermStatus.deniedSoft,
      );
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.usageStats,
        status: PermStatus.deniedPermanent,
      );

      final soft = await repo.get('dev-1', PermKey.accessibility);
      final hard = await repo.get('dev-1', PermKey.usageStats);

      expect(soft!.status, PermStatus.deniedSoft);
      expect(hard!.status, PermStatus.deniedPermanent);
      expect(
        soft.status == hard.status,
        isFalse,
        reason: 'the whole point of ADR-050: the two denials differ',
      );
    });

    test('(device, key) is the identity — a re-check updates in place', () async {
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.notifications,
        status: PermStatus.notAsked,
      );
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.notifications,
        status: PermStatus.granted,
      );

      final rows = await repo.forDevice('dev-1');

      expect(rows, hasLength(1));
      expect(rows.single.status, PermStatus.granted);
    });

    test('rows are scoped to their device', () async {
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.autostart,
        status: PermStatus.deniedSoft,
      );
      await repo.setStatus(
        deviceId: 'dev-2',
        key: PermKey.autostart,
        status: PermStatus.granted,
      );

      expect(await repo.forDevice('dev-1'), hasLength(1));
      expect(await repo.forDevice('dev-2'), hasLength(1));
    });

    test('missingFor is exactly the device-health list', () async {
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.usageStats,
        status: PermStatus.granted,
      );
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.accessibility,
        status: PermStatus.deniedPermanent,
      );
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.screenTimeIos,
        status: PermStatus.notApplicable,
      );
      await repo.setStatus(
        deviceId: 'dev-1',
        key: PermKey.batteryUnrestricted,
        status: PermStatus.deniedSoft,
      );

      final missing = await repo.missingFor('dev-1');

      expect(
        missing.map((r) => r.permKey),
        [PermKey.accessibility, PermKey.batteryUnrestricted],
        reason: 'granted and not-applicable are not "missing to fix"',
      );
    });
  });

  group('ADR-050 policy', () {
    test('rule 1 — the core-at-launch whitelist is empty', () {
      expect(
        kCoreAtLaunch,
        isEmpty,
        reason: 'no permission is requested at startup; exceptions are named',
      );
    });

    test('routes: Android special access vs runtime vs iOS', () {
      expect(
        PermissionPolicy.routeFor(PermKey.usageStats, platform: 'android'),
        PermissionRoute.specialAppAccess,
      );
      expect(
        PermissionPolicy.routeFor(PermKey.accessibility, platform: 'android'),
        PermissionRoute.specialAppAccess,
      );
      expect(
        PermissionPolicy.routeFor(PermKey.locationFg, platform: 'android'),
        PermissionRoute.runtimeDialog,
      );
      expect(
        PermissionPolicy.routeFor(PermKey.screenTimeIos, platform: 'ios'),
        PermissionRoute.platformAuthorization,
      );
      expect(
        PermissionPolicy.routeFor(PermKey.usageStats, platform: 'ios'),
        PermissionRoute.notOnPlatform,
      );
      expect(
        PermissionPolicy.routeFor(PermKey.locationFg, platform: 'ios'),
        PermissionRoute.runtimeDialog,
        reason: 'Core Location is real on iOS — not not-applicable',
      );
    });

    test('rule 3 — a hard denial is never re-asked', () {
      for (final status in [
        PermStatus.deniedPermanent,
        PermStatus.restrictedByOs,
      ]) {
        expect(
          PermissionPolicy.actionFor(
            status,
            userInitiated: true,
            rationaleAvailable: true,
          ),
          PermissionAction.routeToHealthOnly,
          reason: 'Android will not show the dialog again: $status',
        );
      }
    });

    test('a soft denial allows exactly one re-ask, and only in context', () {
      expect(
        PermissionPolicy.actionFor(
          PermStatus.deniedSoft,
          userInitiated: true,
          rationaleAvailable: true,
        ),
        PermissionAction.reaskOnce,
      );
      expect(
        PermissionPolicy.actionFor(
          PermStatus.deniedSoft,
          userInitiated: true,
          rationaleAvailable: false,
        ),
        PermissionAction.routeToHealthOnly,
        reason: 'no rationale window = nothing to show',
      );
      expect(
        PermissionPolicy.actionFor(
          PermStatus.deniedSoft,
          userInitiated: false,
          rationaleAvailable: true,
        ),
        PermissionAction.routeToHealthOnly,
        reason: 'never on screen entry — only on a user-initiated action',
      );
    });

    test('granted and not-asked behave as expected', () {
      expect(
        PermissionPolicy.actionFor(PermStatus.granted),
        PermissionAction.nothing,
      );
      expect(
        PermissionPolicy.actionFor(PermStatus.notAsked),
        PermissionAction.askInContext,
      );
      expect(
        PermissionPolicy.actionFor(PermStatus.notApplicable),
        PermissionAction.notApplicable,
      );
    });

    test('rule 4 — a key that does not exist on the platform is not a denial', () {
      expect(
        PermissionPolicy.statusFor(
          PermKey.screenTimeIos,
          platform: 'android',
          observed: PermStatus.granted,
        ),
        PermStatus.notApplicable,
        reason: 'ADR-045: nothing for the parent to fix',
      );
      expect(
        PermissionPolicy.statusFor(
          PermKey.usageStats,
          platform: 'android',
          observed: PermStatus.deniedSoft,
        ),
        PermStatus.deniedSoft,
      );
    });

    test('healthRows keeps a stable order', () {
      expect(
        PermissionPolicy.healthRows([
          PermKey.usageStats,
          PermKey.accessibility,
        ]),
        [PermKey.accessibility, PermKey.usageStats],
        reason: 'sorted by enum declaration order, not by insertion',
      );
    });
  });
}
