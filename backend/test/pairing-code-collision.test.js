import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test from 'node:test';

import { createApp } from '../src/app.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

async function withServer(app, run) {
  const server = await new Promise((resolve) => {
    const value = app.listen(0, '127.0.0.1', () => resolve(value));
  });
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  }
}

async function request(baseUrl, path, { method = 'GET', authorization, idempotencyKey, body } = {}) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(authorization ? { authorization } : {}),
      ...(idempotencyKey ? { 'idempotency-key': idempotencyKey } : {}),
      ...(body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

async function makeFamilyChild(baseUrl) {
  const family = (await (await request(baseUrl, '/v1/families', {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'collision-family',
    body: { displayName: 'Collision family' },
  })).json()).family;
  const child = (await (await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: 'collision-child',
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  })).json()).child;
  return { family, child };
}

function issuePairing(baseUrl, family, child, key) {
  return request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: key,
    body: { deviceLabel: 'Amani Android' },
  });
}

function newStore() {
  return new MemoryFoundationStore({ now: () => new Date('2026-10-04T13:00:00.000Z') });
}

test('a new 6-digit code never equals an active pairing code', async () => {
  const store = newStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    const { family, child } = await makeFamilyChild(baseUrl);
    const first = (await (await issuePairing(baseUrl, family, child, 'collision-first')).json()).pairing.pairingCode;
    const replacement = first === '482913' ? '519274' : '482913';
    let calls = 0;
    store.newPairingCode = () => (calls++ === 0 ? first : replacement);

    const second = (await (await issuePairing(baseUrl, family, child, 'collision-second')).json()).pairing.pairingCode;
    assert.equal(calls, 2, 'the colliding candidate is discarded and a second one is drawn');
    assert.notEqual(second, first);
    assert.equal(second, replacement);
  });
});

test('when every candidate collides, issuing fails with a retryable 503 and creates nothing', async () => {
  const store = newStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    const { family, child } = await makeFamilyChild(baseUrl);
    const first = (await (await issuePairing(baseUrl, family, child, 'exhaust-first')).json()).pairing.pairingCode;
    store.newPairingCode = () => first;
    const before = store.devicePairings.size;

    const response = await issuePairing(baseUrl, family, child, 'exhaust-second');
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error.code, 'pairing_code_unavailable');
    assert.equal(store.devicePairings.size, before);
  });
});

test('an ambiguous code fails closed: it claims nothing and creates no device', async () => {
  const store = newStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    const { family, child } = await makeFamilyChild(baseUrl);
    const code = (await (await issuePairing(baseUrl, family, child, 'ambiguous-first')).json()).pairing.pairingCode;
    // Simulate two active rows that share one code (what a race or a legacy row could produce).
    const original = [...store.devicePairings.values()][0];
    store.devicePairings.set(randomUUID(), { ...original, id: randomUUID() });

    const claim = await request(baseUrl, '/v1/device-pairings/claim', { method: 'POST', body: { pairingCode: code } });
    assert.equal(claim.status, 400);
    assert.equal((await claim.json()).error.code, 'pairing_not_claimable');
    assert.equal(store.devices.size, 0);
  });
});

test('a code that is not exactly six digits is rejected before any lookup', async () => {
  const store = newStore();
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  await withServer(app, async (baseUrl) => {
    for (const pairingCode of ['12345', '1234567', '48 2913', 'abcdef', 'a'.repeat(43)]) {
      const response = await request(baseUrl, '/v1/device-pairings/claim', { method: 'POST', body: { pairingCode } });
      assert.equal(response.status, 400, pairingCode);
    }
  });
});
