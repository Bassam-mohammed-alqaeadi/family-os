// One fail-closed dispatcher for the notification-shaped rows in outbox_events.
//
// Ordinary audit/outbox facts are not notifications. Only the four reviewed safety facts below
// may reach FCM. Chat messages continue through the existing, idempotent chat nudger; every other
// event is recorded as skipped with a reason. Unknown event types fail closed and remain visible
// as failed outbox rows rather than disappearing into an open-ended notification rule. Protection
// reports notify only for the explicitly registered tamper observations; healthy/unsupported
// reports remain audit-only outcomes.

import { PROTECTION_OBSERVED_STATES, TAMPER_OBSERVED_STATES } from './web-filter.js';

const copy = (arTitle, arBody, enTitle, enBody) => Object.freeze({
  ar: Object.freeze({ title: arTitle, body: arBody }),
  en: Object.freeze({ title: enTitle, body: enBody }),
});

export const ALERT_COPY = Object.freeze({
  'sos.raised': copy(
    'استغاثة من {child}',
    'ضغط زر الاستغاثة الساعة {time}',
    '{child} needs help',
    'Pressed the SOS button at {time}',
  ),
  'geofence.entered': copy(
    '{child} وصل إلى {zone}',
    'دخل المنطقة الآمنة الساعة {time}',
    '{child} arrived at {zone}',
    'Entered the safe zone at {time}',
  ),
  'geofence.exited': copy(
    '{child} خرج من {zone}',
    'غادر المنطقة الآمنة الساعة {time}',
    '{child} left {zone}',
    'Left the safe zone at {time}',
  ),
  'protection.reported': copy(
    'حالة الحماية على جهاز {child} تحتاج إلى مراجعة',
    'أبلغ الجهاز عن مؤشر يؤثر في الحماية الساعة {time}',
    '{child}’s protection needs attention',
    'The device reported a protection concern at {time}',
  ),
});

export const NOTIFY_TYPES = Object.freeze({
  'family.sos_alert_raised': Object.freeze({
    copyKey: 'sos.raised', subject: 'child', channelId: 'familyos_sos_alerts', ttlSeconds: 3600, urgency: 'alert',
  }),
  'family.geofence_entered': Object.freeze({
    copyKey: 'geofence.entered', subject: 'child', channelId: 'familyos_geofence_alerts', ttlSeconds: 1800, urgency: 'alert',
  }),
  'family.geofence_exited': Object.freeze({
    copyKey: 'geofence.exited', subject: 'child', channelId: 'familyos_geofence_alerts', ttlSeconds: 1800, urgency: 'alert',
  }),
  'family.device_protection_reported': Object.freeze({
    copyKey: 'protection.reported', subject: 'device', channelId: 'familyos_protection_alerts', ttlSeconds: 3600, urgency: 'high',
  }),
});

// This is the closed inventory of server eventType literals. `family.chat_message_sent` is
// deliberately attributed to the existing chat nudger: routing it through this dispatcher would
// send the same message twice. Keep each key tied to a literal in server source; the classification
// drift test enforces both directions.
const auditOnlyEvents = {
  'family.event_created': 'audit_only',
  'family.event_responded': 'audit_only',
  'family.event_attendance_recorded': 'audit_only',
  'family.event_updated': 'audit_only',
  'family.event_cancelled': 'audit_only',
  'family.collaboration_policy_updated': 'audit_only',
  'command.dispatched': 'audit_only',
  'command.expired': 'audit_only',
  'command.applied': 'audit_only',
  'command.failed': 'audit_only',
  'family.child_location_erased': 'audit_only',
  'family.child_archived': 'audit_only',
  'device.capability.changed': 'audit_only',
  'family.child_device_revoked': 'audit_only',
  'family.child_device_location_erased': 'audit_only',
  'device.revoked': 'audit_only',
  'family.chat_media_uploaded': 'audit_only',
  'family.chat_media_uploaded_device': 'audit_only',
  'family.chat_thread_created': 'audit_only',
  'family.chat_member_added': 'audit_only',
  'family.chat_message_sent': 'chat_nudge_existing_nudger',
  'family.chat_message_edited': 'audit_only',
  'family.chat_message_deleted': 'audit_only',
  'family.chat_read_marked': 'audit_only',
  'family.invite_code_issued': 'audit_only',
  'family.invite_code_revoked': 'audit_only',
  'family.invite_code_redeemed': 'audit_only',
  'family.location_fix_recorded': 'audit_only',
  'family.safe_zone_created': 'audit_only',
  'family.safe_zone_alerts_changed': 'audit_only',
  'family.screen_time_policy_updated': 'audit_only',
  'family.app_rule_updated': 'audit_only',
  'family.child_screen_locked': 'audit_only',
  'family.child_screen_unlocked': 'audit_only',
  'family.time_request_created': 'audit_only',
  'family.time_request_approved': 'audit_only',
  'family.time_request_denied': 'audit_only',
  'family.sos_alert_acknowledged': 'audit_only',
  'family.sos_alert_escalated': 'audit_only',
  'family.sos_alert_resolved': 'audit_only',
  'family.sos_backup_contact_added': 'audit_only',
  'family.sos_backup_contact_verified': 'audit_only',
  'family.sos_backup_contact_changed': 'audit_only',
  'family.created': 'audit_only',
  'family.child_created': 'audit_only',
  'family.child.created': 'audit_only',
  'family.child_device_linked': 'audit_only',
  'family.device_pairing_created': 'audit_only',
  'family.device_paired': 'audit_only',
  'family.device_telemetry_received': 'audit_only',
  'family.membership_invited': 'audit_only',
  'family.membership_accepted': 'audit_only',
  'family.membership_invitation_revoked': 'audit_only',
  'family.membership_removed': 'audit_only',
  'guardian_transfer.requested': 'audit_only',
  'guardian_transfer.expired': 'audit_only',
  'guardian_transfer.completed': 'audit_only',
  'guardian_transfer.cancelled': 'audit_only',
  'family.task_created': 'audit_only',
  'family.task_claimed': 'audit_only',
  'family.task_confirmed': 'audit_only',
  'family.task_declined': 'audit_only',
  'family.web_filter_policy_updated': 'audit_only',
  'family.web_filter_temp_allow_requested': 'audit_only',
  'family.web_filter_temp_allow_denied': 'audit_only',
  'family.web_filter_temp_allow_approved': 'audit_only',
  // Programme «family character» (migration 135). Which days a family rests, how its week opens and
  // what its members are called are decisions the whole household shares, and the household is in
  // the room that shows them: no phone should buzz because someone edited a preference.
  'family.customization_updated': 'audit_only',
};
export const AUDIT_ONLY_REASONS = Object.freeze(auditOnlyEvents);

