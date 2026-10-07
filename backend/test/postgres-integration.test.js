// Real PostgreSQL integration — the Environment Gate.
//
// Written on 2026-10-06, after an audit found that migrations 001-101 had never been
// executed anywhere: the schema tests used a fake client, so they verified the text of
// the SQL and the checksums of the files, never the statements themselves. A migration
// that has never run is a claim, not an artifact.
//
// This file runs the real thing against a real server. It is skipped when DATABASE_URL
// is absent so the ordinary suite stays fast and dependency-free, and it runs in CI,
// where the workflow provides PostgreSQL. That is the difference the gate is about:
// written once and executed never, versus executed on every push.
//
// What it proves, in order of how much it would hurt to be wrong:
//   1. Every migration applies to an empty database, in order, with its checksum intact.
//   2. The revocation guard holds under a real UPDATE, including the race.
//   3. The provenance constraint actually rejects a reason the vocabulary forbids.
//   4. The derived device view is computed from real rows the way the tests assume.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { createApp } from '../src/app.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { deviceRevocationFor } from '../src/device-revocation.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';
import { TestAuthVerifier } from './memory-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';

/**
 * A database of its own per test, so tests can run concurrently and a failure leaves no
 * half-migrated state behind for the next one.
 */
async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_gate_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
  try {
    await admin.query(`CREATE DATABASE ${name}`);
    const client = new Client({ connectionString: withDatabase(DATABASE_URL, name) });
    await client.connect();
    try {
      await run(client);
    } finally {
      await client.end();
    }
  } finally {
    await admin.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
    await admin.end();
  }
}

function withDatabase(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

async function migrate(client) {
  const files = (await readdir(migrationDirectory)).filter((file) => file.endsWith('.sql')).sort();
  assert.deepEqual(
    files,
    FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name),
    'the manifest and the migration directory must describe the same set',
  );
  await applyMigrations({
    client,
    migrations: FOUNDATION_SCHEMA_MIGRATIONS,
    readVerifiedMigration: async (migration) => {
      const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
      const checksum = createHash('sha256').update(sql).digest('hex');
      assert.equal(checksum, migration.sha256, `${migration.name} must match its recorded checksum`);
      return sql;
    },
  });
}

/** Creates an account, a family with a primary guardian and a child - and no device yet. */
async function seedFamily(client) {
  const account = await client.query(
    `INSERT INTO accounts (id, oidc_subject) VALUES (gen_random_uuid(), $1) RETURNING id`,
    ['gate-primary'],
  );
  const family = await client.query(
    `INSERT INTO families (id, display_name, status) VALUES (gen_random_uuid(), 'Gate family', 'active')
     RETURNING id`,
  );
  // target_subject is required by the schema, and account_id is what the server's own
  // membership query joins on. Both are set here for the same reason the real invitation
  // flow sets them: the subject identifies the person, the account is how they authenticate.
  const membership = await client.query(
    `INSERT INTO family_memberships (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES (gen_random_uuid(), $1, $2, $3, 'primary_guardian', 'active', NOW()) RETURNING id`,
    [family.rows[0].id, account.rows[0].id, 'gate-primary'],
  );
  await client.query(`UPDATE families SET primary_membership_id = $1 WHERE id = $2`, [
    membership.rows[0].id,
    family.rows[0].id,
  ]);
  const child = await client.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES (gen_random_uuid(), $1, 'Amani', 9) RETURNING id`,
    [family.rows[0].id],
  );
  return {
    familyId: family.rows[0].id,
    childId: child.rows[0].id,
    membershipId: membership.rows[0].id,
  };
}

/** The same family, with one device already holding a credential. */
async function seedPairedDevice(client) {
  const ids = await seedFamily(client);
  const device = await client.query(
    // A credential and its issue time travel together: migration 008 refuses a device that
    // holds one without the other. The server's own claim path sets both; so does this seed.
    `INSERT INTO family_child_devices
       (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
     VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
     RETURNING id, family_id, child_id`,
    [ids.familyId, ids.childId, 'a'.repeat(64)],
  );
  return { ...ids, deviceId: device.rows[0].id };
}

function revokeOn(store, ids) {
  const revoke = deviceRevocationFor(store);
  return revoke({
    principal: { subject: 'gate-primary' },
    familyId: ids.familyId,
    childId: ids.childId,
    deviceId: ids.deviceId,
    reasonCode: 'stolen',
    idempotencyKey: 'gate-revoke-1',
    // The schema requires a real sha256 digest here, not a label. The server derives it
    // from the request fingerprint; this is the same shape.
    requestHash: 'b'.repeat(64),
    correlationId: '11111111-2222-4333-8444-555555555555',
  });
}

/**
 * Issues a pairing code the way the guardian's screen does, and returns the one thing that
 * code is good for: the value the handset will claim with.
 */
async function issuePairing(store, { ids, principal, idempotencyKey, requestHash, correlationId }) {
  const { pairing } = await store.createDevicePairing({
    principal,
    familyId: ids.familyId,
    childId: ids.childId,
    deviceLabel: 'Amani Android',
    idempotencyKey,
    requestHash,
    correlationId,
  });
  return pairing.pairingCode;
}

/** Cuts one specific device off, so a journey test can hold two devices at once. */
function revokeWith(store, { ids, deviceId, reasonCode, idempotencyKey, requestHash, correlationId }) {
  const revoke = deviceRevocationFor(store);
  return revoke({
    principal: { subject: 'gate-primary' },
    familyId: ids.familyId,
    childId: ids.childId,
    deviceId,
    reasonCode,
    idempotencyKey,
    requestHash,
    correlationId,
  });
}

test('every migration applies to an empty database', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);

    const applied = await client.query('SELECT name FROM schema_migrations ORDER BY name');
    assert.deepEqual(
      applied.rows.map((row) => row.name),
      FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name),
    );

    // The tables the product actually depends on, by name. A migration that silently
    // does nothing would satisfy the recorded row above and fail here.
    const tables = await client.query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'`,
    );
    const present = new Set(tables.rows.map((row) => row.table_name));
    for (const table of [
      'families',
      'family_memberships',
      'family_children',
      'family_child_devices',
      'family_device_pairings',
      'family_audit_events',
      'outbox_events',
      'ai_events',
      'idempotency_records',
    ]) {
      assert.ok(present.has(table), `${table} must exist after migrating`);
    }
  });
});

test('readiness agrees only when the complete migration set is applied', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    const url = withDatabase(DATABASE_URL, client.database);
    const store = new PostgresFoundationStore({ connectionString: url });
    try {
      // The store reads schema_migrations itself. An empty database must not claim to be
      // ready, because a server that starts against an unmigrated schema fails later and
      // much less clearly.
      const before = await store.health();
      assert.equal(before.available, false, 'an empty database must not report ready');

      await migrate(client);

      const after = await store.health();
      assert.equal(after.available, true, 'a fully migrated database must report ready');
    } finally {
      await store.close();
    }
  });
});

test('a real revocation commits, and the device stops being trusted', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedPairedDevice(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    try {
      const result = await revokeOn(store, ids);
      assert.equal(result.device.health.state, 'revoked');
      assert.equal(result.device.credentialState, 'revoked');

      const row = await client.query(
        `SELECT credential_revoked_at, revoked_by_membership_id, revocation_reason, version
           FROM family_child_devices WHERE id = $1`,
        [ids.deviceId],
      );
      // The database's clock wrote this, not the process. If the server had invented the
      // timestamp, a revocation could predate the telemetry it is meant to stop.
      assert.ok(row.rows[0].credential_revoked_at instanceof Date);
      assert.equal(row.rows[0].revoked_by_membership_id, ids.membershipId);
      assert.equal(row.rows[0].revocation_reason, 'stolen');
      assert.equal(row.rows[0].version, 2);

      // The audit record, the outbox event and the fact must exist, because they were
      // written in the same transaction the update committed in.
      const audit = await client.query(
        `SELECT count(*)::int AS n FROM family_audit_events WHERE subject_id = $1`,
        [ids.deviceId],
      );
      assert.equal(audit.rows[0].n, 1);
      const outbox = await client.query(`SELECT count(*)::int AS n FROM outbox_events`);
      assert.equal(outbox.rows[0].n, 1);
      const fact = await client.query(
        `SELECT event_type, device_id FROM ai_events WHERE device_id = $1`,
        [ids.deviceId],
      );
      assert.equal(fact.rows[0]?.event_type, 'device.revoked');
    } finally {
      await store.close();
    }
  });
});

