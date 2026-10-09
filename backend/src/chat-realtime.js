// W9 realtime — a WebSocket that carries HINTS, never content.
//
// The owner's decision (D3) and doc 46 §5 set the shape: the database is the source of truth and
// a socket only says "something changed in this room, go and ask the API". So:
//
//   * A hint is `{type, threadId, seq}`. It holds no message text, no name and no media, so a
//     socket that is somehow read by someone else reveals only that a room moved.
//   * Every hint is checked against the room AT THE MOMENT IT IS SENT. A member who was removed
//     stops receiving hints on the same connection, and gets an error frame. The check is the
//     REST check (`canReadThread`), so a socket can never receive what a GET would refuse.
//   * Authentication happens on the HTTP upgrade, with the same credentials the REST routes use:
//     a bearer token for a person, or the `Device` credential for a paired handset with its
//     `deviceId` in the query. Nothing secret is put in a URL.
//   * Nothing is replayed from the socket. A client that reconnects refetches from the REST API
//     with its `afterSeq` cursor - the same path a polling client uses - so reconnection cannot
//     create a second source of truth.
//   * Bounded everywhere: frame size, frames per minute, subscriptions per socket, sockets per
//     person, and the outbound buffer. A slow reader is disconnected, not allowed to grow memory.
//
// The bus below is in-process. One Render instance serves it directly; a second instance would
// need Postgres LISTEN/NOTIFY carrying the same minimal payload. That is a scale step, recorded
// in the proposal, and it changes nothing about what a hint may contain.

import { WebSocketServer } from 'ws';

export const CHAT_REALTIME_PATH = '/v1/realtime';
export const CHAT_HINT_TYPES = Object.freeze(['chat.message', 'chat.receipt']);

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DEVICE_AUTHORIZATION = /^Device ([A-Za-z0-9_-]{32,128})$/;

export const CHAT_REALTIME_LIMITS = Object.freeze({
  maxFrameBytes: 1024,
  maxInboundPerMinute: 60,
  maxSubscriptions: 20,
  maxSocketsPerSubject: 2,
  maxBufferedBytes: 512 * 1024,
  heartbeatMs: 25_000,
});

/// An in-process publish/subscribe bus for hints. Publishing never waits for a subscriber, and a
/// subscriber that throws cannot stop the others or the request that published.
export function createChatEventBus() {
  const handlers = new Set();
  return {
    publish(event) {
      if (!CHAT_HINT_TYPES.includes(event?.type)) {
        throw new Error('A chat hint must be one of the declared hint types.');
      }
      for (const handler of [...handlers]) {
        Promise.resolve()
          .then(() => handler(event))
          .catch(() => {
            // A failing listener is that listener's problem. It is not reported with room data.
          });
      }
    },
    subscribe(handler) {
      handlers.add(handler);
      return () => handlers.delete(handler);
    },
    size() {
      return handlers.size;
    },
  };
}

function reject(socket, status, code) {
  const body = JSON.stringify({ error: { code, message: 'The realtime connection was refused.' } });
  socket.write(
    `HTTP/1.1 ${status} ${status === 401 ? 'Unauthorized' : status === 429 ? 'Too Many Requests' : 'Refused'}\r\n`
      + 'Connection: close\r\n'
      + 'Content-Type: application/json\r\n'
      + `Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`,
  );
  socket.destroy();
}

/**
 * Attaches the gateway to an HTTP server. `familyChat` supplies the two checks the gateway
 * depends on (`canReadThread`, `authenticateDevice`); `authVerifier` verifies people; `ready`
 * says whether the service may serve protected operations at all.
 */