const DEFAULT_SWEEP_LIMIT = 3;
const MAX_SWEEP_LIMIT = 50;
const BOOT_SWEEP_LIMIT = 20;
const BOOT_PENDING_AGE_SECONDS = 5;
const STALE_PROCESSING_SECONDS = 120;
const MAX_FCM_SEND_ATTEMPTS = 5;
// Backoff is bounded at 10 minutes unless FCM supplies a longer Retry-After (capped at 1 hour).
const RETRY_BACKOFF_SECONDS = Object.freeze([5, 30, 120, 600]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ARABIC_INDIC_DIGITS = Object.freeze(['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩']);

export function classifyNotificationEvent(eventType) {
  if (Object.hasOwn(NOTIFY_TYPES, eventType)) {
    return Object.freeze({ kind: 'notify', type: NOTIFY_TYPES[eventType] });
  }
  if (Object.hasOwn(AUDIT_ONLY_REASONS, eventType)) {
    return Object.freeze({ kind: 'skip', reason: AUDIT_ONLY_REASONS[eventType] });
  }
  throw new Error('unclassified_outbox_event_type');
}

export function formatNotificationTime(value, locale = 'en') {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) throw new Error('notification_time_invalid');
  const parts = new Intl.DateTimeFormat('en-US', {
    hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'UTC',
  }).formatToParts(date);
  const hour = parts.find((part) => part.type === 'hour')?.value;
  const minute = parts.find((part) => part.type === 'minute')?.value;
  const period = parts.find((part) => part.type === 'dayPeriod')?.value;
  if (!hour || !minute || !period) throw new Error('notification_time_invalid');
  if (locale === 'ar') {
    const digits = `${hour}:${minute}`.replace(/[0-9]/g, (digit) => ARABIC_INDIC_DIGITS[Number(digit)]);
    return `${digits} ${period === 'AM' ? 'ص' : 'م'} بتوقيت UTC`;
  }
  return `${hour}:${minute} ${period} UTC`;
}

export function renderAlertCopy(copyKey, { locale = 'en', child, zone = null, time }) {
  const template = ALERT_COPY[copyKey];
  if (!template || typeof child !== 'string' || child.trim().length === 0) {
    throw new Error('notification_copy_context_invalid');
  }
  const language = locale === 'ar' ? 'ar' : 'en';
  const safeZone = typeof zone === 'string' && zone.trim().length > 0
    ? zone.trim()
    : language === 'ar' ? 'منطقة آمنة' : 'a safe zone';
  const values = { child: child.trim(), zone: safeZone, time: formatNotificationTime(time, language) };
  const interpolate = (text) => text.replace(/\{(child|zone|time)\}/g, (whole, key) => {
    const value = values[key];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error('notification_copy_context_invalid');
    }
    return value.trim();
  });
  const selected = template[language];
  return Object.freeze({ title: interpolate(selected.title), body: interpolate(selected.body) });
}

function rowPayload(row) {
  if (row.payload && typeof row.payload === 'object' && !Array.isArray(row.payload)) return row.payload;
  if (typeof row.payload === 'string') {
    try {
      const decoded = JSON.parse(row.payload);
      if (decoded && typeof decoded === 'object' && !Array.isArray(decoded)) return decoded;
    } catch {
      // A malformed payload is failed closed by the caller.
    }
  }
  throw new Error('notification_payload_invalid');
}