test('the guard in the WHERE clause survives two real concurrent revocations', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedPairedDevice(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    try {
      const revoke = deviceRevocationFor(store);
      const call = (key) =>
        revoke({
          principal: { subject: 'gate-primary' },
          familyId: ids.familyId,
          childId: ids.childId,
          deviceId: ids.deviceId,
          reasonCode: null,
          idempotencyKey: key,
          requestHash: key === 'race-a' ? 'c'.repeat(64) : 'd'.repeat(64),
          correlationId: '11111111-2222-4333-8444-555555555555',
        });

      // Two genuine simultaneous instructions. Exactly one may win, and the loser must
      // be told so rather than silently erasing who cut the device off.
      const outcomes = await Promise.allSettled([call('race-a'), call('race-b')]);
      const fulfilled = outcomes.filter((outcome) => outcome.status === 'fulfilled');
      const rejected = outcomes.filter((outcome) => outcome.status === 'rejected');
      assert.equal(fulfilled.length, 1, 'exactly one revocation may succeed');
      assert.equal(rejected.length, 1, 'the other must be refused');
      assert.equal(rejected[0].reason.status, 409);
      assert.equal(rejected[0].reason.code, 'device_already_revoked');

      const row = await client.query(
        `SELECT count(*)::int AS n FROM family_audit_events WHERE subject_id = $1`,
        [ids.deviceId],
      );
      assert.equal(row.rows[0].n, 1, 'one instruction produced one audit record');
    } finally {
      await store.close();
    }
  });
});

test('the provenance constraint rejects a reason the vocabulary forbids', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedPairedDevice(client);

    // The database is the last line: even a caller that bypassed validation cannot write
    // a reason outside the closed set. The revoker is supplied so that provenance is
    // satisfied and the vocabulary is what actually refuses the write.
    await assert.rejects(
      () =>
        client.query(
          `UPDATE family_child_devices
              SET credential_revoked_at = NOW(), revoked_by_membership_id = $2,
                  revocation_reason = 'because_i_said_so'
            WHERE id = $1`,
          [ids.deviceId, ids.membershipId],
        ),
      /revocation_reason_valid/,
      'the closed vocabulary must be enforced by the database, not only by validation',
    );

    // Provenance is all-or-nothing in both directions: a revocation with no revoker is
    // impossible, and so is a revoker with no revocation. This is what keeps "who cut
    // this device off, and when" answerable for the life of the row.
    await assert.rejects(
      () =>
        client.query(`UPDATE family_child_devices SET revoked_by_membership_id = $2 WHERE id = $1`, [
          ids.deviceId,
          ids.membershipId,
        ]),
      /revocation_provenance_valid/,
    );

    await assert.rejects(
      () =>
        client.query(`UPDATE family_child_devices SET credential_revoked_at = NOW() WHERE id = $1`, [
          ids.deviceId,
        ]),
      /revocation_provenance_valid/,
    );
  });
});

test('the migrated schema enforces the device rules the server relies on', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);

    // A device row with no family must be impossible, and a half-written telemetry
    // reading must be impossible: the all-or-nothing rule from migration 007.
    await assert.rejects(
      () =>
        client.query(
          `INSERT INTO family_child_devices (id, family_id, child_id, device_label, battery_level)
           VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'Orphan', 50)`,
        ),
      /foreign key|violates/i,
    );
  });
});

test('the guardian read surface derives the lifecycle from the real row', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedPairedDevice(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    try {
      const principal = { subject: 'gate-primary' };

      // The seed writes a hash, as the schema requires. Telemetry presents the raw
      // credential, so this test sets the one the hash belongs to rather than a credential
      // that could never have produced it. Real pairing does this in claimDevicePairing.
      const RAW_CREDENTIAL = 'gate-device-credential-0000000001';
      await client.query(`UPDATE family_child_devices SET credential_hash = $2 WHERE id = $1`, [
        ids.deviceId,
        createHash('sha256').update(RAW_CREDENTIAL).digest('hex'),
      ]);

      // Before anything reports: a device that holds a credential nobody has used yet. The
      // honest description is that it never started, not that its protection is working.
      const firstRead = await store.listFamilyDevices({ principal, familyId: ids.familyId });
      assert.equal(firstRead.devices.length, 1);
      const [waiting] = firstRead.devices;
      assert.equal(waiting.credentialState, 'active');
      assert.equal(waiting.health.state, 'never_reported');
      assert.equal(waiting.health.reasonCode, 'never_reported');
      assert.equal(waiting.health.needsAttention, true);
      assert.ok(
        waiting.capabilities.every((capability) => capability.state === 'unavailable'),
        'a device that never reported claimed a capability',
      );

      // One real telemetry write through the store the server uses, then read again. The
      // columns the derivation needs must actually be selected, which is the failure this
      // test exists to catch: a correct derivation fed incomplete rows.
      const telemetry = await store.ingestDeviceTelemetry({
        deviceId: ids.deviceId,
        deviceCredential: RAW_CREDENTIAL,
        principal: null,
        batteryLevel: 58,
        batteryStatus: 'unplugged',
        locationLat: 15.3694,
        locationLng: 44.191,
        locationLabel: 'البيت',
        correlationId: '22222222-3333-4444-8555-666666666666',
      });
      assert.equal(telemetry.device.health.state, 'active');

      const [reporting] = (await store.listFamilyDevices({ principal, familyId: ids.familyId })).devices;
      assert.equal(reporting.health.state, 'active');
      assert.equal(reporting.health.reasonCode, 'reporting_now');
      assert.equal(reporting.health.needsAttention, false);
      assert.equal(reporting.version, 2);
      const capabilities = Object.fromEntries(
        reporting.capabilities.map((entry) => [entry.id, entry]),
      );
      assert.equal(capabilities.telemetry.state, 'available');
      assert.equal(capabilities.location.state, 'available');
      assert.equal(capabilities.location.reasonCode, 'location_reported');

      // Revoke, then read the same surface a guardian would open afterwards. The write
      // surface and the read surface must not disagree about a lost handset.
      await revokeOn(store, ids);
      const [revoked] = (await store.listFamilyDevices({ principal, familyId: ids.familyId })).devices;
      assert.equal(revoked.credentialState, 'revoked');
      assert.equal(revoked.health.state, 'revoked');
      assert.equal(revoked.health.needsAttention, true);
      assert.ok(
        revoked.capabilities.every((capability) => capability.reasonCode === 'device_revoked'),
        'a revoked device reported a capability it cannot have',
      );
      // The row's own version moved with the revocation, so a client can tell that the
      // record it is holding is the record it just changed.
      assert.equal(revoked.version, 3);
    } finally {
      await store.close();
    }
  });
});

