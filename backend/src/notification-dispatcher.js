// One fail-closed dispatcher for the notification-shaped rows in outbox_events.
//
// Ordinary audit/outbox facts are not notifications. Only the four reviewed safety facts below
// may reach FCM. Chat messages continue through the existing, idempotent chat nudger; every other
// event is recorded as skipped with a reason. Unknown event types fail closed and remain visible
// as failed outbox rows rather than disappearing into an open-ended notification rule.

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
    'حماية {child} مُعطَّلة',
    'تم تعطيل الحماية على جهازه الساعة {time}',
    '{child}’s protection is disabled',
    'Device protection was turned off at {time}',
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
};
export const AUDIT_ONLY_REASONS = Object.freeze(auditOnlyEvents);

const DEFAULT_SWEEP_LIMIT = 3;
const MAX_SWEEP_LIMIT = 50;
const BOOT_SWEEP_LIMIT = 20;
const BOOT_PENDING_AGE_SECONDS = 5;
const STALE_PROCESSING_SECONDS = 120;
const URGENT_COPY_KEYS = new Set([
  'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported',
]);
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
    return `${digits} ${period === 'AM' ? 'ص' : 'م'}`;
  }
  return `${hour}:${minute} ${period}`;
}

export function renderAlertCopy(copyKey, { locale = 'en', child, zone = null, time }) {
  const template = ALERT_COPY[copyKey];
  if (!template || typeof child !== 'string' || child.trim().length === 0) {
    throw new Error('notification_copy_context_invalid');
  }
  const language = locale === 'ar' ? 'ar' : 'en';
  const values = { child: child.trim(), zone, time: formatNotificationTime(time, language) };
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
    const zone = payload.zoneName;
    if (typeof childId !== 'string' || !UUID.test(childId)
      || typeof zoneId !== 'string' || !UUID.test(zoneId)
      || typeof zone !== 'string' || zone.trim().length === 0
      || typeof payload.occurredAt !== 'string' && !(payload.occurredAt instanceof Date)) {
      throw new Error('notification_payload_invalid');
    }
    const { rows } = await client.query(
      `SELECT id, display_name
         FROM family_children
        WHERE family_id = $1 AND id = $2 AND archived_at IS NULL`,
      [familyId, childId],
    );
    if (rows.length === 0) throw new Error('notification_subject_unavailable');
    return Object.freeze({
      familyId,
      childId,
      child: rows[0].display_name,
      alertId: null,
      zoneId,
      zone: zone.trim(),
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
  if (error?.message === 'notification_subject_unavailable') return 'subject_unavailable';
  if (error?.message === 'notification_payload_invalid') return 'payload_invalid';
  if (error?.message === 'unclassified_outbox_event_type') return 'unclassified_event_type';
  if (error?.message === 'notification_copy_context_invalid') return 'copy_context_invalid';
  return 'dispatch_error';
}

function logDispatchFailure(outboxId, eventType, reason) {
  console.error(JSON.stringify({
    severity: 'error', event: 'notification_dispatch_failed', outboxId, eventType, reason,
  }));
}

export class NotificationDispatcher {
  constructor(fcmSender, clientFactory, { now = () => new Date() } = {}) {
    if (typeof clientFactory !== 'function') throw new TypeError('A database client factory is required.');
    this.fcmSender = fcmSender ?? null;
    this.clientFactory = clientFactory;
    this.now = now;
    this.running = false;
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
      const rows = await this.#claim({ limit: safeLimit, olderThanSeconds, includeStaleProcessing: false });
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
              (status = 'pending' AND created_at <= NOW() - ($1::int * INTERVAL '1 second'))
              OR ($2::boolean AND status = 'processing'
                  AND processing_at <= NOW() - ($3::int * INTERVAL '1 second'))
            )
            AND ($4::uuid IS NULL OR id = $4::uuid)
          ORDER BY created_at ASC, id ASC
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
    if (!this.fcmSender || typeof this.fcmSender.send !== 'function') {
      await this.#markSosUnavailable(event, 'push_not_configured');
      await this.#finish(event.id, 'skipped', 'push_not_configured');
      return { outboxId: event.id, status: 'skipped', reason: 'push_not_configured' };
    }

    let subject;
    let targets;
    let priorAttempts;
    const client = await this.clientFactory();
    try {
      subject = await resolveNotificationSubject(client, event);
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
          ORDER BY membership.joined_at ASC, membership.id ASC, registration.id ASC`,
        [subject.familyId, definition.copyKey],
      );
      targets = targetResult.rows;
      const attemptResult = await client.query(
        `SELECT registration_id, outcome, provider_message_id, failure_reason
           FROM outbox_delivery_attempts
          WHERE outbox_id = $1`,
        [event.id],
      );
      priorAttempts = new Map(attemptResult.rows.map((row) => [row.registration_id, row]));
    } catch (error) {
      const reason = safeFailureReason(error);
      await this.#finish(event.id, 'failed', reason);
      logDispatchFailure(event.id, event.event_type, reason);
      return { outboxId: event.id, status: 'failed', reason };
    } finally {
      client.release?.();
    }

    const unseenTargets = targets.filter((target) => !priorAttempts.has(target.registration_id));
    if (unseenTargets.length === 0 && targets.length === 0) {
      await this.#markSosUnavailable(event, 'push_registration_absent');
      await this.#finish(event.id, 'skipped', 'no_active_registration');
      return { outboxId: event.id, status: 'skipped', reason: 'no_active_registration' };
    }

    let deliveredCount = [...priorAttempts.values()].filter((row) => row.outcome === 'delivered').length;
    let removedCount = [...priorAttempts.values()].filter((row) => row.outcome === 'unregistered').length;
    let failedCount = [...priorAttempts.values()].filter((row) => row.outcome === 'failed').length;

    for (const target of unseenTargets) {
      let providerMessageId = null;
      try {
        const message = renderAlertCopy(definition.copyKey, {
          locale: target.locale,
          child: subject.child,
          zone: subject.zone,
          time: subject.occurredAt,
        });
        const result = await this.fcmSender.send({
          token: target.token,
          locale: target.locale,
          title: message.title,
          body: message.body,
          ttlSeconds: definition.ttlSeconds,
          urgency: definition.urgency,
          channelId: definition.channelId,
          data: dataPayload(event, definition, subject),
          onAccepted: (id) => { providerMessageId = id; },
        });
        if (result === 'sent' && providerMessageId) {
          await this.#recordAttempt(event, target, definition, {
            outcome: 'delivered', providerMessageId, failureReason: null,
          });
          await this.#updateSosDelivery(event, target, 'delivered', null, providerMessageId);
          deliveredCount += 1;
        } else if (result === 'unregistered') {
          await this.#recordAttempt(event, target, definition, {
            outcome: 'unregistered', providerMessageId: null, failureReason: null,
          });
          await this.#removeRegistration(target.registration_id);
          await this.#updateSosDelivery(event, target, 'failed', 'token_unregistered', null);
          removedCount += 1;
        } else {
          await this.#recordAttempt(event, target, definition, {
            outcome: 'failed', providerMessageId: null, failureReason: 'provider_receipt_missing',
          });
          await this.#updateSosDelivery(event, target, 'failed', 'provider_receipt_missing', null);
          failedCount += 1;
        }
      } catch (error) {
        const reason = safeFailureReason(error);
        try {
          await this.#recordAttempt(event, target, definition, {
            outcome: 'failed', providerMessageId: null, failureReason: reason,
          });
          await this.#updateSosDelivery(event, target, 'failed', reason, null);
        } catch (recordError) {
          logDispatchFailure(event.id, event.event_type, safeFailureReason(recordError));
        }
        failedCount += 1;
        logDispatchFailure(event.id, event.event_type, reason);
      }
    }

    if (failedCount > 0 || deliveredCount === 0) {
      const reason = failedCount > 0 ? 'one_or_more_targets_failed' : 'all_tokens_unregistered';
      await this.#finish(event.id, 'failed', reason);
      return { outboxId: event.id, status: 'failed', deliveredCount, removedCount, failedCount, reason };
    }
    await this.#finish(event.id, 'delivered', null, this.now());
    return { outboxId: event.id, status: 'delivered', deliveredCount, removedCount, failedCount };
  }

  async #recordAttempt(event, target, definition, result) {
    const client = await this.clientFactory();
    try {
      await client.query(
        `INSERT INTO outbox_delivery_attempts
           (outbox_id, registration_id, copy_key, outcome, provider_message_id, failure_reason)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (outbox_id, registration_id) DO NOTHING`,
        [event.id, target.registration_id, definition.copyKey, result.outcome,
          result.providerMessageId, result.failureReason],
      );
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

  async #updateSosDelivery(event, target, state, reasonCode, providerMessageId) {
    if (event.event_type !== 'family.sos_alert_raised') return;
    const payload = rowPayload(event);
    const alertId = payload.alertId ?? payload.subjectId;
    const client = await this.clientFactory();
    try {
      if (state === 'delivered') {
        await client.query(
          `UPDATE family_sos_alert_deliveries
              SET delivery_state = 'delivered', reason_code = NULL, delivered_at = $3,
                  fcm_message_id = $4
            WHERE alert_id = $1 AND recipient_membership_id = $2 AND channel = 'push'
              AND delivery_state IN ('recorded', 'failed', 'not_configured')`,
          [alertId, target.membership_id, this.now(), providerMessageId],
        );
      } else {
        await client.query(
          `UPDATE family_sos_alert_deliveries
              SET delivery_state = 'failed', reason_code = $3, delivered_at = NULL, fcm_message_id = NULL
            WHERE alert_id = $1 AND recipient_membership_id = $2 AND channel = 'push'
              AND delivery_state IN ('recorded', 'not_configured')`,
          [alertId, target.membership_id, reasonCode ?? 'provider_error'],
        );
      }
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
