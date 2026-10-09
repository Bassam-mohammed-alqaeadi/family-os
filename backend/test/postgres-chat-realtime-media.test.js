// W9 against real PostgreSQL: media, receipts, the child's handset, the database laws and the
// realtime hint channel. Gated by DATABASE_URL like every other PostgreSQL test, and run in CI
// by backend_ci.yml.
//
// What it must prove, in the order it would hurt to be wrong:
//   1. Media bytes reach a room only through the room. A guardian who is not in the room, a
//      participant who joined later, and a removed child's handset all get 404 for the same file.
//   2. Metadata that reveals a location is gone from what is stored and what is served.
//   3. Receipts are aggregate: counts only, monotonic, never ahead of the newest message, and
//      a read is also a delivery. No per-person list exists in any response.
//   4. The database itself refuses a media row or receipt that breaks a rule, whatever the API
//      code does.
//   5. A socket carries hints, never content; a removed participant stops receiving hints on
//      the connection they already hold; and a person has at most two sockets.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, readdir, rm, stat } from 'node:fs/promises';
import http from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import WebSocket from 'ws';
import { createApp } from '../src/app.js';
import { attachChatRealtime } from '../src/chat-realtime.js';
import { LocalDiskChatMediaStore } from '../src/chat-media-store.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';
import { TestAuthVerifier } from './memory-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const SECRET_LOCATION = 'GPS-SECRET-LOCATION-9731';

// ── fixtures ────────────────────────────────────────────────────────────────────────────────

function u16(value) {
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16BE(value);
  return buffer;
}

/** A small, well-formed JPEG whose APP1 (EXIF) segment carries a location string. */
function jpegWithLocation() {
  const exif = Buffer.concat([Buffer.from('Exif\0\0'), Buffer.from(SECRET_LOCATION)]);
  const app1 = Buffer.concat([Buffer.from([0xff, 0xe1]), u16(exif.length + 2), exif]);
  const dqt = Buffer.concat([Buffer.from([0xff, 0xdb]), u16(67), Buffer.alloc(65, 1)]);
  const sof0 = Buffer.concat([Buffer.from([0xff, 0xc0]), u16(11), Buffer.from([8, 0, 2, 0, 2, 1, 1, 0x11, 0])]);
  const sos = Buffer.concat([Buffer.from([0xff, 0xda]), u16(8), Buffer.from([1, 1, 0, 0, 63, 0]), Buffer.from([0x12, 0x34, 0x56])]);
  return Buffer.concat([Buffer.from([0xff, 0xd8]), app1, dqt, sof0, sos, Buffer.from([0xff, 0xd9])]);
}

function voiceNote(tag = 'voice') {
  return Buffer.concat([Buffer.from('OggS'), Buffer.from(tag), Buffer.alloc(64, 7)]);
}

function sha256Hex(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function withDatabase(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

// Every store a test opens is closed before its database is dropped. A pool left open would be
// killed by DROP DATABASE ... WITH (FORCE) and would keep the test process alive.
const openStores = new Set();

function openStore(connectionString) {
  const store = new PostgresFoundationStore({ connectionString });
  openStores.add(store);
  return store;
}

async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_w9_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
  try {
    await admin.query(`CREATE DATABASE ${name}`);
    const client = new Client({ connectionString: withDatabase(DATABASE_URL, name) });
    await client.connect();
    try {
      await run(client, name);
    } finally {
      for (const store of openStores) await store.close();
      openStores.clear();
      await client.end();
    }
  } finally {
    await admin.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
    await admin.end();
  }
}

async function migrate(client) {
  await applyMigrations({
    client,
    migrations: FOUNDATION_SCHEMA_MIGRATIONS,
    readVerifiedMigration: async (migration) => {
      const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
      assert.equal(sha256Hex(sql), migration.sha256, `${migration.name} must match its recorded checksum`);
      return sql;
    },
  });
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

function authorized(subject, extra = {}) {
  return { authorization: `Bearer ${subject}`, ...extra };
}

async function call(baseUrl, path, { method = 'GET', headers = {}, body, raw = false } = {}) {
  const isBuffer = Buffer.isBuffer(body);
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      accept: raw ? '*/*' : 'application/json',
      ...headers,
      ...(body === undefined || isBuffer ? {} : { 'content-type': 'application/json' }),
    },
    body: body === undefined ? undefined : isBuffer ? body : JSON.stringify(body),
  });
  const bytes = Buffer.from(await response.arrayBuffer());
  const type = response.headers.get('content-type') ?? '';
  const json = type.includes('application/json') && bytes.length > 0 ? JSON.parse(bytes.toString('utf8')) : null;
  return { status: response.status, body: json, bytes, headers: response.headers };
}

