// The one gate that decides whether a notification may reach a handset.
//
// `family_notification_preferences` (migration 122) stored a guardian's wishes and nothing read
// them; this module is the single reader of that row for every path that can push. A second
// implementation of the same rules would be a second truth about the family's silence, so both
// the dispatcher and any future flusher must come through `decideDelivery` here.
//
// Two laws are older than this file and are kept exactly:
//   · Safety copy keys are never silenced. Migration 122 refuses to store them in
//     `disabled_copy_keys`, and a bypass in this module is what turns that refusal into behaviour.
//   · Quiet hours are judged on the guardian's own clock, not on UTC. The window is stored as
//     clock faces; the phone's offset (migration 136) says where that guardian lives right now.
//     A traveller's window stays where the app last left it until the app is opened again —
//     that staleness is the accepted cost, and the screen says it in plain words.

/** The four keys migration 122 forbids from `disabled_copy_keys`. */
export const SAFETY_COPY_KEYS = Object.freeze([
  'sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported',
]);

/** The only outcomes the delivery ledger accepts. */
export const GATE_DECISIONS = Object.freeze(['delivered', 'suppressed', 'digest_queued']);

/** The only reasons the delivery ledger accepts, each paired with its decision by a CHECK. */
export const GATE_REASONS = Object.freeze([
  'delivered', 'safety_bypass', 'push_disabled', 'copy_muted', 'child_requests_disabled',
  'history_only', 'digest_mode', 'quiet_hours',
]);

const MINUTES_PER_DAY = 1_440;

/** `HH:MM` / `HH:MM:SS` (the shape a Postgres `TIME` arrives in) as minutes since local midnight. */
export function timeToMinutes(value) {
  if (value == null) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value.getUTCHours() * 60 + value.getUTCMinutes();
  }
  const match = /^(\d{1,2}):(\d{2})(?::\d{2})?(?:\.\d+)?$/.exec(String(value).trim());
  if (match == null) return null;
  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}

/** The minute of the day on the guardian's clock, for an instant given in UTC. */
export function localMinuteOf(when, offsetMinutes) {
  const offset = Number.isInteger(offsetMinutes) ? offsetMinutes : 0;
  const minutes = when.getUTCHours() * 60 + when.getUTCMinutes();
  return ((minutes + offset) % MINUTES_PER_DAY + MINUTES_PER_DAY) % MINUTES_PER_DAY;
}

/**
 * Whether `atMinute` falls inside the window. A window that wraps midnight is a window; a pair of
 * equal faces silences the whole day. Mirrors `NotificationPrefs.isInQuietWindow` in the app so
 * the guardian's preview and the server's behaviour cannot disagree.
 */
export function isWithinWindow(atMinute, startMinute, endMinute) {
  if (startMinute == null || endMinute == null) return false;
  if (startMinute === endMinute) return true;
  if (endMinute > startMinute) return atMinute >= startMinute && atMinute < endMinute;
  return atMinute >= startMinute || atMinute < endMinute;
}

/**
 * Whether a window is open on the guardian's clock at this UTC instant. An incomplete pair is not
 * a window — the database floor (`family_notification_preferences_quiet_pair`) forbids enabling
 * quiet hours without both faces, so a half window can only arrive from a row written before that.
 */
export function quietHoursApply({ enabled, start, end, offsetMinutes, now }) {
  if (enabled !== true) return false;
  const startMinute = timeToMinutes(start);
  const endMinute = timeToMinutes(end);
  if (startMinute == null || endMinute == null) return false;
  return isWithinWindow(localMinuteOf(now, offsetMinutes), startMinute, endMinute);
}

function wouldSuppress(definition, preferences, now) {
  const copyKey = definition?.copyKey ?? null;
  if (preferences.pushAllowed === false) return 'push_disabled';
  const muted = Array.isArray(preferences.disabledCopyKeys) ? preferences.disabledCopyKeys : [];
  if (copyKey != null && muted.includes(copyKey)) return 'copy_muted';
  if (definition?.gatedByChildRequests === true && preferences.childRequestsEnabled === false) {
    return 'child_requests_disabled';
  }
  const mode = preferences.deliveryMode ?? 'interrupt';
  if (mode === 'history_only') return 'history_only';
  if (mode === 'daily_digest') return 'digest_mode';
  if (quietHoursApply({
    enabled: preferences.quietHoursEnabled,
    start: preferences.quietHoursStart,
    end: preferences.quietHoursEnd,
    offsetMinutes: preferences.quietHoursOffsetMinutes,
    now,
  })) return 'quiet_hours';
  return null;
}

/**
 * The verdict for one recipient of one event.
 *
 * `safety_bypass` is a delivery: the notification goes out and the ledger records that a floor
 * was overridden to do it. `digest_queued` is not a delivery — the alert belongs to the family's
 * rollup instead of this instant, and the queue that carries it is the digest flusher's job.
 */
export function decideDelivery({ definition, preferences, now = new Date() }) {
  const guard = preferences ?? {};
  const when = now instanceof Date ? now : new Date(now);
  if (Number.isNaN(when.getTime())) throw new Error('notification_gate_clock_invalid');
  const blocked = wouldSuppress(definition, guard, when);
  if (blocked == null) return Object.freeze({ decision: 'delivered', reason: 'delivered' });
  if (SAFETY_COPY_KEYS.includes(definition?.copyKey)) {
    return Object.freeze({ decision: 'delivered', reason: 'safety_bypass', blockedBy: blocked });
  }
  if (blocked === 'digest_mode') {
    return Object.freeze({ decision: 'digest_queued', reason: 'digest_mode' });
  }
  return Object.freeze({ decision: 'suppressed', reason: blocked });
}
