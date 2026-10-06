// AiEvent v1 contract tests.
//
// These tests defend three properties that the intelligence systems depend on:
// a fact is emitted inside the same transaction as the mutation it describes,
// an observed fact is never dressed up as an inference, and the read surface
// carries identifiers and a registered explanation only.
import assert from 'node:assert/strict';
import test from 'node:test';
import { AI_EVENT_SCHEMA_VERSION, AI_EVENT_TYPES, aiEventDefinition } from '../src/ai-events.js';
import { createApp } from '../src/app.js';
import { PERMISSION_POLICY_VERSION } from '../src/permission-policy.js';
import { UnconfiguredFoundationStore } from '../src/store/unconfigured-foundation-store.js';
import { DisabledAuthVerifier } from '../src/auth/oidc-verifier.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

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

function request(baseUrl, path, { token, idempotencyKey, body, method = 'GET' } = {}) {
  const headers = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
  if (body) headers['Content-Type'] = 'application/json';
  return fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
}

const PRIMARY = 'test-parent-a';
const CHILD = 'test-child-a';

function foundationApp(store = new MemoryFoundationStore()) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });
}

async function seedFamily(baseUrl, { withChild = true } = {}) {
  const created = await request(baseUrl, '/v1/families', {
    method: 'POST',
    token: PRIMARY,
    idempotencyKey: 'ai-events-family',
    body: { displayName: 'Synthetic family' },
  });
  assert.equal(created.status, 201);
  const family = (await created.json()).family;

  if (withChild) {
    const child = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: PRIMARY,
      idempotencyKey: 'ai-events-child',
      body: {
        displayName: 'Synthetic child',
        ageYears: 8,
        avatarEmoji: '🧒',
        themeColor: 'purple',
      },
    });
    assert.equal(child.status, 201);
    return { family, child: (await child.json()).child };
  }
  return { family, child: null };
}

test('only registered fact types exist and every one is a certain observation', () => {
  assert.deepEqual(AI_EVENT_TYPES, [
    'family.child.created',
    'device.registered',
    'device.paired',
    'device.revoked',
  ]);
  for (const eventType of AI_EVENT_TYPES) {
    const definition = aiEventDefinition(eventType);
    assert.equal(definition.source, 'server');
    assert.equal(definition.confidence, 1);
    assert.equal(definition.rejectPath, null, 'a fact has nothing to reject');
    assert.ok(definition.explanation.length > 0);
  }
  assert.throws(() => aiEventDefinition('family.child.inferred'), TypeError);
});

test('creating a child emits exactly one AiEvent v1 fact for that child', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family, child } = await seedFamily(baseUrl);

    const response = await request(baseUrl, `/v1/families/${family.id}/ai-events`, {
      token: PRIMARY,
    });
    assert.equal(response.status, 200);
    const { events } = await response.json();

    assert.equal(events.length, 1);
    const [event] = events;
    assert.equal(event.schemaVersion, AI_EVENT_SCHEMA_VERSION);
    assert.equal(event.eventType, 'family.child.created');
    assert.equal(event.familyId, family.id);
    assert.equal(event.childId, child.id);
    assert.equal(event.deviceId, null);
    assert.equal(event.policyVersion, PERMISSION_POLICY_VERSION);
    assert.equal(event.source, 'server');
    assert.equal(event.confidence, 1);
    assert.equal(event.rejectPath, null);
    assert.ok(Number.isFinite(Date.parse(event.occurredAt)));
  });
});

test('the emitted fact carries identifiers and a registered explanation, never typed family content', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const response = await request(baseUrl, `/v1/families/${family.id}/ai-events`, {
      token: PRIMARY,
    });
    const body = await response.text();
    assert.equal(body.includes('Synthetic child'), false, 'a typed child name must not enter AiEvent');
    assert.equal(body.includes('Synthetic family'), false, 'a typed family name must not enter AiEvent');
    assert.equal(body.includes('correlationId'), false, 'internal trace context stays server-side');
    assert.equal(body.includes('Bearer'), false);
  });
});

test('an idempotent replay confirms the mutation without duplicating the fact', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const replay = await request(baseUrl, `/v1/families/${family.id}/children`, {
      method: 'POST',
      token: PRIMARY,
      idempotencyKey: 'ai-events-child',
      body: {
        displayName: 'Synthetic child',
        ageYears: 8,
        avatarEmoji: '🧒',
        themeColor: 'purple',
      },
    });
    assert.equal(replay.status, 201);

    const { events } = await (
      await request(baseUrl, `/v1/families/${family.id}/ai-events`, { token: PRIMARY })
    ).json();
    assert.equal(events.length, 1, 'a replayed request is one fact, not two');
  });
});

test('a child membership cannot read family intelligence events', async () => {
  await withServer(foundationApp(), async (baseUrl) => {
    const { family } = await seedFamily(baseUrl);

    const invited = await request(baseUrl, `/v1/families/${family.id}/memberships`, {
      method: 'POST',
      token: PRIMARY,
      idempotencyKey: 'ai-events-child-member',
      body: { role: 'child', targetSubject: CHILD },
    });
    assert.equal(invited.status, 201);
    const membership = (await invited.json()).membership;
    const accepted = await request(
      baseUrl,
      `/v1/families/${family.id}/memberships/${membership.id}/accept`,
      { method: 'POST', token: CHILD, idempotencyKey: 'ai-events-child-member-accept' },
    );
    assert.ok(accepted.status === 200 || accepted.status === 201);

    const denied = await request(baseUrl, `/v1/families/${family.id}/ai-events`, {
      token: CHILD,
    });
    assert.equal(denied.status, 403);
    const body = await denied.json();
    assert.equal(body.events, undefined);
  });
});

test('an unconfigured runtime reports unavailability instead of inventing an empty history', async () => {
  const app = createApp({
    store: new UnconfiguredFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });

  await withServer(app, async (baseUrl) => {
    const response = await request(
      baseUrl,
      '/v1/families/11111111-1111-4111-8111-111111111111/ai-events',
      { token: 'test-parent-a' },
    );
    assert.equal(response.status, 503);
  });
});