test('a cut-off device can be replaced, and what was cut off stays cut off', { skip }, async () => {
  // The journey in the parent's words: the handset is gone, cut it off, then protect the
  // child again. The server half of the card's promise is that the second half exists.
  //
  // Two rules are under test, and getting either wrong costs the family something real:
  //
  //   1. Revocation must not brick the child. If the family could never pair a replacement,
  //      a guardian facing a lost phone would have to choose between an unprotected child
  //      and a permanently dead record.
  //   2. Revocation must not come back to life. The credential that was cut off stays dead
  //      across the replacement, forever, and the replacement walks the same pairing
  //      journey - there is no "known device" shortcut that a holder of the old handset
  //      could step through.
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedFamily(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    const principal = { subject: 'gate-primary' };
    const correlationId = '33333333-4444-4555-8666-777777777777';
    const report = (deviceId, deviceCredential) =>
      store.ingestDeviceTelemetry({
        deviceId,
        deviceCredential,
        principal: null,
        batteryLevel: 64,
        batteryStatus: 'unplugged',
        locationLat: 15.3694,
        locationLng: 44.191,
        locationLabel: 'البيت',
        correlationId,
      });
    try {
      // The first pairing: a code issued by the guardian, then claimed by the handset.
      const firstCode = await issuePairing(store, {
        ids,
        principal,
        idempotencyKey: 'pair-1',
        requestHash: 'e'.repeat(64),
        correlationId,
      });
      const first = await store.claimDevicePairing({ pairingCode: firstCode, correlationId });
      assert.equal(first.device.health.state, 'never_reported');
      assert.equal((await report(first.device.id, first.deviceCredential)).device.health.state, 'active');

      // The handset is lost, and the guardian cuts it off.
      const revoked = await revokeWith(store, {
        ids,
        deviceId: first.device.id,
        reasonCode: 'lost',
        idempotencyKey: 'revoke-the-lost-one',
        requestHash: 'f'.repeat(64),
        correlationId,
      });
      assert.equal(revoked.device.health.state, 'revoked');

      // A cut-off credential cannot report, and the refusal is the same one whether the
      // server compares hashes or reads the revocation - both paths lead to 401.
      await assert.rejects(
        () => report(first.device.id, first.deviceCredential),
        (error) => error.status === 401 && error.code === 'invalid_device_credential',
        'a revoked credential was accepted for telemetry',
      );

      // The used code is spent, so the replacement cannot be a replay of the first journey:
      // a second device has to be paired by a second code the guardian issues.
      await assert.rejects(
        () => store.claimDevicePairing({ pairingCode: firstCode, correlationId }),
        (error) => error.status === 400 && error.code === 'pairing_not_claimable',
        'a claimed pairing code was claimable a second time',
      );

      // Same journey, one step at a time. No shortcut exists, and this is the honest cost
      // of that: the guardian issues a fresh code, and the new handset claims it.
      const secondCode = await issuePairing(store, {
        ids,
        principal,
        idempotencyKey: 'pair-2',
        requestHash: '1'.repeat(64),
        correlationId,
      });
      const second = await store.claimDevicePairing({ pairingCode: secondCode, correlationId });
      assert.notEqual(second.device.id, first.device.id, 'the replacement must be its own device');
      assert.equal(second.device.health.state, 'never_reported');
      assert.equal(
        (await report(second.device.id, second.deviceCredential)).device.health.state,
        'active',
        'the replacement device could not report, so the child is still unprotected',
      );

      // Rule 2. The replacement did not resurrect the old credential: the handset that was
      // reported lost is still refused with its own credential, next to a working one.
      await assert.rejects(
        () => report(first.device.id, first.deviceCredential),
        (error) => error.status === 401 && error.code === 'invalid_device_credential',
        'pairing a replacement brought the cut-off credential back to life',
      );

      // What the guardian sees afterwards: two records, one of them honestly marked as cut
      // off, and the child protected again by the other.
      const { devices } = await store.listFamilyDevices({ principal, familyId: ids.familyId });
      assert.equal(devices.length, 2);
      const byId = Object.fromEntries(devices.map((device) => [device.id, device]));
      assert.equal(byId[first.device.id].health.state, 'revoked');
      assert.equal(byId[first.device.id].credentialState, 'revoked');
      assert.equal(byId[second.device.id].health.state, 'active');
      assert.equal(byId[second.device.id].health.needsAttention, false);

      // The database's own account of the two devices, so this test cannot be satisfied by
      // a view layer that merely says the right thing.
      const rows = await client.query(
        `SELECT id, credential_hash, credential_revoked_at, revoked_by_membership_id,
                revocation_reason, version
           FROM family_child_devices
          ORDER BY linked_at ASC, id ASC`,
      );
      assert.equal(rows.rowCount, 2);
      const [oldRow, newRow] = rows.rows;
      assert.equal(oldRow.id, first.device.id);
      assert.ok(oldRow.credential_revoked_at instanceof Date);
      assert.equal(oldRow.revoked_by_membership_id, ids.membershipId);
      assert.equal(oldRow.revocation_reason, 'lost');
      assert.equal(newRow.id, second.device.id);
      assert.equal(newRow.credential_revoked_at, null, 'the replacement was born revoked');
      assert.notEqual(
        newRow.credential_hash,
        oldRow.credential_hash,
        'the replacement reused the credential of the device that was cut off',
      );
    } finally {
      await store.close();
    }
  });
});

/**
 * The invitation lifecycle, end to end through the live HTTP surface over real PostgreSQL.
 *
 * `postgres-integration` proved the environment and the schema. This proves the journey a
 * family actually walks, through the routes the server really mounts: the guardian invites,
 * the invited account accepts, the roster tells each caller which row is theirs, and the
 * guardian revokes. Nothing is stubbed except identity - `TestAuthVerifier` maps a test
 * bearer token to a subject, which is the one thing a test cannot obtain from a real
 * identity provider.
 *
 * The two rules worth stating, because both are places a weaker system lies:
 *   * An invitation is not a membership. Until it is accepted, the invited account is
 *     refused the roster - the door is not opened by an offer.
 *   * A revoked membership loses access immediately, and the roster of the family it left
 *     is no longer its business.
 */
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

async function jsonRequest(baseUrl, path, { method = 'GET', headers = {}, body } = {}) {
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
  return { status: response.status, body: text.length > 0 ? JSON.parse(text) : null };
}

test('an invitation is offered, accepted, recognised as self, and revoked', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        // 1. The guardian creates the family. The response already carries the primary
        //    membership, created in the same transaction.
        const created = await jsonRequest(baseUrl, '/v1/families', {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'journey-family' }),
          body: { displayName: 'عائلة البوابة' },
        });
        assert.equal(created.status, 201);
        const familyId = created.body.family.id;
        assert.equal(created.body.family.members.length, 1);
        assert.equal(created.body.family.members[0].role, 'primary_guardian');

        // 2. Invite a co-guardian. Role assignment happens here: the invitation carries the
        //    role the member will hold once accepted.
        const invite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'journey-invite' }),
          body: { role: 'co_guardian', targetSubject: 'test-co' },
        });
        assert.equal(invite.status, 201);
        const membershipId = invite.body.membership.id;
        assert.equal(invite.body.membership.status, 'invited');
        assert.equal(invite.body.membership.role, 'co_guardian');

        // 3. The same request replayed with the same key returns the same membership and,
        //    in the database, still exactly one invitation. That is the idempotency guard
        //    doing its job rather than a second row nobody noticed.
        const replayed = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'journey-invite' }),
          body: { role: 'co_guardian', targetSubject: 'test-co' },
        });
        assert.ok([200, 201].includes(replayed.status), `replay answered ${replayed.status}`);
        assert.equal(replayed.body.membership.id, membershipId);
        const invitationRows = await client.query(
          `SELECT count(*)::int AS n FROM family_memberships WHERE family_id = $1 AND status = 'invited'`,
          [familyId],
        );
        assert.equal(invitationRows.rows[0].n, 1, 'a replayed invitation created a second row');

        // 4. The roster, as the guardian reads it: the guardian's own row is marked as
        //    theirs, the invitation is visible and is not.
        const rosterAsGuardian = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          headers: authorized('test-primary'),
        });
        assert.equal(rosterAsGuardian.status, 200);
        const guardianRows = rosterAsGuardian.body.memberships;
        assert.equal(guardianRows.length, 2);
        const guardianSelf = guardianRows.filter((membership) => membership.isSelf);
        assert.equal(guardianSelf.length, 1, 'exactly one row may be the caller');
        assert.equal(guardianSelf[0].role, 'primary_guardian');
        const pending = guardianRows.find((membership) => membership.id === membershipId);
        assert.equal(pending.status, 'invited');
        assert.equal(pending.isSelf, false);

        // 5. An invitation is not a membership: before accepting, the invited account has
        //    no access to the family it was invited to.
        const rosterAsInvitee = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          headers: authorized('test-co'),
        });
        assert.equal(rosterAsInvitee.status, 403);

        // 6. Only the invited account may accept. A stranger holding the membership id is
        //    refused, and the refusal names that specific reason.
        const stolenAcceptance = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${membershipId}/accept`,
          {
            method: 'POST',
            headers: authorized('test-stranger', { 'idempotency-key': 'journey-steal' }),
          },
        );
        assert.equal(stolenAcceptance.status, 403);
        assert.equal(stolenAcceptance.body.error.code, 'membership_acceptance_denied');

        // 7. The invited account accepts: access is granted.
        const accepted = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${membershipId}/accept`,
          {
            method: 'POST',
            headers: authorized('test-co', { 'idempotency-key': 'journey-accept' }),
          },
        );
        assert.equal(accepted.status, 200);
        assert.equal(accepted.body.membership.status, 'active');
        assert.equal(accepted.body.membership.role, 'co_guardian');

        // 8. Now the roster is theirs to read, and their own row is the one marked as self.
        const rosterAsMember = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          headers: authorized('test-co'),
        });
        assert.equal(rosterAsMember.status, 200);
        const coRows = rosterAsMember.body.memberships.filter((membership) => membership.isSelf);
        assert.equal(coRows.length, 1);
        assert.equal(coRows[0].id, membershipId);

        // 9. Revocation, with its reason. The guardian cuts the membership off.
        const revoked = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${membershipId}/revoke`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'journey-revoke' }),
            body: { reasonCode: 'member_left' },
          },
        );
        // The server's own vocabulary, which is finer than "revoked": an ACTIVE member who
        // leaves is `removed`, and only an invitation that never became a membership is
        // `revoked`. Step 11 below covers the other branch, so both are asserted.
        assert.equal(revoked.status, 200);
        assert.equal(revoked.body.membership.status, 'removed');

        // 10. Access is gone with it. The same account that read the roster a moment ago is
        //     refused now - which is the whole point of revoking rather than hiding a row.
        const rosterAfterRevocation = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          headers: authorized('test-co'),
        });
        assert.equal(rosterAfterRevocation.status, 403);

        // 11. The database's own account of the journey: one row, revoked, with its reason
        //     recorded and its version advanced.
        const finalRow = await client.query(
          `SELECT role, status, status_reason_code, version, joined_at, status_changed_at
             FROM family_memberships WHERE id = $1`,
          [membershipId],
        );
        assert.equal(finalRow.rows[0].status, 'removed');
        assert.equal(finalRow.rows[0].status_reason_code, 'member_left');
        assert.ok(finalRow.rows[0].version >= 3, 'invited, accepted and removed are three writes');
        assert.ok(finalRow.rows[0].joined_at instanceof Date, 'acceptance never recorded its time');

        // 11.b The other branch of cancellation: an invitation nobody accepted yet is
        //      revoked rather than removed, and it never opens a door on the way out.
        const secondInvite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'journey-invite-2' }),
          body: { role: 'co_guardian', targetSubject: 'test-guardian' },
        });
        assert.equal(secondInvite.status, 201);
        const cancelled = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${secondInvite.body.membership.id}/revoke`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'journey-cancel' }),
            body: { reasonCode: 'invitation_withdrawn' },
          },
        );
        assert.equal(cancelled.status, 200);
        assert.equal(cancelled.body.membership.status, 'revoked');
        const cancelledRow = await client.query(
          `SELECT status, status_reason_code FROM family_memberships WHERE id = $1`,
          [secondInvite.body.membership.id],
        );
        assert.deepEqual(cancelledRow.rows[0], {
          status: 'revoked',
          status_reason_code: 'invitation_withdrawn',
        });

        // 12. And the audit trail: one event per membership change, written in the same
        //     transaction as the change itself.
        const audit = await client.query(
          `SELECT event_type FROM family_audit_events
            WHERE family_id = $1 AND subject_type = 'membership'
            ORDER BY occurred_at ASC, id ASC`,
          [familyId],
        );
        assert.deepEqual(
          audit.rows.map((row) => row.event_type),
          [
            'family.membership_invited',
            'family.membership_accepted',
            'family.membership_removed',
            'family.membership_invited',
            'family.membership_invitation_revoked',
          ],
        );
      });
    } finally {
      await store.close();
    }
  });
});
/**
 * W3 on real PostgreSQL: a zone is drawn, a device reports, and the server decides.
 *
 * This is the Environment Gate for the location surface. What it proves, in the order that
 * would hurt most to be wrong:
 *
 *   1. A crossing is judged by the server against the zone the child is assigned to, and
 *      the crossing carries the shape version it was judged against.
 *   2. The FIRST sighting of a state is recorded as a baseline and announces nothing -
 *      "we had never looked before" is not "she just arrived".
 *   3. A replay produces no second row and no second alert; a report that arrives late is
 *      kept in the trail and never evaluated, so history cannot be replayed backwards.
 *   4. Every member of the family reads the SAME picture, a child included, which is what
 *      makes the no-covert-tracking promise checkable rather than a slogan.
 *   5. Retention bounds the trail and never deletes the sample a crossing points at.
 */
