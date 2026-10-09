// The FCM sender against a real RSA key: the service-account assertion is signed and its claims
// are checked by verification, not by string matching. The transport is a fake; the sandbox has
// no route to Google, so the live endpoint is verified by the owner's deployment, not here.
import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import test from 'node:test';
import { jwtVerify } from 'jose';
import {
  FCM_SCOPE,
  FcmSender,
  parseServiceAccount,
  PUSH_COPY,
} from '../src/fcm-sender.js';

const TOKEN_URL = 'https://oauth2.example.test/token';
const FCM_ORIGIN = 'https://fcm.example.test';
const CLIENT_EMAIL = 'push-sender@family-os-test.iam.gserviceaccount.com';
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });

function json(status, body) {
  return new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
}

function fakeGoogle({ tokenStatus = 200, sendResponses = [] } = {}) {
  const requests = [];
  const queue = [...sendResponses];
  const transport = async (url, init) => {
    requests.push({ url: String(url), init });
    if (String(url) === TOKEN_URL) {
      return tokenStatus === 200
        ? json(200, { access_token: 'ya29.test-access-token', expires_in: 3600 })
        : json(tokenStatus, { error: 'invalid_grant' });
    }
    return queue.shift() ?? json(200, { name: 'projects/x/messages/1' });
  };
  return { requests, transport };
}

function sender(transport, extra = {}) {
  return new FcmSender({
    projectId: 'family-os-test',
    serviceAccount: { clientEmail: CLIENT_EMAIL, privateKey: pem },
    fetch: transport,
    tokenUrl: TOKEN_URL,
    fcmOrigin: FCM_ORIGIN,
    ...extra,
  });
}

const device = 'dGVzdC1kZXZpY2UtdG9rZW4tMDAwMDAwMDAwMDAwMDAw';

test('the service-account JWT is RS256-signed with the right issuer, audience and scope', async () => {
  const fake = fakeGoogle();
  await sender(fake.transport).send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 't1' } });
  const tokenRequest = fake.requests[0];
  assert.equal(tokenRequest.url, TOKEN_URL);
  const assertion = new URLSearchParams(tokenRequest.init.body).get('assertion');
  const { payload, protectedHeader } = await jwtVerify(assertion, publicKey, {
    issuer: CLIENT_EMAIL,
    audience: TOKEN_URL,
  });
  assert.equal(protectedHeader.alg, 'RS256');
  assert.equal(payload.sub, CLIENT_EMAIL);
  assert.equal(payload.scope, FCM_SCOPE);
  assert.ok(payload.exp - payload.iat <= 3600);
});

test('a nudge is sent over HTTP v1 with the bearer token and carries only neutral text and the thread', async () => {
  const fake = fakeGoogle();
  const outcome = await sender(fake.transport).send({
    token: device,
    locale: 'ar',
    data: { type: 'chat.message', threadId: '0b8f8a3e-2d0e-4a53-9a5e-3f0c1a2b3c4d' },
  });
  assert.equal(outcome, 'sent');
  const send = fake.requests[1];
  assert.equal(send.url, `${FCM_ORIGIN}/v1/projects/family-os-test/messages:send`);
  assert.equal(send.init.headers.authorization, 'Bearer ya29.test-access-token');
  const body = JSON.parse(send.init.body);
  assert.equal(body.message.token, device);
  assert.deepEqual(body.message.notification, PUSH_COPY.ar);
  assert.deepEqual(body.message.data, { type: 'chat.message', threadId: '0b8f8a3e-2d0e-4a53-9a5e-3f0c1a2b3c4d' });
});

test('the access token is cached until shortly before it expires', async () => {
  const fake = fakeGoogle();
  let clock = 1_000_000;
  const instance = sender(fake.transport, { now: () => clock });
  await instance.send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'a' } });
  await instance.send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'b' } });
  const tokenCalls = fake.requests.filter((request) => request.url === TOKEN_URL).length;
  assert.equal(tokenCalls, 1);
  clock += 3600 * 1000;
  await instance.send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'c' } });
  assert.equal(fake.requests.filter((request) => request.url === TOKEN_URL).length, 2);
});

test('FCM saying the token is unregistered is reported, so the registration can be removed', async () => {
  const fake = fakeGoogle({
    sendResponses: [json(404, { error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } })],
  });
  assert.equal(await sender(fake.transport).send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'x' } }), 'unregistered');
});

test('any other refusal throws and removes nothing, and its message names no token', async () => {
  const fake = fakeGoogle({ sendResponses: [json(500, { error: { status: 'INTERNAL' } })] });
  await assert.rejects(
    sender(fake.transport).send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'x' } }),
    (error) => /HTTP 500/.test(error.message) && !error.message.includes(device),
  );
});

test('a refused access token throws without the assertion or the key', async () => {
  const fake = fakeGoogle({ tokenStatus: 401 });
  await assert.rejects(
    sender(fake.transport).send({ token: device, locale: 'en', data: { type: 'chat.message', threadId: 'x' } }),
    (error) => /HTTP 401/.test(error.message) && !error.message.includes('BEGIN PRIVATE KEY'),
  );
});

test('the service account is parsed strictly and its error never echoes the key', () => {
  const good = JSON.stringify({ client_email: CLIENT_EMAIL, private_key: pem });
  assert.deepEqual(parseServiceAccount(good), { clientEmail: CLIENT_EMAIL, privateKey: pem });
  assert.throws(() => parseServiceAccount('{not json'), /not valid JSON/);
  assert.throws(
    () => parseServiceAccount(JSON.stringify({ client_email: 'a@example.com', private_key: 'BEGIN PRIVATE KEY' })),
    (error) => !error.message.includes('BEGIN PRIVATE KEY'),
  );
});

test('the project id must be a valid Firebase project id', () => {
  assert.throws(() => new FcmSender({ projectId: 'Bad Project!', serviceAccount: { clientEmail: CLIENT_EMAIL, privateKey: pem } }));
});
