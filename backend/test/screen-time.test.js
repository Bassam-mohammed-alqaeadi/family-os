// W5 — the laws of screen time, as pure functions.
//
// These tests need no database and no server on purpose. A rule that can only be checked
// through a socket is a rule nobody checks, and the rules below are the ones a family
// relies on without ever seeing them:
//
//   * a lock beats a bedtime, a bedtime beats a school morning, and the cap comes last;
//   * the cap counts entertainment only - a bedtime does not end the Quran app, while an
//     instant lock ends everything, because that is what a lock is for;
//   * the family's clock decides, not the server's, so a child in Sanaa is not put to bed
//     at their own lunchtime;
//   * extra minutes that were granted extend the same day they were granted for.
//
// These are the same functions the routes call. Nothing here re-implements a decision.
import assert from 'node:assert/strict';
import test from 'node:test';
import {
  DEFAULT_POLICY,
  effectiveCategory,
  evaluateAppAccess,
  evaluateScreenState,
  familyLocalParts,
  endOfFamilyDay,
  isCountable,
  remainingMinutes,
  windowContains,
  createScreenTimePolicyUpdate,
  createTimeRequestDecision,
  screenTimePolicyView,
} from '../src/screen-time.js';

const policy = (overrides = {}) => ({ ...DEFAULT_POLICY, ...overrides });
const at = (iso) => new Date(iso);

test('a window crosses midnight, which is what every bedtime does', () => {
  // 21:00 to 06:00, the shape of the bedtime a family actually sets.
  assert.equal(windowContains(1260, 360, 1300), true, 'just after bedtime is inside');
  assert.equal(windowContains(1260, 360, 30), true, 'early morning is inside the same window');
  assert.equal(windowContains(1260, 360, 600), false, '10:00 is outside it');
  assert.equal(windowContains(420, 840, 600), true, 'a school morning is inside its own window');
  assert.equal(windowContains(420, 840, 900), false, 'after the school day it is not');
  // A window with no length is not a window. Migration 105 refuses to store one; this is
  // the second place the same rule is stated, because a state machine that treats it as
  // always-open would lock a child's phone forever.
  assert.equal(windowContains(600, 600, 600), false);
});

test("the family's day, weekday and minute come from the family's own offset", () => {
  // 21:30 UTC is already tomorrow in Sanaa (+03:00), and tomorrow is a Thursday.
  const sanaa = familyLocalParts(at('2026-10-07T21:30:00.000Z'), 180);
  assert.deepEqual(sanaa, { date: '2026-10-08', weekday: 4, minuteOfDay: 30 });
  // The same instant in London is still Wednesday evening: one instant, two families.
  const london = familyLocalParts(at('2026-10-07T21:30:00.000Z'), 0);
  assert.deepEqual(london, { date: '2026-10-07', weekday: 3, minuteOfDay: 1290 });
});

test("the family's day ends at the family's midnight", () => {
  const end = endOfFamilyDay(at('2026-10-07T21:30:00.000Z'), 180);
  assert.equal(end.toISOString(), '2026-10-08T21:00:00.000Z');
});

