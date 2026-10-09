import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

/**
 * The minutes a child has, the apps those minutes belong to, and the one honest answer to
 * "may this phone be used right now".
 *
 * Why this module exists, in one paragraph: screen time is the feature families pay for,
 * and it is also the feature where a platform most easily starts lying. "Time is up" that
 * does not stop anything, a cap that a reinstall erases, a lock that a child can dismiss -
 * each of those teaches a parent to stop relying on the product, and by the time it
 * matters the trust is already gone. So the rules of this surface are stated once, here,
 * and every one of them is checkable from the outside.
 *
 * The six laws:
 *
 *   1. THE STATE IS COMPUTED, NOT STORED. Bedtime, school mode and the daily cap are
 *      evaluated from the policy, today's usage and the clock at the moment someone asks.
 *      There is no `blocked` column to go stale, and the answer a parent reads and the
 *      answer a child's handset reads are produced by the same function - the same law
 *      migration 103 holds for geofences, applied to minutes.
 *
 *   2. A LOCK IS AN EVENT WITH AN AUTHOR. An instant lock is the one state that is stored,
 *      because it is a decision a person made rather than a fact about a clock: it names
 *      the guardian, the reason and the release. One live lock per child is enforced by a
 *      partial unique index, so "lock now" pressed twice finds the lock that exists.
 *
 *   3. MINUTES NEVER SHRINK BY ACCIDENT. A usage report is cumulative for the day and the
 *      write keeps the greater of what is stored and what arrived. A retry, a replay or a
 *      handset that reconnects after a day offline can neither reduce nor inflate what a
 *      family is looking at, and there is no "estimated" anywhere in the payload.
 *
 *   4. EDUCATION AND FREE APPS ARE NOT COUNTED. The entertainment cap applies to countable
 *      apps only - the same rule the client's `AppAccessRuleMapper` already holds - while
 *      an instant lock stops everything, because that is what a lock is. Bedtime and
 *      school mode stop countable apps and leave education alone: killing Quran practice
 *      at 21:00 is not what a family asked for by setting a bedtime.
 *
 *   5. A QUESTION EXPIRES. A time request carries `expires_at`, and a request nobody
 *      answered is reported as expired rather than as "waiting for a parent" three days
 *      later. Its granted minutes belong to a stated day, so the day's allowance is the
 *      sum of that day's approvals - there is no wallet table to drift.
 *
 *   6. THE FAMILY'S CLOCK, NOT THE SERVER'S. Policy windows are evaluated in the family's
 *      own offset, which is stored data rather than an assumption: a bedtime computed in
 *      the server's timezone would lock a child's phone in the middle of their afternoon.
 *
 * Authorization, precisely:
 *
 *   read / write the family's screen time        guardians. The child's own handset reads
 *                                                and reports through the device
 *                                                credential, which proves WHICH child it
 *                                                is - this schema has no link from a
 *                                                membership to a child row, so a child
 *                                                membership cannot be proven to be the
 *                                                subject, and answering "every child in
 *                                                the family" would be surveillance.
 *   lock / unlock                                guardians.
 *   ask for more minutes                         the child's device (device credential) and
 *                                                a guardian on a child's behalf, so a
 *                                                spoken question has a record too.
 *   decide a request                             guardians. A child cannot approve itself.
 */

export const APP_CATEGORIES = Object.freeze(['games', 'social', 'edu', 'tools']);
export const APP_RULE_STATUSES = Object.freeze(['allowed', 'free', 'blocked', 'pending']);
export const LOCK_REASONS = Object.freeze(['parent_lock', 'check_in', 'task_time', 'other']);
export const REQUEST_STATUSES = Object.freeze(['pending', 'approved', 'denied', 'expired']);
export const SCREEN_STATE_KINDS = Object.freeze(['free', 'limited', 'blocked']);

/** The reasons a state or an app decision can carry, as one closed vocabulary. */
export const SCREEN_REASON_CODES = Object.freeze([
  'instant_lock',
  'bedtime',
  'school_mode',
  'daily_limit',
  'app_blocked',
  'app_limit',
  'awaiting_decision',
]);

export const MAX_REQUESTED_MINUTES = 240;
export const MAX_DAILY_LIMIT_MINUTES = 1440;
export const MAX_APP_REPORTS = 200;

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);
const APP_CATEGORY_SET = new Set(APP_CATEGORIES);
const COUNTABLE_CATEGORIES = new Set(['games', 'social', 'tools']);

/** A request nobody answers within this many hours is expired by the clock, not by a job. */
const REQUEST_MINIMUM_LIFETIME_MINUTES = 60;

function requireGuardian(actor, code, message) {
  if (!GUARDIAN_ROLES.has(actor.role)) {
    throw new HttpError(403, code, message);
  }
}

// ---------------------------------------------------------------------------------------
// The clock, in the family's own offset.
// ---------------------------------------------------------------------------------------

/**
 * The family's local day, weekday and minute-of-day for an instant.
 *
 * Returned as data rather than as a Date because every rule below is about a *window* in a
 * family's day, and a Date in the server's timezone would answer a different question.
 */
export function familyLocalParts(now, offsetMinutes) {
  const shifted = new Date(now.getTime() + offsetMinutes * 60_000);
  const weekday = shifted.getUTCDay() === 0 ? 7 : shifted.getUTCDay();
  return {
    date: shifted.toISOString().slice(0, 10),
    weekday,
    minuteOfDay: shifted.getUTCHours() * 60 + shifted.getUTCMinutes(),
  };
}

/** A window that may cross midnight, asked in minutes-of-day. */
export function windowContains(startMinute, endMinute, minuteOfDay) {
  if (startMinute === endMinute) return false;
  if (startMinute < endMinute) {
    return minuteOfDay >= startMinute && minuteOfDay < endMinute;
  }
  return minuteOfDay >= startMinute || minuteOfDay < endMinute;
}

/** The end of the family's local day, as an instant. */
export function endOfFamilyDay(now, offsetMinutes) {
  const shifted = new Date(now.getTime() + offsetMinutes * 60_000);
  const startOfDay = Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate(),
  );
  const endOfDay = startOfDay + 24 * 60 * 60 * 1000;
  return new Date(endOfDay - offsetMinutes * 60_000);
}

export const DEFAULT_POLICY = Object.freeze({
  dailyLimitMinutes: 0,
  schoolModeEnabled: false,
  schoolDays: Object.freeze([7, 1, 2, 3, 4]),
  schoolStartMinute: 420,
  schoolEndMinute: 840,
  bedtimeStartMinute: 1260,
  bedtimeEndMinute: 360,
  timezoneOffsetMinutes: 180,
});

