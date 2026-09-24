import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/policy/sos_alert.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';

import 'sos_break_glass_allowlist.dart';
import 'sos_evidence_policy.dart';
import 'sos_final_store.dart';
import 'sos_incident.dart';
import 'sos_lifecycle_engine.dart';
import 'sos_readiness.dart';

/// Coordinates SOS Final lifecycle + evidence + break-glass (FS-006-LIFE).
final class SosFinalService {
  SosFinalService({
    required SosFinalRepository store,
    required this.familyId,
    DateTime Function()? clock,
    String Function()? idFactory,
  })  : _store = store,
        _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _defaultId;

  final SosFinalRepository _store;
  final FamilyId familyId;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'sos_$_seq';
  }

  Future<SosIncident?> loadOpen({ChildId? childId}) =>
      _store.loadOpen(familyId: familyId, childId: childId);

  Future<SosIncident?> loadById(String incidentId) =>
      _store.loadById(incidentId);

  Future<List<SosLifecycleAuditEntry>> auditTrail(String incidentId) =>
      _store.listAudit(incidentId);

  Future<List<SosOpsSample>> opsSamples(String incidentId) =>
      _store.listOpsSamples(incidentId);

  /// Child HOLD complete → durable ACTIVE + audit + ops snapshot.
  Future<SosIncident> fireHold({
    required ChildId childId,
    SosLocationClass locationClass = SosLocationClass.acquiring,
    SosConnectionClass connectionClass = SosConnectionClass.online,
    int batteryPercent = 0,
    bool panicQuietAtTrigger = false,
    String deliveriesJson = '[]',
    String childDisplayName = '',
    String childEmoji = '',
    String locationLabel = '',
    String? locationSampleJson,
  }) async {
    final open = await _store.loadOpen(familyId: familyId, childId: childId);
    SosLifecycleEngine.assertCanFire(alreadyOpen: open != null);
    final now = _clock().toUtc();
    final id = _idFactory();
    final incident = SosIncident.fire(
      id: id,
      familyId: familyId,
      childId: childId,
      triggeredAt: now,
      locationClass: locationClass,
      connectionClass: connectionClass,
      batteryPercent: batteryPercent,
      panicQuietAtTrigger: panicQuietAtTrigger,
      deliveriesJson: deliveriesJson,
      childDisplayName: childDisplayName,
      childEmoji: childEmoji,
      locationLabel: locationLabel,
    );
    await _store.saveIncident(incident);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${id}_fired',
        incidentId: id,
        familyId: familyId,
        eventType: SosAuditEventType.fired,
        at: now,
        actorId: childId.value,
        payloadJson: '{"trigger":"hold"}',
      ),
    );
    await _store.appendOpsSample(
      SosOpsSample(
        id: '${id}_bat',
        incidentId: id,
        familyId: familyId,
        kind: SosOpsSampleKind.deviceBattery,
        capturedAt: now,
        retainUntil: SosEvidencePolicy.retainUntilFrom(now),
        payloadJson: '{"battery":$batteryPercent}',
      ),
    );
    if (locationSampleJson != null) {
      await _store.appendOpsSample(
        SosOpsSample(
          id: '${id}_loc',
          incidentId: id,
          familyId: familyId,
          kind: SosOpsSampleKind.location,
          capturedAt: now,
          retainUntil: SosEvidencePolicy.retainUntilFrom(now),
          payloadJson: locationSampleJson,
        ),
      );
    }
    return incident;
  }

  Future<SosIncident> acknowledge({
    required String incidentId,
    required SosActor actor,
    required String actorId,
  }) async {
    final incident = await _requireOpen(incidentId);
    final now = _clock().toUtc();
    final next = SosLifecycleEngine.acknowledge(
      incident: incident,
      actor: actor,
      now: now,
      actorId: actorId,
    );
    await _store.saveIncident(next);
    if (next.status == SosAlertStatus.acknowledged &&
        incident.status == SosAlertStatus.active) {
      await _store.appendAudit(
        SosLifecycleAuditEntry(
          id: '${incidentId}_ack_${now.millisecondsSinceEpoch}',
          incidentId: incidentId,
          familyId: familyId,
          eventType: SosAuditEventType.acknowledged,
          at: now,
          actorId: actorId,
        ),
      );
    }
    return next;
  }

  Future<SosIncident> escalate({
    required String incidentId,
    required SosActor actor,
    required String actorId,
  }) async {
    final incident = await _requireOpen(incidentId);
    final now = _clock().toUtc();
    final next = SosLifecycleEngine.escalate(incident: incident, actor: actor);
    await _store.saveIncident(next);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${incidentId}_esc_${now.millisecondsSinceEpoch}',
        incidentId: incidentId,
        familyId: familyId,
        eventType: SosAuditEventType.escalating,
        at: now,
        actorId: actorId,
      ),
    );
    await _store.appendOpsSample(
      SosOpsSample(
        id: '${incidentId}_esc_ops_${now.millisecondsSinceEpoch}',
        incidentId: incidentId,
        familyId: familyId,
        kind: SosOpsSampleKind.escalation,
        capturedAt: now,
        retainUntil: SosEvidencePolicy.retainUntilFrom(incident.triggeredAt),
        payloadJson: '{"actor":"$actorId"}',
      ),
    );
    return next;
  }

  Future<SosIncident> resolve({
    required String incidentId,
    required SosActor actor,
    required String actorId,
    SosTerminalReason reason = SosTerminalReason.helped,
  }) async {
    final incident = await _requireOpen(incidentId);
    final now = _clock().toUtc();
    final next = SosLifecycleEngine.resolve(
      incident: incident,
      actor: actor,
      now: now,
      actorId: actorId,
      reason: reason,
    );
    await _store.saveIncident(next);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${incidentId}_res_${now.millisecondsSinceEpoch}',
        incidentId: incidentId,
        familyId: familyId,
        eventType: SosAuditEventType.resolved,
        at: now,
        actorId: actorId,
        payloadJson: '{"reason":"${reason.name}"}',
      ),
    );
    return next;
  }

  Future<SosIncident> cancelFalseAlarm({
    required String incidentId,
    required SosActor actor,
    required String actorId,
  }) async {
    final incident = await _requireOpen(incidentId);
    final now = _clock().toUtc();
    final next = SosLifecycleEngine.cancelAsFalseAlarm(
      incident: incident,
      actor: actor,
      now: now,
      actorId: actorId,
    );
    await _store.saveIncident(next);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${incidentId}_cancel_${now.millisecondsSinceEpoch}',
        incidentId: incidentId,
        familyId: familyId,
        eventType: SosAuditEventType.cancelled,
        at: now,
        actorId: actorId,
        payloadJson: '{"reason":"falseAlarm"}',
      ),
    );
    return next;
  }

  /// Break-glass START→ACTIVE with allowlist + RBAC; never mutates permanent policy.
  Future<Map<String, Object?>> startBreakGlass({
    required String incidentId,
    required SosActor actor,
    required String actorId,
    required String capabilityId,
    required String reason,
    Duration duration = const Duration(minutes: 15),
  }) async {
    if (!SosRoleActions.canBreakGlass(actor)) {
      throw StateError('break-glass denied for actor');
    }
    SosBreakGlassAllowlist.assertAllowed(capabilityId);
    if (reason.trim().isEmpty) {
      throw StateError('break-glass reason required');
    }
    final incident = await _requireOpen(incidentId);
    final now = _clock().toUtc();
    final ends = now.add(duration);
    final id = _idFactory();
    final row = <String, Object?>{
      'id': id,
      'incident_id': incident.id,
      'family_id': familyId.value,
      'actor_id': actorId,
      'capability_id': capabilityId,
      'reason': reason.trim(),
      'phase': 'overrideActive',
      'started_at': now.millisecondsSinceEpoch,
      'ends_at': ends.millisecondsSinceEpoch,
      'ended_at': null,
      'end_reason': null,
    };
    await _store.saveBreakGlass(row);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${id}_bg',
        incidentId: incidentId,
        familyId: familyId,
        eventType: SosAuditEventType.breakGlassStarted,
        at: now,
        actorId: actorId,
        payloadJson:
            '{"capability":"$capabilityId","reason":${_jsonString(reason)}}',
      ),
    );
    return row;
  }

  Future<Map<String, Object?>> expireBreakGlass({
    required String sessionId,
    String endReason = 'expiry',
  }) async {
    final rows = await _store.listBreakGlass();
    final match = rows.where((r) => r['id'] == sessionId).toList();
    if (match.isEmpty) throw StateError('break-glass session missing');
    final row = Map<String, Object?>.from(match.first);
    final now = _clock().toUtc();
    row['phase'] = endReason == 'manual' ? 'revoked' : 'expired';
    row['ended_at'] = now.millisecondsSinceEpoch;
    row['end_reason'] = endReason;
    await _store.saveBreakGlass(row);
    await _store.appendAudit(
      SosLifecycleAuditEntry(
        id: '${sessionId}_end',
        incidentId: row['incident_id']! as String,
        familyId: familyId,
        eventType: endReason == 'manual'
            ? SosAuditEventType.breakGlassRevoked
            : SosAuditEventType.breakGlassExpired,
        at: now,
        actorId: row['actor_id'] as String?,
        payloadJson: '{"endReason":"$endReason"}',
      ),
    );
    return row;
  }

  /// Purge operational samples past retain_until; never touch core/audit.
  Future<int> purgeExpiredOps({DateTime? now}) {
    return _store.purgeExpiredOpsSamples(now: (now ?? _clock()).toUtc());
  }

  SosReadinessSnapshot evaluateReadiness(SosReadinessInputs inputs) {
    return SosReadinessEvaluator.evaluate(inputs, clock: _clock);
  }

  Future<SosIncident> _requireOpen(String incidentId) async {
    final incident = await _store.loadById(incidentId);
    if (incident == null || !incident.isOpen) {
      throw StateError('Open incident not found');
    }
    if (incident.familyId != familyId) {
      throw StateError('Incident family mismatch');
    }
    return incident;
  }

  static String _jsonString(String s) {
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