test('the state is decided in the order the family experiences it', () => {
  const now = at('2026-10-07T20:00:00.000Z'); // 23:00 in Sanaa, inside the default bedtime
  const bedtime = evaluateScreenState({ policy: policy(), now });
  assert.equal(bedtime.kind, 'blocked');
  assert.equal(bedtime.reasonCode, 'bedtime');
  assert.equal(bedtime.since, null, 'a bedtime is not a moment somebody pressed something');

  // A lock on top of a bedtime is reported as the lock: the more specific truth wins,
  // because the parent who pressed it wants to see their own decision.
  const lock = {
    id: 'lock-1',
    reason_code: 'parent_lock',
    locked_at: '2026-10-07T19:55:00.000Z',
    locked_by_membership_id: 'guardian-1',
    released_at: null,
    version: 1,
  };
  const locked = evaluateScreenState({ policy: policy(), lock, now });
  assert.equal(locked.reasonCode, 'instant_lock');
  assert.equal(locked.since, '2026-10-07T19:55:00.000Z');

  // School beats the cap, the cap beats nothing else, and outside every window the child is
  // simply free when no cap was set.
  const schoolNow = at('2026-10-07T06:00:00.000Z'); // 09:00 Sanaa, a school day (Wednesday)
  const school = evaluateScreenState({ policy: policy({ schoolModeEnabled: true }), now: schoolNow });
  assert.equal(school.reasonCode, 'school_mode');
  const capped = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60, schoolModeEnabled: true }),
    countableUsedMinutes: 60,
    now: schoolNow,
  });
  assert.equal(capped.reasonCode, 'school_mode', 'school is still the reason');
  const overBoth = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60, schoolModeEnabled: true, bedtimeStartMinute: 1260 }),
    countableUsedMinutes: 60,
    now: at('2026-10-07T19:00:00.000Z'), // 22:00 Sanaa, past the bedtime
  });
  assert.equal(overBoth.reasonCode, 'bedtime', 'the later window is the more specific truth');
  const afterSchool = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60, schoolModeEnabled: false, bedtimeStartMinute: 1260 }),
    countableUsedMinutes: 60,
    now: at('2026-10-07T12:00:00.000Z'), // 15:00 Sanaa
  });
  assert.equal(afterSchool.reasonCode, 'daily_limit');
  assert.equal(afterSchool.remainingMinutes, 0);
  const free = evaluateScreenState({
    policy: policy({ bedtimeStartMinute: 1260 }),
    now: at('2026-10-07T12:00:00.000Z'),
  });
  assert.equal(free.kind, 'free');
  assert.equal(free.reasonCode, null);
  assert.equal(free.capMinutes, null, 'no cap means no cap, not a hidden default');
});

test('granted minutes extend the day they were granted for', () => {
  const now = at('2026-10-07T12:00:00.000Z');
  const nearly = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 55,
    now,
  });
  assert.equal(nearly.kind, 'limited');
  assert.equal(nearly.remainingMinutes, 5);
  const extended = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 60,
    grantedMinutes: 20,
    now,
  });
  assert.equal(extended.kind, 'limited');
  assert.equal(extended.reasonCode, null);
  assert.equal(extended.remainingMinutes, 20);
  // The cap with its grant can never produce a negative remainder a screen would have to
  // interpret, and 0 means exactly "nothing left".
  assert.equal(remainingMinutes({ policy: policy({ dailyLimitMinutes: 60 }), countableUsedMinutes: 90, grantedMinutes: 0 }), 0);
  assert.equal(remainingMinutes({ policy: policy({ dailyLimitMinutes: 0 }), countableUsedMinutes: 900 }), null);
});

test('entertainment counts, education and freed apps do not', () => {
  assert.equal(isCountable('games'), true);
  assert.equal(isCountable('social'), true);
  assert.equal(isCountable('tools'), true);
  assert.equal(isCountable('edu'), false);
  // An app with no category, or one this build has never heard of, is treated as
  // entertainment. A game installed this morning must not be free until a parent notices it.
  assert.equal(isCountable(undefined), true);
  assert.equal(isCountable('puzzle'), true);
  assert.equal(effectiveCategory('edu'), 'edu');
  assert.equal(effectiveCategory('puzzle'), 'games', 'the published vocabulary is closed');
  assert.equal(effectiveCategory(undefined), 'games');
});

test('a blocked app is blocked at noon and at midnight', () => {
  const state = evaluateScreenState({
    policy: policy({ bedtimeStartMinute: 1260 }),
    now: at('2026-10-07T12:00:00.000Z'),
  });
  assert.equal(state.kind, 'free');
  const blocked = evaluateAppAccess({ status: 'blocked', category: 'edu', state });
  assert.deepEqual(blocked, { allowed: false, reasonCode: 'app_blocked' });
  const pending = evaluateAppAccess({ status: 'pending', category: 'games', state });
  assert.deepEqual(pending, { allowed: false, reasonCode: 'awaiting_decision' });
});

