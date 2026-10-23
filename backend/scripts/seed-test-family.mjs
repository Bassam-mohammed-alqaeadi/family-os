// S3 · D5 preparation — one clean, synthetic test family for the device check.
//
// Creates: one family, one child, and 30 free minutes granted by the guardian. Through the public
// API only (no database access). Every value is synthetic and labelled as such.
//
// Run from an interactive terminal (the guardian token is typed without echo; it is never printed):
//   STAGING_API_BASE_URL=https://<host> SEED_ACK=synthetic-test-family node scripts/seed-test-family.mjs
//
// Prints only the family and child identifiers, which the device check needs.

import { randomUUID } from 'node:crypto';

if (process.env.SEED_ACK !== 'synthetic-test-family') {
  throw new Error('Set SEED_ACK=synthetic-test-family to acknowledge this creates a synthetic family.');
}
const base = process.env.STAGING_API_BASE_URL;
if (!base || !/^https:\/\//.test(base)) {
  throw new Error('Set STAGING_API_BASE_URL to an https origin.');
}

async function readHiddenLine(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== 'function') {
    throw new Error('Run this from an interactive terminal so the token is entered without echo.');
  }
  const input = process.stdin;
  let value = '';
  process.stdout.write(prompt);
  input.setEncoding('utf8');
  input.setRawMode(true);
  input.resume();
  return new Promise((resolve, reject) => {
    const cleanup = () => {
      input.removeListener('data', onData);
      input.setRawMode(false);
      input.pause();
      process.stdout.write('\n');
    };
    const onData = (chunk) => {
      for (const character of chunk) {
        if (character === '\u0003') { cleanup(); reject(new Error('Cancelled.')); return; }
        if (character === '\r' || character === '\n') { cleanup(); resolve(value); return; }
        if (character === '\u007F' || character === '\b') { value = value.slice(0, -1); continue; }
        value += character;
      }
    };
    input.on('data', onData);
  });
}

async function call(token, method, path, body) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'Idempotency-Key': randomUUID(),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    // The body names the refusal; the token is never part of it.
    throw new Error(`${method} ${path} refused with ${response.status}: ${text.slice(0, 200)}`);
  }
  return JSON.parse(text);
}

const token = await readHiddenLine('Guardian Firebase ID token (hidden): ');
const family = await call(token, 'POST', '/v1/families', { displayName: 'Synthetic test family' });
const familyId = family.family?.id;
if (!familyId) throw new Error('The family was created but no identifier came back.');

const child = await call(token, 'POST', `/v1/families/${familyId}/children`, {
  displayName: 'Synthetic child',
  ageYears: 9,
  avatarEmoji: '🧪',
  themeColor: 'teal',
});
const childId = child.child?.id ?? child.id;
if (!childId) throw new Error('The child was created but no identifier came back.');

await call(token, 'POST', `/v1/families/${familyId}/children/${childId}/minutes/grants`, {
  minutes: 30,
  scope: 'free',
  reason: 'synthetic seed for the device check',
});

console.log(JSON.stringify({ familyId, childId, minutesGranted: 30, synthetic: true }, null, 2));
