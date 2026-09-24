import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/fs_foundation/capability_registry.dart';
import 'package:family_os/core/fs_foundation/capability_status.dart';
import 'package:family_os/core/fs_foundation/local_database.dart';
import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_ladder.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';
import 'package:family_os/core/policy/sos_settings.dart';
import 'package:family_os/core/sos_final/sos_final.dart';

void main() {
  late MemoryLocalDatabase db;
  late LocalSosFinalStore store;
  late CapabilityRegistry capabilities;
  final family = FamilyId('fam_sos');
  final child = ChildId('child_a');
  final now = DateTime.utc(2026, 9, 24, 12, 0);

  setUp(() async {
    db = MemoryLocalDatabase();
    await db.open();
    expect(await db.schemaVersion(), FamilyLocalSchema.currentVersion);
    store = LocalSosFinalStore(db);
    capabilities = CapabilityRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('schema v9 exposes sos_final tables', () async {
    expect(FamilyLocalSchema.currentVersion, 10);
    await db.insert('sos_incident', {
      'id': 'x',
      'family_id': family.value,
      'child_id': child.value,
      'status': 'active',
      'terminal_reason': null,
      'triggered_at': 1,
      'acknowledged_at': null,
      'acknowledged_by': null,
      'resolved_at': null,
      'resolved_by': null,
      'trigger_source': 'hold',
      'location_class': 'acquiring',
      'connection_class': 'online',
      'battery_percent': 50,
      'panic_quiet_at_trigger': 0,
      'evidence_retain_until': 2,
      'deliveries_json': '[]',
      'child_display_name': '',
      'child_emoji': '',
      'location_label': '',
    });
    expect((await db.query('sos_incident')).length, 1);
  });

  test('fire → ack → escalate → resolve retains core + audit', () async {
    var idSeq = 0;
    final svc = SosFinalService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'sos_${++idSeq}',
    );

    final fired = await svc.fireHold(
      childId: child,
      batteryPercent: 72,
      locationSampleJson: '{"lat":24.7,"lon":46.6}',
    );
    expect(fired.status, SosAlertStatus.active);
    expect(fired.triggerSource, SosTriggerSource.hold);
    expect(
      fired.evidenceRetainUntil,
      SosEvidencePolicy.retainUntilFrom(now),
    );

    final acked = await svc.acknowledge(
      incidentId: fired.id,
      actor: SosActor.primary(),
      actorId: 'father',
    );
    expect(acked.status, SosAlertStatus.acknowledged);
    expect(acked.acknowledgedBy, 'father');

    final esc = await svc.escalate(
      incidentId: fired.id,
      actor: SosActor.mother(MotherLevel.partner),
      actorId: 'mother',
    );
    expect(esc.status, SosAlertStatus.escalating);

    final closed = await svc.resolve(
      incidentId: fired.id,
      actor: SosActor.primary(),
      actorId: 'father',
      reason: SosTerminalReason.helped,
    );
    expect(closed.status, SosAlertStatus.resolved);
    expect(closed.terminalReason, SosTerminalReason.helped);

    // OD-18: resolve does not delete core.
    final still = await store.loadById(fired.id);
    expect(still, isNotNull);
    expect(still!.isResolved, isTrue);

    final audit = await svc.auditTrail(fired.id);
    expect(audit.map((e) => e.eventType), containsAll([
      SosAuditEventType.fired,
      SosAuditEventType.acknowledged,
      SosAuditEventType.escalating,
      SosAuditEventType.resolved,
    ]));

    final ops = await svc.opsSamples(fired.id);
    expect(ops.any((s) => s.kind == SosOpsSampleKind.location), isTrue);
    expect(ops.any((s) => s.kind == SosOpsSampleKind.deviceBattery), isTrue);
  });

  test('child cancel false-alarm; observer cannot ack', () async {
    var idSeq = 0;
    final svc = SosFinalService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'sos_c_${++idSeq}',
    );
    final fired = await svc.fireHold(childId: child);

    expect(
      () => svc.acknowledge(
        incidentId: fired.id,
        actor: SosActor.mother(MotherLevel.observer),
        actorId: 'obs',
      ),
      throwsStateError,
    );

    final cancelled = await svc.cancelFalseAlarm(
      incidentId: fired.id,
      actor: SosActor.child(),
      actorId: child.value,
    );
    expect(cancelled.terminalReason, SosTerminalReason.falseAlarm);
    final audit = await svc.auditTrail(fired.id);
    expect(
      audit.any((e) => e.eventType == SosAuditEventType.cancelled),
      isTrue,
    );
  });

  test('ops purge after 90d; audit retained', () async {
    var idSeq = 0;
    final svc = SosFinalService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'sos_p_${++idSeq}',
    );
    final fired = await svc.fireHold(
      childId: child,
      locationSampleJson: '{}',
    );
    expect(await svc.opsSamples(fired.id), isNotEmpty);

    final purged = await svc.purgeExpiredOps(
      now: now.add(const Duration(days: 91)),
    );
    expect(purged, greaterThan(0));
    expect(await svc.opsSamples(fired.id), isEmpty);
    expect(await store.loadById(fired.id), isNotNull);
    expect(await svc.auditTrail(fired.id), isNotEmpty);
  });

  test('break-glass allowlist + RBAC; forbidden rejected', () async {
    var idSeq = 0;
    final svc = SosFinalService(
      store: store,
      familyId: family,
      clock: () => now,
      idFactory: () => 'sos_bg_${++idSeq}',
    );
    final fired = await svc.fireHold(childId: child);

    expect(
      () => svc.startBreakGlass(
        incidentId: fired.id,
        actor: SosActor.mother(MotherLevel.partner),
        actorId: 'partner',
        capabilityId: 'lock_shell_bypass',
        reason: 'need map',
      ),
      throwsStateError,
    );

    expect(
      () => svc.startBreakGlass(
        incidentId: fired.id,
        actor: SosActor.primary(),
        actorId: 'father',
        capabilityId: 'unlock_everything',
        reason: 'nope',
      ),
      throwsStateError,
    );

    final row = await svc.startBreakGlass(
      incidentId: fired.id,
      actor: SosActor.mother(MotherLevel.full),
      actorId: 'mother',
      capabilityId: 'lock_shell_bypass',
      reason: 'respond to child',
    );
    expect(row['phase'], 'overrideActive');
    expect(SosBreakGlassAllowlist.isAllowed('lock_shell_bypass'), isTrue);

    final ended = await svc.expireBreakGlass(sessionId: row['id']! as String);
    expect(ended['phase'], 'expired');
  });

  test('readiness never claims ready without push or fallbacks', () {
    final snap = SosReadinessEvaluator.evaluate(
      SosReadinessInputs(
        ladder: SosLadder.defaults(familyId: family.value),
        settings: const SosLocalSettings(),
        pushCapability: CapabilityStatus.notImplemented,
        smsConfigured: false,
        callConfigured: false,
        locationClass: SosLocationClass.unavailable,
      ),
      clock: () => now,
    );
    expect(snap.claimsReady, isFalse);

    final ok = SosReadinessEvaluator.evaluate(
      SosReadinessInputs(
        ladder: SosLadder.defaults(familyId: family.value),
        settings: const SosLocalSettings(panicQuietPreferred: true),
        pushCapability: CapabilityStatus.mockRemote,
        smsConfigured: true,
        locationClass: SosLocationClass.ready,
      ),
      clock: () => now,
    );
    // Location unavailable would fail; ready + degraded push + SMS OK.
    expect(ok.claimsReady, isTrue);
    expect(
      ok.rows.any((r) => r.id == 'panic_quiet'),
      isTrue,
    );
  });

  test('applyFs006LifeCapabilities marks lifecycle/evidence/readiness', () async {
    await capabilities.applyFs006LifeCapabilities();
    expect(
      (await capabilities.get('fs006.sos_lifecycle'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs006.evidence_retention'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs006.readiness'))!.status,
      CapabilityStatus.implemented,
    );
    expect(
      (await capabilities.get('fs006.remote_delivery'))!.status,
      CapabilityStatus.mockRemote,
    );
  });
}