/** Resolve names at send time. Child names never enter the outbox payload. */
export async function resolveNotificationSubject(client, event) {
  const payload = rowPayload(event);
  const familyId = event.aggregate_id ?? event.family_id;
  if (typeof familyId !== 'string' || !UUID.test(familyId)) throw new Error('notification_family_invalid');

  if (event.event_type === 'family.sos_alert_raised') {
    const alertId = payload.alertId ?? payload.subjectId;
    if (typeof alertId !== 'string' || !UUID.test(alertId)) throw new Error('notification_alert_id_invalid');
    const { rows } = await client.query(
      `SELECT alert.id AS alert_id, alert.child_id, alert.pressed_at AS occurred_at,
              child.display_name
         FROM family_sos_alerts alert
         JOIN family_children child
           ON child.family_id = alert.family_id AND child.id = alert.child_id
        WHERE alert.family_id = $1 AND alert.id = $2 AND child.archived_at IS NULL`,
      [familyId, alertId],
    );
    if (rows.length === 0) throw new Error('notification_subject_unavailable');
    return Object.freeze({
      familyId,
      childId: rows[0].child_id,
      child: rows[0].display_name,
      alertId: rows[0].alert_id,
      zoneId: null,
      zone: null,
      occurredAt: rows[0].occurred_at,
    });
  }

  if (event.event_type === 'family.geofence_entered' || event.event_type === 'family.geofence_exited') {
    const childId = payload.childId;
    const zoneId = payload.zoneId;
    if (typeof childId !== 'string' || !UUID.test(childId)
      || typeof zoneId !== 'string' || !UUID.test(zoneId)
      || typeof payload.occurredAt !== 'string' && !(payload.occurredAt instanceof Date)) {
      throw new Error('notification_payload_invalid');
    }
    const { rows: childRows } = await client.query(
      `SELECT id, display_name
         FROM family_children
        WHERE family_id = $1 AND id = $2 AND archived_at IS NULL`,
      [familyId, childId],
    );
    if (childRows.length === 0) throw new Error('notification_subject_unavailable');
    const { rows: zoneRows } = await client.query(
      `SELECT name
         FROM family_safe_zones
        WHERE family_id = $1 AND id = $2 AND archived_at IS NULL`,
      [familyId, zoneId],
    );
    return Object.freeze({
      familyId,
      childId,
      child: childRows[0].display_name,
      alertId: null,
      zoneId,
      // The zone may have been archived after the crossing. Copy rendering then uses a
      // localized generic safe-zone label instead of failing or trusting stored text.
      zone: zoneRows[0]?.name ?? null,
      occurredAt: payload.occurredAt,
    });
  }

  if (event.event_type === 'family.device_protection_reported') {
    const deviceId = payload.deviceId ?? payload.subjectId;
    if (typeof deviceId !== 'string' || !UUID.test(deviceId)) throw new Error('notification_device_id_invalid');
    const { rows } = await client.query(
      `SELECT device.child_id, child.display_name
         FROM family_child_devices device
         JOIN family_children child
           ON child.family_id = device.family_id AND child.id = device.child_id
        WHERE device.family_id = $1 AND device.id = $2 AND child.archived_at IS NULL`,
      [familyId, deviceId],
    );
    if (rows.length === 0) throw new Error('notification_subject_unavailable');
    const occurredAt = payload.occurredAt;
    if (typeof occurredAt !== 'string' && !(occurredAt instanceof Date)) {
      throw new Error('notification_time_invalid');
    }
    return Object.freeze({
      familyId,
      childId: rows[0].child_id,
      child: rows[0].display_name,
      alertId: null,
      deviceId,
      zoneId: null,
      zone: null,
      occurredAt,
    });
  }

  throw new Error('notification_subject_type_unsupported');
}

function dataPayload(event, definition, subject) {
  return Object.fromEntries(Object.entries({
    type: event.event_type,
    alertId: subject.alertId,
    childId: subject.childId,
    deviceId: subject.deviceId,
    zoneId: subject.zoneId,
    copyKey: definition.copyKey,
    occurredAt: subject.occurredAt instanceof Date
      ? subject.occurredAt.toISOString()
      : new Date(subject.occurredAt).toISOString(),
  }).filter(([, value]) => value != null));
}

function safeFailureReason(error) {
  // Error messages may contain provider details. Persist only a small, closed class.
  const fcmReasons = new Set([
    'invalid_request', 'sender_configuration', 'oauth_transport_failure',
    'oauth_temporary_failure', 'oauth_rejected', 'provider_unavailable',
    'provider_rejected', 'provider_outcome_unknown', 'provider_receipt_missing',
    'acceptance_callback_failed', 'retry_exhausted',
  ]);
  if (fcmReasons.has(error?.reasonCode)) return error.reasonCode;
  if (error?.message === 'notification_subject_unavailable') return 'subject_unavailable';
  if (error?.message === 'notification_payload_invalid') return 'payload_invalid';
  if (error?.message === 'notification_time_invalid') return 'time_invalid';
  if (error?.message === 'unclassified_outbox_event_type') return 'unclassified_event_type';
  if (error?.message === 'notification_copy_context_invalid') return 'copy_context_invalid';
  return 'dispatch_error';
}

function providerFailure(error) {
  const classification = ['transient', 'permanent', 'ambiguous'].includes(error?.classification)
    ? error.classification
    : 'ambiguous';
  let reason = safeFailureReason(error);
  if (reason === 'dispatch_error') {
    reason = classification === 'transient' ? 'provider_unavailable' : 'provider_outcome_unknown';
  }
  return { classification, reason, retryAfterSeconds: error?.retryAfterSeconds };
}

function latestAttemptMap(rows) {
  const latest = new Map();
  for (const row of rows) {
    const previous = latest.get(row.registration_id);
    if (!previous || Number(row.attempt_number) > Number(previous.attempt_number)) {
      latest.set(row.registration_id, row);
    }
  }
  return latest;
}

function attemptCounts(latestAttempts) {
  const rows = [...latestAttempts.values()];
  return {
    deliveredCount: rows.filter((row) => row.outcome === 'delivered').length,
    removedCount: rows.filter((row) => row.outcome === 'unregistered').length,
    failedCount: rows.filter((row) => ['permanent_failure', 'ambiguous'].includes(row.outcome)).length,
  };
}

function logDispatchFailure(outboxId, eventType, reason) {
  console.error(JSON.stringify({
    severity: 'error', event: 'notification_dispatch_failed', outboxId, eventType, reason,
  }));
}

function preserveLease(error) {
  const wrapped = new Error('notification_attempt_evidence_unavailable', { cause: error });
  wrapped.preserveNotificationLease = true;
  return wrapped;
}

function retryDelaySeconds(attemptNumber, providerRetryAfterSeconds = null) {
  const base = RETRY_BACKOFF_SECONDS[Math.min(attemptNumber - 1, RETRY_BACKOFF_SECONDS.length - 1)];
  const providerHint = Number.isInteger(providerRetryAfterSeconds)
    ? Math.max(0, Math.min(3600, providerRetryAfterSeconds))
    : 0;
  return Math.min(3600, Math.max(base, providerHint));
}

