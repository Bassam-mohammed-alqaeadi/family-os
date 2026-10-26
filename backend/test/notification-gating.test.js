// The gate is the family's silence, so its arithmetic is pinned here rather than trusted:
// a window that wraps midnight, a guardian east of UTC, and the four safety keys that outrank
// every wish. These are pure-function proofs; `postgres-notification-delivery.test.js` proves the
// same rules are the ones the dispatcher actually applies and writes down.
import assert from 'node:assert/strict';
import test from 'node:test';
import {
  GATE_DECISIONS,
  GATE_REASONS,
  SAFETY_COPY_KEYS,
  decideDelivery,
  isWithinWindow,
  localMinuteOf,
  quietHoursApply,
  timeToMinutes,
} from '../src/notification-gating.js';

const at = (iso) => new Date(iso);
const sos = { copyKey: 'sos.raised', subject: 'child', urgency: 'alert' };
const claim = { copyKey: 'task.claimed', subject: 'child', urgency: 'normal', gatedByChildRequests: true };

test('a TIME arrives as a clock face, with or without seconds, and nothing else', () => {
  assert.equal(timeToMinutes('22:00'), 1_320);
  assert.equal(timeToMinutes('07:00:00'), 420);
  assert.equal(timeToMinutes(' 00:00 '), 0);
  assert.equal(timeToMinutes('23:59:59.123456'), 1_439);
  assert.equal(timeToMinutes(null), null);
  assert.equal(timeToMinutes('24:00'), null);
  assert.equal(timeToMinutes('9am'), null);
  assert.equal(timeToMinutes(''), null);
});

test('the guardian\'s clock, not UTC, decides the minute of the day', () => {
  // 22:30 UTC is 01:30 for a guardian at UTC+3, and 17:30 for one at UTC-5.
  assert.equal(localMinuteOf(at('2026-10-26T22:30:00Z'), 180), 90);
  assert.equal(localMinuteOf(at('2026-10-26T22:30:00Z'), -300), 1_050);
  assert.equal(localMinuteOf(at('2026-10-26T00:10:00Z'), -60), 1_390);
  // A missing or unusable offset reads as UTC, never as a crash or a guess.
  assert.equal(localMinuteOf(at('2026-10-26T22:30:00Z'), undefined), 1_350);
  assert.equal(localMinuteOf(at('2026-10-26T22:30:00Z'), '3'), 1_350);
});

test('a window that wraps midnight is a window, and equal faces are a whole day', () => {
  assert.equal(isWithinWindow(1_330, 1_320, 420), true, '22:10 is inside 22:00 → 07:00');
  assert.equal(isWithinWindow(419, 1_320, 420), true, '06:59 is inside 22:00 → 07:00');
  assert.equal(isWithinWindow(420, 1_320, 420), false, 'the end face is exclusive');
  assert.equal(isWithinWindow(1_319, 1_320, 420), false, 'one minute before the start is awake');
  assert.equal(isWithinWindow(600, 540, 660), true, 'a daytime window works the same way');
  assert.equal(isWithinWindow(1_320, 1_320, 1_320), true, 'equal faces silence the whole day');
  assert.equal(isWithinWindow(600, null, 660), false, 'a half window is not a window');
});

test('quiet hours need the switch, both faces, and the clock', () => {
  assert.equal(quietHoursApply({ enabled: false, start: '22:00', end: '07:00', now: at('2026-10-26T22:30:00Z') }), false);
  assert.equal(quietHoursApply({ enabled: true, start: null, end: '07:00', now: at('2026-10-26T22:30:00Z') }), false);
  assert.equal(quietHoursApply({ enabled: true, start: '22:00', end: '07:00', now: at('2026-10-26T22:30:00Z') }), true);
  // A guardian at UTC+3 is awake at that instant: 01:30 is inside 22:00 → 07:00, so it is silent.
  assert.equal(quietHoursApply({
    enabled: true, start: '22:00', end: '07:00', offsetMinutes: 180, now: at('2026-10-26T22:30:00Z'),
  }), true);
  // The same faces for a guardian at UTC+9: 07:30 local — the window closed half an hour ago.
  assert.equal(quietHoursApply({
    enabled: true, start: '22:00', end: '07:00', offsetMinutes: 540, now: at('2026-10-26T22:30:00Z'),
  }), false);
});

