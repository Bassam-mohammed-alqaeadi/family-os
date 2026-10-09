// Push nudges against real PostgreSQL. Gated by DATABASE_URL like every PostgreSQL test; CI runs
// it in backend_ci.yml.
//
// What it must prove:
//   1. Without an FCM sender, registration answers 503 and writes nothing.
//   2. Only guardians register; a token moves to the latest guardian who registers it; a guardian
//      removes only their own registration.
//   3. A message nudges the other active guardians in its room, never the author and never a
//      guardian outside the room, whether a guardian or a child sent it.
//   4. A nudge carries no message text and no sender name.
//   5. A token FCM reports as unregistered is removed; a transient refusal removes nothing.
//   6. A replayed send is not nudged a second time.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { createApp } from '../src/app.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';
import { TestAuthVerifier } from './memory-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const MESSAGE_TEXT = 'SECRET-MESSAGE-TEXT-4417';
const TOKEN_A = 'android-token-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const TOKEN_B = 'android-token-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const TOKEN_C = 'android-token-cccccccccccccccccccccccccccccccc';

function sha256Hex(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function withDatabase(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

const openStores = new Set();

async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_push_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
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

async function call(baseUrl, path, { method = 'GET', headers = {}, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      accept: 'application/json',
      ...headers,
      ...(body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}

/** A recording sender. `outcome` decides what each nudge returns. */
function recordingSender(outcome = () => 'sent') {
  const sent = [];
  return {
    sent,
    async send(args) {
      sent.push(args);
      return outcome(args);
    },
  };
}

async function waitFor(condition, label) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (await condition()) return;
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  assert.fail(`timed out waiting for ${label}`);
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
    [familyId, child.body.child.id, sha256Hex(deviceCredential)],
  );
  return {
    familyId,
    deviceId: device.rows[0].id,
    deviceCredential,
    primary: membershipOf('test-primary'),
    co: membershipOf('test-co'),
    co2: membershipOf('test-co2'),
  };
}

async function groupRoom(baseUrl, familyId, participants, key) {
  const room = await call(baseUrl, `/v1/families/${familyId}/chat/threads`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': key }),
    body: { kind: 'group', title: 'مجموعة الاختبار', participants },
  });
  assert.equal(room.status, 201, JSON.stringify(room.body));
  return room.body.thread.id;
}

function appWith(store, pushSender) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
    pushSender,
  });
}

function registerPath(familyId) {
  return `/v1/families/${familyId}/push/registrations`;
}

test('without an FCM sender, registration answers 503 and writes nothing', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
    openStores.add(store);
    await withServer(appWith(store, null), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'push503');
      const registered = await call(baseUrl, registerPath(h.familyId), {
        method: 'POST',
        headers: authorized('test-co'),
        body: { token: TOKEN_A, platform: 'android', locale: 'ar' },
      });
      assert.equal(registered.status, 503);
      assert.equal(registered.body.error.code, 'push_not_configured');
      const rows = await client.query('SELECT count(*)::int AS n FROM family_push_registrations');
      assert.equal(rows.rows[0].n, 0);
    });
  });
});

test('registration is guardian-only, a token moves to its latest guardian, and removal is owner-only', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
    openStores.add(store);
    await withServer(appWith(store, recordingSender()), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'pushreg');
      const body = { token: TOKEN_A, platform: 'android', locale: 'ar' };

      const first = await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized('test-co'), body });
      assert.equal(first.status, 201, JSON.stringify(first.body));
      assert.equal(first.body.registration.locale, 'ar');
      assert.equal(first.body.registration.platform, 'android');

      const again = await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized('test-co'), body });
      assert.equal(again.status, 200);
      assert.equal(again.body.registration.id, first.body.registration.id);

      // Another guardian signs in on the same handset: the token moves to them.
      const moved = await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized('test-co2'), body: { ...body, locale: 'en' } });
      assert.equal(moved.status, 200);
      const owner = await client.query('SELECT membership_id, locale FROM family_push_registrations WHERE token = $1', [TOKEN_A]);
      assert.equal(owner.rows.length, 1);
      assert.equal(owner.rows[0].membership_id, h.co2);
      assert.equal(owner.rows[0].locale, 'en');

      // The previous owner cannot remove what is now the other guardian's registration.
      const stolen = await call(baseUrl, `${registerPath(h.familyId)}/${moved.body.registration.id}`, {
        method: 'DELETE',
        headers: authorized('test-co'),
      });
      assert.equal(stolen.status, 404);
      const removed = await call(baseUrl, `${registerPath(h.familyId)}/${moved.body.registration.id}`, {
        method: 'DELETE',
        headers: authorized('test-co2'),
      });
      assert.equal(removed.status, 204);
      const gone = await client.query('SELECT count(*)::int AS n FROM family_push_registrations');
      assert.equal(gone.rows[0].n, 0);

      const invalidToken = await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized('test-co'), body: { ...body, token: 'short' } });
      assert.equal(invalidToken.status, 400);
      assert.equal(invalidToken.body.error.code, 'invalid_push_token');
      const extraField = await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized('test-co'), body: { ...body, owner: 'x' } });
      assert.equal(extraField.status, 400);
    });
  });
});

