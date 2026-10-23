import assert from 'node:assert/strict';
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

async function issuePairingCode(baseUrl, key) {
  const family = (await (await request(baseUrl, '/v1/families', {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: `${key}-family`,
    body: { displayName: 'Attempts family' },
  })).json()).family;
  const child = (await (await request(baseUrl, `/v1/families/${family.id}/children`, {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: `${key}-child`,
    body: { displayName: 'Amani', ageYears: 9, avatarEmoji: '🧒', themeColor: 'teal' },
  })).json()).child;
  const pairing = await request(baseUrl, `/v1/families/${family.id}/children/${child.id}/device-pairings`, {
    method: 'POST', authorization: 'Bearer test-primary', idempotencyKey: `${key}-pairing`,
    body: { deviceLabel: 'Amani Android' },
  });
  return (await pairing.json()).pairing.pairingCode;
}

// Six-digit codes that are not the issued one: well-formed, and always a failed claim.
function wrongCodes(correct, count) {
  const out = [];
  for (let value = 100000; out.length < count; value += 1) {
    if (String(value) !== correct) out.push(String(value));
  }
  return out;
}

async function claim(baseUrl, pairingCode) {
  return request(baseUrl, '/v1/device-pairings/claim', { method: 'POST', body: { pairingCode } });
}

function newApp() {
  const store = new MemoryFoundationStore({ now: () => new Date('2026-10-04T13:00:00.000Z') });
  const app = createApp({ store, authVerifier: new TestAuthVerifier(), readiness: () => ({ ready: true }) });
  return { store, app };
}

test('five failed claims are allowed; the sixth is refused even with the right code, and nothing is claimed', async () => {
  const { store, app } = newApp();
  await withServer(app, async (baseUrl) => {
    const correct = await issuePairingCode(baseUrl, 'budget');
    for (const wrong of wrongCodes(correct, 5)) {
      const response = await claim(baseUrl, wrong);
      assert.equal(response.status, 400, `failure ${wrong} is a normal refusal`);
    }
    const sixth = await claim(baseUrl, correct);
    assert.equal(sixth.status, 429);
    assert.equal((await sixth.json()).error.code, 'rate_limit_exceeded');
    assert.equal(store.devices.size, 0, 'the refused claim created no device');
  });
});

test('a successful claim is not counted: earlier typos and a success leave the full budget for later guesses', async () => {
  const { app } = newApp();
  await withServer(app, async (baseUrl) => {
    const first = await issuePairingCode(baseUrl, 'first');
    for (const wrong of wrongCodes(first, 4)) {
      assert.equal((await claim(baseUrl, wrong)).status, 400);
    }
    assert.equal((await claim(baseUrl, first)).status, 201, 'the right code still works after four typos');

    const second = await issuePairingCode(baseUrl, 'second');
    const [fifthGuess, sixthGuess] = wrongCodes(second, 2);
    assert.equal((await claim(baseUrl, fifthGuess)).status, 400, 'the fifth failure is still allowed');
    assert.equal((await claim(baseUrl, sixthGuess)).status, 429, 'the sixth failure is refused');
  });
});
