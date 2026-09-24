import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/fs_foundation/policy_delivery.dart';
import 'package:family_os/core/web_filter/web_filter_delivery.dart';
import 'package:family_os/core/web_filter/web_filter_enforcement.dart';
import 'package:family_os/core/web_filter/web_filter_temp_allow.dart';
import 'package:family_os/core/web_filter/web_filter_temp_allow_store.dart';

void main() {
  late MemoryLocalDatabase db;
  final family = FamilyId('fam_enf');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 18);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema v5 exposes wf_temp_allow', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('wf_temp_allow', {
      'id': 'ta1',
      'family_id': family.value,
      'child_id': child.value,
      'host': 'x.example',
      'request_id': 'r1',
      'starts_at': now.millisecondsSinceEpoch,
      'expires_at': now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
      'status': 'active',
    });
    expect((await db.query('wf_temp_allow')).length, 1);
  });

  test('delivery tracker Configured→Verified without claiming native', () async {
    final tracker = WebFilterDeliveryTracker(db, clock: () => now);
    final started = await tracker.onPolicySaved(
      scopeKey: 'child:${child.value}',
      policyVersion: 2,
    );
    expect(started.phase, PolicyDeliveryPhase.configured);

    final verified = await tracker.simulateLocalAckToVerified(
      'child:${child.value}',
    );
    expect(verified.phase, PolicyDeliveryPhase.verified);
    expect(verified.isVerified, isTrue);

    final claim = WebFilterEnforcementClaim(
      availability: WebFilterEnforcementAvailability.enforced,
      deliveryVerified: verified.isVerified,
      nativePlaneMockRemote: true,
    );
    // MOCK-REMOTE native plane forbids "enforced" claim even if delivery verified.
    expect(claim.mayClaimEnforced, isFalse);
  });

  test('campaign baseline never claims enforced', () {
    final claim = WebFilterEnforcementClaim.campaignBaseline(
      deliveryVerified: true,
    );
    expect(claim.mayClaimEnforced, isFalse);
    expect(claim.availability, WebFilterEnforcementAvailability.degraded);
  });

  test('temp allow expires and drops from activeHosts', () async {
    final store = LocalWebFilterTempAllowStore(db, clock: () => now);
    await store.save(
      WebFilterTempAllow(
        id: 'ta_exp',
        familyId: family,
        childId: child,
        host: 'temp.example',
        requestId: 'r_exp',
        startsAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(minutes: 1)),
        status: WebFilterTempAllowStatus.active,
      ),
    );
    final hosts = await store.activeHosts(family, child, now: now);
    expect(hosts, isEmpty);
    final listed = await store.listForChild(family, child);
    expect(listed.single.status, WebFilterTempAllowStatus.expired);
  });

  test('applyFs002EnfCapabilities upgrades delivery + timed unlock', () async {
    final registry = CapabilityRegistry(db, clock: () => now);
    await registry.ensureSeeded();
    await registry.applyFs002EnfCapabilities();
    expect(
      (await registry.get('fs002.delivery_plane'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs002.timed_unlock'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await registry.get('fs002.native_block'))!.status,
      CapabilityStatus.mockRemote,
    );
  });
}