// ---------------------------------------------------------------------------------------
// The laws, as pure functions. These are the whole product, and they are testable without
// a database because a rule that can only be checked through a socket is a rule nobody
// checks.
// ---------------------------------------------------------------------------------------

/**
 * The state of one child's device right now.
 *
 * `lock` is the live instant lock row (or null). `policy` is a stored policy or the
 * defaults. `countableUsedMinutes` is today's usage of the apps that count, and
 * `grantedMinutes` is today's approved extra time.
 */
export function evaluateScreenState({
  policy,
  countableUsedMinutes = 0,
  grantedMinutes = 0,
  lock = null,
  now = new Date(),
}) {
  const local = familyLocalParts(now, policy.timezoneOffsetMinutes);
  if (lock != null) {
    return stateView('blocked', 'instant_lock', { lock, local, policy, countableUsedMinutes, grantedMinutes });
  }
  if (windowContains(policy.bedtimeStartMinute, policy.bedtimeEndMinute, local.minuteOfDay)) {
    return stateView('blocked', 'bedtime', { lock, local, policy, countableUsedMinutes, grantedMinutes });
  }
  if (
    policy.schoolModeEnabled &&
    policy.schoolDays.includes(local.weekday) &&
    windowContains(policy.schoolStartMinute, policy.schoolEndMinute, local.minuteOfDay)
  ) {
    return stateView('blocked', 'school_mode', { lock, local, policy, countableUsedMinutes, grantedMinutes });
  }
  const remaining = remainingMinutes({ policy, countableUsedMinutes, grantedMinutes });
  if (policy.dailyLimitMinutes > 0 && remaining <= 0) {
    return stateView('blocked', 'daily_limit', { lock, local, policy, countableUsedMinutes, grantedMinutes });
  }
  return stateView(
    policy.dailyLimitMinutes > 0 ? 'limited' : 'free',
    null,
    { lock, local, policy, countableUsedMinutes, grantedMinutes },
  );
}

/** Minutes left under the cap, or null when the family set no cap for the day. */
export function remainingMinutes({ policy, countableUsedMinutes, grantedMinutes }) {
  if (policy.dailyLimitMinutes <= 0) return null;
  return Math.max(0, policy.dailyLimitMinutes + grantedMinutes - countableUsedMinutes);
}

function stateView(kind, reasonCode, { lock, local, policy, countableUsedMinutes, grantedMinutes }) {
  return Object.freeze({
    kind,
    reasonCode,
    since: lock != null && kind === 'blocked' && reasonCode === 'instant_lock'
      ? lock.locked_at ?? null
      : null,
    date: local.date,
    minuteOfDay: local.minuteOfDay,
    weekday: local.weekday,
    capMinutes: policy.dailyLimitMinutes > 0 ? policy.dailyLimitMinutes : null,
    grantedMinutes,
    countableUsedMinutes,
    remainingMinutes: remainingMinutes({ policy, countableUsedMinutes, grantedMinutes }),
    lock: lock == null ? null : lockView(lock),
  });
}

/**
 * Whether one app may be opened, and the reason when it may not.
 *
 * The order matters and is the product's order: a lock beats everything, a blocked app is
 * blocked whatever the clock says, an undecided app waits for a parent, and only then does
 * the cap apply - to the apps that count.
 */
export function evaluateAppAccess({
  status,
  category,
  limitMinutes = null,
  unlimited = false,
  usedMinutes = 0,
  state,
}) {
  // The family's two decisions about the app come first, and they come first for a reason:
  // a blocked app is blocked at noon and at midnight, and an undecided app is waiting for a
  // parent whatever the clock says.
  if (status === 'blocked') return Object.freeze({ allowed: false, reasonCode: 'app_blocked' });
  if (status === 'pending') return Object.freeze({ allowed: false, reasonCode: 'awaiting_decision' });
  // Then the clock, but only for the apps the clock is about. A bedtime, a school morning or
  // an exhausted evening cap end the entertainment; they do not end the Quran app, the
  // dictionary or the thing a teacher asked for. The instant lock is the one state that
  // stops everything, because that is what a lock is for.
  if (status === 'free' || category === 'edu') {
    return state.reasonCode === 'instant_lock'
      ? Object.freeze({ allowed: false, reasonCode: 'instant_lock' })
      : Object.freeze({ allowed: true, reasonCode: null });
  }
  // A bedtime, a school morning and a lock are statements about WHEN this phone may be
  // entertainment, so they apply whatever the budget says - including to an app the family
  // marked unlimited, which buys exemption from the cap and nothing else.
  if (state.kind === 'blocked' && state.reasonCode !== 'daily_limit') {
    return Object.freeze({ allowed: false, reasonCode: state.reasonCode });
  }
  if (limitMinutes != null && usedMinutes >= limitMinutes) {
    return Object.freeze({ allowed: false, reasonCode: 'app_limit' });
  }
  // The cap is about how much, and this app was exempted from it.
  if (unlimited) return Object.freeze({ allowed: true, reasonCode: null });
  if (state.remainingMinutes != null && state.remainingMinutes <= 0) {
    return Object.freeze({ allowed: false, reasonCode: 'daily_limit' });
  }
  return Object.freeze({ allowed: true, reasonCode: null });
}

/**
 * The category a rule or a report is treated as.
 *
 * Anything unrecognised counts as entertainment. That is the conservative direction on
 * purpose: a game the handset labelled with a word this build does not know must not be
 * free until a parent notices it, and a package the inventory has never seen is exactly
 * the app a parent is trying to limit.
 */
export function effectiveCategory(category) {
  return APP_CATEGORY_SET.has(category) ? category : 'games';
}

/** Whether a category counts against the entertainment cap. */
export function isCountable(category) {
  return COUNTABLE_CATEGORIES.has(effectiveCategory(category));
}

// ---------------------------------------------------------------------------------------
// Views: the shapes the contract publishes.
// ---------------------------------------------------------------------------------------

/**
 * A stored policy row as the flat shape the rules and the port speak.
 *
 * One function, because the read a parent makes and the read a handset makes must not be
 * able to disagree about what is stored - and because a second copy of this mapping is
 * exactly where a new field gets forgotten.
 */
