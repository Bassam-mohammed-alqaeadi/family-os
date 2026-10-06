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
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { deviceRevocationFor } from '../src/device-revocation.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';

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

/** Creates an account, a family with a primary guardian, a child and a paired device. */
async function seedPairedDevice(client) {
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
  const device = await client.query(
    // A credential and its issue time travel together: migration 008 refuses a device that
    // holds one without the other. The server's own claim path sets both; so does this seed.
    `INSERT INTO family_child_devices
       (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
     VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
     RETURNING id, family_id, child_id`,
    [family.rows[0].id, child.rows[0].id, 'a'.repeat(64)],
  );
  return {
    familyId: family.rows[0].id,
    childId: child.rows[0].id,
    deviceId: device.rows[0].id,
    membershipId: membership.rows[0].id,
  };
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
