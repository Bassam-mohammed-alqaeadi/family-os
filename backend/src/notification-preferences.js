// Notification preferences, one row per guardian — the door that writes what the gate reads.
//
// Migration 122 created the table and its comment promised the knobs would be honoured. Migration
// 136 built the honouring (`notification-gating.js`) and left the writing undone: nothing in the
// service could store a guardian's quiet hours, so the gate was reading a row nobody wrote. This
// module closes that half. A missing row is not an error and not a silenced family: it is the
// default view, so a guardian who never opened the screen is interrupted exactly as before.
//
// Whose row it is matters. These are per-guardian facts on purpose — one adult's night is not
// another's — so a guardian reads and writes their own row and cannot reach a co-guardian's. A
// child has no row to write and is refused by name.
//
// What is NOT accepted here is as deliberate as what is. A knob with no engine (`analysisNotices`,
// `summaryDigest`, `eveningDigest`) is refused rather than stored, because a saved decoration is a
// promise the app cannot keep; and the four safety copy keys cannot be muted at all — the database
// refuses them (`family_notification_preferences_never_silence_safety`) and this file says why
// before that constraint is ever reached.

import { HttpError } from './http-error.js';
import { SAFETY_COPY_KEYS } from './notification-gating.js';

/** The three ways a family can ask to be reached. Migration 122 allows no fourth. */
export const DELIVERY_MODES = Object.freeze(['interrupt', 'daily_digest', 'history_only']);

/**
 * The copy keys muting can act on today. One entry, because exactly one ordinary alert is
 * registered in `NOTIFY_TYPES`; a key absent from this list is a key the gate would never consult,
 * so offering it would be a switch with no wire. Promotion of another event adds its key here, in
 * the same slice as the promotion — nowhere else, or the list becomes a second vocabulary.
 */
export const MUTABLE_COPY_KEYS = Object.freeze(['task.claimed']);

/** The largest offset any inhabited clock runs from UTC. */
export const MAX_UTC_OFFSET_MINUTES = 840;

const MAX_DISABLED_KEYS = 32;

const PREFERENCE_COLUMNS = `id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
       quiet_hours_offset_minutes, push_allowed, delivery_mode, disabled_copy_keys,
       child_requests_enabled, version, updated_at`;

export class NotificationPreferencesError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'NotificationPreferencesError';
  }
}

/** `HH:MM` as Postgres expects it, from the minutes-of-day the app speaks in. */
function minutesToTime(minutes) {
  const hh = String(Math.floor(minutes / 60)).padStart(2, '0');
  const mm = String(minutes % 60).padStart(2, '0');
  return `${hh}:${mm}`;
}

function minutesOf(value) {
  if (value == null) return null;
  if (value instanceof Date) return value.getUTCHours() * 60 + value.getUTCMinutes();
  const match = /^(\d{1,2}):(\d{2})/.exec(String(value));
  if (match == null) return null;
  return Number(match[1]) * 60 + Number(match[2]);
}

/**
 * The view as the app consumes it: minutes of day, not clock faces. The client's own model
 * (`NotificationPrefs.toJson`) is in minutes too, so one unit travels the whole road and no second
 * conversion — the kind that has historically been off by an hour — is invented on either side.
 */
export function notificationPreferencesView(row) {
  if (row == null) {
    return {
      version: 0,
      quietHoursEnabled: false,
      quietStartMinutes: null,
      quietEndMinutes: null,
      quietHoursOffsetMinutes: 0,
      pushAllowed: true,
      deliveryMode: 'interrupt',
      childRequestsEnabled: true,
      disabledCopyKeys: [],
      updatedAt: null,
      source: 'default',
    };
  }
  const enabled = row.quiet_hours_enabled === true;
  return {
    version: Number(row.version),
    quietHoursEnabled: enabled,
    // A window that the database allows but the gate cannot use — a face missing while the switch
    // is on — is reported as unset rather than as a guessed midnight. `quiet_pair` makes that
    // state unwritable; this line is what it would read like if an old row ever carried it.
    quietStartMinutes: row.quiet_hours_start == null ? null : minutesOf(row.quiet_hours_start),
    quietEndMinutes: row.quiet_hours_end == null ? null : minutesOf(row.quiet_hours_end),
    quietHoursOffsetMinutes: Number(row.quiet_hours_offset_minutes ?? 0),
    pushAllowed: row.push_allowed !== false,
    deliveryMode: DELIVERY_MODES.includes(row.delivery_mode) ? row.delivery_mode : 'interrupt',
    childRequestsEnabled: row.child_requests_enabled !== false,
    disabledCopyKeys: Array.isArray(row.disabled_copy_keys) ? [...row.disabled_copy_keys] : [],
    updatedAt: row.updated_at == null ? null : new Date(row.updated_at).toISOString(),
    source: 'stored',
  };
}