export function policyFromRow(row) {
  return {
    dailyLimitMinutes: row.daily_limit_minutes,
    schoolModeEnabled: row.school_mode_enabled,
    schoolDays: row.school_days.map((day) => Number(day)),
    schoolStartMinute: row.school_start_minute,
    schoolEndMinute: row.school_end_minute,
    bedtimeStartMinute: row.bedtime_start_minute,
    bedtimeEndMinute: row.bedtime_end_minute,
    timezoneOffsetMinutes: row.timezone_offset_minutes,
  };
}

/**
 * What a family actually chose once this patch is applied.
 *
 * A screen that changes bedtime must not have to resend the daily cap, and - the part that
 * matters - the fields it did not send must keep the value the family chose rather than
 * being reset to a default nobody picked.
 */
export function mergePolicy(base, patch) {
  const merged = { ...base };
  if (patch.dailyLimitMinutes !== undefined) merged.dailyLimitMinutes = patch.dailyLimitMinutes;
  if (patch.timezoneOffsetMinutes !== undefined) merged.timezoneOffsetMinutes = patch.timezoneOffsetMinutes;
  if (patch.schoolMode !== undefined) {
    const { enabled, days, startMinute, endMinute } = patch.schoolMode;
    merged.schoolModeEnabled = enabled ?? base.schoolModeEnabled;
    merged.schoolDays = days ?? base.schoolDays;
    merged.schoolStartMinute = startMinute ?? base.schoolStartMinute;
    merged.schoolEndMinute = endMinute ?? base.schoolEndMinute;
  }
  if (patch.bedtime !== undefined) {
    const { startMinute, endMinute } = patch.bedtime;
    merged.bedtimeStartMinute = startMinute ?? base.bedtimeStartMinute;
    merged.bedtimeEndMinute = endMinute ?? base.bedtimeEndMinute;
  }
  return merged;
}

/**
 * A window with no length is not a window, and a school mode with no school days is a
 * schedule nobody can be late for. Migration 105 refuses both as a last line of defence;
 * refusing them here is what lets the answer name the field instead of a constraint.
 */
function requireCoherentPolicy(policy) {
  if (policy.bedtimeStartMinute === policy.bedtimeEndMinute) {
    throw new HttpError(
      400,
      'screen_time_window_empty',
      'bedtime.startMinute and bedtime.endMinute must differ.',
    );
  }
  if (policy.schoolModeEnabled) {
    if (policy.schoolStartMinute === policy.schoolEndMinute) {
      throw new HttpError(
        400,
        'screen_time_window_empty',
        'schoolMode.startMinute and schoolMode.endMinute must differ.',
      );
    }
    if (!Array.isArray(policy.schoolDays) || policy.schoolDays.length === 0) {
      throw new HttpError(
        400,
        'screen_time_school_days_empty',
        'School mode needs at least one weekday.',
      );
    }
  }
}

export function screenTimePolicyView(row, childId = null) {
  if (row == null) {
    return Object.freeze({
      childId,
      configured: false,
      dailyLimitMinutes: DEFAULT_POLICY.dailyLimitMinutes,
      schoolMode: Object.freeze({
        enabled: DEFAULT_POLICY.schoolModeEnabled,
        days: Object.freeze([...DEFAULT_POLICY.schoolDays]),
        startMinute: DEFAULT_POLICY.schoolStartMinute,
        endMinute: DEFAULT_POLICY.schoolEndMinute,
      }),
      bedtime: Object.freeze({
        startMinute: DEFAULT_POLICY.bedtimeStartMinute,
        endMinute: DEFAULT_POLICY.bedtimeEndMinute,
      }),
      timezoneOffsetMinutes: DEFAULT_POLICY.timezoneOffsetMinutes,
      version: null,
      updatedAt: null,
    });
  }
  return Object.freeze({
    childId: row.child_id,
    configured: true,
    dailyLimitMinutes: row.daily_limit_minutes,
    schoolMode: Object.freeze({
      enabled: row.school_mode_enabled,
      days: Object.freeze(row.school_days.map((day) => Number(day))),
      startMinute: row.school_start_minute,
      endMinute: row.school_end_minute,
    }),
    bedtime: Object.freeze({
      startMinute: row.bedtime_start_minute,
      endMinute: row.bedtime_end_minute,
    }),
    timezoneOffsetMinutes: row.timezone_offset_minutes,
    version: row.version,
    updatedAt: row.updated_at,
  });
}

export function appRuleView(row) {
  if (row == null) return null;
  return Object.freeze({
    status: row.status,
    limitMinutes: row.limit_minutes ?? null,
    unlimited: row.unlimited,
    version: row.version,
    updatedAt: row.updated_at,
  });
}

export function lockView(row) {
  if (row == null) return null;
  return Object.freeze({
    id: row.id,
    reasonCode: row.reason_code,
    lockedAt: row.locked_at,
    lockedByMembershipId: row.locked_by_membership_id ?? null,
    releasedAt: row.released_at ?? null,
    version: row.version,
  });
}

export function timeRequestView(row) {
  return Object.freeze({
    id: row.id,
    childId: row.child_id,
    usageDate: typeof row.usage_date === 'string' ? row.usage_date : row.usage_date.toISOString().slice(0, 10),
    requestedMinutes: row.requested_minutes,
    requestedByKind: row.requested_by_kind,
    reasonCode: row.reason_code ?? null,
    status: row.status,
    grantedMinutes: row.granted_minutes ?? null,
    expiresAt: row.expires_at,
    decidedAt: row.decided_at ?? null,
    decidedByMembershipId: row.decided_by_membership_id ?? null,
    version: row.version,
    createdAt: row.created_at,
  });
}

// ---------------------------------------------------------------------------------------
// Operations.
// ---------------------------------------------------------------------------------------

/**
 * Builds the read every screen starts from: policy, today's minutes, the state, the live
 * lock, today's grant and whatever question is open.
 *
 * It also settles the one thing a read is allowed to write: a pending request whose
 * `expires_at` has passed is expired, and saying so here is how the stored status and the
 * reported status stay the same fact instead of two.
 */
export function createScreenTimeRead({ port, now = () => new Date() }) {
  return async function readFamilyScreenTime({ principal, familyId, childId }) {
    return port.withTransaction(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may read a child\'s screen time.');
      return readScreenTimeInside(port, tx, { familyId, childId, now });
    });
  };
}