test('a message nudges the other guardians in its room, never the author or an outsider, and carries no text', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
    openStores.add(store);
    const sender = recordingSender();
    await withServer(appWith(store, sender), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'pushnudge');
      for (const [subject, token] of [['test-primary', TOKEN_A], ['test-co', TOKEN_B], ['test-co2', TOKEN_C]]) {
        const registered = await call(baseUrl, registerPath(h.familyId), {
          method: 'POST',
          headers: authorized(subject),
          body: { token, platform: 'android', locale: 'en' },
        });
        assert.equal(registered.status, 201, JSON.stringify(registered.body));
      }
      // co2 is registered but is not in the room: they must not be nudged.
      const room = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'pushnudge-room' }),
        body: { kind: 'direct', participants: [{ kind: 'membership', id: h.co }] },
      });
      assert.equal(room.status, 201, JSON.stringify(room.body));
      const threadId = room.body.thread.id;

      const sent = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${threadId}/messages`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'pushnudge-send-1' }),
        body: { body: MESSAGE_TEXT, clientMessageId: 'client-pushnudge-1' },
      });
      assert.equal(sent.status, 201, JSON.stringify(sent.body));

      await waitFor(() => sender.sent.length >= 1, 'the guardian nudge');
      assert.deepEqual(sender.sent.map((call) => call.token), [TOKEN_B]);
      assert.deepEqual(sender.sent[0].data, { type: 'chat.message', threadId });
      assert.equal(JSON.stringify(sender.sent).includes(MESSAGE_TEXT), false);
      assert.equal(JSON.stringify(sender.sent).includes('أماني'), false);
    });
  });
});

test('a child handset\'s message nudges every guardian in the room', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
    openStores.add(store);
    const sender = recordingSender();
    await withServer(appWith(store, sender), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'pushchild');
      for (const [subject, token] of [['test-primary', TOKEN_A], ['test-co', TOKEN_B]]) {
        const registered = await call(baseUrl, registerPath(h.familyId), {
          method: 'POST',
          headers: authorized(subject),
          body: { token, platform: 'android', locale: 'ar' },
        });
        assert.equal(registered.status, 201);
      }
      const deviceAuth = { authorization: `Device ${h.deviceCredential}` };
      const room = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads`, {
        method: 'POST',
        headers: { ...deviceAuth, 'idempotency-key': 'pushchild-room-0001' },
        body: { kind: 'direct', participants: [{ kind: 'membership', id: h.primary }] },
      });
      assert.equal(room.status, 201, JSON.stringify(room.body));
      const threadId = room.body.thread.id;
      // The direct room has only the primary guardian: the nudge goes to them, not to co.
      const sent = await call(baseUrl, `/v1/devices/${h.deviceId}/chat/threads/${threadId}/messages`, {
        method: 'POST',
        headers: { ...deviceAuth, 'idempotency-key': 'pushchild-send-0001' },
        body: { body: MESSAGE_TEXT, clientMessageId: 'client-pushchild-1' },
      });
      assert.equal(sent.status, 201, JSON.stringify(sent.body));
      await waitFor(() => sender.sent.length >= 1, 'the child message nudge');
      assert.deepEqual(sender.sent.map((call) => call.token), [TOKEN_A]);
      assert.equal(sender.sent[0].locale, 'ar');
      assert.equal(JSON.stringify(sender.sent).includes(MESSAGE_TEXT), false);
    });
  });
});

test('a token FCM reports as unregistered is removed; a transient refusal removes nothing; a replay is not nudged again', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
    openStores.add(store);
    const sender = recordingSender((args) => {
      if (args.token === TOKEN_B) return 'unregistered';
      if (args.token === TOKEN_C) throw new Error('transient');
      return 'sent';
    });
    await withServer(appWith(store, sender), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'pushfail');
      for (const [subject, token] of [['test-primary', TOKEN_A], ['test-co', TOKEN_B], ['test-co2', TOKEN_C]]) {
        await call(baseUrl, registerPath(h.familyId), { method: 'POST', headers: authorized(subject), body: { token, platform: 'android', locale: 'en' } });
      }
      const threadId = await groupRoom(
        baseUrl,
        h.familyId,
        [{ kind: 'membership', id: h.co }, { kind: 'membership', id: h.co2 }],
        'pushfail-room',
      );
      const payload = {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'pushfail-send-1' }),
        body: { body: MESSAGE_TEXT, clientMessageId: 'client-pushfail-1' },
      };
      const sent = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${threadId}/messages`, payload);
      assert.equal(sent.status, 201);

      await waitFor(async () => (await client.query('SELECT count(*)::int AS n FROM family_push_registrations WHERE token = $1', [TOKEN_B])).rows[0].n === 0, 'the unregistered token to be removed');
      await waitFor(() => sender.sent.length >= 2, 'both nudges');
      const remaining = await client.query('SELECT token FROM family_push_registrations ORDER BY token');
      assert.deepEqual(remaining.rows.map((row) => row.token), [TOKEN_A, TOKEN_C].sort());

      // A replay of the same send returns the first result and sends no second nudge.
      const replay = await call(baseUrl, `/v1/families/${h.familyId}/chat/threads/${threadId}/messages`, payload);
      assert.equal(replay.status, 201);
      assert.equal(replay.body.message.id, sent.body.message.id);
      await new Promise((resolve) => setTimeout(resolve, 200));
      assert.equal(sender.sent.length, 2);
    });
  });
});
