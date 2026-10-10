// Invite codes without a database: the shape of a code, how a typed code is forgiven, and the
// two rate limits that stand in front of redemption. The rules that need a transaction - single
// use, expiry, one family, no oracle - are proven on real PostgreSQL in
// postgres-invite-codes.test.js.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { HttpError } from '../src/http-error.js';
import {
  displayInviteCode,
  inviteCodeDigest,
  newInviteCode,
} from '../src/family-invite-codes.js';
import {
  INVITE_CODE_ALPHABET,
  createInviteCodeInput,
  normalizeInviteCode,
  redeemInviteCodeInput,
} from '../src/validation.js';
import { MemoryFoundationStore, TestAuthVerifier } from './memory-foundation-store.js';

test('a code is ten letters from the unambiguous alphabet, shown as two halves', () => {
  assert.equal(INVITE_CODE_ALPHABET.length, 31);
  for (const ambiguous of ['0', 'O', '1', 'I', 'L']) {
    assert.equal(INVITE_CODE_ALPHABET.includes(ambiguous), false, `${ambiguous} must not appear`);
  }
  const seen = new Set();
  for (let index = 0; index < 500; index += 1) {
    const code = newInviteCode();
    assert.match(code, /^[A-HJKMNP-Z2-9]{10}$/);
    assert.match(displayInviteCode(code), /^[A-HJKMNP-Z2-9]{5}-[A-HJKMNP-Z2-9]{5}$/);
    seen.add(code);
  }
  assert.equal(seen.size, 500, 'five hundred draws never repeat');
});

test('rejection sampling never folds a biased byte into the alphabet', () => {
  // 248 is the largest multiple of 31 below 256; bytes 248..255 must be skipped, not wrapped.
  let calls = 0;
  const random = (size) => {
    calls += 1;
    return calls === 1 ? Buffer.alloc(size, 255) : Buffer.alloc(size, 0);
  };
  assert.equal(newInviteCode(random), 'AAAAAAAAAA');
  assert.equal(calls, 2);
});

test('a typed code forgives case, spaces and the hyphen, and nothing else', () => {
  assert.equal(normalizeInviteCode('abcde-fghjk'), 'ABCDEFGHJK');
  assert.equal(normalizeInviteCode(' ABCDE FGHJK '), 'ABCDEFGHJK');
  assert.equal(normalizeInviteCode('ABCDEFGHJ'), null);
  assert.equal(normalizeInviteCode('ABCDEFGHJKM'), null);
  assert.equal(normalizeInviteCode('ABCDEFGHI0'), null, 'ambiguous letters are never issued');
  assert.equal(normalizeInviteCode(12345), null);
  assert.equal(normalizeInviteCode('A'.repeat(65)), null);
  assert.deepEqual(redeemInviteCodeInput({ code: 'abcde-fghjk' }), { code: 'ABCDEFGHJK' });
  assert.throws(() => redeemInviteCodeInput({ code: 'nope' }), { code: 'invalid_request' });
  assert.throws(() => redeemInviteCodeInput({ code: 'ABCDEFGHJK', familyId: 'x' }), { code: 'invalid_request' });
});

test('issuing names a role and nothing about the invitee', () => {
  assert.deepEqual(createInviteCodeInput({ role: 'co_guardian' }), { role: 'co_guardian' });
  assert.deepEqual(createInviteCodeInput({ role: 'child' }), { role: 'child' });
  assert.throws(() => createInviteCodeInput({ role: 'primary_guardian' }), { code: 'invalid_request' });
  assert.throws(() => createInviteCodeInput({ role: 'co_guardian', targetSubject: 'x' }), { code: 'invalid_request' });
});

test('the stored digest is domain-separated and never the code itself', () => {
  const digest = inviteCodeDigest('ABCDEFGHJK');
  assert.match(digest, /^[0-9a-f]{64}$/);
  assert.notEqual(digest, inviteCodeDigest('ABCDEFGHJM'));
  assert.equal(digest.includes('ABCDEFGHJK'), false);
});

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

async function redeem(baseUrl, subject, code, key) {
  const response = await fetch(`${baseUrl}/v1/invite-codes/redeem`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${subject}`,
      'content-type': 'application/json',
      'idempotency-key': key,
    },
    body: JSON.stringify({ code }),
  });
  const body = await response.json();
  return { status: response.status, body };
}

test('redemption is rate limited per subject, and per network peer across subjects', async () => {
  const calls = [];
  const app = createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
    inviteRedeemRateLimit: { subjectLimit: 3, peerLimit: 5 },
    familyInviteCodes: {
      async issue() { throw new Error('not used'); },
      async revoke() { throw new Error('not used'); },
      async redeem(input) {
        calls.push(input.code);
        throw new HttpError(404, 'invite_code_not_redeemable', 'not redeemable');
      },
    },
  });
  await withServer(app, async (baseUrl) => {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const answer = await redeem(baseUrl, 'test-guesser', 'ABCDE-FGHJK', `subject-${attempt}`);
      assert.notEqual(answer.status, 429);
    }
    const limited = await redeem(baseUrl, 'test-guesser', 'ABCDE-FGHJK', 'subject-4');
    assert.equal(limited.status, 429);
    assert.equal(limited.body.error.code, 'rate_limit_exceeded');

    // A second throwaway account from the same peer shares the peer budget (5 in total).
    const fresh = await redeem(baseUrl, 'test-other', 'ABCDE-FGHJK', 'other-1');
    assert.notEqual(fresh.status, 429);
    const peerLimited = await redeem(baseUrl, 'test-third', 'ABCDE-FGHJK', 'third-1');
    assert.equal(peerLimited.status, 429);
  });
  assert.equal(calls.length, 4, 'a limited attempt never reaches the code lookup');
});

test('a malformed code is refused before any lookup', async () => {
  let reached = false;
  const app = createApp({
    store: new MemoryFoundationStore(),
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
    familyInviteCodes: {
      async issue() { reached = true; },
      async revoke() { reached = true; },
      async redeem() { reached = true; },
    },
  });
  await withServer(app, async (baseUrl) => {
    const answer = await redeem(baseUrl, 'test-invitee', 'O0O0O-I1I1I', 'malformed-1');
    assert.equal(answer.status, 400);
    assert.equal(answer.body.error.code, 'invalid_request');
    const unauthenticated = await fetch(`${baseUrl}/v1/invite-codes/redeem`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'idempotency-key': 'anon-1' },
      body: JSON.stringify({ code: 'ABCDE-FGHJK' }),
    });
    assert.equal(unauthenticated.status, 401);
  });
  assert.equal(reached, false);
});