test('bedtime ends the entertainment, not the Quran app - a lock ends everything', () => {
  const bedtime = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 90,
    now: at('2026-10-07T20:00:00.000Z'), // 23:00 Sanaa: inside the default bedtime
  });
  assert.equal(bedtime.reasonCode, 'bedtime');
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'games', state: bedtime }),
    { allowed: false, reasonCode: 'bedtime' },
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'edu', state: bedtime }),
    { allowed: true, reasonCode: null },
    'the Quran app survives a bedtime',
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'free', category: 'tools', state: bedtime }),
    { allowed: true, reasonCode: null },
    'an app the family freed is not entertainment',
  );

  // The same exhausted cap: the entertainment stops, education keeps working.
  const capped = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 60,
    now: at('2026-10-07T12:00:00.000Z'),
  });
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'social', state: capped }),
    { allowed: false, reasonCode: 'daily_limit' },
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'edu', state: capped }),
    { allowed: true, reasonCode: null },
  );

  // The instant lock is the one decision that stops everything.
  const locked = evaluateScreenState({
    policy: policy(),
    lock: { id: 'l', reason_code: 'check_in', locked_at: '2026-10-07T12:00:00.000Z', released_at: null, version: 1 },
    now: at('2026-10-07T12:00:30.000Z'),
  });
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'edu', state: locked }),
    { allowed: false, reasonCode: 'instant_lock' },
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'free', category: 'tools', state: locked }),
    { allowed: false, reasonCode: 'instant_lock' },
  );
  // ...and an app a parent deliberately blocked stays blocked even with time on the clock.
  assert.deepEqual(
    evaluateAppAccess({ status: 'blocked', category: 'games', state: evaluateScreenState({ policy: policy(), now: at('2026-10-07T12:00:00.000Z') }) }),
    { allowed: false, reasonCode: 'app_blocked' },
  );
});

test("an app's own limit is its own, and unlimited means the cap does not apply", () => {
  const state = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 30,
    now: at('2026-10-07T12:00:00.000Z'),
  });
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'games', limitMinutes: 30, usedMinutes: 30, state }),
    { allowed: false, reasonCode: 'app_limit' },
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'games', limitMinutes: 45, usedMinutes: 30, state }),
    { allowed: true, reasonCode: null },
  );
  // Unlimited lifts the family cap for one app, and never lifts a block: the two are
  // different decisions and the app-level one is checked first.
  const exhausted = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    countableUsedMinutes: 60,
    now: at('2026-10-07T12:00:00.000Z'),
  });
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'games', unlimited: true, state: exhausted }),
    { allowed: true, reasonCode: null },
    'unlimited buys exemption from the cap',
  );
  // ...and nothing else: a bedtime still ends an unlimited app's evening.
  const bedtime = evaluateScreenState({
    policy: policy({ dailyLimitMinutes: 60 }),
    now: at('2026-10-07T20:00:00.000Z'),
  });
  assert.deepEqual(
    evaluateAppAccess({ status: 'allowed', category: 'games', unlimited: true, state: bedtime }),
    { allowed: false, reasonCode: 'bedtime' },
  );
  assert.deepEqual(
    evaluateAppAccess({ status: 'blocked', category: 'games', unlimited: true, state }),
    { allowed: false, reasonCode: 'app_blocked' },
  );
});

test('the published defaults are the ones a screen may show before a family decides', () => {
  // Published, not invented: the client draws these before it has ever heard from the
  // server, so they live in one place and this pins them.
  assert.equal(DEFAULT_POLICY.dailyLimitMinutes, 0, 'no cap until a family sets one');
  assert.equal(DEFAULT_POLICY.timezoneOffsetMinutes, 180);
  assert.deepEqual([...DEFAULT_POLICY.schoolDays], [7, 1, 2, 3, 4], 'the school week runs Sunday to Thursday here');
  assert.equal(DEFAULT_POLICY.schoolStartMinute, 420);
  assert.equal(DEFAULT_POLICY.schoolEndMinute, 840);
  assert.equal(DEFAULT_POLICY.bedtimeStartMinute, 1260);
  assert.equal(DEFAULT_POLICY.bedtimeEndMinute, 360);
});