function requireOffset(value) {
  if (!Number.isInteger(value) || Math.abs(value) > MAX_UTC_OFFSET_MINUTES) {
    throw new NotificationPreferencesError(
      400,
      'notification_preferences_offset_invalid',
      `quietHoursOffsetMinutes must be a whole number of minutes between -${MAX_UTC_OFFSET_MINUTES} and ${MAX_UTC_OFFSET_MINUTES}.`,
    );
  }
}

/**
 * The law the row must satisfy before it is written, stated here so the refusal names the field.
 * The same three rules are `CHECK`s in migration 122/136; a caller is never handed a constraint
 * number as an error, and a database is never trusted to be the only place the law lives.
 */
function assertFloors(merged) {
  const hasStart = merged.quietStartMinutes != null;
  const hasEnd = merged.quietEndMinutes != null;
  if (merged.quietHoursEnabled && (!hasStart || !hasEnd)) {
    throw new NotificationPreferencesError(
      400,
      'notification_preferences_quiet_pair_required',
      'Quiet hours need both a start and an end minute of day.',
    );
  }
  for (const [label, minutes] of [['quietStartMinutes', merged.quietStartMinutes],
    ['quietEndMinutes', merged.quietEndMinutes]]) {
    if (minutes != null && (!Number.isInteger(minutes) || minutes < 0 || minutes > 1_439)) {
      throw new NotificationPreferencesError(
        400,
        'notification_preferences_minute_out_of_day',
        `${label} must be a minute of day between 0 and 1439.`,
      );
    }
  }
  if (!DELIVERY_MODES.includes(merged.deliveryMode)) {
    throw new NotificationPreferencesError(
      400,
      'notification_preferences_delivery_mode_invalid',
      `deliveryMode must be one of ${DELIVERY_MODES.join(', ')}.`,
    );
  }
  const muted = merged.disabledCopyKeys;
  if (!Array.isArray(muted) || muted.length > MAX_DISABLED_KEYS) {
    throw new NotificationPreferencesError(
      400,
      'notification_preferences_mute_list_bounded',
      `disabledCopyKeys must be a list of at most ${MAX_DISABLED_KEYS} keys.`,
    );
  }
  const unsafe = muted.filter((key) => SAFETY_COPY_KEYS.includes(key));
  if (unsafe.length > 0) {
    throw new NotificationPreferencesError(
      403,
      'notification_preferences_safety_never_muted',
      `A safety alert is never silenced: ${unsafe.join(', ')} cannot be muted by any family.`,
    );
  }
  const unknown = muted.filter((key) => !MUTABLE_COPY_KEYS.includes(key));
  if (unknown.length > 0) {
    throw new NotificationPreferencesError(
      400,
      'notification_preferences_unknown_copy_key',
      `${unknown.join(', ')} is not a notification this family can be told about yet, so muting it would be a switch with no wire.`,
    );
  }
}

