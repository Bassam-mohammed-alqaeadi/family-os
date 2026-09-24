import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/app_control/app_control.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/policy/app_access_rules.dart';
import 'package:family_os/core/policy/app_access_rules_repository.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalAppControlStore store;
  late LocalAppAccessExceptionStore exceptions;
  late LocalAppLockNowStore lockNow;
  late LocalAppInstallTicketStore installs;
  late AppControlService service;
  final family = FamilyId('fam_ac');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 18);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalAppControlStore(db, clock: () => now);
    exceptions = LocalAppAccessExceptionStore(db);
    lockNow = LocalAppLockNowStore(db);
    installs = LocalAppInstallTicketStore(db);
    service = AppControlService(
      documents: store,
      exceptions: exceptions,
      lockNow: lockNow,
      installs: installs,
      familyId: family,
      clock: () => now,
      idFactory: () => 'ac-test-1',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('schema v6 exposes ac_document + overlays', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('ac_document', {
      'scope_key': 'family',
      'family_id': family.value,
      'child_id': null,
      'dispositions_json': '{}',
      'policy_version': 1,
      'updated_at': 1,
    });
    expect((await db.query('ac_document')).length, 1);
  });

  test('APP-OD-01 child override wins over family baseline', () async {
    await store.save(
      AppControlDocument(
        familyId: family,
        scopeKind: AppControlScopeKind.familyBaseline,
        dispositions: {'minecraft': AppPackageDisposition.allow},
      ),
    );
    await store.save(
      AppControlDocument(
        familyId: family,
        scopeKind: AppControlScopeKind.childOverride,
        childId: child,
        dispositions: {'minecraft': AppPackageDisposition.block},
      ),
    );
    final effective = await store.loadEffective(family, child);
    expect(effective.scopeKind, AppControlScopeKind.childOverride);
    expect(effective.dispositionOf('minecraft'), AppPackageDisposition.block);
  });

  test('protected packages cannot be denied', () async {
    final doc = AppControlDocument(
      familyId: family,
      scopeKind: AppControlScopeKind.childOverride,
      childId: child,
      dispositions: {
        ProtectedPackageIds.quran: AppPackageDisposition.block,
        'tiktok': AppPackageDisposition.block,
      },
    );
    expect(
      doc.dispositionOf(ProtectedPackageIds.quran),
      AppPackageDisposition.allow,
    );

    final v = AppControlEngine.decide(
      packageId: ProtectedPackageIds.quran,
      document: doc,
    );
    expect(v.allowed, isTrue);
    expect(v.allowSource, AppControlAllowSource.protected);

    expect(
      () => service.setPermanentBlock(
        childId: child,
        packageId: 'quran',
        actor: const AppControlActor.father(),
      ),
      throwsStateError,
    );
  });

  test('exception allows without rewriting Permanent Block', () async {
    await service.setPermanentBlock(
      childId: child,
      packageId: 'roblox',
      actor: const AppControlActor.father(),
    );
    final before = await store.loadEffective(family, child);
    expect(before.dispositionOf('roblox'), AppPackageDisposition.block);

    final req = await service.requestException(
      childId: child,
      packageId: 'roblox',
    );
    final active = await service.approveException(
      exceptionId: req.id,
      childId: child,
      actor: const AppControlActor.mother(MotherLevel.partner),
    );
    expect(active.status, AppAccessExceptionStatus.active);
    expect(active.isActiveAt(now), isTrue);

    final after = await store.loadEffective(family, child);
    expect(after.dispositionOf('roblox'), AppPackageDisposition.block);

    final verdict = AppControlEngine.decide(
      packageId: 'roblox',
      document: after,
      exceptionActive: true,
    );
    expect(verdict.allowed, isTrue);
    expect(verdict.allowSource, AppControlAllowSource.exception);
    expect(verdict.underlyingDisposition, AppPackageDisposition.block);
  });

  test('Lock Now denies independently of Permanent Block', () async {
    await service.setDisposition(
      childId: child,
      packageId: 'youtube',
      disposition: AppPackageDisposition.allow,
      actor: const AppControlActor.father(),
    );
    await service.lockNow(
      childId: child,
      packageId: 'youtube',
      actor: const AppControlActor.father(),
    );
    final doc = await store.loadEffective(family, child);
    final v = AppControlEngine.decide(
      packageId: 'youtube',
      document: doc,
      lockNowActive: true,
    );
    expect(v.isDenied, isTrue);
    expect(v.denySource, AppControlDenySource.lockNow);
    expect(doc.dispositionOf('youtube'), AppPackageDisposition.allow);
  });

  test(
    'unknown package deny-until-approved; install approve is child-scoped',
    () async {
      final baseline = AppControlDocument.familyDefaults(family);
      final unknown = AppControlEngine.decide(
        packageId: 'new.game',
        document: baseline,
      );
      expect(unknown.isDenied, isTrue);
      expect(unknown.denySource, AppControlDenySource.pendingUnknown);

      final ticket = await service.observeInstall(
        childId: child,
        packageId: 'new.game',
        label: 'New Game',
      );
      await service.approveInstall(
        ticketId: ticket.id,
        childId: child,
        actor: const AppControlActor.father(),
      );
      final childDoc = await store.loadChildOverride(family, child);
      expect(childDoc!.dispositionOf('new.game'), AppPackageDisposition.allow);
      final familyDoc = await store.loadFamilyBaseline(family);
      expect(familyDoc?.dispositionOf('new.game'), isNull);
    },
  );

  test('only Primary reopens Permanent Block', () async {
    await service.setPermanentBlock(
      childId: child,
      packageId: 'tiktok',
      actor: const AppControlActor.mother(MotherLevel.full),
    );
    expect(
      () => service.reopenPermanentBlock(
        childId: child,
        packageId: 'tiktok',
        actor: const AppControlActor.mother(MotherLevel.full),
      ),
      throwsStateError,
    );
    await service.reopenPermanentBlock(
      childId: child,
      packageId: 'tiktok',
      actor: const AppControlActor.father(),
    );
    final doc = await store.loadEffective(family, child);
    expect(doc.dispositionOf('tiktok'), AppPackageDisposition.allow);
  });

  test(
    'DomainAppAccessRulesRepository AC owns blocked; ST keeps axes',
    () async {
      final st = InMemoryAppAccessRulesRepository({
        child.value: AppAccessRuleSet(
          childId: child,
          rules: const [
            AppAccessRule(
              appId: 'minecraft',
              blocked: false,
              limitMinutes: 60,
              unlimited: true,
            ),
          ],
        ),
      });
      final adapter = DomainAppAccessRulesRepository(
        store,
        familyId: family,
        stAxes: st,
      );

      await adapter.save(
        child,
        AppAccessRuleSet(
          childId: child,
          rules: const [
            AppAccessRule(
              appId: 'minecraft',
              blocked: true,
              limitMinutes: 60,
              unlimited: true,
            ),
          ],
        ),
      );

      final ac = await store.loadEffective(family, child);
      expect(ac.dispositionOf('minecraft'), AppPackageDisposition.block);

      final stSaved = await st.load(child);
      expect(stSaved.ruleFor('minecraft')!.blocked, isFalse);
      expect(stSaved.ruleFor('minecraft')!.limitMinutes, 60);
      expect(stSaved.ruleFor('minecraft')!.unlimited, isTrue);

      final merged = await adapter.load(child);
      expect(merged.ruleFor('minecraft')!.blocked, isTrue);
      expect(merged.ruleFor('minecraft')!.limitMinutes, 60);
      expect(merged.ruleFor('minecraft')!.unlimited, isTrue);
    },
  );

  test(
    'applyFs003OwnCapabilities upgrades honesty without faking intercept',
    () async {
      final caps = CapabilityRegistry(db);
      await caps.applyFs003OwnCapabilities();
      expect(
        (await caps.get('fs003.app_dispositions'))!.status,
        CapabilityStatus.implemented,
      );
      expect(
        (await caps.get('fs003.protected_packages'))!.status,
        CapabilityStatus.implemented,
      );
      expect(
        (await caps.get('fs003.app_exception'))!.status,
        CapabilityStatus.implemented,
      );
      expect(
        (await caps.get('fs003.os_intercept'))!.status,
        CapabilityStatus.mockRemote,
      );
    },
  );
}