test('a zone is drawn, a device reports, and the boundary crossing becomes a recorded fact', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        // 1. A family, a child, and the child's OWN account, invited and accepted through
        //    the real endpoints - a membership inserted by hand would not prove the child
        //    can reach this surface at all.
        const created = await jsonRequest(baseUrl, '/v1/families', {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-family' }),
          body: { displayName: 'عائلة الموقع' },
        });
        assert.equal(created.status, 201);
        const familyId = created.body.family.id;

        const children = await jsonRequest(baseUrl, `/v1/families/${familyId}/children`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-child' }),
          body: { displayName: 'أماني', ageYears: 9, avatarEmoji: '🦁', themeColor: 'sky' },
        });
        assert.equal(children.status, 201);
        const childId = children.body.child.id;

        const invite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-invite-child' }),
          body: { role: 'child', targetSubject: 'test-child' },
        });
        assert.equal(invite.status, 201);
        const accepted = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${invite.body.membership.id}/accept`,
          {
            method: 'POST',
            headers: authorized('test-child', { 'idempotency-key': 'w3-accept-child' }),
          },
        );
        assert.equal(accepted.status, 200);

        const deviceCredential = 'w3-device-credential-value-000000000001';
        const device = await client.query(
          `INSERT INTO family_child_devices
             (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
           VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
           RETURNING id`,
          [familyId, childId, createHash('sha256').update(deviceCredential).digest('hex')],
        );
        const deviceId = device.rows[0].id;
        const deviceAuth = { authorization: `Device ${deviceCredential}` };

        const now = Date.now();
        const at = (offsetMs) => new Date(now + offsetMs).toISOString();
        const minute = 60 * 1000;
        const postFix = (fixId, body, key, offsetMs) =>
          jsonRequest(baseUrl, `/v1/devices/${deviceId}/location-fixes`, {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': key },
            body: { fixId, recordedAt: at(offsetMs), accuracyMeters: 18, ...body },
          });

        // 2. A boundary the child cannot see is not a boundary this product ships.
        const emptyZones = await jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones`, {
          headers: authorized('test-child'),
        });
        assert.equal(emptyZones.status, 200);
        assert.deepEqual(emptyZones.body.zones, []);

        const home = { latitude: 15.3694, longitude: 44.191 };
        const zone = await jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-zone-home' }),
          body: {
            name: 'البيت',
            emoji: '🏠',
            geometry: { kind: 'CIRCLE', center: home, radiusMeters: 150 },
            childIds: [childId],
          },
        });
        assert.equal(zone.status, 201);
        assert.equal(zone.body.zone.version, 1);
        assert.deepEqual(zone.body.zone.childIds, [childId]);
        assert.equal(zone.body.zone.geometry.kind, 'CIRCLE');
        const zoneId = zone.body.zone.id;

        const zoneReplay = await jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-zone-home' }),
          body: {
            name: 'البيت',
            emoji: '🏠',
            geometry: { kind: 'CIRCLE', center: home, radiusMeters: 150 },
            childIds: [childId],
          },
        });
        assert.ok([200, 201].includes(zoneReplay.status));
        assert.equal(zoneReplay.body.zone.id, zoneId);
        const zoneRows = await client.query(
          `SELECT count(*)::int AS n FROM family_safe_zones WHERE family_id = $1`,
          [familyId],
        );
        assert.equal(zoneRows.rows[0].n, 1, 'a replayed zone created a second boundary');

        // A zone assigned to nobody reads like protection and evaluates like nothing.
        const unassigned = await jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-zone-nobody' }),
          body: {
            name: 'مكان بلا أحد',
            geometry: { kind: 'CIRCLE', center: home, radiusMeters: 200 },
            childIds: [],
          },
        });
        assert.equal(unassigned.status, 400);

        // 3. Ten minutes ago: far from the zone. Stored, judged, and nothing crossed.
        const farAway = await postFix(
          '11111111-1111-4111-8111-111111111111',
          { acquisition: 'located', latitude: 15.5, longitude: 44.3 },
          'w3-fix-1',
          -10 * minute,
        );
        assert.equal(farAway.status, 201);
        assert.equal(farAway.body.evaluated, true);
        assert.deepEqual(farAway.body.crossings, []);
        assert.equal(farAway.body.replayed, false);

        // 4. Nine minutes ago: the first sighting INSIDE. A baseline: recorded, silent.
        const arrives = await postFix(
          '22222222-2222-4222-8222-222222222222',
          { acquisition: 'located', latitude: home.latitude, longitude: home.longitude },
          'w3-fix-2',
          -9 * minute,
        );
        assert.equal(arrives.status, 201);
        assert.deepEqual(arrives.body.crossings, [
          { zoneId, kind: 'ENTER', baseline: true, notified: false, zoneVersion: 1 },
        ]);
        const baselineOutbox = await client.query(
          `SELECT count(*)::int AS n FROM outbox_events
            WHERE aggregate_id = $1
              AND event_type IN ('family.geofence_entered', 'family.geofence_exited')`,
          [familyId],
        );
        assert.equal(
          baselineOutbox.rows[0].n,
          0,
          'a baseline sighting announced an arrival nobody watched happen',
        );

        // 5. Eight minutes ago: leaving. This one IS a crossing, and it IS announced.
        const leaves = await postFix(
          '33333333-3333-4333-8333-333333333333',
          { acquisition: 'located', latitude: 15.42, longitude: 44.25 },
          'w3-fix-3',
          -8 * minute,
        );
        assert.deepEqual(leaves.body.crossings, [
          { zoneId, kind: 'EXIT', baseline: false, notified: true, zoneVersion: 1 },
        ]);
        const exitOutbox = await client.query(
          `SELECT payload FROM outbox_events
            WHERE aggregate_id = $1 AND event_type = 'family.geofence_exited'`,
          [familyId],
        );
        assert.equal(exitOutbox.rowCount, 1);
        assert.equal(exitOutbox.rows[0].payload.zoneId, zoneId);
        assert.equal(exitOutbox.rows[0].payload.kind, 'EXIT');
        assert.equal(exitOutbox.rows[0].payload.zoneVersion, 1);
        assert.equal(exitOutbox.rows[0].payload.childId, childId);

        // 6. The same report again under a FRESH key: one fix id is one report. No second
        //    row, no second crossing, and an answer that says which of the two happened.
        const replay = await postFix(
          '33333333-3333-4333-8333-333333333333',
          { acquisition: 'located', latitude: 15.42, longitude: 44.25 },
          'w3-fix-3-retry',
          -8 * minute,
        );
        assert.equal(replay.status, 201);
        assert.equal(replay.body.replayed, true);
        assert.equal(replay.body.evaluated, false);
        assert.equal(replay.body.reason, 'duplicate');
        const trailCount = await client.query(
          `SELECT count(*)::int AS n FROM family_child_location_fixes WHERE family_id = $1`,
          [familyId],
        );
        assert.equal(trailCount.rows[0].n, 3, 'a replayed fix was stored twice');
        const crossingCount = await client.query(
          `SELECT count(*)::int AS n FROM family_geofence_events WHERE family_id = $1`,
          [familyId],
        );
        assert.equal(crossingCount.rows[0].n, 2, 'a replayed fix produced a second crossing');

        // 7. An hour ago, arriving now: kept in the trail and NOT judged. Judging it would
        //    replay history in the wrong order and invent a state that is not true.
        const late = await postFix(
          '44444444-4444-4444-8444-444444444444',
          { acquisition: 'stale_last_known', latitude: 15.5, longitude: 44.3 },
          'w3-fix-4',
          -60 * minute,
        );
        assert.equal(late.status, 201);
        assert.equal(late.body.evaluated, false);
        assert.equal(late.body.reason, 'stored_out_of_order');
        assert.deepEqual(late.body.crossings, []);
        const afterLate = await client.query(
          `SELECT count(*)::int AS n FROM family_geofence_events WHERE family_id = $1`,
          [familyId],
        );
        assert.equal(afterLate.rows[0].n, 2, 'a late report was judged against newer state');

        // 8. A handset that has no position yet says so, and is believed.
        const noFix = await postFix(
          '55555555-5555-4555-8555-555555555555',
          { acquisition: 'acquiring' },
          'w3-fix-5',
          -7 * minute,
        );
        assert.equal(noFix.status, 201);
        assert.equal(noFix.body.reason, 'no_coordinates');
        assert.equal(noFix.body.fix.latitude, null);
        assert.equal(noFix.body.fix.longitude, null);

        // A fix that pretends to a position it does not have is refused before storage.
        const dishonest = await postFix(
          '55555555-5555-4555-8555-555555555556',
          { acquisition: 'unavailable', latitude: 15.4, longitude: 44.2 },
          'w3-fix-dishonest',
          -7 * minute,
        );
        assert.equal(dishonest.status, 400);

        // 9. A second shape, evaluated by the same authority: a polygon school.
        const school = await jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w3-zone-school' }),
          body: {
            name: 'المدرسة',
            emoji: '🏫',
            geometry: {
              kind: 'POLYGON',
              vertices: [
                { latitude: 15.4, longitude: 44.2 },
                { latitude: 15.4, longitude: 44.21 },
                { latitude: 15.41, longitude: 44.21 },
                { latitude: 15.41, longitude: 44.2 },
              ],
            },
            childIds: [childId],
          },
        });
        assert.equal(school.status, 201);
        assert.equal(school.body.zone.geometry.kind, 'POLYGON');
        const schoolId = school.body.zone.id;
        const inSchool = await postFix(
          '66666666-6666-4666-8666-666666666666',
          { acquisition: 'located', latitude: 15.405, longitude: 44.205 },
          'w3-fix-6',
          -6 * minute,
        );
        assert.deepEqual(inSchool.body.crossings, [
          { zoneId: schoolId, kind: 'ENTER', baseline: true, notified: false, zoneVersion: 1 },
        ]);

        // 10. The picture a family reads. The guardian and the CHILD get the same rows:
        //     that is the promise, and it is asserted rather than described.
        const asGuardian = await jsonRequest(baseUrl, `/v1/families/${familyId}/location`, {
          headers: authorized('test-primary'),
        });
        assert.equal(asGuardian.status, 200);
        assert.equal(asGuardian.body.visibility, 'family_members');
        assert.equal(asGuardian.body.children.length, 1);
        const childRow = asGuardian.body.children[0];
        assert.equal(childRow.childId, childId);
        assert.equal(childRow.devices.length, 1);
        assert.equal(childRow.devices[0].state, 'live');
        assert.equal(childRow.devices[0].lastFix.acquisition, 'located');
        assert.equal(childRow.devices[0].lastFix.latitude, 15.405);
        const schoolState = childRow.zones.find((row) => row.zoneId === schoolId);
        assert.equal(schoolState.inside, true);
        assert.equal(schoolState.observedCrossing, false, 'a baseline is not an observed crossing');
        const homeState = childRow.zones.find((row) => row.zoneId === zoneId);
        assert.equal(homeState.inside, false);

        const asChild = await jsonRequest(baseUrl, `/v1/families/${familyId}/location`, {
          headers: authorized('test-child'),
        });
        assert.equal(asChild.status, 200);
        assert.deepEqual(
          asChild.body.children,
          asGuardian.body.children,
          'the child sees a different picture from the guardian, which is the asymmetry this '
            + 'surface exists to prevent',
        );

        const outsider = await jsonRequest(baseUrl, `/v1/families/${familyId}/location`, {
          headers: authorized('test-stranger'),
        });
        assert.equal(outsider.status, 403);

        // 11. The feed the alerts are read from: newest first, with its baselines marked.
        const feed = await jsonRequest(baseUrl, `/v1/families/${familyId}/geofence-events`, {
          headers: authorized('test-child'),
        });
        assert.equal(feed.status, 200);
        assert.deepEqual(
          feed.body.events.map((event) => [event.kind, event.baseline, event.zoneId]),
          [
            ['ENTER', true, schoolId],
            ['EXIT', false, zoneId],
            ['ENTER', true, zoneId],
          ],
        );

        // 12. The audit trail: every fix recorded, every crossing named, each in the same
        //     transaction as the change itself.
        const audit = await client.query(
          `SELECT event_type, count(*)::int AS n
             FROM family_audit_events
            WHERE family_id = $1
              AND (event_type LIKE 'family.location%' OR event_type LIKE 'family.geofence%')
            GROUP BY event_type ORDER BY event_type`,
          [familyId],
        );
        assert.deepEqual(
          audit.rows.map((row) => [row.event_type, row.n]),
          [
            ['family.geofence_entered', 2],
            ['family.geofence_exited', 1],
            ['family.location_fix_recorded', 6],
          ],
        );

        // 13. Retention: the trail is bounded, and the one sample a crossing points at is
        //     never deleted - an event whose measurement is gone is an event nobody can
        //     check, which is worse than a longer trail.
        const expired = await client.query(
          `INSERT INTO family_child_location_fixes
             (id, family_id, child_id, device_id, acquisition, location_lat, location_lng,
              accuracy_meters, recorded_at)
           VALUES (gen_random_uuid(), $1, $2, $3, 'located', 15.3, 44.1, 20, NOW() - INTERVAL '40 days')
           RETURNING id`,
          [familyId, childId, deviceId],
        );
        const newest = await postFix(
          '77777777-7777-4777-8777-777777777777',
          { acquisition: 'located', latitude: 15.42, longitude: 44.25 },
          'w3-fix-7',
          -5 * minute,
        );
        assert.equal(newest.status, 201);
        assert.ok(newest.body.pruned >= 1, 'an expired trail sample survived a real write');
        const vanished = await client.query(
          `SELECT count(*)::int AS n FROM family_child_location_fixes WHERE id = $1`,
          [expired.rows[0].id],
        );
        assert.equal(vanished.rows[0].n, 0, 'the expired sample was not pruned');
        const provenanceKept = await client.query(
          `SELECT count(*)::int AS n
             FROM family_geofence_events AS event
             JOIN family_child_location_fixes AS fix ON fix.id = event.fix_id
            WHERE event.family_id = $1`,
          [familyId],
        );
        assert.equal(provenanceKept.rows[0].n, 4, 'a crossing lost the measurement it points at');


        // 13. The trail read back. Same rule as the live picture: one read, one rule for
        //     every active member, newest first, and a device that answered without a
        //     position keeps its null coordinates instead of a zero.
        const historyAsGuardian = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/location-history`,
          { headers: authorized('test-primary') },
        );
        assert.equal(historyAsGuardian.status, 200);
        assert.equal(historyAsGuardian.body.visibility, 'family_members');
        assert.equal(historyAsGuardian.body.retentionDays, 30);
        assert.equal(historyAsGuardian.body.childId, childId);
        const trail = historyAsGuardian.body.fixes;
        assert.ok(trail.length >= 6, `the trail lost fixes: ${trail.length}`);
        assert.ok(
          trail.some((row) => row.id === '11111111-1111-4111-8111-111111111111'),
          'the first fix of the journey is missing from the trail',
        );
        for (let i = 1; i < trail.length; i += 1) {
          assert.ok(
            new Date(trail[i - 1].recordedAt).getTime() >= new Date(trail[i].recordedAt).getTime(),
            'the trail is not newest first',
          );
        }
        const acquiringRow = trail.find((row) => row.acquisition === 'acquiring');
        assert.ok(acquiringRow, 'the honest non-answer was not kept in the trail');
        assert.equal(acquiringRow.latitude, null, 'a missing position became a coordinate');
        assert.equal(acquiringRow.longitude, null);
        assert.ok(
          trail.every(
            (row) =>
              ['located', 'stale_last_known', 'acquiring', 'unavailable'].includes(row.acquisition),
          ),
          'the trail carries a state the contract does not declare',
        );
        const locatedRow = trail.find((row) => row.acquisition === 'located');
        assert.ok(locatedRow.latitude !== null && locatedRow.longitude !== null);

        const historyAsChild = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/location-history`,
          { headers: authorized('test-child') },
        );
        assert.equal(historyAsChild.status, 200);
        assert.deepEqual(
          historyAsChild.body.fixes,
          trail,
          'the child reads a different history from the guardian, which is the asymmetry '
            + 'this read exists to prevent',
        );

        const historyOfAGhost = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${'99999999-9999-4999-8999-999999999999'}/location-history`,
          { headers: authorized('test-primary') },
        );
        assert.equal(historyOfAGhost.status, 404);

        const historyForAStranger = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/location-history`,
          { headers: authorized('test-stranger') },
        );
        assert.equal(historyForAStranger.status, 403);

        // 11. The switch a family reaches for at night. Changing which transitions a zone
        //     announces must not be able to move the boundary, and must not be able to
        //     re-describe a crossing that was already reported.
        const patchZone = (subject, key, body) =>
          jsonRequest(baseUrl, `/v1/families/${familyId}/safe-zones/${schoolId}`, {
            method: 'PATCH',
            headers: authorized(subject, { 'idempotency-key': key }),
            body,
          });

        const alertsOff = await patchZone('test-primary', 'w3-alerts-off', { alertEnter: false });
        assert.equal(alertsOff.status, 200);
        assert.equal(alertsOff.body.zone.alertEnter, false);
        assert.equal(alertsOff.body.zone.alertExit, true, 'a flag the family did not touch changed');
        assert.equal(alertsOff.body.zone.version, 2, 'a rule change did not move the version');
        assert.equal(alertsOff.body.zone.geometry.version, 2, 'the geometry kept the old version');
        const { version: _changedVersion, ...shapeAfter } = alertsOff.body.zone.geometry;
        const { version: _firstVersion, ...shapeBefore } = school.body.zone.geometry;
        assert.deepEqual(shapeAfter, shapeBefore, 'changing the alert flags moved the boundary');
        assert.deepEqual(alertsOff.body.zone.childIds, [childId], 'the assignment was lost');

        const childPatch = await patchZone('test-child', 'w3-alerts-child', { alertEnter: false });
        assert.equal(childPatch.status, 403);
        assert.equal(childPatch.body.error.code, 'safe_zone_guardian_required');

        const nothingToChange = await patchZone('test-primary', 'w3-alerts-empty', {});
        assert.equal(nothingToChange.status, 400);

        const moveBoundary = await patchZone('test-primary', 'w3-alerts-move', {
          alertEnter: true,
          geometry: { kind: 'CIRCLE', center: home, radiusMeters: 400 },
        });
        assert.equal(moveBoundary.status, 400, 'the boundary is not editable through the flags switch');

        const unknownZone = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/safe-zones/${'99999999-9999-4999-8999-999999999999'}`,
          {
            method: 'PATCH',
            headers: authorized('test-primary', { 'idempotency-key': 'w3-alerts-ghost' }),
            body: { alertEnter: true },
          },
        );
        assert.equal(unknownZone.status, 404);

        // 12. A crossing still happens and is still recorded - it is simply not announced,
        //     because the family said they no longer want to hear about arrivals here. An
        //     alert switch governs announcements; it must never govern the trail.
        //
        //     The child already stepped out of the school during the pruning write above
        //     (that trail sample was placed away from the school), so this report is outside
        //     a zone she had left: it must produce nothing at all rather than a crossing
        //     invented by the flag change.
        const awayAgain = await postFix(
          '78787878-7878-4878-8878-787878787878',
          { acquisition: 'located', latitude: 15.45, longitude: 44.25 },
          'w3-alert-fix-away',
          -4 * minute,
        );
        assert.equal(awayAgain.status, 201);
        assert.equal(awayAgain.body.evaluated, true);
        assert.deepEqual(awayAgain.body.crossings, [], 'flipping a flag produced a crossing');

        // 12a. Walking back in: recorded in the trail, and silent.
        const backAgain = await postFix(
          '88888888-8888-4888-8888-888888888888',
          { acquisition: 'located', latitude: 15.405, longitude: 44.205 },
          'w3-alert-fix-back',
          -3 * minute,
        );
        assert.equal(backAgain.status, 201);
        assert.deepEqual(
          backAgain.body.crossings,
          [{ zoneId: schoolId, kind: 'ENTER', baseline: false, notified: false, zoneVersion: 2 }],
          'a silenced arrival was still announced',
        );

        // 12b. Leaving again: the flag the family left alone still speaks, and it says which
        //      version of the zone it was judged against.
        const awayOnceMore = await postFix(
          '89898989-8989-4989-8989-898989898989',
          { acquisition: 'located', latitude: 15.45, longitude: 44.25 },
          'w3-alert-fix-away2',
          -2 * minute,
        );
        assert.equal(awayOnceMore.status, 201);
        assert.deepEqual(awayOnceMore.body.crossings, [
          { zoneId: schoolId, kind: 'EXIT', baseline: false, notified: true, zoneVersion: 2 },
        ]);

        const schoolAnnouncements = await client.query(
          `SELECT event_type, payload
             FROM outbox_events
            WHERE aggregate_id = $1
              AND event_type IN ('family.geofence_entered', 'family.geofence_exited')
              AND payload->>'zoneId' = $2
            ORDER BY created_at ASC, id ASC`,
          [familyId, schoolId],
        );
        assert.deepEqual(
          schoolAnnouncements.rows.map((row) => row.event_type),
          ['family.geofence_exited', 'family.geofence_exited'],
          'the announcement queue disagrees with the switch the family flipped',
        );
        assert.equal(schoolAnnouncements.rows[0].payload.zoneVersion, 1);
        assert.equal(schoolAnnouncements.rows[1].payload.zoneVersion, 2);
        assert.equal(schoolAnnouncements.rows[1].payload.kind, 'EXIT');
        assert.equal(schoolAnnouncements.rows[1].payload.childId, childId);

        // The trail keeps every crossing, including the two the family did not want to hear
        // about, and each one still points at the measurement it was judged from.
        const schoolTrail = await client.query(
          `SELECT kind, baseline, zone_version
             FROM family_geofence_events
            WHERE family_id = $1 AND zone_id = $2
            ORDER BY occurred_at ASC`,
          [familyId, schoolId],
        );
        assert.deepEqual(
          schoolTrail.rows.map((row) => [row.kind, row.baseline, row.zone_version]),
          [
            ['ENTER', true, 1],
            ['EXIT', false, 1],
            ['ENTER', false, 2],
            ['EXIT', false, 2],
          ],
          'a crossing was dropped from the trail because the family did not want an alert',
        );

        const toggledBack = await patchZone('test-primary', 'w3-alerts-back', { alertEnter: true });
        assert.equal(toggledBack.status, 200);
        assert.equal(toggledBack.body.zone.version, 3);
        assert.equal(toggledBack.body.zone.alertEnter, true);
      });
    } finally {
      await store.close();
    }
  });
});

/**
 * The emergency journey (W4) — and the four things this test would rather fail on than
 * discover later.
 *
 *   1. The child sees exactly what the guardians see. Selective visibility on an incident
 *      is how a safety product becomes a surveillance product, so the read is compared
 *      row for row rather than described.
 *   2. Nothing claims a delivery nobody made. There is no push transport and no SMS
 *      transport in this repository, so a delivery row may only be `recorded` or
 *      `not_configured`, and the database itself refuses `delivered`. That refusal is
 *      asserted by trying to write one.
 *   3. Escalation climbs only verified rungs, and says how many it skipped. An unverified
 *      number must not ring, and the family must not be told it did.
 *   4. An incident's measurement outlives the retention window. A press that points at a
 *      sample would otherwise be an alarm nobody can check afterwards.
 *
 * Identity is the only stubbed part (`TestAuthVerifier`); every other step goes through
 * the real HTTP surface against real PostgreSQL.
 */
test('a child presses the button, the family answers it, and nothing claims a delivery nobody made', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = new PostgresFoundationStore({
      connectionString: withDatabase(DATABASE_URL, client.database),
    });
    const app = createApp({
      store,
      authVerifier: new TestAuthVerifier(),
      readiness: () => ({ ready: true, missing: [] }),
    });
    try {
      await withServer(app, async (baseUrl) => {
        // 1. A family with two guardians and one child, and the child's OWN account -
        //    invited and accepted through the real endpoints, because a membership inserted
        //    by hand would not prove the child can reach this surface at all.
        const created = await jsonRequest(baseUrl, '/v1/families', {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-family' }),
          body: { displayName: 'عائلة الطوارئ' },
        });
        assert.equal(created.status, 201);
        const familyId = created.body.family.id;

        const coGuardianInvite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-invite-co' }),
          body: { role: 'co_guardian', targetSubject: 'test-co' },
        });
        assert.equal(coGuardianInvite.status, 201);
        const coGuardianAccepted = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${coGuardianInvite.body.membership.id}/accept`,
          { method: 'POST', headers: authorized('test-co', { 'idempotency-key': 'w4-accept-co' }) },
        );
        assert.equal(coGuardianAccepted.status, 200);

        const children = await jsonRequest(baseUrl, `/v1/families/${familyId}/children`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-child' }),
          body: { displayName: 'أماني', ageYears: 9, avatarEmoji: '🦁', themeColor: 'sky' },
        });
        assert.equal(children.status, 201);
        const childId = children.body.child.id;

        const invite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-invite-child' }),
          body: { role: 'child', targetSubject: 'test-child' },
        });
        assert.equal(invite.status, 201);
        const accepted = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships/${invite.body.membership.id}/accept`,
          { method: 'POST', headers: authorized('test-child', { 'idempotency-key': 'w4-accept-child' }) },
        );
        assert.equal(accepted.status, 200);

        const deviceCredential = 'w4-device-credential-value-000000000001';
        const device = await client.query(
          `INSERT INTO family_child_devices
             (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
           VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
           RETURNING id`,
          [familyId, childId, createHash('sha256').update(deviceCredential).digest('hex')],
        );
        const deviceId = device.rows[0].id;
        const deviceAuth = { authorization: `Device ${deviceCredential}` };

        const now = Date.now();
        const day = 24 * 60 * 60 * 1000;
        const at = (offsetMs) => new Date(now + offsetMs).toISOString();
        const reportFix = (fixId, recordedAt, body = {}) =>
          jsonRequest(baseUrl, `/v1/devices/${deviceId}/location-fixes`, {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': `w4-fix-${fixId.slice(0, 8)}` },
            body: {
              fixId,
              acquisition: 'located',
              latitude: 15.3694,
              longitude: 44.191,
              accuracyMeters: 12,
              recordedAt,
              ...body,
            },
          });

        // 2. The sample the press will point at. It is reported while it is still fresh -
        //    a sample older than the window is pruned inside the very write that stores it,
        //    which is the correct behaviour and useless for this test - and then AGED by
        //    the test, because observing a thirty-day window must not mean waiting thirty
        //    days. Everything after this point is the real surface.
        const evidenceFixId = 'a1a1a1a1-1111-4111-8111-111111111111';
        const evidence = await reportFix(evidenceFixId, at(-60 * 1000));
        assert.equal(evidence.status, 201);
        assert.equal(evidence.body.fix.id, evidenceFixId);
        await client.query(
          `UPDATE family_child_location_fixes
              SET recorded_at = NOW() - INTERVAL '40 days'
            WHERE id = $1`,
          [evidenceFixId],
        );

        // 3. The button. The handset proves itself with its credential and states the
        //    picture it had at that moment: a real position, with the accuracy it came with.
        const press = {
          locationClass: 'ready',
          latitude: 15.3701,
          longitude: 44.1912,
          accuracyMeters: 9,
          connectionClass: 'degraded',
          batteryPercent: 63,
          placeLabel: 'قرب حديقة الحي',
          panicQuiet: false,
          fixId: evidenceFixId,
          pressedAt: at(-2 * 60 * 1000),
        };
        const raised = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-1' },
          body: press,
        });
        assert.equal(raised.status, 201);
        const alertId = raised.body.alert.id;
        assert.equal(raised.body.alert.raisedByKind, 'child_device');
        assert.equal(raised.body.alert.status, 'active');
        assert.equal(raised.body.alert.open, true);
        assert.equal(raised.body.alert.picture.latitude, press.latitude);
        assert.equal(raised.body.alert.picture.accuracyMeters, 9);
        assert.equal(raised.body.alert.picture.fixId, evidenceFixId);
        assert.equal(raised.body.alert.picture.connectionClass, 'degraded');

        // The first rung is the family's guardians, derived from the roster. Both of them,
        // on both channels - and the push rows say plainly that this build cannot send one.
        const firstDeliveries = raised.body.alert.deliveries;
        assert.equal(firstDeliveries.length, 4, 'two guardians, an in-app row and a push row each');
        assert.deepEqual(
          [...new Set(firstDeliveries.map((row) => row.channel))].sort(),
          ['in_app', 'push'],
        );
        for (const row of firstDeliveries) {
          assert.equal(row.recipientKind, 'guardian');
          assert.notEqual(row.recipientMembershipId, null);
          if (row.channel === 'in_app') {
            assert.equal(row.deliveryState, 'recorded');
            assert.equal(row.reasonCode, null);
          } else {
            assert.equal(row.deliveryState, 'not_configured');
            assert.equal(row.reasonCode, 'push_transport_absent');
          }
        }
        // Nobody who answers a button press is the child who pressed it: rung 1 is the
        // people responsible for coming, not a copy of the alarm back to the alarm.
        assert.equal(
          new Set(firstDeliveries.map((row) => row.recipientMembershipId)).size,
          2,
          'the two guardians are the recipients',
        );

        // 4. The same press under the same key is the same incident, and a second press
        //    under a fresh key is refused with the incident that already exists - the
        //    family's attention is not split across two screens.
        const replayed = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-1' },
          body: press,
        });
        assert.equal(replayed.status, 201);
        assert.equal(replayed.body.alert.id, alertId);

        const secondPress = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-2' },
          body: press,
        });
        assert.equal(secondPress.status, 409);
        assert.equal(secondPress.body.error.code, 'sos_alert_already_open');
        assert.equal(secondPress.body.error.details.alertId, alertId);

        // 5. The child reads it. Row for row, the same incident a parent reads: this is the
        //    promise, and it is the assertion that will fail if selective visibility is ever
        //    added to the other read.
        const guardianRead = await jsonRequest(baseUrl, `/v1/families/${familyId}/sos-alerts`, {
          headers: authorized('test-primary'),
        });
        assert.equal(guardianRead.status, 200);
        const childRead = await jsonRequest(baseUrl, `/v1/families/${familyId}/sos-alerts`, {
          headers: authorized('test-child'),
        });
        assert.equal(childRead.status, 200);
        assert.deepEqual(childRead.body.alerts, guardianRead.body.alerts);

        // The child cannot acknowledge their own incident, and the refusal is a fact of the
        // schema: nothing links a child row to a membership row, so the server cannot prove
        // the incident is that account's. The handset can close it, and only as a false alarm.
        const childAck = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/acknowledge`,
          {
            method: 'POST',
            headers: authorized('test-child', { 'idempotency-key': 'w4-child-ack' }),
          },
        );
        assert.equal(childAck.status, 403);
        assert.equal(childAck.body.error.code, 'sos_acknowledge_forbidden');

        // 6. "I have seen this" is not "this is over". A parent acknowledges, and the second
        //    parent's acknowledgement reports the incident rather than creating anything.
        const acknowledged = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/acknowledge`,
          {
            method: 'POST',
            headers: authorized('test-co', { 'idempotency-key': 'w4-ack-1' }),
          },
        );
        assert.equal(acknowledged.status, 200);
        assert.equal(acknowledged.body.alert.status, 'acknowledged');
        assert.notEqual(acknowledged.body.alert.acknowledgedAt, null);
        const acknowledgedVersion = acknowledged.body.alert.version;

        const secondAck = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/acknowledge`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w4-ack-2' }),
          },
        );
        assert.equal(secondAck.status, 200);
        assert.equal(secondAck.body.replayed, true);
        assert.equal(secondAck.body.alert.version, acknowledgedVersion);

        // 7. The ladder. Two contacts are added - and a new rung is created `unverified`
        //    whatever the caller sends - then one of them is verified in a separate act.
        const added = await jsonRequest(baseUrl, `/v1/families/${familyId}/sos-backup-contacts`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-ladder-1' }),
          body: { name: 'العم سالم', relation: 'عم', phoneE164: '+967771111111' },
        });
        assert.equal(added.status, 201);
        assert.equal(added.body.contact.verification, 'unverified');

        const second = await jsonRequest(baseUrl, `/v1/families/${familyId}/sos-backup-contacts`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w4-ladder-2' }),
          body: { name: 'الجار أحمد', relation: 'جار', phoneE164: '+967772222222', priority: 2 },
        });
        assert.equal(second.status, 201);
        const verifiedContactId = second.body.contact.id;
        const verified = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-backup-contacts/${verifiedContactId}`,
          {
            method: 'PATCH',
            headers: authorized('test-primary', { 'idempotency-key': 'w4-ladder-verify' }),
            body: { verification: 'verified' },
          },
        );
        assert.equal(verified.status, 200);
        assert.equal(verified.body.contact.verification, 'verified');

        // Escalating climbs the verified rung only, and says how many it skipped.
        const escalated = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/escalate`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w4-escalate-1' }),
          },
        );
        assert.equal(escalated.status, 200);
        assert.equal(escalated.body.alert.status, 'escalating');
        assert.deepEqual(escalated.body.escalation, { eligibleContacts: 1, skippedUnverified: 1 });
        const escalatedTo = escalated.body.alert.deliveries.filter(
          (row) => row.recipientKind === 'backup',
        );
        assert.equal(escalatedTo.length, 1, 'only the verified contact is reached');
        assert.equal(escalatedTo[0].recipientContactId, verifiedContactId);
        assert.equal(escalatedTo[0].channel, 'sms');
        assert.equal(escalatedTo[0].deliveryState, 'not_configured');
        assert.equal(escalatedTo[0].reasonCode, 'sms_transport_absent');
        assert.equal(
          escalated.body.alert.deliveries.some((row) => row.deliveryState === 'delivered'),
          false,
        );

        // Escalating twice adds nothing: the second answer reports what the first did.
        const escalatedAgain = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/escalate`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w4-escalate-2' }),
          },
        );
        assert.equal(escalatedAgain.status, 200);
        assert.equal(escalatedAgain.body.replayed, true);
        assert.equal(escalatedAgain.body.alert.deliveries.length, firstDeliveries.length + 1);

        // 8. Closing it. A guardian states why; the incident reports the reason and is no
        //    longer open.
        const resolved = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts/${alertId}/resolve`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w4-resolve-1' }),
            body: { terminalReason: 'helped' },
          },
        );
        assert.equal(resolved.status, 200);
        assert.equal(resolved.body.alert.status, 'resolved');
        assert.equal(resolved.body.alert.terminalReason, 'helped');
        assert.equal(resolved.body.alert.open, false);
        assert.notEqual(resolved.body.alert.resolvedAt, null);

        const openAfter = await jsonRequest(baseUrl, `/v1/families/${familyId}/sos-alerts`, {
          headers: authorized('test-primary'),
        });
        assert.equal(openAfter.status, 200);
        assert.deepEqual(openAfter.body.alerts, []);

        const allAfter = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/sos-alerts?status=all`,
          { headers: authorized('test-primary') },
        );
        assert.equal(allAfter.body.alerts.length, 1);

        // 9. The handset closes its own incident, and only as a false alarm - which is the
        //    one act a child is allowed to take on their own alarm.
        const pressedAgain = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-3' },
          body: { ...press, locationClass: 'acquiring', latitude: undefined, longitude: undefined, accuracyMeters: undefined, fixId: undefined },
        });
        assert.equal(pressedAgain.status, 201);
        const falseAlarmId = pressedAgain.body.alert.id;
        assert.equal(pressedAgain.body.alert.picture.latitude, null);
        assert.equal(pressedAgain.body.alert.picture.locationClass, 'acquiring');

        const helpedFromHandset = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/sos-alerts/${falseAlarmId}/resolve`,
          {
            method: 'POST',
            headers: deviceAuth,
            body: { terminalReason: 'helped' },
          },
        );
        assert.equal(helpedFromHandset.status, 400);

        const cancelled = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/sos-alerts/${falseAlarmId}/resolve`,
          {
            method: 'POST',
            headers: deviceAuth,
            body: { terminalReason: 'false_alarm' },
          },
        );
        assert.equal(cancelled.status, 200);
        assert.equal(cancelled.body.alert.status, 'resolved');
        assert.equal(cancelled.body.alert.terminalReason, 'false_alarm');

        // 10. A dishonest press is refused where it is written down: a place with no stated
        //     accuracy, and a place that claims a position while calling itself absent.
        const thirdPress = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-4' },
          body: { locationClass: 'ready', latitude: 15.37, longitude: 44.19, connectionClass: 'online' },
        });
        assert.equal(thirdPress.status, 400);
        const fourthPress = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/sos-alerts`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w4-sos-5' },
          body: {
            locationClass: 'unavailable',
            latitude: 15.37,
            longitude: 44.19,
            connectionClass: 'offline',
          },
        });
        assert.equal(fourthPress.status, 400);

        // 11. The evidence survives the retention window. A new old sample arrives, the
        //     prune runs inside that same write, and the sample the incident points at is
        //     the one thing it does not delete.
        const secondOldFixId = 'b2b2b2b2-2222-4222-8222-222222222222';
        const pruned = await reportFix(secondOldFixId, at(-41 * day));
        assert.equal(pruned.status, 201);
        assert.equal(pruned.body.reason, 'stored_out_of_order');
        assert.equal(pruned.body.pruned, 1, 'the unreferenced old sample is deleted');
        const survivors = await client.query(
          `SELECT id FROM family_child_location_fixes WHERE family_id = $1`,
          [familyId],
        );
        assert.deepEqual(
          survivors.rows.map((row) => row.id),
          [evidenceFixId],
          'the sample an incident points at must outlive the retention window',
        );

        // 12. The audit trail and the announcement queue agree with the story, and the
        //     deliveries table contains only the two states this platform can prove.
        const audit = await client.query(
          `SELECT event_type FROM family_audit_events
            WHERE subject_type = 'sos_alert' AND subject_id = $1
            ORDER BY occurred_at ASC`,
          [alertId],
        );
        assert.deepEqual(audit.rows.map((row) => row.event_type), [
          'family.sos_alert_raised',
          'family.sos_alert_acknowledged',
          'family.sos_alert_escalated',
          'family.sos_alert_resolved',
        ]);
        const outbox = await client.query(
          `SELECT event_type FROM outbox_events WHERE aggregate_id = $1 ORDER BY event_type`,
          [familyId],
        );
        for (const eventType of [
          'family.sos_alert_raised',
          'family.sos_alert_acknowledged',
          'family.sos_alert_escalated',
          'family.sos_alert_resolved',
        ]) {
          assert.ok(
            outbox.rows.some((row) => row.event_type === eventType),
            `${eventType} must reach the announcement queue`,
          );
        }

        const states = await client.query(
          `SELECT DISTINCT delivery_state FROM family_sos_alert_deliveries`,
        );
        assert.deepEqual(
          states.rows.map((row) => row.delivery_state).sort(),
          ['not_configured', 'recorded'],
        );
        await assert.rejects(
          () =>
            client.query(
              `UPDATE family_sos_alert_deliveries SET delivery_state = 'delivered' WHERE alert_id = $1`,
              [alertId],
            ),
          /violates check constraint/i,
          'the database must refuse a delivery state this platform cannot prove',
        );
      });
    } finally {
      await store.close();
    }
  });
});