/** A family with a primary guardian, a child, two co-guardians and one paired handset. */
async function seedHousehold(baseUrl, client, tag) {
  const created = await call(baseUrl, '/v1/families', {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': `${tag}-family` }),
    body: { displayName: 'عائلة الاختبار' },
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const familyId = created.body.family.id;

  const child = await call(baseUrl, `/v1/families/${familyId}/children`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': `${tag}-child` }),
    body: { displayName: 'أماني', ageYears: 11, avatarEmoji: '🦁', themeColor: 'sky' },
  });
  assert.equal(child.status, 201);
  const childId = child.body.child.id;

  for (const [subject, key] of [['test-co', `${tag}-co`], ['test-co2', `${tag}-co2`]]) {
    const invite = await call(baseUrl, `/v1/families/${familyId}/memberships`, {
      method: 'POST',
      headers: authorized('test-primary', { 'idempotency-key': key }),
      body: { role: 'co_guardian', targetSubject: subject },
    });
    assert.equal(invite.status, 201);
    const accepted = await call(baseUrl, `/v1/families/${familyId}/memberships/${invite.body.membership.id}/accept`, {
      method: 'POST',
      headers: authorized(subject, { 'idempotency-key': `${key}-accept` }),
    });
    assert.equal(accepted.status, 200);
  }

  const rows = await client.query(
    `SELECT target_subject, id FROM family_memberships WHERE family_id = $1 AND status = 'active'`,
    [familyId],
  );
  const membershipOf = (subject) => rows.rows.find((row) => row.target_subject === subject).id;

  const deviceCredential = `${tag}-device-credential-value-0001`;
  const device = await client.query(
    `INSERT INTO family_child_devices
       (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
     VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
     RETURNING id`,
    [familyId, childId, sha256Hex(deviceCredential)],
  );
  return {
    familyId,
    childId,
    deviceId: device.rows[0].id,
    deviceCredential,
    primary: membershipOf('test-primary'),
    co: membershipOf('test-co'),
    co2: membershipOf('test-co2'),
  };
}

async function createDirectRoom(baseUrl, familyId, withMembershipId, key) {
  const room = await call(baseUrl, `/v1/families/${familyId}/chat/threads`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': key }),
    body: { kind: 'direct', participants: [{ kind: 'membership', id: withMembershipId }] },
  });
  assert.equal(room.status, 201, JSON.stringify(room.body));
  return room.body.thread.id;
}

async function createGroupRoom(baseUrl, familyId, participants, key) {
  const room = await call(baseUrl, `/v1/families/${familyId}/chat/threads`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': key }),
    body: { kind: 'group', title: 'مجموعة الاختبار', participants },
  });
  assert.equal(room.status, 201, JSON.stringify(room.body));
  return room.body.thread.id;
}

async function sendText(baseUrl, familyId, threadId, subject, text, key) {
  const sent = await call(baseUrl, `/v1/families/${familyId}/chat/threads/${threadId}/messages`, {
    method: 'POST',
    headers: authorized(subject, { 'idempotency-key': key }),
    body: { body: text, clientMessageId: `client-${key}` },
  });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  return sent.body.message;
}

async function uploadImage(baseUrl, familyId, threadId, subject, bytes, clientMediaId) {
  return call(baseUrl, `/v1/families/${familyId}/chat/threads/${threadId}/media?clientMediaId=${clientMediaId}`, {
    method: 'POST',
    headers: authorized(subject, { 'content-type': 'image/jpeg' }),
    body: bytes,
  });
}

// ── tests ───────────────────────────────────────────────────────────────────────────────────

