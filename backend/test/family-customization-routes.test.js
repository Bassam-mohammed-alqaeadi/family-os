// Programme «family character», slice 1 — the two routes, over HTTP.
//
// The unit file proves the laws; the PostgreSQL file proves the floor. This one proves the door: that
// a family id is a uuid or nothing is asked, that no query parameter is tolerated, that the body is
// parsed into a change and an `expectedVersion` before the module ever sees it, that a withheld knob
// is refused on the wire rather than accepted and ignored, and that a refusal from the module reaches
// the caller with its own code and status instead of a generic 500.
import assert from 'node:assert/strict';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { FamilyCustomizationError } from '../src/family-customization.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

const PRIMARY = 'test-primary';
const CO_GUARDIAN = 'test-co-guardian';

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
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

const token = (subject) => `Bearer ${subject}`;

const PROFILE = {
  version: 2,
  weekStartDay: 'sat',
  restDays: ['thu', 'fri'],
  guardianLabels: { father: 'بابا', mother: 'حبيبتي' },
  updatedAt: '2026-10-26T00:00:00.000Z',
  updatedByMembershipId: '22222222-2222-4222-8222-222222222222',
  source: 'family',
};

/**
 * The profile surface with its decisions scripted. The module's own laws are proven in
 * `family-customization.test.js`; here the fake answers exactly as the module would so the route
 * contract — parsed input, correlation id, refusal codes — is what is under test.
 */
function customizationSurface(mode = 'ok') {
  const seen = [];
  return {
    seen,
    profiles: {
      async read({ principal, familyId }) {
        seen.push({ op: 'read', subject: principal.subject, familyId });
        return { profile: PROFILE };
      },
      async update({ principal, familyId, change, expectedVersion, correlationId }) {
        seen.push({ op: 'update', subject: principal.subject, familyId, change, expectedVersion, correlationId });
        if (mode === 'stale') {
          throw new FamilyCustomizationError(409, 'customization_stale_version', 'The family profile changed since it was read.');
        }
        if (mode === 'forbidden') {
          throw new FamilyCustomizationError(403, 'customization_primary_guardian_required', 'Only the primary guardian may change this family\'s character profile.');
        }
        if (mode === 'no-rest-day') {
          throw new FamilyCustomizationError(400, 'customization_rest_day_required', 'A family must keep at least one rest day.');
        }
        return { profile: { ...PROFILE, version: expectedVersion + 1 } };
      },
    },
  };
}

async function seedFamily(baseUrl, subject = PRIMARY, key = 'customization-family') {
  const response = await request(baseUrl, '/v1/families', {
    method: 'POST',
    authorization: token(subject),
    idempotencyKey: key,
    body: { displayName: 'Character family' },
  });
  assert.equal(response.status, 201);
  return (await response.json()).family;
}

test('the profile is readable only for a family named by a uuid, and never with a query string', async () => {
  const { profiles, seen } = customizationSurface('ok');
  const store = new MemoryFoundationStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true, missing: [] }), familyCustomization: profiles });

  await withServer(app, async (baseUrl) => {
    const unauthorized = await request(baseUrl, '/v1/families/11111111-1111-4111-8111-111111111111/customization');
    assert.equal(unauthorized.status, 401, 'a bearer token is what opens this door');

    const family = await seedFamily(baseUrl);
    const ok = await request(baseUrl, `/v1/families/${family.id}/customization`, { authorization: token(PRIMARY) });
    assert.equal(ok.status, 200);
    const body = await ok.json();
    assert.deepEqual(Object.keys(body).sort(), ['profile']);
    assert.deepEqual(body.profile.restDays, ['thu', 'fri'], 'rest days travel as a canonical day list');
    assert.equal(seen.at(-1).familyId, family.id);

    const notUuid = await request(baseUrl, '/v1/families/fam_1/customization', { authorization: token(PRIMARY) });
    assert.equal(notUuid.status, 400);
    assert.equal((await notUuid.json()).error.code, 'invalid_request');
    assert.equal(seen.filter((entry) => entry.op === 'read').length, 1, 'a malformed path must not reach the module');

    const withQuery = await request(baseUrl, `/v1/families/${family.id}/customization?debug=1`, { authorization: token(PRIMARY) });
    assert.equal(withQuery.status, 400);
  });
});

test('a write arrives as a parsed change and a version, and refusals keep their own names', async () => {
  const surface = customizationSurface('ok');
  const store = new MemoryFoundationStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true, missing: [] }), familyCustomization: surface.profiles });

  await withServer(app, async (baseUrl) => {
    const family = await seedFamily(baseUrl);
    const path = `/v1/families/${family.id}/customization`;

    const missingVersion = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { weekStartDay: 'sun' },
    });
    assert.equal(missingVersion.status, 400, 'a write without the version it read is not a write');

    const inventedKnob = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { expectedVersion: 2, hijriMode: 'both' },
    });
    assert.equal(inventedKnob.status, 400);
    assert.equal((await inventedKnob.json()).error.code, 'invalid_request',
      'a knob no engine reads is closed on the wire, not accepted and ignored');

    const digits = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { expectedVersion: 2, numerals: 'eastern' },
    });
    assert.equal(digits.status, 200, 'the family may choose its digits - the owner opened this on 2026-10-26');
    assert.equal(surface.seen.at(-1).change.numerals, 'eastern');

    const wrongDigits = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { expectedVersion: 2, numerals: 'roman' },
    });
    assert.equal(wrongDigits.status, 400, 'two legal words, not a free string');

    const unknownDay = await request(baseUrl, path, {
      method: 'PATCH', authorization: token(PRIMARY), body: { expectedVersion: 2, restDays: ['friday'] },
    });
    assert.equal(unknownDay.status, 400);

    const good = await request(baseUrl, path, {
      method: 'PATCH',
      authorization: token(PRIMARY),
      body: { expectedVersion: 2, weekStartDay: 'sat', restDays: ['fri', 'sat'], labels: { father: 'بابا', mother: null } },
    });
    assert.equal(good.status, 200);
    assert.equal((await good.json()).profile.version, 3, 'the version the server stored is what comes back');

    const call = surface.seen.at(-1);
    assert.deepEqual(call.change, { weekStartDay: 'sat', restDays: ['fri', 'sat'], labels: { father: 'بابا', mother: null } });
    assert.equal(call.expectedVersion, 2);
    assert.ok(typeof call.correlationId === 'string' && call.correlationId.length > 0,
      'the audit trail the module appends is tied to the request that caused it');
  });
});

test('a stale version, a forbidden writer and a refused week reach the caller as 409, 403 and 400', async () => {
  for (const [mode, status, code] of [
    ['stale', 409, 'customization_stale_version'],
    ['forbidden', 403, 'customization_primary_guardian_required'],
    ['no-rest-day', 400, 'customization_rest_day_required'],
  ]) {
    const surface = customizationSurface(mode);
    const store = new MemoryFoundationStore();
    const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true, missing: [] }), familyCustomization: surface.profiles });
    await withServer(app, async (baseUrl) => {
      const family = await seedFamily(baseUrl, mode === 'forbidden' ? CO_GUARDIAN : PRIMARY);
      const response = await request(baseUrl, `/v1/families/${family.id}/customization`, {
        method: 'PATCH',
        authorization: token(mode === 'forbidden' ? CO_GUARDIAN : PRIMARY),
        body: { expectedVersion: 0, restDays: [] },
      });
      assert.equal(response.status, status, `${mode} must answer ${status}`);
      const body = await response.json();
      assert.equal(body.error.code, code, `${mode} must name the refusal, not wrap it`);
    });
  }
});