/** Everything the read is made of, shared by every operation that returns a state. */
async function readScreenTimeInside(port, tx, { familyId, childId, now }) {
  const child = await port.readChild(tx, { familyId, childId });
  if (child == null) {
    throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
  }
  await port.expirePendingRequests(tx, { childId });
  const row = await port.readPolicy(tx, { familyId, childId });
  const policy = row == null ? DEFAULT_POLICY : policyFromRow(row);
  const local = familyLocalParts(now(), policy.timezoneOffsetMinutes);
  const usage = await port.readUsageForDate(tx, { childId, usageDate: local.date });
  const rules = await port.readAppRules(tx, { childId });
  const countableUsedMinutes = countableMinutes({ usage, rules });
  const grantedMinutes = await port.readGrantedMinutes(tx, { childId, usageDate: local.date });
  const lock = await port.readLiveLock(tx, { childId });
  const state = evaluateScreenState({ policy, countableUsedMinutes, grantedMinutes, lock, now: now() });
  const pending = await port.readPendingRequest(tx, { childId });
  return {
    childId,
    date: local.date,
    policy: screenTimePolicyView(row, childId),
    state,
    lock: lockView(lock),
    usage: Object.freeze({
      date: local.date,
      countableUsedMinutes,
      grantedMinutes,
      remainingMinutes: state.remainingMinutes,
      byApp: Object.freeze(
        usage
          .slice()
          .sort((left, right) => left.app_id.localeCompare(right.app_id))
          .map((entry) => Object.freeze({
            appId: entry.app_id,
            usedMinutes: entry.used_minutes,
          })),
      ),
    }),
    openRequest: pending == null ? null : timeRequestView(pending),
  };
}

/**
 * Today's countable minutes.
 *
 * An app nobody wrote a rule for counts if its reported category counts: a game installed
 * this morning must not be free until a parent notices it. Education and free apps do not
 * count - that is what those words mean here.
 */
function countableMinutes({ usage, rules }) {
  const byApp = new Map(rules.map((rule) => [rule.app_id, rule]));
  let total = 0;
  for (const entry of usage) {
    const rule = byApp.get(entry.app_id);
    if (rule?.status === 'free') continue;
    const category = rule?.category ?? entry.category;
    if (!isCountable(category)) continue;
    total += entry.used_minutes;
  }
  return total;
}

/** Changes the family's policy for one child. Guardians only, version-checked when asked. */
export function createScreenTimePolicyUpdate({ port }) {
  return async function updateFamilyScreenTimePolicy({
    principal,
    familyId,
    childId,
    policy,
    expectedVersion = null,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:policy:${familyId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may change the screen-time policy.');
        const existing = await port.readPolicy(tx, { familyId, childId }, { forUpdate: true });
        if (existing == null) {
          const child = await port.readChild(tx, { familyId, childId });
          if (child == null) {
            throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
          }
        }
        if (expectedVersion != null) {
          const current = existing?.version ?? 0;
          if (current !== expectedVersion) {
            throw new HttpError(
              409,
              'screen_time_stale_version',
              'The policy changed since this screen read it.',
            );
          }
        }
        const merged = mergePolicy(
          existing == null ? DEFAULT_POLICY : policyFromRow(existing),
          policy,
        );
        requireCoherentPolicy(merged);
        const row = await port.upsertPolicy(tx, {
          familyId,
          childId,
          policy: merged,
          expectedVersion,
          actorMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: childId,
          subjectType: 'screen_time_policy',
          eventType: 'family.screen_time_policy_updated',
        });
        return { policy: screenTimePolicyView(row) };
      },
    );
  };
}

/** The app inventory with each app's rule, today's minutes and the decision that follows. */
export function createChildAppsRead({ port, now = () => new Date() }) {
  return async function readFamilyChildApps({ principal, familyId, childId }) {
    return port.withTransaction(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may read a child\'s apps.');
      const child = await port.readChild(tx, { familyId, childId });
      if (child == null) {
        throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
      }
      // The read names the family as well: it is what the policy query is keyed on, and a
      // child whose policy is looked up without it would silently read the defaults.
      return appsInside(port, tx, { familyId, childId, now });
    });
  };
}

async function appsInside(port, tx, { familyId, childId, now }) {
  const rules = await port.readAppRules(tx, { childId });
  const inventory = await port.readApps(tx, { childId });
  const policyRow = await port.readPolicy(tx, { familyId, childId });
  const policy = policyRow == null ? DEFAULT_POLICY : policyFromRow(policyRow);
  const local = familyLocalParts(now(), policy.timezoneOffsetMinutes);
  const usage = await port.readUsageForDate(tx, { childId, usageDate: local.date });
  const grantedMinutes = await port.readGrantedMinutes(tx, { childId, usageDate: local.date });
  const lock = await port.readLiveLock(tx, { childId });
  const rulesByApp = new Map(rules.map((rule) => [rule.app_id, rule]));
  const usageByApp = new Map(usage.map((entry) => [entry.app_id, entry.used_minutes]));
  const inventoryByApp = new Map(inventory.map((entry) => [entry.app_id, entry]));

  // Every app the family has an opinion about, plus every app the handset reported. An app
  // in the inventory with no rule is `pending` - visible, undecided, not silently allowed.
  const appIds = [...new Set([...rulesByApp.keys(), ...inventoryByApp.keys()])].sort();
  const mergedRules = appIds.map((appId) =>
    rulesByApp.get(appId) ?? {
      app_id: appId,
      status: 'pending',
      limit_minutes: null,
      unlimited: false,
      version: 0,
      updated_at: null,
    },
  );
  const countableUsedMinutes = countableMinutes({
    usage,
    rules: mergedRules.map((rule) => ({ ...rule, category: inventoryByApp.get(rule.app_id)?.category })),
  });
  const state = evaluateScreenState({ policy, countableUsedMinutes, grantedMinutes, lock, now: now() });

  return {
    childId,
    date: local.date,
    state,
    apps: Object.freeze(
      appIds.map((appId) => {
        const rule = rulesByApp.get(appId) ?? null;
        const inventoryEntry = inventoryByApp.get(appId) ?? null;
        const status = rule?.status ?? 'pending';
        const category = effectiveCategory(inventoryEntry?.category);
        const countable = status !== 'free' && isCountable(category);
        const usedMinutes = usageByApp.get(appId) ?? 0;
        const decision = evaluateAppAccess({
          status,
          category,
          limitMinutes: rule?.limit_minutes ?? null,
          unlimited: rule?.unlimited ?? false,
          usedMinutes,
          state,
        });
        return Object.freeze({
          appId,
          displayName: inventoryEntry?.display_name ?? appId,
          category,
          ageRating: inventoryEntry?.age_rating ?? '',
          knownOnDevice: inventoryEntry != null,
          countable,
          usedMinutes,
          remainingMinutes:
            rule?.limit_minutes != null && countable
              ? Math.max(0, rule.limit_minutes - usedMinutes)
              : null,
          rule: appRuleView(rule),
          decision,
        });
      }),
    ),
  };
}