export function notificationPreferencesFor(store) {
  return {
    async read({ principal, familyId }) {
      return store.withTransaction(async (client) => {
        const actor = await store.activeActorMembership(client, familyId, principal.subject);
        const { rows } = await client.query(
          `SELECT ${PREFERENCE_COLUMNS}
             FROM family_notification_preferences
            WHERE family_id = $1 AND membership_id = $2`,
          [familyId, actor.id],
        );
        return {
          preferences: notificationPreferencesView(rows[0] ?? null),
          mutableCopyKeys: [...MUTABLE_COPY_KEYS],
        };
      });
    },

    async update({ principal, familyId, change, expectedVersion, correlationId }) {
      return store.withTransaction(async (client) => {
        const actor = await store.activeActorMembership(client, familyId, principal.subject);
        if (actor.role !== 'primary_guardian' && actor.role !== 'co_guardian') {
          throw new NotificationPreferencesError(
            403,
            'notification_preferences_guardian_only',
            'Notification preferences belong to a guardian of this family.',
          );
        }

        const { rows: currentRows } = await client.query(
          `SELECT ${PREFERENCE_COLUMNS}
             FROM family_notification_preferences
            WHERE family_id = $1 AND membership_id = $2
              FOR UPDATE`,
          [familyId, actor.id],
        );
        const current = notificationPreferencesView(currentRows[0] ?? null);
        if (current.version !== expectedVersion) {
          throw new NotificationPreferencesError(
            409,
            'notification_preferences_stale_version',
            'These preferences changed since they were read.',
          );
        }

        const merged = {
          quietHoursEnabled: change.quietHoursEnabled ?? current.quietHoursEnabled,
          // Switching the window off drops both faces, because the stored law is an equality:
          // `quiet_hours_enabled = (both faces present)`. A client that sends minutes with the
          // switch off is asking for silence to be lifted, not for a half window to be kept.
          quietStartMinutes: change.quietHoursEnabled === false
            ? null
            : (change.quietStartMinutes ?? current.quietStartMinutes),
          quietEndMinutes: change.quietHoursEnabled === false
            ? null
            : (change.quietEndMinutes ?? current.quietEndMinutes),
          quietHoursOffsetMinutes: change.quietHoursOffsetMinutes ?? current.quietHoursOffsetMinutes,
          pushAllowed: change.pushAllowed ?? current.pushAllowed,
          deliveryMode: change.deliveryMode ?? current.deliveryMode,
          childRequestsEnabled: change.childRequestsEnabled ?? current.childRequestsEnabled,
          disabledCopyKeys: change.disabledCopyKeys ?? current.disabledCopyKeys,
        };
        if (change.quietHoursOffsetMinutes !== undefined) requireOffset(change.quietHoursOffsetMinutes);
        assertFloors(merged);

        const nextVersion = current.version + 1;
        const { rows } = await client.query(
          `INSERT INTO family_notification_preferences
             (family_id, membership_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
              quiet_hours_offset_minutes, push_allowed, delivery_mode, disabled_copy_keys,
              child_requests_enabled, version, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::text[], $10, $11, NOW(), NOW())
           ON CONFLICT (family_id, membership_id) DO UPDATE SET
             quiet_hours_enabled = EXCLUDED.quiet_hours_enabled,
             quiet_hours_start = EXCLUDED.quiet_hours_start,
             quiet_hours_end = EXCLUDED.quiet_hours_end,
             quiet_hours_offset_minutes = EXCLUDED.quiet_hours_offset_minutes,
             push_allowed = EXCLUDED.push_allowed,
             delivery_mode = EXCLUDED.delivery_mode,
             disabled_copy_keys = EXCLUDED.disabled_copy_keys,
             child_requests_enabled = EXCLUDED.child_requests_enabled,
             version = EXCLUDED.version,
             updated_at = NOW()
           WHERE family_notification_preferences.version = $12
           RETURNING ${PREFERENCE_COLUMNS}`,
          [
            familyId,
            actor.id,
            merged.quietHoursEnabled,
            merged.quietStartMinutes == null ? null : minutesToTime(merged.quietStartMinutes),
            merged.quietEndMinutes == null ? null : minutesToTime(merged.quietEndMinutes),
            merged.quietHoursOffsetMinutes,
            merged.pushAllowed,
            merged.deliveryMode,
            merged.disabledCopyKeys,
            merged.childRequestsEnabled,
            nextVersion,
            expectedVersion,
          ],
        );
        if (rows[0] == null) {
          // The row moved between the locked read and this statement. The answer is the same
          // refusal the read gave, never a silent overwrite of a choice someone else just made.
          throw new NotificationPreferencesError(
            409,
            'notification_preferences_stale_version',
            'These preferences changed since they were read.',
          );
        }

        await store.appendAuditAndOutbox(client, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: rows[0].id,
          subjectType: 'family_notification_preferences',
          eventType: 'family.notification_preferences_updated',
          payload: { changed: Object.keys(change).sort() },
        });
        return {
          preferences: notificationPreferencesView(rows[0]),
          mutableCopyKeys: [...MUTABLE_COPY_KEYS],
        };
      });
    },
  };
}