export class NotificationDispatcher {
  constructor(fcmSender, clientFactory, { now = () => new Date() } = {}) {
    if (typeof clientFactory !== 'function') throw new TypeError('A database client factory is required.');
    this.fcmSender = fcmSender ?? null;
    this.clientFactory = clientFactory;
    this.now = now;
    this.running = false;
    this.retryTimer = null;
    this.retryTimerAt = null;
  }

  /** Called by the store only after the event's transaction has committed. */
  async notify(outboxId, eventType) {
    if (typeof outboxId !== 'string' || !UUID.test(outboxId)) return { claimed: false, reason: 'invalid_outbox_id' };
    const rows = await this.#claim({ outboxId, eventType, limit: 1, olderThanSeconds: 0, includeStaleProcessing: false });
    if (rows.length === 0) return { claimed: false, reason: 'already_claimed_or_complete' };
    return this.#dispatch(rows[0]);
  }

  /** Small, non-blocking request-tail sweep; callers deliberately do not await delivery. */
  async sweep({ limit = DEFAULT_SWEEP_LIMIT, olderThanSeconds = 0 } = {}) {
    const safeLimit = Math.max(1, Math.min(MAX_SWEEP_LIMIT, Number.isInteger(limit) ? limit : DEFAULT_SWEEP_LIMIT));
    if (this.running) return { processed: 0, busy: true };
    this.running = true;
    try {
      const rows = await this.#claim({
        limit: safeLimit,
        olderThanSeconds,
        includeStaleProcessing: true,
        staleProcessingSeconds: STALE_PROCESSING_SECONDS,
      });
      const results = [];
      for (const row of rows) {
        try { results.push(await this.#dispatch(row)); }
        catch (error) {
          logDispatchFailure(row.id, row.event_type, safeFailureReason(error));
          results.push({ outboxId: row.id, status: 'failed', reason: safeFailureReason(error) });
        }
      }
      return { processed: results.length, results };
    } finally {
      this.running = false;
      try {
        await this.#armEarliestPendingRetry();
      } catch (error) {
        logDispatchFailure(null, 'notification.retry_wakeup', safeFailureReason(error));
      }
    }
  }