test('guardian PATCH sets earnedMinutesExtendLimit true/false; default is false for a child with no policy row; a child/handset cannot change it (403)', async () => {
  // 1. DEFAULT_POLICY and unconfigured policy view must default earnedMinutesExtendLimit to false
  assert.equal(DEFAULT_POLICY.earnedMinutesExtendLimit, false);
  const unconfigured = screenTimePolicyView(null, 'child-1');
  assert.equal(unconfigured.earnedMinutesExtendLimit, false);
  assert.equal(unconfigured.configured, false);

  // 2. Policy update port mock
  let storedRow = null;
  let auditedPayload = null;
  const mockPort = {
    idempotent: async (_scope, _key, _hash, fn) => fn({}),
    authorize: async (_tx, { subject }) => {
      if (subject === 'child-sub' || subject === 'device-sub') {
        return { id: 'm-child', role: 'child' };
      }
      return { id: 'm-guardian', role: 'primary_guardian' };
    },
    readPolicy: async () => storedRow,
    readChild: async () => ({ id: 'child-1' }),
    upsertPolicy: async (_tx, { policy: pol }) => {
      storedRow = {
        child_id: 'child-1',
        daily_limit_minutes: pol.dailyLimitMinutes,
        school_mode_enabled: pol.schoolModeEnabled,
        school_days: pol.schoolDays,
        school_start_minute: pol.schoolStartMinute,
        school_end_minute: pol.schoolEndMinute,
        bedtime_start_minute: pol.bedtimeStartMinute,
        bedtime_end_minute: pol.bedtimeEndMinute,
        timezone_offset_minutes: pol.timezoneOffsetMinutes,
        earned_minutes_extend_limit: pol.earnedMinutesExtendLimit,
        version: 1,
        updated_at: new Date(),
      };
      return storedRow;
    },
    audit: async (_tx, event) => {
      auditedPayload = event;
    },
  };

  const update = createScreenTimePolicyUpdate({ port: mockPort });

  // Guardian updates earnedMinutesExtendLimit to true
  const res = await update({
    principal: { subject: 'guardian-sub' },
    familyId: 'fam-1',
    childId: 'child-1',
    policy: { earnedMinutesExtendLimit: true },
    idempotencyKey: 'k1',
    requestHash: 'h1',
    correlationId: 'c1',
  });
  assert.equal(res.policy.earnedMinutesExtendLimit, true);
  assert.equal(storedRow.earned_minutes_extend_limit, true);
  assert.equal(auditedPayload.eventType, 'family.screen_time_policy_updated');
  assert.equal(auditedPayload.payload.earnedMinutesExtendLimit, true);

  // Child / handset caller cannot change it -> 403 screen_time_forbidden
  await assert.rejects(
    async () => {
      await update({
        principal: { subject: 'child-sub' },
        familyId: 'fam-1',
        childId: 'child-1',
        policy: { earnedMinutesExtendLimit: false },
        idempotencyKey: 'k2',
        requestHash: 'h2',
        correlationId: 'c2',
      });
    },
    (err) => err.status === 403 && err.code === 'screen_time_forbidden',
  );
});

