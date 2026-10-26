// Launch closure, slice س٣ — the notification-preferences door, over HTTP.
//
// The module's laws are proven against a real database in `postgres-notification-preferences.test.js`;
// this file proves the door: that a family id is a uuid or nothing is asked, that no query parameter
// is tolerated (this endpoint is about the caller's own row, so a `memberId` is a refusal rather than
// a shortcut to someone else's), that a knob with no engine is refused on the wire instead of being
// stored and ignored, and that a refusal from the module reaches the caller with its own code and
// status rather than as a generic 500.
import assert from 'node:assert/strict';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { NotificationPreferencesError } from '../src/notification-preferences.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

const PRIMARY = 'test-primary';
const CHILD = 'test-child';
const PATH = '/v1/families/11111111-1111-4111-8111-111111111111/me/notification-preferences';

const PREFERENCES = {
  version: 3,
  quietHoursEnabled: true,
  quietStartMinutes: 1_320,
  quietEndMinutes: 420,
  quietHoursOffsetMinutes: 180,
  pushAllowed: true,
  deliveryMode: 'interrupt',
  childRequestsEnabled: true,
  disabledCopyKeys: [],
  updatedAt: '2026-10-26T00:00:00.000Z',
  source: 'stored',
};

/** The surface with its decisions scripted, exactly as the module would answer. */
function preferencesSurface(mode = 'ok') {
  const seen = [];
  const refuse = (error) => {
    if (error == null) return;
    throw new NotificationPreferencesError(error.status, error.code, error.message);
  };
  const errors = {
    stale: { status: 409, code: 'notification_preferences_stale_version', message: 'These preferences changed since they were read.' },
    child: { status: 403, code: 'notification_preferences_guardian_only', message: 'Notification preferences belong to a guardian of this family.' },
    safety: { status: 403, code: 'notification_preferences_safety_never_muted', message: 'A safety alert is never silenced: sos.raised cannot be muted by any family.' },
    halfWindow: { status: 400, code: 'notification_preferences_quiet_pair_required', message: 'Quiet hours need both a start and an end minute of day.' },
  };
  return {
    seen,
    preferences: {
      async read({ principal, familyId }) {
        seen.push({ op: 'read', subject: principal.subject, familyId });
        return { preferences: PREFERENCES, mutableCopyKeys: ['task.claimed'] };
      },
      async update({ principal, familyId, change, expectedVersion, correlationId }) {
        seen.push({ op: 'update', subject: principal.subject, familyId, change, expectedVersion, correlationId });
        refuse(errors[mode]);
        return {
          preferences: { ...PREFERENCES, version: expectedVersion + 1, ...change },
          mutableCopyKeys: ['task.claimed'],
        };
      },
    },
  };
}

async function withServer(app, run) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

function request(baseUrl, path, { method = 'GET', authorization, idempotencyKey, body } = {}) {
  const headers = { Accept: 'application/json' };
  if (authorization) headers.Authorization = authorization;
  // A mutation is replay-safe or it is not accepted; the door is under test, so the key is real.
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

const token = (subject) => `Bearer ${subject}`;

async function seedFamily(baseUrl, subject = PRIMARY) {
  const response = await request(baseUrl, '/v1/families', {
    method: 'POST',
    authorization: token(subject),
    idempotencyKey: `prefs-family-${subject}`,
    body: { displayName: 'Gate family' },
  });
  assert.equal(response.status, 201);
  return (await response.json()).family;
}

test('the door opens for a uuid family, for a bearer token, and never with a member named in the query', async () => {
  const surface = preferencesSurface('ok');
  const app = createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
    notificationPreferences: surface.preferences,
  });

  await withServer(app, async (baseUrl) => {
    const anonymous = await request(baseUrl, PATH);
    assert.equal(anonymous.status, 401, 'a bearer token is what opens this door');

    const family = await seedFamily(baseUrl);
    const path = `/v1/families/${family.id}/me/notification-preferences`;
    const ok = await request(baseUrl, path, { authorization: token(PRIMARY) });
    assert.equal(ok.status, 200);
    const body = await ok.json();
    assert.deepEqual(Object.keys(body).sort(), ['mutableCopyKeys', 'preferences'],
      'the muteable keys travel with the row, so a screen lists only what the server will honour');
    assert.deepEqual(body.mutableCopyKeys, ['task.claimed']);
    assert.equal(body.preferences.quietStartMinutes, 1_320);
    assert.equal(surface.seen.at(-1).familyId, family.id);

    const notUuid = await request(baseUrl, '/v1/families/not-a-uuid/me/notification-preferences', {
      authorization: token(PRIMARY),
    });
    assert.equal(notUuid.status, 400, 'a family is named by a uuid or nothing is asked of the store');

    const someoneElsesRow = await request(
      baseUrl,
      `${path}?memberId=22222222-2222-4222-8222-222222222222`,
      { authorization: token(PRIMARY) },
    );
    assert.equal(someoneElsesRow.status, 400,
      'this endpoint is about the caller; naming another member is refused, not obeyed');
  });
});