test('media: the bytes are cleaned before they are kept, replay is idempotent, and a lie is refused', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const root = await mkdtemp(join(tmpdir(), 'family-os-w9-media-'));
    const mediaStore = new LocalDiskChatMediaStore({ root });
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      chatMediaStore: mediaStore,
    });
    try {
      await withServer(app, async (baseUrl) => {
        const household = await seedHousehold(baseUrl, client, 'w9media');
        const room = await createDirectRoom(baseUrl, household.familyId, household.co, 'w9media-room');

        const original = jpegWithLocation();
        const first = await uploadImage(baseUrl, household.familyId, room, 'test-primary', original, 'photo-0000001');
        assert.equal(first.status, 201, JSON.stringify(first.body));
        const mediaId = first.body.media.id;
        assert.equal(first.body.media.kind, 'image');
        assert.equal(first.body.media.mimeType, 'image/jpeg');
        assert.equal(first.body.media.contentPath.endsWith('/content'), true);
        assert.equal(JSON.stringify(first.body).includes('storageKey'), false, 'no storage handle is exposed');
        assert.equal(JSON.stringify(first.body).includes(SECRET_LOCATION), false);

        // What is stored: the stored row, the hash the row records, and the file on disk agree,
        // and none of them carries the location.
        const row = await client.query(
          `SELECT storage_key, encode(sha256, 'hex') AS sha, byte_size FROM family_chat_media WHERE id = $1`,
          [mediaId],
        );
        const stored = await readFile(join(root, row.rows[0].storage_key));
        assert.equal(stored.includes(Buffer.from(SECRET_LOCATION)), false, 'the file on disk is clean');
        assert.equal(row.rows[0].sha, sha256Hex(stored), 'the recorded hash is of the stored bytes');
        assert.equal(row.rows[0].byte_size, stored.length);
        assert.ok(stored.length < original.length);

        // Replay: the same id and the same file is the same media, reported as a replay.
        const replay = await uploadImage(baseUrl, household.familyId, room, 'test-primary', original, 'photo-0000001');
        assert.equal(replay.status, 200);
        assert.equal(replay.body.media.id, mediaId);
        assert.equal(replay.body.replayed, true);

        // The same id with a different file is a conflict, never a silent overwrite.
        const different = await uploadImage(
          baseUrl, household.familyId, room, 'test-primary', Buffer.concat([original, Buffer.from('x')]), 'photo-0000001',
        );
        assert.equal(different.status, 409);
        assert.equal(different.body.error.code, 'chat_media_client_id_conflict');

        // A file that claims to be a JPEG and is not one is refused, and nothing is stored.
        const before = (await readdir(root, { recursive: true })).length;
        const liar = await uploadImage(baseUrl, household.familyId, room, 'test-primary', voiceNote('liar'), 'photo-liar-01');
        assert.equal(liar.status, 415);
        assert.equal(liar.body.error.code, 'chat_media_type_mismatch');
        assert.equal((await readdir(root, { recursive: true })).length, before, 'a refused upload leaves no file');

        // An audio note must declare its length, and the length must be within the law.
        const missingDuration = await call(baseUrl, `/v1/families/${household.familyId}/chat/threads/${room}/media?clientMediaId=voice-0000001`, {
          method: 'POST',
          headers: authorized('test-primary', { 'content-type': 'audio/ogg' }),
          body: voiceNote(),
        });
        assert.equal(missingDuration.status, 400);
        assert.equal(missingDuration.body.error.code, 'chat_media_duration_invalid');

        // A message may not be sent with media that someone else uploaded.
        const hijack = await call(baseUrl, `/v1/families/${household.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-co', { 'idempotency-key': 'hijack-0001' }),
          body: { mediaId, clientMessageId: 'client-hijack-01' },
        });
        assert.equal(hijack.status, 404);
        assert.equal(hijack.body.error.code, 'chat_media_not_found');

        // The uploader sends it. Only then is it visible to the room as a message.
        const sent = await call(baseUrl, `/v1/families/${household.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'send-img-0001' }),
          body: { mediaId, body: 'صورة', clientMessageId: 'client-img-000001' },
        });
        assert.equal(sent.status, 201, JSON.stringify(sent.body));
        assert.equal(sent.body.message.kind, 'image');
        assert.equal(sent.body.message.media.id, mediaId);

        // What is served: the same bytes, with a sniffed type and the sandbox policy.
        const served = await call(baseUrl, `/v1/families/${household.familyId}/chat/threads/${room}/media/${mediaId}/content`, {
          headers: authorized('test-co'),
          raw: true,
        });
        assert.equal(served.status, 200);
        assert.equal(served.headers.get('content-type'), 'image/jpeg');
        assert.equal(served.headers.get('x-content-type-options'), 'nosniff');
        assert.match(served.headers.get('content-security-policy'), /sandbox/);
        assert.equal(served.headers.get('cache-control'), 'private, no-store');
        assert.deepEqual(served.bytes, stored);

        // Sent media cannot be attached to a second message.
        const reuse = await call(baseUrl, `/v1/families/${household.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'send-img-0002' }),
          body: { mediaId, clientMessageId: 'client-img-000002' },
        });
        assert.equal(reuse.status, 409);
        assert.equal(reuse.body.error.code, 'chat_media_already_sent');
      });
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

test('media: the room decides who may see the bytes - now, after joining, and after removal', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const root = await mkdtemp(join(tmpdir(), 'family-os-w9-room-'));
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      chatMediaStore: new LocalDiskChatMediaStore({ root }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'w9room');
        const room = await createGroupRoom(
          baseUrl,
          h.familyId,
          [{ kind: 'membership', id: h.co }, { kind: 'child', id: h.childId }],
          'w9room-room',
        );
        const before = await uploadImage(baseUrl, h.familyId, room, 'test-primary', jpegWithLocation(), 'before-join-01');
        const beforeMediaId = before.body.media.id;
        const beforeSend = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9room-before' }),
          body: { mediaId: beforeMediaId, clientMessageId: 'client-before-01' },
        });
        assert.equal(beforeSend.status, 201);
        const contentPath = (mediaId) => `/v1/families/${h.familyId}/chat/threads/${room}/media/${mediaId}/content`;

        // A guardian who is in the family but not in the room cannot read the room's media.
        const outsider = await call(baseUrl, contentPath(beforeMediaId), { headers: authorized('test-co2'), raw: true });
        assert.equal(outsider.status, 404);

        // The co-guardian joins later. They see what is sent after they join, and nothing before.
        const join = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/members`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9room-join' }),
          body: { participantKind: 'membership', participantId: h.co2 },
        });
        assert.equal(join.status, 200, JSON.stringify(join.body));
        const stillBefore = await call(baseUrl, contentPath(beforeMediaId), { headers: authorized('test-co2'), raw: true });
        assert.equal(stillBefore.status, 404, 'media sent before joining stays out of reach');

        const after = await uploadImage(baseUrl, h.familyId, room, 'test-primary', jpegWithLocation(), 'after-join-01');
        const afterSend = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9room-after' }),
          body: { mediaId: after.body.media.id, clientMessageId: 'client-after-001' },
        });
        assert.equal(afterSend.status, 201);
        const seen = await call(baseUrl, contentPath(after.body.media.id), { headers: authorized('test-co2'), raw: true });
        assert.equal(seen.status, 200);

        // Removal of the room's member closes access on the next request, for the bytes too.
        await client.query(
          `UPDATE family_chat_thread_members SET left_at = NOW()
            WHERE thread_id = $1 AND participant_kind = 'membership' AND participant_id = $2`,
          [room, h.co2],
        );
        const removed = await call(baseUrl, contentPath(after.body.media.id), { headers: authorized('test-co2'), raw: true });
        assert.equal(removed.status, 404, 'a removed member is refused the same bytes');
      });
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