export function attachChatRealtime(httpServer, {
  bus,
  authVerifier,
  familyChat,
  ready,
  limits = CHAT_REALTIME_LIMITS,
}) {
  const wss = new WebSocketServer({ noServer: true, maxPayload: limits.maxFrameBytes });
  const sockets = new Set();
  const socketsBySubject = new Map();

  const authenticate = async (request, url) => {
    const authorization = request.headers.authorization;
    const device = DEVICE_AUTHORIZATION.exec(authorization ?? '');
    if (device != null) {
      const deviceId = url.searchParams.get('deviceId');
      if (deviceId == null || !UUID.test(deviceId)) return null;
      const verified = await familyChat.authenticateDevice({ deviceId, deviceCredential: device[1] });
      if (verified == null) return null;
      return {
        identity: { deviceId, deviceCredential: device[1] },
        subject: `device:${deviceId}`,
        familyId: verified.familyId,
      };
    }
    const principal = await authVerifier.verify(authorization);
    return { identity: { principal }, subject: `person:${principal.subject}`, familyId: null };
  };

  const onUpgrade = async (request, socket, head) => {
    const url = new URL(request.url ?? '/', 'http://gateway.invalid');
    if (url.pathname !== CHAT_REALTIME_PATH) {
      socket.destroy();
      return;
    }
    let who;
    try {
      if (!(await ready())) return reject(socket, 503, 'service_not_ready');
      who = await authenticate(request, url);
    } catch {
      return reject(socket, 401, 'authentication_required');
    }
    if (who == null) return reject(socket, 401, 'authentication_required');
    const open = socketsBySubject.get(who.subject) ?? 0;
    if (open >= limits.maxSocketsPerSubject) return reject(socket, 429, 'rate_limit_exceeded');

    wss.handleUpgrade(request, socket, head, (ws) => register(ws, who));
  };

  const register = (ws, who) => {
    const state = {
      ws,
      who,
      subscriptions: new Map(), // threadId -> familyId
      alive: true,
      inboundWindowStart: Date.now(),
      inboundCount: 0,
    };
    sockets.add(state);
    socketsBySubject.set(who.subject, (socketsBySubject.get(who.subject) ?? 0) + 1);

    const send = (frame) => {
      if (ws.readyState !== ws.OPEN) return;
      // A reader that falls behind is cut off. Its client reconnects and refetches from REST.
      if (ws.bufferedAmount > limits.maxBufferedBytes) {
        ws.terminate();
        return;
      }
      ws.send(JSON.stringify(frame));
    };
    state.send = send;

    // A socket error (an oversize frame, a dropped connection) must not reach the process as an
    // unhandled 'error' event. The socket is already being closed by ws when this fires.
    ws.on('error', () => {});

    ws.on('pong', () => {
      state.alive = true;
    });

    ws.on('message', async (raw) => {
      const now = Date.now();
      if (now - state.inboundWindowStart >= 60_000) {
        state.inboundWindowStart = now;
        state.inboundCount = 0;
      }
      state.inboundCount += 1;
      if (state.inboundCount > limits.maxInboundPerMinute) {
        ws.close(1008, 'rate_limited');
        return;
      }
      let frame;
      try {
        frame = JSON.parse(raw.toString('utf8'));
      } catch {
        send({ type: 'error', code: 'invalid_frame' });
        return;
      }
      try {
        await handleFrame(state, frame);
      } catch {
        // A failed access check answers with a generic error. Nothing about the room leaks.
        send({ type: 'error', code: 'internal_error' });
      }
    });

    ws.on('close', () => {
      sockets.delete(state);
      const remaining = (socketsBySubject.get(who.subject) ?? 1) - 1;
      if (remaining <= 0) socketsBySubject.delete(who.subject);
      else socketsBySubject.set(who.subject, remaining);
    });

    send({ type: 'ready', heartbeatMs: limits.heartbeatMs });
  };

  const handleFrame = async (state, frame) => {
    const { send } = state;
    if (frame?.type === 'ping') {
      send({ type: 'pong' });
      return;
    }
    if (frame?.type === 'unsubscribe' && typeof frame.threadId === 'string') {
      state.subscriptions.delete(frame.threadId);
      send({ type: 'unsubscribed', threadId: frame.threadId });
      return;
    }
    if (frame?.type !== 'subscribe' || typeof frame.threadId !== 'string' || !UUID.test(frame.threadId)) {
      send({ type: 'error', code: 'invalid_frame' });
      return;
    }
    const threadId = frame.threadId;
    // A person names the family they are subscribing in; a handset's family is its own.
    const familyId = state.who.familyId ?? frame.familyId ?? null;
    if (familyId == null || !UUID.test(String(familyId))) {
      send({ type: 'error', code: 'invalid_frame', threadId });
      return;
    }
    if (state.subscriptions.size >= limits.maxSubscriptions && !state.subscriptions.has(threadId)) {
      send({ type: 'error', code: 'chat_subscription_limit', threadId });
      return;
    }
    const allowed = await familyChat.canReadThread({ ...state.who.identity, familyId, threadId });
    if (!allowed) {
      // The same answer a REST read gives for a room the caller is not in.
      send({ type: 'error', code: 'chat_thread_not_found', threadId });
      return;
    }
    state.subscriptions.set(threadId, familyId);
    send({ type: 'subscribed', threadId });
  };

  // Every hint is re-authorised for every socket that holds the room. Removal therefore takes
  // effect on the next hint, without a reconnect.
  const unsubscribeBus = bus.subscribe(async (event) => {
    await Promise.all([...sockets].map(async (state) => {
      const familyId = state.subscriptions.get(event.threadId);
      if (familyId == null) return;
      try {
        const allowed = await familyChat.canReadThread({ ...state.who.identity, familyId, threadId: event.threadId });
        if (!allowed) {
          state.subscriptions.delete(event.threadId);
          state.send({ type: 'error', code: 'chat_thread_not_found', threadId: event.threadId });
          return;
        }
      } catch {
        // If the check itself fails the hint is withheld; the socket is not told why.
        return;
      }
      const hint = { type: event.type, threadId: event.threadId };
      if (event.seq !== undefined) hint.seq = event.seq;
      state.send(hint);
    }));
  });

  const heartbeat = setInterval(() => {
    for (const state of sockets) {
      if (!state.alive) {
        state.ws.terminate();
        continue;
      }
      state.alive = false;
      state.ws.ping();
    }
  }, limits.heartbeatMs);
  heartbeat.unref();

  httpServer.on('upgrade', onUpgrade);

  return {
    connectionCount: () => sockets.size,
    close() {
      clearInterval(heartbeat);
      unsubscribeBus();
      httpServer.off('upgrade', onUpgrade);
      for (const state of sockets) state.ws.terminate();
      wss.close();
    },
  };
}
