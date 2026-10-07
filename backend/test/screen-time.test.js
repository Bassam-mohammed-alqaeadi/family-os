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