  /** Startup recovery: don't race the just-committed request path; reclaim old work only. */
  async bootSweep() {
    const rows = await this.#claim({
      limit: BOOT_SWEEP_LIMIT,
      olderThanSeconds: BOOT_PENDING_AGE_SECONDS,
      includeStaleProcessing: true,
      staleProcessingSeconds: STALE_PROCESSING_SECONDS,
    });
    const results = [];
    for (const row of rows) {
      try { results.push(await this.#dispatch(row)); }
      catch (error) {
        logDispatchFailure(row.id, row.event_type, safeFailureReason(error));
        results.push({ outboxId: row.id, status: 'failed', reason: safeFailureReason(error) });
      }
    }
    try {
      await this.#armEarliestPendingRetry();
    } catch (error) {
      logDispatchFailure(null, 'notification.retry_wakeup', safeFailureReason(error));
    }
    return { processed: results.length, results };
  }

  async #claim({
    outboxId = null,
    eventType = null,
    limit,
    olderThanSeconds,
    includeStaleProcessing,
    staleProcessingSeconds = STALE_PROCESSING_SECONDS,
  }) {
    const client = await this.clientFactory();
    if (!client || typeof client.query !== 'function') return [];
    try {
      await client.query('BEGIN');
      const { rows } = await client.query(
        `SELECT id, event_type, aggregate_id, payload, copy_key
           FROM outbox_events
          WHERE (
              (status = 'pending' AND available_at <= NOW() - ($1::int * INTERVAL '1 second'))
              OR ($2::boolean AND status = 'processing'
                  AND processing_at <= NOW() - ($3::int * INTERVAL '1 second'))
            )
            AND ($4::uuid IS NULL OR id = $4::uuid)
          ORDER BY available_at ASC, created_at ASC, id ASC
          FOR UPDATE SKIP LOCKED
          LIMIT $5`,
        [olderThanSeconds, includeStaleProcessing, staleProcessingSeconds, outboxId, limit],
      );
      if (eventType != null && rows.length > 0 && rows[0].event_type !== eventType) {
        await client.query(
          `UPDATE outbox_events
              SET status = 'failed', failure_reason = 'event_type_mismatch', processing_at = NULL
            WHERE id = $1`,
          [rows[0].id],
        );
        await client.query('COMMIT');
        logDispatchFailure(rows[0].id, eventType, 'event_type_mismatch');
        return [];
      }
      for (const row of rows) {
        await client.query(
          `UPDATE outbox_events SET status = 'processing', processing_at = NOW(), failure_reason = NULL,
                                    delivered_at = NULL
            WHERE id = $1`,
          [row.id],
        );
      }
      await client.query('COMMIT');
      return rows;
    } catch (error) {
      await client.query('ROLLBACK').catch(() => {});
      throw error;
    } finally {
      client.release?.();
    }
  }

  async #dispatch(event) {
    try {
      return await this.#dispatchInner(event);
    } catch (error) {
      if (error?.preserveNotificationLease) {
        logDispatchFailure(event.id, event.event_type, 'attempt_evidence_unavailable');
        return { outboxId: event.id, status: 'indeterminate', reason: 'attempt_evidence_unavailable' };
      }
      if (error?.message === 'unclassified_outbox_event_type') throw error;
      const reason = safeFailureReason(error);
      try { await this.#finish(event.id, 'failed', reason); } catch { /* failure is logged below */ }
      logDispatchFailure(event.id, event.event_type, reason);
      return { outboxId: event.id, status: 'failed', reason };
    }
  }

  async #dispatchInner(event) {
    const classification = (() => {
      try { return classifyNotificationEvent(event.event_type); }
      catch (error) { return { kind: 'unknown', error }; }
    })();
    if (classification.kind === 'unknown') {
      await this.#finish(event.id, 'failed', 'unclassified_event_type');
      logDispatchFailure(event.id, event.event_type, 'unclassified_event_type');
      throw classification.error;
    }
    if (classification.kind === 'skip') {
      await this.#finish(event.id, 'skipped', classification.reason);
      return { outboxId: event.id, status: 'skipped', reason: classification.reason };
    }
    const definition = classification.type;
    if (event.copy_key !== definition.copyKey) {
      await this.#finish(event.id, 'failed', 'copy_key_mismatch');
      logDispatchFailure(event.id, event.event_type, 'copy_key_mismatch');
      return { outboxId: event.id, status: 'failed', reason: 'copy_key_mismatch' };
    }
    if (event.event_type === 'family.device_protection_reported') {
      const payload = rowPayload(event);
      if (!PROTECTION_OBSERVED_STATES.includes(payload.observedState)) {
        await this.#finish(event.id, 'failed', 'payload_invalid');
        logDispatchFailure(event.id, event.event_type, 'payload_invalid');
        return { outboxId: event.id, status: 'failed', reason: 'payload_invalid' };
      }
      if (!TAMPER_OBSERVED_STATES.includes(payload.observedState)) {
        await this.#finish(event.id, 'skipped', 'protection_observation_not_alertable');
        return { outboxId: event.id, status: 'skipped', reason: 'protection_observation_not_alertable' };
      }
    }
    if (!this.fcmSender || typeof this.fcmSender.send !== 'function') {
      await this.#markSosUnavailable(event, 'push_not_configured');
      await this.#finish(event.id, 'skipped', 'push_not_configured');
      return { outboxId: event.id, status: 'skipped', reason: 'push_not_configured' };
    }

    const isSos = event.event_type === 'family.sos_alert_raised';
    let subject;
    let targets;
    let attemptRows;
    let expectedSosRecipients = [];
    const client = await this.clientFactory();
    try {
      subject = await resolveNotificationSubject(client, event);
      if (isSos) {
        const expectedResult = await client.query(
          `SELECT delivery.recipient_membership_id AS membership_id, membership.status AS membership_status
             FROM family_sos_alert_deliveries delivery
             LEFT JOIN family_memberships membership
               ON membership.family_id = delivery.family_id
              AND membership.id = delivery.recipient_membership_id
            WHERE delivery.alert_id = $1 AND delivery.channel = 'push'
              AND delivery.recipient_kind = 'guardian'
              AND delivery.recipient_membership_id IS NOT NULL
            ORDER BY delivery.created_at ASC, delivery.id ASC`,
          [subject.alertId],
        );
        expectedSosRecipients = expectedResult.rows;
      }
      const recipientIds = isSos ? expectedSosRecipients.map((row) => row.membership_id) : null;
      const targetResult = await client.query(
        `SELECT registration.id AS registration_id, registration.token, registration.locale,
                membership.id AS membership_id
           FROM family_push_registrations registration
           JOIN family_memberships membership
             ON membership.family_id = registration.family_id
            AND membership.id = registration.membership_id
            AND membership.status = 'active'
            AND membership.role IN ('primary_guardian', 'co_guardian')
           LEFT JOIN family_notification_preferences preferences
             ON preferences.family_id = registration.family_id
            AND preferences.membership_id = membership.id
          WHERE registration.family_id = $1
            AND NOT (COALESCE(preferences.disabled_copy_keys, '{}'::text[]) @> ARRAY[$2]::text[])
            AND ($3::uuid[] IS NULL OR membership.id = ANY($3::uuid[]))
          ORDER BY membership.joined_at ASC, membership.id ASC, registration.id ASC`,
        [subject.familyId, definition.copyKey, recipientIds],
      );
      targets = targetResult.rows;
      const attemptResult = await client.query(
        `SELECT registration_id, recipient_membership_id, attempt_number, outcome,
                provider_message_id, failure_reason, retry_after_at,
                (retry_after_at IS NOT NULL AND retry_after_at <= NOW()) AS retry_due
           FROM outbox_delivery_attempts
          WHERE outbox_id = $1
          ORDER BY registration_id ASC, attempt_number ASC`,
        [event.id],
      );
      attemptRows = attemptResult.rows;
    } catch (error) {
      const reason = safeFailureReason(error);
      await this.#finish(event.id, 'failed', reason);
      logDispatchFailure(event.id, event.event_type, reason);
      return { outboxId: event.id, status: 'failed', reason };
    } finally {
      client.release?.();
    }

    let latest = latestAttemptMap(attemptRows);
    for (const target of targets) {
      const previous = latest.get(target.registration_id);
      if (previous?.outcome === 'delivered'
        || previous?.outcome === 'unregistered'
        || previous?.outcome === 'permanent_failure'
        || previous?.outcome === 'ambiguous') continue;

      if (previous?.outcome === 'in_flight') {
        await this.#completeAttempt(event.id, target.registration_id, previous.attempt_number, {
          outcome: 'ambiguous', providerMessageId: null, failureReason: 'provider_outcome_unknown',
        });
        continue;
      }

      if (previous?.outcome === 'retryable_failure') {
        if (Number(previous.attempt_number) >= MAX_FCM_SEND_ATTEMPTS) {
          await this.#exhaustRetryableAttempt(event.id, target.registration_id, previous.attempt_number);
          continue;
        }
        if (!previous.retry_due) continue;
      }

      const attemptNumber = previous ? Number(previous.attempt_number) + 1 : 1;
      let message;
      let data;
      try {
        message = renderAlertCopy(definition.copyKey, {
          locale: target.locale,
          child: subject.child,
          zone: subject.zone,
          time: subject.occurredAt,
        });
        data = dataPayload(event, definition, subject);
      } catch (error) {
        const reason = safeFailureReason(error);
        await this.#finish(event.id, 'failed', reason);
        logDispatchFailure(event.id, event.event_type, reason);
        return { outboxId: event.id, status: 'failed', reason };
      }

      const started = await this.#startAttempt(event, target, definition, attemptNumber);
      if (!started) continue;

      let providerMessageId = null;
      let sendResult;
      let sendError = null;
      try {
        sendResult = await this.fcmSender.send({
          token: target.token,
          locale: target.locale,
          title: message.title,
          body: message.body,
          ttlSeconds: definition.ttlSeconds,
          urgency: definition.urgency,
          channelId: definition.channelId,
          data,
          onAccepted: (id) => { providerMessageId = id; },
        });
      } catch (error) {
        sendError = error;
      }

      let attemptResult;
      if (providerMessageId || (!sendError && sendResult === 'sent')) {
        attemptResult = {
          outcome: providerMessageId ? 'delivered' : 'ambiguous',
          providerMessageId,
          failureReason: providerMessageId ? null : 'provider_receipt_missing',
        };
      } else if (!sendError && sendResult === 'unregistered') {
        attemptResult = { outcome: 'unregistered', providerMessageId: null, failureReason: null };
      } else {
        const providerFailureResult = providerFailure(sendError);
        attemptResult = {
          outcome: providerFailureResult.classification === 'transient'
            ? 'retryable_failure'
            : providerFailureResult.classification === 'permanent'
              ? 'permanent_failure'
              : 'ambiguous',
          providerMessageId: null,
          failureReason: providerFailureResult.reason,
          retryAfterSeconds: providerFailureResult.retryAfterSeconds,
        };
      }
      if (attemptResult.outcome === 'retryable_failure'
        && attemptNumber >= MAX_FCM_SEND_ATTEMPTS) {
        attemptResult.outcome = 'permanent_failure';
        attemptResult.failureReason = 'retry_exhausted';
        attemptResult.retryAfterSeconds = null;
      }
      if (attemptResult.outcome === 'retryable_failure') {
        attemptResult.retryAfterSeconds = retryDelaySeconds(
          attemptNumber,
          attemptResult.retryAfterSeconds,
        );
      }
      await this.#completeAttempt(event.id, target.registration_id, attemptNumber, attemptResult);
      if (attemptResult.outcome === 'unregistered') {
        try {
          await this.#removeRegistration(target.registration_id);
        } catch {
          logDispatchFailure(event.id, event.event_type, 'registration_cleanup_failed');
        }
      }
    }

    // A stale `in_flight` row is evidence of an interrupted/ambiguous provider call. Resolve
    // it without replaying the push, including attempts whose registration was since removed.
    const currentRegistrationIds = new Set(targets.map((target) => target.registration_id));
    latest = await this.#readLatestAttempts(event.id);
    for (const attempt of latest.values()) {
      if (attempt.outcome === 'in_flight') {
        await this.#completeAttempt(event.id, attempt.registration_id, attempt.attempt_number, {
          outcome: 'ambiguous', providerMessageId: null, failureReason: 'provider_outcome_unknown',
        });
      } else if (attempt.outcome === 'retryable_failure'
        && !currentRegistrationIds.has(attempt.registration_id)) {
        // A registration can be deleted (for example on logout or token rotation) while
        // its retry is waiting. Do not keep scheduling an attempt that has no active target.
        await this.#failRetryWithoutRegistration(event.id, attempt.registration_id, attempt.attempt_number);
      }
    }
    latest = await this.#readLatestAttempts(event.id);

    if (isSos) {
      await this.#reconcileSosDeliveries(event, expectedSosRecipients, targets, latest);
    }

    const pendingRetries = [...latest.values()].filter((attempt) => (
      attempt.outcome === 'retryable_failure'
      && Number(attempt.attempt_number) < MAX_FCM_SEND_ATTEMPTS
    ));
    if (pendingRetries.length > 0) {
      const retryAt = await this.#scheduleRetry(event.id);
      const counts = attemptCounts(latest);
      return {
        outboxId: event.id,
        status: 'retry_scheduled',
        retryAt,
        ...counts,
      };
    }

    if (!isSos && targets.length === 0 && latest.size === 0) {
      await this.#finish(event.id, 'skipped', 'no_active_registration');
      return { outboxId: event.id, status: 'skipped', reason: 'no_active_registration' };
    }

    const counts = attemptCounts(latest);
    if (isSos) {
      const deliveries = await this.#readSosDeliveries(event);
      const deliveredCount = deliveries.filter((row) => row.delivery_state === 'delivered').length;
      const failedCount = deliveries.filter((row) => row.delivery_state !== 'delivered').length;
      const removedCount = counts.removedCount;
      if (deliveries.length > 0 && failedCount === 0) {
        await this.#finish(event.id, 'delivered', null, this.now());
        return { outboxId: event.id, status: 'delivered', deliveredCount, removedCount, failedCount: 0 };
      }
      const reason = deliveries.length === 0
        ? 'sos_recipients_missing'
        : targets.length === 0 && latest.size === 0
          ? 'no_active_registration'
          : 'one_or_more_recipients_failed';
      await this.#finish(event.id, 'failed', reason);
      return { outboxId: event.id, status: 'failed', deliveredCount, removedCount, failedCount, reason };
    }

    if (counts.failedCount > 0 || counts.deliveredCount === 0) {
      const reason = counts.failedCount > 0
        ? 'one_or_more_targets_failed'
        : counts.removedCount > 0 ? 'all_tokens_unregistered' : 'no_active_registration';
      await this.#finish(event.id, 'failed', reason);
      return { outboxId: event.id, status: 'failed', ...counts, reason };
    }
    await this.#finish(event.id, 'delivered', null, this.now());
    return { outboxId: event.id, status: 'delivered', ...counts };
  }

  async #startAttempt(event, target, definition, attemptNumber) {
    const client = await this.clientFactory();
    try {
      const { rows } = await client.query(
        `INSERT INTO outbox_delivery_attempts
           (outbox_id, registration_id, recipient_membership_id, copy_key,
            attempt_number, outcome, provider_message_id, failure_reason, retry_after_at)
         VALUES ($1, $2, $3, $4, $5, 'in_flight', NULL, NULL, NULL)
         ON CONFLICT (outbox_id, registration_id, attempt_number) DO NOTHING
         RETURNING id`,
        [event.id, target.registration_id, target.membership_id, definition.copyKey, attemptNumber],
      );
      return rows.length === 1;
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #completeAttempt(outboxId, registrationId, attemptNumber, result) {
    const client = await this.clientFactory();
    try {
      const { rows } = await client.query(
        `UPDATE outbox_delivery_attempts
            SET outcome = $4, provider_message_id = $5, failure_reason = $6,
                retry_after_at = CASE WHEN $4 = 'retryable_failure'
                  THEN NOW() + ($7::int * INTERVAL '1 second') ELSE NULL END
          WHERE outbox_id = $1 AND registration_id = $2 AND attempt_number = $3
            AND outcome = 'in_flight'
        RETURNING registration_id, recipient_membership_id, attempt_number, outcome,
                  provider_message_id, failure_reason, retry_after_at`,
        [outboxId, registrationId, attemptNumber, result.outcome, result.providerMessageId,
          result.failureReason, result.retryAfterSeconds ?? null],
      );
      return rows[0] ?? null;
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #exhaustRetryableAttempt(outboxId, registrationId, attemptNumber) {
    const client = await this.clientFactory();
    try {
      await client.query(
        `UPDATE outbox_delivery_attempts
            SET outcome = 'permanent_failure', failure_reason = 'retry_exhausted', retry_after_at = NULL
          WHERE outbox_id = $1 AND registration_id = $2 AND attempt_number = $3
            AND outcome = 'retryable_failure'`,
        [outboxId, registrationId, attemptNumber],
      );
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #failRetryWithoutRegistration(outboxId, registrationId, attemptNumber) {
    const client = await this.clientFactory();
    try {
      await client.query(
        `UPDATE outbox_delivery_attempts
            SET outcome = 'permanent_failure', failure_reason = 'registration_unavailable',
                retry_after_at = NULL
          WHERE outbox_id = $1 AND registration_id = $2 AND attempt_number = $3
            AND outcome = 'retryable_failure'`,
        [outboxId, registrationId, attemptNumber],
      );
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #readLatestAttempts(outboxId) {
    const client = await this.clientFactory();
    try {
      const { rows } = await client.query(
        `SELECT registration_id, recipient_membership_id, attempt_number, outcome,
                provider_message_id, failure_reason, retry_after_at,
                (retry_after_at IS NOT NULL AND retry_after_at <= NOW()) AS retry_due
           FROM outbox_delivery_attempts
          WHERE outbox_id = $1
          ORDER BY registration_id ASC, attempt_number ASC`,
        [outboxId],
      );
      return latestAttemptMap(rows);
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  #armRetryWakeup(retryAt) {
    const dueAt = retryAt instanceof Date ? retryAt.getTime() : Date.parse(String(retryAt));
    if (!Number.isFinite(dueAt)) return;
    // Keep an already armed earlier wakeup; an early wake simply re-reads the durable queue.
    if (this.retryTimer != null && this.retryTimerAt != null && this.retryTimerAt <= dueAt) return;
    if (this.retryTimer != null) clearTimeout(this.retryTimer);
    this.retryTimerAt = dueAt;
    const delay = Math.max(0, Math.min(2_147_483_647, dueAt - Date.now() + 25));
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      this.retryTimerAt = null;
      void (async () => {
        try {
          await this.sweep({ limit: MAX_SWEEP_LIMIT });
        } catch (error) {
          logDispatchFailure(null, 'notification.retry_wakeup', safeFailureReason(error));
        }
        try {
          await this.#armEarliestPendingRetry();
        } catch (error) {
          logDispatchFailure(null, 'notification.retry_wakeup', safeFailureReason(error));
          // A database blip must not strand a durable retry. Use a single bounded recovery wakeup.
          this.#armRetryWakeup(new Date(Date.now() + 1_000));
        }
      })();
    }, delay);
    this.retryTimer.unref?.();
  }

  async #armEarliestPendingRetry() {
    const client = await this.clientFactory();
    if (!client || typeof client.query !== 'function') return;
    try {
      const { rows } = await client.query(
        `SELECT MIN(event.available_at) AS retry_at
           FROM outbox_events event
          WHERE event.status = 'pending'
            AND EXISTS (
              SELECT 1
                FROM outbox_delivery_attempts attempt
               WHERE attempt.outbox_id = event.id
                 AND attempt.outcome = 'retryable_failure'
                 AND attempt.attempt_number < $1
                 AND attempt.attempt_number = (
                   SELECT MAX(previous.attempt_number)
                     FROM outbox_delivery_attempts previous
                    WHERE previous.outbox_id = event.id
                      AND previous.registration_id = attempt.registration_id
                 )
            )`,
        [MAX_FCM_SEND_ATTEMPTS],
      );
      const retryAt = rows[0]?.retry_at;
      if (retryAt == null) {
        if (this.retryTimer != null) clearTimeout(this.retryTimer);
        this.retryTimer = null;
        this.retryTimerAt = null;
        return;
      }
      this.#armRetryWakeup(retryAt);
    } finally {
      client.release?.();
    }
  }

  async #scheduleRetry(outboxId) {
    const client = await this.clientFactory();
    try {
      const { rows } = await client.query(
        `WITH latest_attempts AS (
           SELECT DISTINCT ON (registration_id)
                  registration_id, attempt_number, outcome, retry_after_at
             FROM outbox_delivery_attempts
            WHERE outbox_id = $1
            ORDER BY registration_id, attempt_number DESC
         )
         UPDATE outbox_events
            SET status = 'pending', available_at = (
                  SELECT MIN(retry_after_at) FROM latest_attempts
                   WHERE outcome = 'retryable_failure' AND attempt_number < $2
                ),
                failure_reason = NULL, delivered_at = NULL, processing_at = NULL
          WHERE id = $1 AND status = 'processing'
        RETURNING available_at`,
        [outboxId, MAX_FCM_SEND_ATTEMPTS],
      );
      if (rows.length === 0 || !rows[0].available_at) throw new Error('notification_retry_schedule_missing');
      this.#armRetryWakeup(rows[0].available_at);
      return rows[0].available_at;
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #removeRegistration(registrationId) {
    const client = await this.clientFactory();
    try {
      await client.query('DELETE FROM family_push_registrations WHERE id = $1', [registrationId]);
    } finally {
      client.release?.();
    }
  }

  async #reconcileSosDeliveries(event, expectedRecipients, targets, latestAttempts) {
    const payload = rowPayload(event);
    const alertId = payload.alertId ?? payload.subjectId;
    const targetsByMembership = new Map();
    const membershipByRegistration = new Map();
    for (const target of targets) {
      membershipByRegistration.set(target.registration_id, target.membership_id);
      const membersTargets = targetsByMembership.get(target.membership_id) ?? [];
      membersTargets.push(target);
      targetsByMembership.set(target.membership_id, membersTargets);
    }
    for (const expected of expectedRecipients) {
      const membershipId = expected.membership_id;
      const currentTargets = targetsByMembership.get(membershipId) ?? [];
      const relatedAttempts = [...latestAttempts.values()].filter((attempt) => (
        attempt.recipient_membership_id === membershipId
        || (attempt.recipient_membership_id == null
          && membershipByRegistration.get(attempt.registration_id) === membershipId)
      ));
      const accepted = relatedAttempts.find((attempt) => attempt.outcome === 'delivered');
      if (accepted) {
        await this.#setSosDelivery(event, alertId, membershipId, 'delivered', null, accepted.provider_message_id);
        continue;
      }
      const stillRetrying = relatedAttempts.some((attempt) => (
        attempt.outcome === 'in_flight'
        || (attempt.outcome === 'retryable_failure'
          && Number(attempt.attempt_number) < MAX_FCM_SEND_ATTEMPTS)
      ));
      if (stillRetrying) continue;

      let reason;
      if (relatedAttempts.length === 0) {
        reason = currentTargets.length === 0
          ? expected.membership_status === 'active' ? 'push_registration_absent' : 'recipient_unavailable'
          : 'delivery_attempt_missing';
      } else if (relatedAttempts.every((attempt) => attempt.outcome === 'unregistered')) {
        reason = 'token_unregistered';
      } else {
        reason = relatedAttempts.find((attempt) => attempt.outcome !== 'unregistered')?.failure_reason
          ?? 'provider_error';
      }
      await this.#setSosDelivery(event, alertId, membershipId, 'failed', reason, null);
    }
  }

  async #setSosDelivery(event, alertId, membershipId, state, reasonCode, providerMessageId) {
    const client = await this.clientFactory();
    try {
      if (state === 'delivered') {
        await client.query(
          `UPDATE family_sos_alert_deliveries
              SET delivery_state = 'delivered', reason_code = NULL, delivered_at = $3,
                  fcm_message_id = $4
            WHERE alert_id = $1 AND recipient_membership_id = $2 AND channel = 'push'
              AND delivery_state IN ('recorded', 'failed', 'not_configured')`,
          [alertId, membershipId, this.now(), providerMessageId],
        );
      } else {
        await client.query(
          `UPDATE family_sos_alert_deliveries
              SET delivery_state = 'failed', reason_code = $3, delivered_at = NULL, fcm_message_id = NULL
            WHERE alert_id = $1 AND recipient_membership_id = $2 AND channel = 'push'
              AND delivery_state IN ('recorded', 'not_configured')`,
          [alertId, membershipId, reasonCode ?? 'provider_error'],
        );
      }
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #readSosDeliveries(event) {
    const payload = rowPayload(event);
    const alertId = payload.alertId ?? payload.subjectId;
    const client = await this.clientFactory();
    try {
      const { rows } = await client.query(
        `SELECT recipient_membership_id, delivery_state, reason_code, delivered_at, fcm_message_id
           FROM family_sos_alert_deliveries
          WHERE alert_id = $1 AND channel = 'push' AND recipient_kind = 'guardian'
          ORDER BY recipient_membership_id ASC`,
        [alertId],
      );
      return rows;
    } catch (error) {
      throw preserveLease(error);
    } finally {
      client.release?.();
    }
  }

  async #markSosUnavailable(event, reasonCode) {
    if (event.event_type !== 'family.sos_alert_raised') return;
    const payload = rowPayload(event);
    const alertId = payload.alertId ?? payload.subjectId;
    const client = await this.clientFactory();
    try {
      await client.query(
        `UPDATE family_sos_alert_deliveries
            SET delivery_state = 'not_configured', reason_code = $2,
                delivered_at = NULL, fcm_message_id = NULL
          WHERE alert_id = $1 AND channel = 'push'
            AND delivery_state IN ('recorded', 'failed')`,
        [alertId, reasonCode],
      );
    } finally {
      client.release?.();
    }
  }

  async #finish(outboxId, status, failureReason, deliveredAt = null) {
    const client = await this.clientFactory();
    try {
      await client.query(
        `UPDATE outbox_events
            SET status = $2, failure_reason = $3, delivered_at = $4, processing_at = NULL
          WHERE id = $1 AND status = 'processing'`,
        [outboxId, status, failureReason, deliveredAt],
      );
    } finally {
      client.release?.();
    }
  }
}