/** One app's rule: allowed, free, blocked, or undecided again. Guardians only. */
export function createAppRuleUpdate({ port }) {
  return async function updateFamilyAppRule({
    principal,
    familyId,
    childId,
    appId,
    rule,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:rule:${familyId}:${childId}:${appId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may change an app rule.');
        const child = await port.readChild(tx, { familyId, childId });
        if (child == null) {
          throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
        }
        const inventoryEntry = await port.readApp(tx, { childId, appId });
        const row = await port.upsertRule(tx, {
          familyId,
          childId,
          appId,
          rule,
          actorMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: row.id,
          subjectType: 'child_app_rule',
          eventType: 'family.app_rule_updated',
        });
        return {
          appId,
          knownOnDevice: inventoryEntry != null,
          category: inventoryEntry?.category ?? null,
          rule: appRuleView(row),
        };
      },
    );
  };
}

/** "This phone is off now." A guardian's decision, with a reason and an author. */
export function createScreenTimeLock({ port, now = () => new Date() }) {
  return async function lockFamilyChildScreen({
    principal,
    familyId,
    childId,
    reasonCode,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:lock:${familyId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may lock a child\'s screen.');
        const child = await port.readChild(tx, { familyId, childId });
        if (child == null) {
          throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
        }
        const existing = await port.readLiveLock(tx, { childId, forUpdate: true });
        // Pressing "lock now" twice is one decision. The lock that exists is the answer,
        // which is also what makes the second press safe to retry.
        const lock = existing ?? await port.insertLock(tx, {
          familyId,
          childId,
          reasonCode,
          actorMembershipId: actor.id,
        });
        if (existing == null) {
          await port.audit(tx, {
            familyId,
            actorMembershipId: actor.id,
            correlationId,
            subjectId: lock.id,
            subjectType: 'child_lock',
            eventType: 'family.child_screen_locked',
          });
        }
        return { created: existing == null, ...(await readScreenTimeInside(port, tx, { familyId, childId, now })) };
      },
    );
  };
}

/** Releases the live lock. Unlocking nothing is answered honestly rather than as an error. */
export function createScreenTimeUnlock({ port, now = () => new Date() }) {
  return async function unlockFamilyChildScreen({
    principal,
    familyId,
    childId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:unlock:${familyId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may unlock a child\'s screen.');
        const child = await port.readChild(tx, { familyId, childId });
        if (child == null) {
          throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
        }
        const live = await port.readLiveLock(tx, { childId, forUpdate: true });
        let released = null;
        if (live != null) {
          released = await port.releaseLock(tx, { lockId: live.id, actorMembershipId: actor.id });
          await port.audit(tx, {
            familyId,
            actorMembershipId: actor.id,
            correlationId,
            subjectId: live.id,
            subjectType: 'child_lock',
            eventType: 'family.child_screen_unlocked',
          });
        }
        return {
          released: released != null,
          ...(await readScreenTimeInside(port, tx, { familyId, childId, now })),
        };
      },
    );
  };
}

/** The questions asked, newest first, with the family's clock settling what expired. */
export function createTimeRequestList({ port, now = () => new Date() }) {
  return async function listFamilyTimeRequests({ principal, familyId, childId, status }) {
    return port.withTransaction(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may read a child\'s requests.');
      const child = await port.readChild(tx, { familyId, childId });
      if (child == null) {
        throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
      }
      await port.expirePendingRequests(tx, { childId });
      const rows = await port.readRequests(tx, { childId, status });
      return {
        childId,
        requests: Object.freeze(rows.map((row) => timeRequestView(row))),
      };
    });
  };
}

/**
 * A question: the child's handset asks through its own credential, and a guardian may ask
 * on the child's behalf - the spoken version of the same request, recorded the same way.
 */