test('deleting a voice note removes its bytes from disk, and the message keeps its place without them', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const root = await mkdtemp(join(tmpdir(), 'family-os-w9-purge-'));
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      chatMediaStore: new LocalDiskChatMediaStore({ root }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'w9purge');
        const room = await createDirectRoom(baseUrl, h.familyId, h.co, 'w9purge-room');
        const upload = await call(
          baseUrl,
          `/v1/families/${h.familyId}/chat/threads/${room}/media?clientMediaId=voice-purge-01&durationMs=9000`,
          { method: 'POST', headers: authorized('test-primary', { 'content-type': 'audio/ogg' }), body: voiceNote('purge') },
        );
        assert.equal(upload.status, 201, JSON.stringify(upload.body));
        assert.equal(upload.body.media.kind, 'audio');
        assert.equal(upload.body.media.durationMs, 9000);
        const mediaId = upload.body.media.id;
        const sent = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'purge-send-01' }),
          body: { mediaId, clientMessageId: 'client-purge-0001' },
        });
        assert.equal(sent.status, 201);
        const messageId = sent.body.message.id;
        const row = await client.query(`SELECT storage_key FROM family_chat_media WHERE id = $1`, [mediaId]);
        const key = row.rows[0].storage_key;
        assert.ok((await stat(join(root, key))).isFile());

        const deleted = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/messages/${messageId}/deletion`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'purge-delete-01' }),
        });
        assert.equal(deleted.status, 200, JSON.stringify(deleted.body));
        assert.equal(JSON.stringify(deleted.body).includes('purgeStorageKeys'), false, 'internal keys are not returned');
        assert.equal(deleted.body.message.kind, 'audio', 'the message keeps its kind');
        assert.equal(deleted.body.message.media, null, 'and loses its media');
        await assert.rejects(stat(join(root, key)), (error) => error.code === 'ENOENT');

        const media = await client.query(`SELECT storage_key, removed_at FROM family_chat_media WHERE id = $1`, [mediaId]);
        assert.equal(media.rows[0].storage_key, null);
        assert.ok(media.rows[0].removed_at, 'the trace of the removal is kept');

        const gone = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/media/${mediaId}/content`, {
          headers: authorized('test-co'),
          raw: true,
        });
        assert.equal(gone.status, 404);
      });
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

