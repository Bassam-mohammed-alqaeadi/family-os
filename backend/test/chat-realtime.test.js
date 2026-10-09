// The W9 realtime gateway and its in-process bus, with no database. These run in the ordinary
// suite, so a regression that lets a hint carry content, or lets a removed member keep hearing a
// room, fails on every push. The PostgreSQL gate covers the same rules against real rows.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import test from 'node:test';

import WebSocket from 'ws';

import {
  CHAT_REALTIME_LIMITS,
  attachChatRealtime,
  createChatEventBus,
} from '../src/chat-realtime.js';

const FAMILY = '22222222-2222-4222-8222-222222222222';
const ROOM = '33333333-3333-4333-8333-333333333333';
const OTHER_ROOM = '44444444-4444-4444-8444-444444444444';
const DEVICE_ID = '55555555-5555-4555-8555-555555555555';
const DEVICE_CREDENTIAL = 'd'.repeat(43);

function tokenPrincipals() {
  return {
    'Bearer good-a': { subject: 'person-a' },
    'Bearer good-b': { subject: 'person-b' },
  };
}

async function startGateway({ allowed = new Set([ROOM]), ready = async () => true, limits } = {}) {
  const principals = tokenPrincipals();
  const bus = createChatEventBus();
  const server = createServer((_request, response) => response.end());
  const state = { allowed };
  const gateway = attachChatRealtime(server, {
    bus,
    ready,
    limits,
    authVerifier: {
      async verify(authorization) {
        const principal = principals[authorization];
        if (principal == null) throw new Error('invalid token');
        return principal;
      },
    },
    familyChat: {
      async canReadThread({ threadId }) {
        return state.allowed.has(threadId);
      },
      async authenticateDevice({ deviceId, deviceCredential }) {
        return deviceId === DEVICE_ID && deviceCredential === DEVICE_CREDENTIAL
          ? { familyId: FAMILY }
          : null;
      },
    },
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  return {
    bus,
    state,
    gateway,
    url: `ws://127.0.0.1:${port}/v1/realtime`,
    async close() {
      gateway.close();
      await new Promise((resolve) => server.close(resolve));
    },
  };
}

/** A queue of parsed frames, so a test can await the next one in order. */
function framesOf(ws) {
  const queued = [];
  const waiting = [];
  ws.on('message', (raw) => {
    const frame = JSON.parse(raw.toString('utf8'));
    if (waiting.length > 0) waiting.shift()(frame);
    else queued.push(frame);
  });
  return () =>
    new Promise((resolve) => {
      if (queued.length > 0) resolve(queued.shift());
      else waiting.push(resolve);
    });
}

async function connect(url, authorization = 'Bearer good-a', query = '') {
  const headers = authorization == null ? {} : { authorization };
  const ws = new WebSocket(`${url}${query}`, { headers });
  const next = framesOf(ws);
  await new Promise((resolve, reject) => {
    ws.once('open', resolve);
    ws.once('unexpected-response', (_request, response) =>
      reject(Object.assign(new Error('refused'), { statusCode: response.statusCode })),
    );
    ws.once('error', reject);
  });
  assert.deepEqual(await next(), { type: 'ready', heartbeatMs: CHAT_REALTIME_LIMITS.heartbeatMs });
  return { ws, next };
}

function refusedStatus(url, headers, query = '') {
  return new Promise((resolve) => {
    const ws = new WebSocket(`${url}${query}`, { headers });
    ws.once('unexpected-response', (_request, response) => {
      resolve(response.statusCode);
      response.resume();
    });
    ws.once('open', () => resolve(200));
    ws.once('error', () => {});
  });
}

test('the bus delivers only declared hint types and isolates failing listeners', async () => {
  const bus = createChatEventBus();
  const received = [];
  bus.subscribe((event) => received.push(['first', event.type]));
  bus.subscribe(() => {
    throw new Error('a listener that fails must not stop the others');
  });
  bus.subscribe((event) => received.push(['third', event.type]));

  assert.throws(() => bus.publish({ type: 'chat.text', threadId: ROOM }), /declared hint types/);
  bus.publish({ type: 'chat.message', threadId: ROOM, seq: 4 });
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(received, [
    ['first', 'chat.message'],
    ['third', 'chat.message'],
  ]);
});

test('the bus unsubscribe stops delivery', async () => {
  const bus = createChatEventBus();
  let count = 0;
  const stop = bus.subscribe(() => {
    count += 1;
  });
  stop();
  bus.publish({ type: 'chat.receipt', threadId: ROOM });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(count, 0);
  assert.equal(bus.size(), 0);
});

test('an upgrade without a valid credential is refused before any frame is sent', async () => {
  const env = await startGateway();
  try {
    assert.equal(await refusedStatus(env.url, {}), 401);
    assert.equal(await refusedStatus(env.url, { authorization: 'Bearer forged' }), 401);
  } finally {
    await env.close();
  }
});

test('the gateway answers 503 while the service is not ready', async () => {
  const env = await startGateway({ ready: async () => false });
  try {
    assert.equal(await refusedStatus(env.url, { authorization: 'Bearer good-a' }), 503);
  } finally {
    await env.close();
  }
});

test('a subscribed room carries hints with exactly type, threadId and seq', async () => {
  const env = await startGateway();
  try {
    const { ws, next } = await connect(env.url);
    ws.send(JSON.stringify({ type: 'subscribe', threadId: ROOM, familyId: FAMILY }));
    assert.deepEqual(await next(), { type: 'subscribed', threadId: ROOM });

    env.bus.publish({ type: 'chat.message', threadId: ROOM, seq: 9 });
    const hint = await next();
    assert.deepEqual(Object.keys(hint).sort(), ['seq', 'threadId', 'type']);
    assert.deepEqual(hint, { type: 'chat.message', threadId: ROOM, seq: 9 });

    env.bus.publish({ type: 'chat.receipt', threadId: ROOM });
    assert.deepEqual(await next(), { type: 'chat.receipt', threadId: ROOM });
    ws.close();
  } finally {
    await env.close();
  }
});

test('a room the caller is not in is refused exactly as a REST read would be', async () => {
  const env = await startGateway();
  try {
    const { ws, next } = await connect(env.url);
    ws.send(JSON.stringify({ type: 'subscribe', threadId: OTHER_ROOM, familyId: FAMILY }));
    assert.deepEqual(await next(), {
      type: 'error',
      code: 'chat_thread_not_found',
      threadId: OTHER_ROOM,
    });
    ws.close();
  } finally {
    await env.close();
  }
});

test('removal takes effect on the next hint, without a reconnect', async () => {
  const env = await startGateway();
  try {
    const { ws, next } = await connect(env.url);
    ws.send(JSON.stringify({ type: 'subscribe', threadId: ROOM, familyId: FAMILY }));
    await next();

    env.state.allowed.delete(ROOM);
    env.bus.publish({ type: 'chat.message', threadId: ROOM, seq: 10 });
    assert.deepEqual(await next(), { type: 'error', code: 'chat_thread_not_found', threadId: ROOM });

    // Nothing for the room may arrive after the error. A ping proves the socket is quiet.
    ws.send(JSON.stringify({ type: 'ping' }));
    assert.deepEqual(await next(), { type: 'pong' });
    ws.close();
  } finally {
    await env.close();
  }
});

test('malformed frames are refused with a generic code and the socket stays usable', async () => {
  const env = await startGateway();
  try {
    const { ws, next } = await connect(env.url);
    ws.send('not json');
    assert.deepEqual(await next(), { type: 'error', code: 'invalid_frame' });
    ws.send(JSON.stringify({ type: 'subscribe', threadId: 'not-a-uuid', familyId: FAMILY }));
    assert.deepEqual(await next(), { type: 'error', code: 'invalid_frame' });
    ws.send(JSON.stringify({ type: 'subscribe', threadId: ROOM }));
    assert.deepEqual(await next(), { type: 'error', code: 'invalid_frame', threadId: ROOM });
    ws.send(JSON.stringify({ type: 'ping' }));
    assert.deepEqual(await next(), { type: 'pong' });
    ws.close();
  } finally {
    await env.close();
  }
});

test('a person may hold at most two sockets; a third is refused with 429', async () => {
  const env = await startGateway();
  try {
    const first = await connect(env.url);
    const second = await connect(env.url);
    assert.equal(await refusedStatus(env.url, { authorization: 'Bearer good-a' }), 429);
    // Another person is not affected by this person's limit.
    const other = await connect(env.url, 'Bearer good-b');
    first.ws.close();
    second.ws.close();
    other.ws.close();
  } finally {
    await env.close();
  }
});

test('a paired handset authenticates with its Device credential and its deviceId', async () => {
  const env = await startGateway();
  try {
    const { ws, next } = await connect(
      env.url,
      `Device ${DEVICE_CREDENTIAL}`,
      `?deviceId=${DEVICE_ID}`,
    );
    ws.send(JSON.stringify({ type: 'subscribe', threadId: ROOM }));
    assert.deepEqual(await next(), { type: 'subscribed', threadId: ROOM });
    ws.close();
  } finally {
    await env.close();
  }
});

test('an oversize frame closes the socket rather than being parsed', async () => {
  const env = await startGateway();
  try {
    const { ws } = await connect(env.url);
    const closed = new Promise((resolve) => ws.once('close', (code) => resolve(code)));
    ws.send('x'.repeat(CHAT_REALTIME_LIMITS.maxFrameBytes + 1));
    assert.notEqual(await closed, 1000);
  } finally {
    await env.close();
  }
});