export function createTimeRequestCreate({ port, now = () => new Date() }) {
  return async function createFamilyTimeRequest({
    principal,
    deviceCredential,
    deviceId,
    familyId,
    childId,
    requestedMinutes,
    reasonCode,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      deviceId == null
        ? `screen-time:request:${familyId}:${childId}`
        : `screen-time:request:device:${deviceId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        let subjectChildId = childId;
        let actorMembershipId;
        let requestedByKind;
        let effectiveFamilyId = familyId;
        if (deviceId != null) {
          const device = await port.readReportingDevice(tx, { deviceId });
          if (
            device == null
            || device.credential_revoked_at != null
            || !port.credentialMatches(device.credential_hash, deviceCredential)
          ) {
            throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
          }
          // The handset is the proof of which child is asking; there is no childId parameter
          // on this route, and this is why.
          subjectChildId = device.child_id;
          effectiveFamilyId = device.family_id;
          requestedByKind = 'child';
          actorMembershipId = null;
        } else {
          const actor = await port.authorize(tx, { familyId, subject: principal.subject });
          requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may ask on a child\'s behalf.');
          requestedByKind = 'guardian';
          actorMembershipId = actor.id;
        }
        const child = await port.readChild(tx, { familyId: effectiveFamilyId, childId: subjectChildId });
        if (child == null) {
          throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
        }
        const row = await port.readPolicy(tx, { familyId: effectiveFamilyId, childId: subjectChildId });
        if (row == null || row.daily_limit_minutes <= 0) {
          // Extra minutes exist only under a cap. Granting "more" when nothing is limited
          // would put a number on a screen that the server never enforces.
          throw new HttpError(
            409,
            'screen_time_no_cap',
            'This child has no daily cap to extend.',
          );
        }
        await port.expirePendingRequests(tx, { childId: subjectChildId });
        const pending = await port.readPendingRequest(tx, { childId: subjectChildId, forUpdate: true });
        if (pending != null) {
          // Asking twice is the same question. The child gets the question that is already
          // open rather than a second one a parent has to reconcile.
          throw new HttpError(
            409,
            'time_request_pending',
            'A request is already waiting for an answer.',
            { requestId: pending.id },
          );
        }
        const requestedAt = now();
        const localEnd = endOfFamilyDay(requestedAt, row.timezone_offset_minutes);
        const minimumEnd = new Date(requestedAt.getTime() + REQUEST_MINIMUM_LIFETIME_MINUTES * 60_000);
        const expiresAt = localEnd > minimumEnd ? localEnd : minimumEnd;
        const created = await port.insertRequest(tx, {
          familyId: effectiveFamilyId,
          childId: subjectChildId,
          usageDate: familyLocalParts(requestedAt, row.timezone_offset_minutes).date,
          requestedMinutes,
          requestedByKind,
          requestedByMembershipId: actorMembershipId,
          reasonCode,
          expiresAt,
        });
        if (actorMembershipId != null) {
          await port.audit(tx, {
            familyId: effectiveFamilyId,
            actorMembershipId,
            correlationId,
            subjectId: created.id,
            subjectType: 'time_request',
            eventType: 'family.time_request_created',
          });
        }
        return { request: timeRequestView(created) };
      },
    );
  };
}

/** The answer: approve with minutes, or deny. Once, by a guardian, before it expires. */
export function createTimeRequestDecision({ port, now = () => new Date() }) {
  return async function decideFamilyTimeRequest({
    principal,
    familyId,
    childId,
    requestId,
    decision,
    grantedMinutes,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:decide:${familyId}:${requestId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'screen_time_forbidden', 'Only a guardian may answer a time request.');
        const child = await port.readChild(tx, { familyId, childId });
        if (child == null) {
          throw new HttpError(404, 'child_not_found', 'This child is not part of the family.');
        }
        await port.expirePendingRequests(tx, { childId });
        const row = await port.readRequest(tx, { childId, requestId, forUpdate: true });
        if (row == null) {
          throw new HttpError(404, 'time_request_not_found', 'This request is not part of the family.');
        }
        if (row.status !== 'pending') {
          throw new HttpError(
            409,
            'time_request_decided',
            `This request is already ${row.status}.`,
          );
        }
        // A parent may grant less than the child asked and never more: "20 minutes please"
        // answered with 40 is an answer to a different question, and migration 105 refuses
        // it too. The refusal names the number rather than surfacing a constraint name.
        const granting = decision === 'approve' ? (grantedMinutes ?? row.requested_minutes) : null;
        if (granting != null && granting > row.requested_minutes) {
          throw new HttpError(
            400,
            'screen_time_grant_exceeds_request',
            'A grant cannot exceed the minutes the child asked for.',
          );
        }
        const decided = await port.decideRequest(tx, {
          requestId,
          status: decision === 'approve' ? 'approved' : 'denied',
          grantedMinutes: granting,
          actorMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: requestId,
          subjectType: 'time_request',
          eventType: decision === 'approve'
            ? 'family.time_request_approved'
            : 'family.time_request_denied',
        });
        return { request: timeRequestView(decided) };
      },
    );
  };
}

/**
 * The child's own handset reporting in, and the one answer it needs back.
 *
 * Usage and inventory arrive together because they are collected together, and the response
 * is the same state a guardian reads - computed by the same function, from the same rows.
 * A report of "I asked for 20 more minutes" travels in the same call for the same reason:
 * one round trip, one clock, one answer.
 */
export function createDeviceScreenTimeReport({ port, now = () => new Date() }) {
  return async function reportDeviceScreenTime({
    deviceCredential,
    deviceId,
    usage,
    apps,
    requestMinutes,
    requestReasonCode,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `screen-time:report:${deviceId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await port.readReportingDevice(tx, { deviceId });
        if (
          device == null
          || device.credential_revoked_at != null
          || !port.credentialMatches(device.credential_hash, deviceCredential)
        ) {
          throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
        }
        const familyId = device.family_id;
        const childId = device.child_id;
        const reportedAt = now();
        const policyRow = await port.readPolicy(tx, { familyId, childId });
        const offset = policyRow?.timezone_offset_minutes ?? DEFAULT_POLICY.timezoneOffsetMinutes;
        const today = familyLocalParts(reportedAt, offset).date;

        // The device may state the day it measured, which is how a handset that was offline
        // overnight reports yesterday rather than crediting the minutes to today. A date it
        // could not have measured is refused: the trail is bounded by what is checkable.
        const dayFloor = familyLocalParts(
          new Date(reportedAt.getTime() - 48 * 60 * 60 * 1000),
          offset,
        ).date;
        const rows = [];
        for (const entry of usage) {
          const usageDate = entry.date ?? today;
          if (usageDate < dayFloor || usageDate > today) {
            throw new HttpError(
              400,
              'invalid_request',
              'usage[].date must be today or the day before, in the family\'s own clock.',
            );
          }
          rows.push({
            id: randomUUID(),
            familyId,
            childId,
            appId: entry.appId,
            usageDate,
            usedMinutes: entry.usedMinutes,
            deviceId,
          });
        }
        if (rows.length > 0) await port.upsertUsage(tx, { rows });
        if (apps.length > 0) {
          await port.upsertApps(tx, {
            rows: apps.map((entry) => ({
              id: randomUUID(),
              familyId,
              childId,
              appId: entry.appId,
              displayName: entry.displayName,
              category: entry.category,
              ageRating: entry.ageRating ?? '',
              deviceId,
            })),
          });
        }
        let request = null;
        if (requestMinutes != null) {
          if (policyRow == null || policyRow.daily_limit_minutes <= 0) {
            throw new HttpError(409, 'screen_time_no_cap', 'This child has no daily cap to extend.');
          }
          await port.expirePendingRequests(tx, { childId });
          const pending = await port.readPendingRequest(tx, { childId, forUpdate: true });
          request = pending;
          if (pending == null) {
            const localEnd = endOfFamilyDay(reportedAt, offset);
            const minimumEnd = new Date(
              reportedAt.getTime() + REQUEST_MINIMUM_LIFETIME_MINUTES * 60_000,
            );
            request = await port.insertRequest(tx, {
              familyId,
              childId,
              usageDate: today,
              requestedMinutes: requestMinutes,
              requestedByKind: 'child',
              requestedByMembershipId: null,
              reasonCode: requestReasonCode,
              expiresAt: localEnd > minimumEnd ? localEnd : minimumEnd,
            });
          }
        }
        void correlationId;
        // The answer to a reporting handset is the same state a guardian reads plus the
        // inventory, computed by the same functions from the same rows. `openRequest`
        // already carries whatever question is now waiting - the one this call raised
        // included - so there is exactly one field describing it.
        const screen = await readScreenTimeInside(port, tx, { familyId, childId, now });
        const appView = await appsInside(port, tx, { familyId, childId, now });
        return { ...screen, apps: appView.apps, reportedRequest: request == null ? null : timeRequestView(request) };
      },
    );
  };
}