test('receipts are aggregate counts only, never ahead of the newest message, and a read is also a delivery', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    await withServer(app, async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'w9rcpt');
      const room = await createDirectRoom(baseUrl, h.familyId, h.co, 'w9rcpt-room');
      const first = await sendText(baseUrl, h.familyId, room, 'test-primary', 'الأولى', 'rcpt-msg-001');
      await sendText(baseUrl, h.familyId, room, 'test-primary', 'الثانية', 'rcpt-msg-002');

      const deliver = (subject, deliveredSeq, key) => call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/delivered`, {
        method: 'POST',
        headers: authorized(subject, { 'idempotency-key': key }),
        body: { deliveredSeq },
      });
      const listFor = (subject) => call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/messages`, {
        headers: authorized(subject),
      });

      // The co-guardian has received the first message only.
      assert.equal((await deliver('test-co', 1, 'rcpt-del-0001')).status, 200);
      let list = await listFor('test-primary');
      const sentMessage = list.body.messages.find((message) => message.id === first.id);
      assert.deepEqual(Object.keys(sentMessage.receipt).sort(), ['deliveredCount', 'otherParticipantCount', 'readCount']);
      assert.equal(sentMessage.receipt.deliveredCount, 1);
      assert.equal(sentMessage.receipt.readCount, 0);
      assert.equal(sentMessage.receipt.otherParticipantCount, 1);
      assert.equal(JSON.stringify(list.body).includes('"co"'), false, 'no per-person list');
      assert.equal(JSON.stringify(list.body).includes(h.co), false, 'no participant id in a receipt');

      // Moving backwards is not a regression; it is ignored.
      const back = await deliver('test-co', 0, 'rcpt-del-0002');
      assert.equal(back.status, 200);
      const row = await client.query(
        `SELECT last_delivered_seq FROM family_chat_thread_members WHERE thread_id = $1 AND participant_id = $2`,
        [room, h.co],
      );
      assert.equal(Number(row.rows[0].last_delivered_seq), 1, 'delivery only moves forward');

      // Claiming to have received what does not exist is refused.
      const ahead = await deliver('test-co', 99, 'rcpt-del-0003');
      assert.equal(ahead.status, 409);
      assert.equal(ahead.body.error.code, 'chat_delivered_ahead');

      // A read by the co-guardian raises their delivery too, and the receipt reflects both.
      const read = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/reads`, {
        method: 'POST',
        headers: authorized('test-co', { 'idempotency-key': 'rcpt-read-0001' }),
        body: { readSeq: 2 },
      });
      assert.equal(read.status, 200, JSON.stringify(read.body));
      const deliveredRow = await client.query(
        `SELECT last_delivered_seq, last_read_seq FROM family_chat_thread_members WHERE thread_id = $1 AND participant_id = $2`,
        [room, h.co],
      );
      assert.equal(Number(deliveredRow.rows[0].last_read_seq), 2);
      assert.equal(Number(deliveredRow.rows[0].last_delivered_seq), 2, 'a read is also a delivery');

      list = await listFor('test-primary');
      const after = list.body.messages.find((message) => message.id === first.id);
      assert.equal(after.receipt.readCount, 1);
      assert.equal(after.receipt.deliveredCount, 1);
    });
  });
});

test('the database refuses media and receipt rows that break the rules, whatever the API does', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    await withServer(app, async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'w9laws');
      const room = await createDirectRoom(baseUrl, h.familyId, h.co, 'w9laws-room');
      const sha = Buffer.alloc(32, 1);
      const insert = (overrides = {}) => {
        const values = {
          id: '00000000-0000-4000-8000-0000000000a1',
          family_id: h.familyId,
          thread_id: room,
          uploader_kind: 'membership',
          uploader_id: h.primary,
          client_media_id: 'law-client-0001',
          kind: 'audio',
          mime_type: 'audio/ogg',
          byte_size: 100,
          sha256: sha,
          declared_duration_ms: 1000,
          storage_key: '00000000-0000-4000-8000-0000000000b1',
          removed_at: null,
          ...overrides,
        };
        const names = Object.keys(values);
        return client.query(
          `INSERT INTO family_chat_media (${names.join(', ')}) VALUES (${names.map((_, i) => `$${i + 1}`).join(', ')})`,
          names.map((name) => values[name]),
        );
      };

      await assert.rejects(insert({ storage_key: null, removed_at: null }), /family_chat_media_lifecycle_complete/);
      await assert.rejects(insert({ declared_duration_ms: null }), /family_chat_media_kind_limits/);
      await assert.rejects(insert({ byte_size: 6 * 1024 * 1024 + 1 }), /family_chat_media_kind_limits/);
      await assert.rejects(insert({ mime_type: 'text/html', kind: 'image' }), /family_chat_media_mime_type_check|check constraint/);
      await assert.rejects(insert({ storage_key: 'not-a-uuid' }), /storage_key/);
      // A stranger, not a participant of the room, cannot put media into it.
      await assert.rejects(insert({ uploader_id: '00000000-0000-4000-8000-0000000000c9' }), /family_chat_media_uploader_fk/);
      // Only a participant of the room.
      await insert();

      // A message's kind must match its media.
      await assert.rejects(
        client.query(
          `INSERT INTO family_chat_messages
             (id, family_id, thread_id, seq, author_kind, author_id, client_message_id, body, kind, media_id)
           VALUES (gen_random_uuid(), $1, $2, 90, 'membership', $3, 'law-msg-000001', 'x', 'image', NULL)`,
          [h.familyId, room, h.primary],
        ),
        /family_chat_messages_kind_matches_media/,
      );

      // The receipt invariant: delivery is never behind the read.
      await assert.rejects(
        client.query(
          `UPDATE family_chat_thread_members SET last_read_seq = 5, last_delivered_seq = 4
            WHERE thread_id = $1 AND participant_id = $2`,
          [room, h.co],
        ),
        /family_chat_thread_members_delivered_not_before_read/,
      );
    });
  });
});

test('the child handset: a voice note from the device reaches the guardian, and removal cuts it off at once', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const root = await mkdtemp(join(tmpdir(), 'family-os-w9-device-'));
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
      chatMediaStore: new LocalDiskChatMediaStore({ root }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'w9dev');
        const deviceAuth = { authorization: `Device ${h.deviceCredential}` };
        const room = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w9dev-room-0001' },
          body: { kind: 'direct', participants: [{ kind: 'membership', id: h.primary }] },
        });
        assert.equal(room.status, 201, JSON.stringify(room.body));
        const threadId = room.body.thread.id;

        const upload = await call(
          baseUrl,
          `/v1/devices/${h.deviceId}/chat/threads/${threadId}/media?clientMediaId=device-voice-01&durationMs=4000`,
          { method: 'POST', headers: { ...deviceAuth, 'content-type': 'audio/ogg' }, body: voiceNote('device') },
        );
        assert.equal(upload.status, 201, JSON.stringify(upload.body));
        const mediaId = upload.body.media.id;

        const sent = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads/${threadId}/messages`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w9dev-send-0001' },
          body: { mediaId, clientMessageId: 'client-device-0001' },
        });
        assert.equal(sent.status, 201, JSON.stringify(sent.body));
        assert.equal(sent.body.message.kind, 'audio');

        // The guardian in the room hears it; the child's own handset hears it too.
        const guardianFetch = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${threadId}/media/${mediaId}/content`, {
          headers: authorized('test-primary'),
          raw: true,
        });
        assert.equal(guardianFetch.status, 200);
        assert.ok(guardianFetch.bytes.length > 0);
        const deviceFetch = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads/${threadId}/media/${mediaId}/content`, {
          headers: deviceAuth,
          raw: true,
        });
        assert.equal(deviceFetch.status, 200);
        assert.deepEqual(deviceFetch.bytes, guardianFetch.bytes);

        // The child is removed from the room. The handset's next request is refused.
        await client.query(
          `UPDATE family_chat_thread_members SET left_at = NOW()
            WHERE thread_id = $1 AND participant_kind = 'child' AND participant_id = $2`,
          [threadId, h.childId],
        );
        const refused = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads/${threadId}/media/${mediaId}/content`, {
          headers: deviceAuth,
          raw: true,
        });
        assert.equal(refused.status, 404, 'a removed child cannot fetch the room media');
      });
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

test('realtime: authentication on upgrade, membership on subscribe, hints without content, removal and limits', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = openStore(withDatabase(DATABASE_URL, client.database));
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    const server = http.createServer(app);
    const gateway = attachChatRealtime(server, {
      bus: app.locals.chatBus,
      authVerifier: new TestAuthVerifier(),
      familyChat: app.locals.familyChat,
      ready: async () => true,
    });
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    const { port } = server.address();
    const baseUrl = `http://127.0.0.1:${port}`;
    const wsUrl = `ws://127.0.0.1:${port}/v1/realtime`;
    const sockets = [];
    const connect = (headers, query = '') => {
      const ws = new WebSocket(`${wsUrl}${query}`, { headers });
      const frames = [];
      ws.on('message', (raw) => frames.push(JSON.parse(raw.toString('utf8'))));
      ws.on('error', () => {});
      sockets.push(ws);
      return { ws, frames };
    };
    const opened = (socket) => new Promise((resolve, reject) => {
      socket.ws.once('open', resolve);
      socket.ws.once('unexpected-response', (_request, response) => reject(Object.assign(new Error('refused'), { status: response.statusCode })));
      socket.ws.once('error', reject);
    });
    const until = async (socket, predicate, timeoutMs = 3000) => {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        const found = socket.frames.find(predicate);
        if (found) return found;
        await new Promise((resolve) => setTimeout(resolve, 20));
      }
      assert.fail(`expected a frame; saw ${JSON.stringify(socket.frames)}`);
    };
    try {
      const h = await seedHousehold(baseUrl, client, 'w9rt');
      const room = await createDirectRoom(baseUrl, h.familyId, h.co, 'w9rt-room');

      // 1. No credentials, no socket.
      const anonymous = connect({});
      await assert.rejects(opened(anonymous), (error) => error.status === 401);

      // 2. A guardian who is in the room subscribes and is told when it moves.
      const coSocket = connect(authorized('test-co'));
      await opened(coSocket);
      await until(coSocket, (frame) => frame.type === 'ready');
      coSocket.ws.send(JSON.stringify({ type: 'subscribe', threadId: room, familyId: h.familyId }));
      await until(coSocket, (frame) => frame.type === 'subscribed' && frame.threadId === room);

      // 3. A guardian who is not in the room cannot subscribe to it.
      const outsider = connect(authorized('test-co2'));
      await opened(outsider);
      outsider.ws.send(JSON.stringify({ type: 'subscribe', threadId: room, familyId: h.familyId }));
      const denied = await until(outsider, (frame) => frame.type === 'error');
      assert.equal(denied.code, 'chat_thread_not_found');

      // 4. A message is sent. The socket hears a hint: type, room and sequence. Nothing else.
      await sendText(baseUrl, h.familyId, room, 'test-primary', 'سرّ لا يخرج من الصندوق', 'rt-msg-0001');
      const hint = await until(coSocket, (frame) => frame.type === 'chat.message');
      assert.deepEqual(Object.keys(hint).sort(), ['seq', 'threadId', 'type']);
      assert.equal(hint.threadId, room);
      const raw = coSocket.frames.map((frame) => JSON.stringify(frame)).join('');
      assert.equal(raw.includes('سرّ'), false, 'the message text never travels on the socket');
      assert.equal(raw.includes(h.co), false);

      // 5. A read raises a receipt hint for the room.
      await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${room}/reads`, {
        method: 'POST',
        headers: authorized('test-co', { 'idempotency-key': 'rt-read-0001' }),
        body: { readSeq: 1 },
      });
      await until(coSocket, (frame) => frame.type === 'chat.receipt');

      // 6. A bad frame gets a bounded error, not a crash.
      coSocket.ws.send('{not json');
      await until(coSocket, (frame) => frame.type === 'error' && frame.code === 'invalid_frame');

      // 7. Removal: the co-guardian leaves the room. The next hint never reaches the socket.
      await client.query(
        `UPDATE family_chat_thread_members SET left_at = NOW()
          WHERE thread_id = $1 AND participant_kind = 'membership' AND participant_id = $2`,
        [room, h.co],
      );
      const beforeRemoval = coSocket.frames.length;
      await sendText(baseUrl, h.familyId, room, 'test-primary', 'بعد الإزالة', 'rt-msg-0002');
      await until(coSocket, (frame) => frame.type === 'error' && frame.code === 'chat_thread_not_found');
      const afterRemoval = coSocket.frames.slice(beforeRemoval).filter((frame) => frame.type === 'chat.message');
      assert.equal(afterRemoval.length, 0, 'a removed member receives no hint');

      // 8. Two sockets per person are allowed; a third concurrent one is refused before it is upgraded.
      const second = connect(authorized('test-primary'));
      await opened(second);
      const third = connect(authorized('test-primary'));
      await opened(third);
      const fourth = connect(authorized('test-primary'));
      await assert.rejects(opened(fourth), (error) => error.status === 429);

      // 9. A child's handset connects with its device credential and its own device id.
      const device = connect(
        { authorization: `Device ${h.deviceCredential}` },
        `?deviceId=${h.deviceId}`,
      );
      await opened(device);
      // A room the child is not in is refused to the handset, as it is to any stranger.
      device.ws.send(JSON.stringify({ type: 'subscribe', threadId: room }));
      await until(device, (frame) => frame.type === 'error' && frame.code === 'chat_thread_not_found');
      // The child's own room is followed; a hint reaches the handset and carries no text.
      const childRoom = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads`, {
        method: 'POST',
        headers: { authorization: `Device ${h.deviceCredential}`, 'idempotency-key': 'rt-device-room' },
        body: { kind: 'direct', participants: [{ kind: 'membership', id: h.primary }] },
      });
      assert.equal(childRoom.status, 201, JSON.stringify(childRoom.body));
      const childThread = childRoom.body.thread.id;
      device.ws.send(JSON.stringify({ type: 'subscribe', threadId: childThread }));
      await until(device, (frame) => frame.type === 'subscribed' && frame.threadId === childThread);
      await sendText(baseUrl, h.familyId, childThread, 'test-primary', 'رسالة سرية للطفلة', 'rt-device-msg');
      const deviceHint = await until(device, (frame) => frame.type === 'chat.message' && frame.threadId === childThread);
      assert.equal(deviceHint.seq, 1);
      assert.equal(JSON.stringify(device.frames).includes('رسالة سرية'), false);
    } finally {
      for (const socket of sockets) socket.terminate();
      gateway.close();
      await new Promise((resolve) => server.close(resolve));
    }
  });
});
