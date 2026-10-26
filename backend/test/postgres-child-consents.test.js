// Safety slice 2 — the child-consent journey on real PostgreSQL. Gated by DATABASE_URL
// like every PostgreSQL test; CI runs it in backend_ci.yml.
//
// What it must prove:
//   1. No consent, no collection: `location-fixes` refuses with 403 `consent_required`
//      and stores nothing — for the device credential and for the guardian path alike.
//   2. The handset records its grant (its disclosure act), the fix is then accepted, and
//      the row names the DEVICE as granter.
//   3. A guardian withdraws; the fix is refused again; the ledger answers `withdrawn`
//      (not `none`), and the frozen withdrawal is never overwritten by a later grant.
//   4. A guardian of another family reaches none of this.
//   5. The database itself refuses two active consents for one (child, capability).
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
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
  const name = `familyos_consent_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
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
    // A retry wakeup or sweep still in flight can hold a connection after the store closes;
    // WITH (FORCE) would kill it and surface as an uncaught error in whichever test runs next.
    for (let waited = 0; waited < 10_000; waited += 50) {
      const open = await admin.query(`SELECT count(*)::int AS n FROM pg_stat_activity WHERE datname = $1 AND pid <> pg_backend_pid()`, [name]);
      if (open.rows[0].n === 0) break;
      await new Promise((r) => setTimeout(r, 50));
    }
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

/** A family with its own primary guardian, a child and one paired handset. */
async function seedHousehold(baseUrl, client, tag, guardian = 'test-primary') {
  const created = await call(baseUrl, '/v1/families', {
    method: 'POST',
    headers: authorized(guardian, { 'idempotency-key': `${tag}-family` }),
    body: { displayName: 'عائلة الاختبار' },
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const familyId = created.body.family.id;
  const child = await call(baseUrl, `/v1/families/${familyId}/children`, {
    method: 'POST',
    headers: authorized(guardian, { 'idempotency-key': `${tag}-child` }),
    body: { displayName: 'أماني', ageYears: 11, avatarEmoji: '🦁', themeColor: 'sky' },
  });
  assert.equal(child.status, 201);
  const childId = child.body.child.id;
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
    asDevice: (key) => ({
      authorization: `Device ${deviceCredential}`,
      ...(key ? { 'idempotency-key': key } : {}),
    }),
  };
}

const fixBody = (overrides = {}) => ({
  fixId: randomUUID(),
  acquisition: 'located',
  latitude: 15.3694,
  longitude: 44.191,
  accuracyMeters: 12,
  recordedAt: new Date(Date.now() - 30_000).toISOString(),
  ...overrides,
});

function appWith(store) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });
}

test(
  'no consent, no collection: the fix is refused, then granted, withdrawn, and re-granted — exactly the ledger',
  { skip },
  async () => {
    await withFreshDatabase(async (client) => {
      await migrate(client);
      const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
      openStores.add(store);
      await withServer(appWith(store), async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'consent');

        // 1. Nothing granted yet: the handset's report is refused before it is stored.
        const first = fixBody();
        const refused = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: h.asDevice(`fix-${first.fixId}`),
          body: first,
        });
        assert.equal(refused.status, 403, JSON.stringify(refused.body));
        assert.equal(refused.body.error.code, 'consent_required');
        const storedAfterRefusal = await client.query(
          `SELECT count(*)::int AS n FROM family_child_location_fixes WHERE device_id = $1`,
          [h.deviceId],
        );
        assert.equal(storedAfterRefusal.rows[0].n, 0);

        // The guardian path is refused by the same rule: collection is consent-first,
        // whoever reports.
        const guardianRefused = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'guardian-fix-1' }),
          body: fixBody(),
        });
        assert.equal(guardianRefused.status, 403);
        assert.equal(guardianRefused.body.error.code, 'consent_required');

        // 2. The handset records the disclosure act its screen performed.
        const granted = await call(baseUrl, `/v1/devices/${h.deviceId}/consents`, {
          method: 'POST',
          headers: h.asDevice('grant-1'),
          body: { capability: 'location', textVersion: '2026-10-10' },
        });
        assert.equal(granted.status, 201, JSON.stringify(granted.body));
        assert.equal(granted.body.consent.state, 'granted');
        assert.equal(granted.body.consent.grantedByDeviceId, h.deviceId);
        assert.equal(granted.body.consent.grantedByMembershipId, null);

        // A second grant is refused rather than stacked.
        const stacked = await call(baseUrl, `/v1/devices/${h.deviceId}/consents`, {
          method: 'POST',
          headers: h.asDevice('grant-2'),
          body: { capability: 'location', textVersion: '2026-10-10' },
        });
        assert.equal(stacked.status, 409);
        assert.equal(stacked.body.error.code, 'consent_already_granted');

        // 3. Now the fix is accepted.
        const accepted = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: h.asDevice(`fix-${first.fixId}`),
          body: first,
        });
        assert.equal(accepted.status, 201, JSON.stringify(accepted.body));

        // The handset reads its own sharing state and sees the truth.
        const sharing1 = await call(baseUrl, `/v1/devices/${h.deviceId}/location-sharing`, {
          headers: h.asDevice(),
        });
        assert.equal(sharing1.status, 200);
        assert.equal(sharing1.body.capabilities.location.state, 'granted');

        // 4. The guardian withdraws; the fix is refused again; the ledger says `withdrawn`.
        const withdrawn = await call(baseUrl, `/v1/devices/${h.deviceId}/consents/withdrawal`, {
          method: 'POST',
          headers: authorized('test-primary'),
          body: { capability: 'location' },
        });
        assert.equal(withdrawn.status, 200, JSON.stringify(withdrawn.body));
        assert.equal(withdrawn.body.consent.state, 'withdrawn');

        const refusedAgain = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: h.asDevice(`fix-${randomUUID()}`),
          body: fixBody(),
        });
        assert.equal(refusedAgain.status, 403);
        assert.equal(refusedAgain.body.error.code, 'consent_required');

        const sharing2 = await call(baseUrl, `/v1/devices/${h.deviceId}/location-sharing`, {
          headers: h.asDevice(),
        });
        assert.equal(sharing2.body.capabilities.location.state, 'withdrawn');
        assert.notEqual(sharing2.body.capabilities.location.withdrawnAt, null);

        // A second "no" answers the same "no" instead of manufacturing an error.
        const again = await call(baseUrl, `/v1/devices/${h.deviceId}/consents/withdrawal`, {
          method: 'POST',
          headers: authorized('test-primary'),
          body: { capability: 'location' },
        });
        assert.equal(again.status, 200);
        assert.equal(again.body.consent.state, 'withdrawn');

        // 5. Re-grant is a new row; the frozen withdrawal keeps its moment.
        const regranted = await call(baseUrl, `/v1/devices/${h.deviceId}/consents`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'grant-3' }),
          body: { capability: 'location', textVersion: '2026-10-11' },
        });
        assert.equal(regranted.status, 201);
        assert.equal(regranted.body.consent.state, 'granted');
        assert.equal(regranted.body.consent.grantedByMembershipId != null, true);
        const history = await client.query(
          `SELECT state_count, frozen FROM (
             SELECT count(*)::int AS state_count,
                    count(*) FILTER (WHERE withdrawn_at IS NOT NULL)::int AS frozen
             FROM family_child_consents WHERE child_id = $1 AND capability = 'location'
           ) AS t`,
          [h.childId],
        );
        assert.equal(history.rows[0].state_count, 2);
        assert.equal(history.rows[0].frozen, 1);

        // And the fix is accepted once more — collection follows the ledger, exactly.
        const finalFix = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: h.asDevice(`fix-${randomUUID()}`),
          body: fixBody(),
        });
        assert.equal(finalFix.status, 201);
      });
    });
  },
);

test(
  'a guardian of another family records nothing here and reads nothing here',
  { skip },
  async () => {
    await withFreshDatabase(async (client) => {
      await migrate(client);
      const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
      openStores.add(store);
      await withServer(appWith(store), async (baseUrl) => {
        const mine = await seedHousehold(baseUrl, client, 'consent-mine');
        // A DIFFERENT guardian owns the second family: two households, two primaries.
        const theirs = await seedHousehold(baseUrl, client, 'consent-theirs', 'test-rival');

        const grant = await call(baseUrl, `/v1/devices/${theirs.deviceId}/consents`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'foreign-grant' }),
          body: { capability: 'location', textVersion: '2026-10-10' },
        });
        assert.equal(grant.status, 403, JSON.stringify(grant.body));

        const read = await call(baseUrl, `/v1/devices/${theirs.deviceId}/location-sharing`, {
          headers: authorized('test-primary'),
        });
        assert.equal(read.status, 403);

        // And the other way round: the rival guardian reaches nothing in my family.
        const reverse = await call(baseUrl, `/v1/devices/${mine.deviceId}/location-sharing`, {
          headers: authorized('test-rival'),
        });
        assert.equal(reverse.status, 403);

        // A handset cannot speak for a device it does not hold.
        const forged = await call(baseUrl, `/v1/devices/${theirs.deviceId}/location-sharing`, {
          headers: mine.asDevice(),
        });
        assert.equal(forged.status, 401);
      });
    });
  },
);

test(
  'the database itself refuses two active consents for one capability',
  { skip },
  async () => {
    await withFreshDatabase(async (client) => {
      await migrate(client);
      const store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, client.database) });
      openStores.add(store);
      await withServer(appWith(store), async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'consent-unique');
        const granted = await call(baseUrl, `/v1/devices/${h.deviceId}/consents`, {
          method: 'POST',
          headers: h.asDevice('grant-unique'),
          body: { capability: 'location', textVersion: '2026-10-10' },
        });
        assert.equal(granted.status, 201);

        // The partial unique index is the last word, whatever any code path believes.
        await assert.rejects(
          () =>
            client.query(
              `INSERT INTO family_child_consents
                 (family_id, child_id, capability, text_version, granted_by_device_id)
               VALUES ($1, $2, 'location', '2026-10-10', $3)`,
              [h.familyId, h.childId, h.deviceId],
            ),
          (error) => error.code === '23505',
        );
      });
    });
  },
);