/** The child's handset reading its own state, with the same answer a parent would get. */
export function createDeviceScreenTimeRead({ port, now = () => new Date() }) {
  return async function readDeviceScreenTime({ deviceCredential, deviceId }) {
    return port.withTransaction(async (tx) => {
      const device = await port.readReportingDevice(tx, { deviceId });
      if (
        device == null
        || device.credential_revoked_at != null
        || !port.credentialMatches(device.credential_hash, deviceCredential)
      ) {
        throw new HttpError(403, 'device_credential_rejected', 'The device credential is not accepted.');
      }
      const familyId = device.family_id;
      const childId = device.child_id;
      // One shape for both doors to this state: the read a guardian makes and the read a
      // handset makes are the same rows through the same functions, and the handset simply
      // also gets the inventory. `reportedRequest` is null here because this call raised no
      // question - null is the honest answer, not a missing field.
      const screen = await readScreenTimeInside(port, tx, { familyId, childId, now });
      const appView = await appsInside(port, tx, { familyId, childId, now });
      return { ...screen, apps: appView.apps, reportedRequest: null };
    });
  };
}

// ---------------------------------------------------------------------------------------
// The PostgreSQL port: data access only, no rules.
// ---------------------------------------------------------------------------------------

const POLICY_COLUMNS = `child_id, family_id, daily_limit_minutes, school_mode_enabled, school_days,
                        school_start_minute, school_end_minute, bedtime_start_minute,
                        bedtime_end_minute, timezone_offset_minutes, version, updated_at`;

const RULE_COLUMNS = `id, family_id, child_id, app_id, status, limit_minutes, unlimited, version,
                      updated_at`;

const REQUEST_COLUMNS = `id, family_id, child_id, usage_date, requested_minutes, requested_by_kind,
                         requested_by_membership_id, reason_code, status, granted_minutes, expires_at,
                         decided_at, decided_by_membership_id, version, created_at, updated_at`;

const LOCK_COLUMNS = `id, family_id, child_id, reason_code, locked_at, locked_by_membership_id,
                      released_at, released_by_membership_id, version`;