test('a write carries the version it read, and nothing the server has no engine for', async () => {
  const surface = preferencesSurface('ok');
  const app = createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
    notificationPreferences: surface.preferences,
  });

  await withServer(app, async (baseUrl) => {
    const family = await seedFamily(baseUrl);
    const path = `/v1/families/${family.id}/me/notification-preferences`;

    const noVersion = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { quietHoursEnabled: true },
    });
    assert.equal(noVersion.status, 400, 'a write without the version it read is not a write');

    const decoration = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY),
      body: { expectedVersion: 3, analysisNoticesEnabled: false },
    });
    assert.equal(decoration.status, 400,
      'a field with no engine is refused on the wire, not stored so a screen can look busy');

    const muteSafety = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY),
      body: { expectedVersion: 3, sosMuted: true },
    });
    assert.equal(muteSafety.status, 400, 'the SOS-mute vocabulary is not this door’s');

    const written = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY),
      body: {
        expectedVersion: 3,
        quietHoursEnabled: true, quietStartMinutes: 1_320, quietEndMinutes: 420,
        quietHoursOffsetMinutes: 180, deliveryMode: 'daily_digest',
        disabledCopyKeys: ['task.claimed'],
      },
    });
    assert.equal(written.status, 200);
    const seen = surface.seen.at(-1);
    assert.equal(seen.expectedVersion, 3);
    assert.equal(seen.change.quietStartMinutes, 1_320);
    assert.deepEqual(seen.change.disabledCopyKeys, ['task.claimed']);
    assert.match(seen.correlationId, /^[0-9a-f-]{36}$/, 'a preference write is auditable by correlation id');
    assert.equal((await written.json()).preferences.version, 4);
  });
});

test('a refusal from the module keeps its own name all the way to the caller', async () => {
  const refusals = [
    ['stale', 409, 'notification_preferences_stale_version'],
    ['child', 403, 'notification_preferences_guardian_only'],
    ['safety', 403, 'notification_preferences_safety_never_muted'],
    ['halfWindow', 400, 'notification_preferences_quiet_pair_required'],
  ];
  for (const [mode, status, code] of refusals) {
    const surface = preferencesSurface(mode);
    const app = createApp({
      store: new MemoryFoundationStore(),
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      notificationPreferences: surface.preferences,
    });
    await withServer(app, async (baseUrl) => {
      const family = await seedFamily(baseUrl, mode === 'child' ? CHILD : PRIMARY);
      const response = await request(baseUrl, `/v1/families/${family.id}/me/notification-preferences`, {
        method: 'PATCH',
        authorization: token(mode === 'child' ? CHILD : PRIMARY),
        body: { expectedVersion: 0, quietHoursEnabled: true },
      });
      assert.equal(response.status, status, `${mode} must answer ${status}`);
      const body = await response.json();
      assert.equal(body.error.code, code, `${mode} must name the refusal, not wrap it`);
    });
  }
});