test('an ordinary alert is silenced by each wish, and each silence names itself', () => {
  const awake = at('2026-10-26T12:00:00Z');
  assert.deepEqual(decideDelivery({ definition: claim, preferences: {}, now: awake }), {
    decision: 'delivered', reason: 'delivered',
  }, 'a family that never opened the screen is interrupted, as it was before the gate existed');
  assert.deepEqual(
    decideDelivery({ definition: claim, preferences: { pushAllowed: false }, now: awake }),
    { decision: 'suppressed', reason: 'push_disabled' },
  );
  assert.deepEqual(
    decideDelivery({ definition: claim, preferences: { disabledCopyKeys: ['task.claimed'] }, now: awake }),
    { decision: 'suppressed', reason: 'copy_muted' },
  );
  assert.deepEqual(
    decideDelivery({ definition: claim, preferences: { childRequestsEnabled: false }, now: awake }),
    { decision: 'suppressed', reason: 'child_requests_disabled' },
  );
  assert.deepEqual(
    decideDelivery({ definition: claim, preferences: { deliveryMode: 'history_only' }, now: awake }),
    { decision: 'suppressed', reason: 'history_only' },
  );
  assert.deepEqual(
    decideDelivery({ definition: claim, preferences: { deliveryMode: 'daily_digest' }, now: awake }),
    { decision: 'digest_queued', reason: 'digest_mode' },
  );
  assert.deepEqual(
    decideDelivery({
      definition: claim,
      preferences: { quietHoursEnabled: true, quietHoursStart: '22:00', quietHoursEnd: '07:00' },
      now: at('2026-10-26T23:00:00Z'),
    }),
    { decision: 'suppressed', reason: 'quiet_hours' },
  );
});

test('safety outranks every wish, and says which wish it outranked', () => {
  const quietNight = at('2026-10-26T23:00:00Z');
  const silenced = {
    pushAllowed: false,
    deliveryMode: 'history_only',
    childRequestsEnabled: false,
    disabledCopyKeys: ['sos.raised'],
    quietHoursEnabled: true, quietHoursStart: '22:00', quietHoursEnd: '07:00',
  };
  assert.deepEqual(decideDelivery({ definition: sos, preferences: silenced, now: quietNight }), {
    decision: 'delivered', reason: 'safety_bypass', blockedBy: 'push_disabled',
  });
  assert.deepEqual(
    decideDelivery({ definition: sos, preferences: { quietHoursEnabled: true, quietHoursStart: '22:00', quietHoursEnd: '07:00' }, now: quietNight }),
    { decision: 'delivered', reason: 'safety_bypass', blockedBy: 'quiet_hours' },
  );
  assert.deepEqual(
    decideDelivery({ definition: sos, preferences: silenced, now: at('2026-10-26T12:00:00Z') }),
    { decision: 'delivered', reason: 'safety_bypass', blockedBy: 'push_disabled' },
  );
  // The four keys the database forbids from `disabled_copy_keys` are exactly the four that bypass.
  assert.deepEqual([...SAFETY_COPY_KEYS].sort(), ['geofence.entered', 'geofence.exited', 'protection.reported', 'sos.raised']);
});

test('the gate never invents a decision or a reason', () => {
  const verdicts = new Set();
  for (const mode of ['interrupt', 'daily_digest', 'history_only']) {
    for (const push of [true, false]) {
      for (const quiet of [true, false]) {
        for (const requests of [true, false]) {
          const verdict = decideDelivery({
            definition: claim,
            preferences: {
              deliveryMode: mode, pushAllowed: push, childRequestsEnabled: requests,
              quietHoursEnabled: quiet, quietHoursStart: '00:00', quietHoursEnd: '23:59',
            },
            now: at('2026-10-26T12:00:00Z'),
          });
          verdicts.add(verdict.decision);
          assert.ok(GATE_DECISIONS.includes(verdict.decision), verdict.decision);
          assert.ok(GATE_REASONS.includes(verdict.reason), verdict.reason);
        }
      }
    }
  }
  assert.deepEqual([...verdicts].sort(), ['delivered', 'digest_queued', 'suppressed']);
});

test('an unusable clock is refused, not guessed at', () => {
  assert.throws(
    () => decideDelivery({ definition: claim, preferences: {}, now: 'not a moment' }),
    /notification_gate_clock_invalid/,
  );
});