export function postgresScreenTimePort(store, { credentialMatches }) {
  return {
    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    async authorize(client, { familyId, subject }) {
      return store.activeActorMembership(client, familyId, subject);
    },

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readPolicy(client, { familyId, childId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${POLICY_COLUMNS}
           FROM family_child_screen_time_policies
          WHERE child_id = $1 ${familyId == null ? '' : 'AND family_id = $2'}
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        familyId == null ? [childId] : [childId, familyId],
      );
      return rows[0] ?? null;
    },

    async upsertPolicy(client, { familyId, childId, policy, actorMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_child_screen_time_policies
           (child_id, family_id, daily_limit_minutes, school_mode_enabled, school_days,
            school_start_minute, school_end_minute, bedtime_start_minute, bedtime_end_minute,
            timezone_offset_minutes, updated_by_membership_id)
         VALUES ($1, $2, $3, $4, $5::smallint[], $6, $7, $8, $9, $10, $11)
         ON CONFLICT (child_id) DO UPDATE
            SET daily_limit_minutes = EXCLUDED.daily_limit_minutes,
                school_mode_enabled = EXCLUDED.school_mode_enabled,
                school_days = EXCLUDED.school_days,
                school_start_minute = EXCLUDED.school_start_minute,
                school_end_minute = EXCLUDED.school_end_minute,
                bedtime_start_minute = EXCLUDED.bedtime_start_minute,
                bedtime_end_minute = EXCLUDED.bedtime_end_minute,
                timezone_offset_minutes = EXCLUDED.timezone_offset_minutes,
                updated_by_membership_id = EXCLUDED.updated_by_membership_id,
                version = family_child_screen_time_policies.version + 1,
                updated_at = NOW()
         RETURNING ${POLICY_COLUMNS}`,
        [
          childId,
          familyId,
          policy.dailyLimitMinutes,
          policy.schoolModeEnabled,
          policy.schoolDays,
          policy.schoolStartMinute,
          policy.schoolEndMinute,
          policy.bedtimeStartMinute,
          policy.bedtimeEndMinute,
          policy.timezoneOffsetMinutes,
          actorMembershipId,
        ],
      );
      return rows[0];
    },

    async readAppRules(client, { childId }) {
      const { rows } = await client.query(
        `SELECT ${RULE_COLUMNS} FROM family_child_app_rules WHERE child_id = $1 ORDER BY app_id ASC`,
        [childId],
      );
      return rows;
    },

    async readApps(client, { childId }) {
      const { rows } = await client.query(
        `SELECT app_id, display_name, category, age_rating
           FROM family_child_apps
          WHERE child_id = $1
          ORDER BY app_id ASC`,
        [childId],
      );
      return rows;
    },

    async readApp(client, { childId, appId }) {
      const { rows } = await client.query(
        `SELECT app_id, display_name, category, age_rating
           FROM family_child_apps
          WHERE child_id = $1 AND app_id = $2`,
        [childId, appId],
      );
      return rows[0] ?? null;
    },

    async upsertRule(client, { familyId, childId, appId, rule, actorMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_child_app_rules
           (id, family_id, child_id, app_id, status, limit_minutes, unlimited, updated_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (child_id, app_id) DO UPDATE
            SET status = EXCLUDED.status,
                limit_minutes = EXCLUDED.limit_minutes,
                unlimited = EXCLUDED.unlimited,
                updated_by_membership_id = EXCLUDED.updated_by_membership_id,
                version = family_child_app_rules.version + 1,
                updated_at = NOW()
         RETURNING ${RULE_COLUMNS}`,
        [
          randomUUID(),
          familyId,
          childId,
          appId,
          rule.status,
          rule.limitMinutes ?? null,
          rule.unlimited ?? false,
          actorMembershipId,
        ],
      );
      return rows[0];
    },

    async readUsageForDate(client, { childId, usageDate }) {
      const { rows } = await client.query(
        `SELECT usage.app_id, usage.used_minutes, apps.category
           FROM family_child_app_usage_daily AS usage
           LEFT JOIN family_child_apps AS apps
             ON apps.child_id = usage.child_id AND apps.app_id = usage.app_id
          WHERE usage.child_id = $1 AND usage.usage_date = $2
          ORDER BY usage.app_id ASC`,
        [childId, usageDate],
      );
      return rows;
    },

    async upsertUsage(client, { rows }) {
      // GREATEST is the whole rule: a report can move today's number forward and never back.
      // A handset that reconnects and replays yesterday's total cannot un-use minutes, and a
      // duplicate delivery cannot double them.
      for (const row of rows) {
        await client.query(
          `INSERT INTO family_child_app_usage_daily
             (id, family_id, child_id, app_id, usage_date, used_minutes, reported_by_device_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (child_id, app_id, usage_date) DO UPDATE
              SET used_minutes = GREATEST(family_child_app_usage_daily.used_minutes, EXCLUDED.used_minutes),
                  reported_by_device_id = EXCLUDED.reported_by_device_id,
                  reported_at = NOW()`,
          [row.id, row.familyId, row.childId, row.appId, row.usageDate, row.usedMinutes, row.deviceId],
        );
      }
    },

    async upsertApps(client, { rows }) {
      for (const row of rows) {
        await client.query(
          `INSERT INTO family_child_apps
             (id, family_id, child_id, app_id, display_name, category, age_rating, reported_by_device_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (child_id, app_id) DO UPDATE
              SET display_name = EXCLUDED.display_name,
                  category = EXCLUDED.category,
                  age_rating = EXCLUDED.age_rating,
                  last_seen_at = NOW(),
                  reported_by_device_id = EXCLUDED.reported_by_device_id`,
          [row.id, row.familyId, row.childId, row.appId, row.displayName, row.category, row.ageRating, row.deviceId],
        );
      }
    },

    async readGrantedMinutes(client, { childId, usageDate }) {
      const { rows } = await client.query(
        `SELECT COALESCE(SUM(granted_minutes), 0)::int AS granted
           FROM family_child_time_requests
          WHERE child_id = $1 AND usage_date = $2 AND status = 'approved'`,
        [childId, usageDate],
      );
      return rows[0]?.granted ?? 0;
    },

    async readLiveLock(client, { childId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT ${LOCK_COLUMNS}
           FROM family_child_lock_state
          WHERE child_id = $1 AND released_at IS NULL
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [childId],
      );
      return rows[0] ?? null;
    },

    async insertLock(client, { familyId, childId, reasonCode, actorMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_child_lock_state
           (id, family_id, child_id, reason_code, locked_by_membership_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING ${LOCK_COLUMNS}`,
        [randomUUID(), familyId, childId, reasonCode, actorMembershipId],
      );
      return rows[0];
    },

    async releaseLock(client, { lockId, actorMembershipId }) {
      const { rows } = await client.query(
        `UPDATE family_child_lock_state
            SET released_at = NOW(),
                released_by_membership_id = $2,
                version = version + 1
          WHERE id = $1 AND released_at IS NULL
          RETURNING ${LOCK_COLUMNS}`,
        [lockId, actorMembershipId],
      );
      return rows[0] ?? null;
    },

    async expirePendingRequests(client, { childId }) {
      // A clock, not a judgment: the question was already unanswered when its time passed.
      // Settling it here keeps the stored status and the reported status the same fact, and
      // it is what frees the one-pending-per-child index for the next question.
      const { rowCount } = await client.query(
        `UPDATE family_child_time_requests
            SET status = 'expired',
                version = version + 1,
                updated_at = NOW()
          WHERE child_id = $1 AND status = 'pending' AND expires_at <= NOW()`,
        [childId],
      );
      return rowCount;
    },

    async readPendingRequest(client, { childId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT ${REQUEST_COLUMNS}
           FROM family_child_time_requests
          WHERE child_id = $1 AND status = 'pending'
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [childId],
      );
      return rows[0] ?? null;
    },

    async readRequest(client, { childId, requestId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT ${REQUEST_COLUMNS}
           FROM family_child_time_requests
          WHERE child_id = $1 AND id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [childId, requestId],
      );
      return rows[0] ?? null;
    },

    async readRequests(client, { childId, status = 'all' }) {
      const { rows } = await client.query(
        `SELECT ${REQUEST_COLUMNS}
           FROM family_child_time_requests
          WHERE child_id = $1 ${status === 'all' ? '' : 'AND status = $2'}
          ORDER BY created_at DESC, id DESC`,
        status === 'all' ? [childId] : [childId, status],
      );
      return rows;
    },

    async insertRequest(client, request) {
      const { rows } = await client.query(
        `INSERT INTO family_child_time_requests
           (id, family_id, child_id, usage_date, requested_minutes, requested_by_kind,
            requested_by_membership_id, reason_code, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING ${REQUEST_COLUMNS}`,
        [
          randomUUID(),
          request.familyId,
          request.childId,
          request.usageDate,
          request.requestedMinutes,
          request.requestedByKind,
          request.requestedByMembershipId,
          request.reasonCode ?? null,
          request.expiresAt,
        ],
      );
      return rows[0];
    },

    async decideRequest(client, { requestId, status, grantedMinutes, actorMembershipId }) {
      const { rows } = await client.query(
        `UPDATE family_child_time_requests
            SET status = $2,
                granted_minutes = $3,
                decided_at = NOW(),
                decided_by_membership_id = $4,
                version = version + 1,
                updated_at = NOW()
          WHERE id = $1 AND status = 'pending'
          RETURNING ${REQUEST_COLUMNS}`,
        [requestId, status, grantedMinutes, actorMembershipId],
      );
      return rows[0];
    },

    async readReportingDevice(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices
          WHERE id = $1
          FOR UPDATE`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    credentialMatches,

    async audit(client, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        eventType,
        subjectType,
        subjectId,
      });
    },
  };
}

/** Builds every operation for a server that was handed a Foundation store. */
export function screenTimeFor(store, { credentialMatches }) {
  const port = postgresScreenTimePort(store, { credentialMatches });
  return {
    read: createScreenTimeRead({ port }),
    updatePolicy: createScreenTimePolicyUpdate({ port }),
    listApps: createChildAppsRead({ port }),
    updateAppRule: createAppRuleUpdate({ port }),
    lock: createScreenTimeLock({ port }),
    unlock: createScreenTimeUnlock({ port }),
    listTimeRequests: createTimeRequestList({ port }),
    createTimeRequest: createTimeRequestCreate({ port }),
    decideTimeRequest: createTimeRequestDecision({ port }),
    reportFromDevice: createDeviceScreenTimeReport({ port }),
    readFromDevice: createDeviceScreenTimeRead({ port }),
  };
}