test('approving a time request writes a temporary credit row to the ledger, and duplicates are refused', async () => {
  const ledgerRows = [];
  const requests = new Map([
    [
      'req-1',
      {
        id: 'req-1',
        family_id: 'fam-1',
        child_id: 'child-1',
        usage_date: '2026-10-22',
        status: 'pending',
        requested_minutes: 20,
        timezone_offset_minutes: 180,
        expires_at: new Date('2026-10-22T21:00:00Z'),
        version: 1,
        created_at: new Date('2026-10-22T09:00:00Z'),
      },
    ],
    [
      'req-2',
      {
        id: 'req-2',
        family_id: 'fam-1',
        child_id: 'child-1',
        usage_date: '2026-10-22',
        status: 'pending',
        requested_minutes: 15,
        timezone_offset_minutes: 180,
        expires_at: new Date('2026-10-22T21:00:00Z'),
        version: 1,
        created_at: new Date('2026-10-22T09:00:00Z'),
      },
    ],
    [
      'req-3',
      {
        id: 'req-3',
        family_id: 'fam-1',
        child_id: 'child-1',
        usage_date: '2026-10-22',
        status: 'pending',
        requested_minutes: 10,
        timezone_offset_minutes: 180,
        expires_at: new Date('2026-10-22T21:00:00Z'),
        version: 1,
        created_at: new Date('2026-10-22T09:00:00Z'),
      },
    ],
  ]);

  const mockPort = {
    idempotent: async (_scope, _key, _hash, fn) => fn({}),
    authorize: async (_tx, _req) => ({ id: 'guardian-mem-1', role: 'primary_guardian' }),
    readChild: async () => ({ id: 'child-1' }),
    expirePendingRequests: async () => {},
    readRequest: async (_tx, { requestId }) => requests.get(requestId) ?? null,
    decideRequest: async (_tx, { requestId, status, grantedMinutes, actorMembershipId }) => {
      const existing = requests.get(requestId);
      existing.status = status;
      existing.granted_minutes = grantedMinutes;
      existing.decided_by_membership_id = actorMembershipId;
      existing.decided_at = new Date();
      return existing;
    },
    recordTimeRequestGrant: async (_tx, entry) => {
      ledgerRows.push(entry);
    },
    audit: async () => {},
  };

  const decide = createTimeRequestDecision({
    port: mockPort,
    now: () => new Date('2026-10-22T10:00:00Z'),
  });

  // 1. Approving a 20-min request inserts 1 ledger row with the exact fields
  const res1 = await decide({
    principal: { subject: 'guardian-sub' },
    familyId: 'fam-1',
    childId: 'child-1',
    requestId: 'req-1',
    decision: 'approve',
    grantedMinutes: 20,
    idempotencyKey: 'k1',
    requestHash: 'h1',
    correlationId: 'c1',
  });
  assert.equal(res1.request.status, 'approved');
  assert.equal(res1.request.grantedMinutes, 20);
  assert.equal(ledgerRows.length, 1, 'approving a 20-min request inserts 1 ledger row');
  assert.deepEqual(ledgerRows[0], {
    family_id: 'fam-1',
    child_id: 'child-1',
    entry_kind: 'credit',
    channel: 'time_request_grant',
    minutes: 20,
    source_type: 'time_request',
    source_id: 'req-1',
    wallet_scope: 'temporary',
    expires_at: new Date('2026-10-22T21:00:00Z'),
    metadata: {
      approved_by: 'guardian-mem-1',
      request_id: 'req-1',
    },
  });

  // 2. Duplicate approval of the same request does not insert a second row
  await assert.rejects(
    async () => {
      await decide({
        principal: { subject: 'guardian-sub' },
        familyId: 'fam-1',
        childId: 'child-1',
        requestId: 'req-1',
        decision: 'approve',
        grantedMinutes: 20,
        idempotencyKey: 'k1-dup',
        requestHash: 'h1-dup',
        correlationId: 'c1-dup',
      });
    },
    (err) => err.status === 409 && err.code === 'time_request_decided',
  );
  assert.equal(ledgerRows.length, 1, 'duplicate approval does not insert a second row');

  // 3. Rejection inserts 0 rows
  const res2 = await decide({
    principal: { subject: 'guardian-sub' },
    familyId: 'fam-1',
    childId: 'child-1',
    requestId: 'req-2',
    decision: 'deny',
    idempotencyKey: 'k2',
    requestHash: 'h2',
    correlationId: 'c2',
  });
  assert.equal(res2.request.status, 'denied');
  assert.equal(ledgerRows.length, 1, 'rejection inserts 0 rows');

  // 4. Approval with 0 minutes inserts 0 rows
  const res3 = await decide({
    principal: { subject: 'guardian-sub' },
    familyId: 'fam-1',
    childId: 'child-1',
    requestId: 'req-3',
    decision: 'approve',
    grantedMinutes: 0,
    idempotencyKey: 'k3',
    requestHash: 'h3',
    correlationId: 'c3',
  });
  assert.equal(res3.request.status, 'approved');
  assert.equal(ledgerRows.length, 1, 'approval with 0 minutes writes NO ledger row');
});
