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
import { familyLocalParts } from '../src/screen-time.js';
import { postgresCalendarPort } from '../src/calendar.js';
import { postgresTasksPort } from '../src/tasks.js';
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

test('thread-scoped tasks and calendar events are visible only to their active conversation members', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const ids = await seedFamily(client);
    const sibling = await client.query(
      `INSERT INTO family_children (id, family_id, display_name, age_years)
       VALUES (gen_random_uuid(), $1, 'Bashir', 10) RETURNING id`,
      [ids.familyId],
    );
    const siblingId = sibling.rows[0].id;
    const coAccount = await client.query(
      `INSERT INTO accounts (id, oidc_subject) VALUES (gen_random_uuid(), 'gate-co') RETURNING id`,
    );
    const coMembership = await client.query(
      `INSERT INTO family_memberships
         (id, family_id, account_id, target_subject, role, status, joined_at)
       VALUES (gen_random_uuid(), $1, $2, 'gate-co', 'co_guardian', 'active', NOW())
       RETURNING id`,
      [ids.familyId, coAccount.rows[0].id],
    );
    const thread = await client.query(
      `INSERT INTO family_chat_threads
         (id, family_id, kind, title, created_by_membership_id,
          created_by_participant_kind, created_by_participant_id)
       VALUES (gen_random_uuid(), $1, 'group', 'Amani and primary', $2, 'membership', $2)
       RETURNING id`,
      [ids.familyId, ids.membershipId],
    );
    await client.query(
      `INSERT INTO family_chat_thread_members
         (thread_id, family_id, participant_kind, participant_id, membership_id, child_id)
       VALUES ($1, $2, 'membership', $3, $3, NULL),
              ($1, $2, 'child', $4, NULL, $4),
              ($1, $2, 'child', $5, NULL, $5)`,
      [thread.rows[0].id, ids.familyId, ids.membershipId, ids.childId, siblingId],
    );

    const scopedTask = await client.query(
      `INSERT INTO family_tasks
         (id, family_id, child_id, audience_thread_id, title, points, created_by_membership_id)
       VALUES (gen_random_uuid(), $1, $2, $3, 'Group task', 10, $4)
       RETURNING id`,
      [ids.familyId, ids.childId, thread.rows[0].id, ids.membershipId],
    );
    const privateTask = await client.query(
      `INSERT INTO family_tasks
         (id, family_id, child_id, title, points, created_by_membership_id)
       VALUES (gen_random_uuid(), $1, $2, 'Family task', 5, $3)
       RETURNING id`,
      [ids.familyId, ids.childId, ids.membershipId],
    );

    const scopedEvent = await client.query(
      `INSERT INTO family_events
         (id, family_id, audience_thread_id, title, starts_at, ends_at, created_by_membership_id)
       VALUES (gen_random_uuid(), $1, $2, 'Group event', '2026-10-10T10:00:00Z',
               '2026-10-10T11:00:00Z', $3)
       RETURNING id`,
      [ids.familyId, thread.rows[0].id, ids.membershipId],
    );
    const privateEvent = await client.query(
      `INSERT INTO family_events
         (id, family_id, title, starts_at, ends_at, created_by_membership_id)
       VALUES (gen_random_uuid(), $1, 'Family event', '2026-10-11T10:00:00Z',
               '2026-10-11T11:00:00Z', $2)
       RETURNING id`,
      [ids.familyId, ids.membershipId],
    );
    await client.query(
      `INSERT INTO family_event_audience (family_id, event_id, child_id)
       VALUES ($1, $2, $3), ($1, $4, $3)`,
      [ids.familyId, scopedEvent.rows[0].id, ids.childId, privateEvent.rows[0].id],
    );

    const tasks = postgresTasksPort({}, { credentialMatches: () => true });
    const calendar = postgresCalendarPort({}, { credentialMatches: () => true });
    const primaryTasks = await tasks.listTasks(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      viewerKind: 'membership',
      viewerId: ids.membershipId,
    });
    const coGuardianTasks = await tasks.listTasks(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      viewerKind: 'membership',
      viewerId: coMembership.rows[0].id,
    });
    const childTasks = await tasks.listTasks(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      viewerKind: 'child',
      viewerId: ids.childId,
    });
    const siblingTasks = await tasks.listTasks(client, {
      familyId: ids.familyId,
      childId: siblingId,
      viewerKind: 'child',
      viewerId: siblingId,
    });
    assert.deepEqual(new Set(primaryTasks.map((row) => row.id)), new Set([scopedTask.rows[0].id, privateTask.rows[0].id]));
    assert.deepEqual(new Set(coGuardianTasks.map((row) => row.id)), new Set([privateTask.rows[0].id]));
    assert.deepEqual(new Set(childTasks.map((row) => row.id)), new Set([scopedTask.rows[0].id, privateTask.rows[0].id]));
    assert.deepEqual(siblingTasks, [], 'a sibling in the same group cannot see another child\'s task');

    const primaryEvents = await calendar.listEvents(client, {
      familyId: ids.familyId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
      viewerMembershipId: ids.membershipId,
    });
    const coGuardianEvents = await calendar.listEvents(client, {
      familyId: ids.familyId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
      viewerMembershipId: coMembership.rows[0].id,
    });
    assert.deepEqual(new Set(primaryEvents.map((row) => row.id)), new Set([scopedEvent.rows[0].id, privateEvent.rows[0].id]));
    assert.deepEqual(new Set(coGuardianEvents.map((row) => row.id)), new Set([privateEvent.rows[0].id]));

    const childEvents = await calendar.listEventsForChild(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
    });
    const siblingEvents = await calendar.listEventsForChild(client, {
      familyId: ids.familyId,
      childId: siblingId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
    });
    assert.deepEqual(new Set(childEvents.map((row) => row.id)), new Set([scopedEvent.rows[0].id, privateEvent.rows[0].id]));
    assert.deepEqual(siblingEvents, [], 'a sibling in the same chat does not inherit this event invitation');

    await client.query(
      `UPDATE family_chat_thread_members SET left_at = NOW()
        WHERE thread_id = $1 AND participant_kind = 'child' AND participant_id = $2`,
      [thread.rows[0].id, ids.childId],
    );
    const removedChildTasks = await tasks.listTasks(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      viewerKind: 'child',
      viewerId: ids.childId,
    });
    const removedChildEvents = await calendar.listEventsForChild(client, {
      familyId: ids.familyId,
      childId: ids.childId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
    });
    const primaryEventsAfterRemoval = await calendar.listEvents(client, {
      familyId: ids.familyId,
      from: '2026-10-01T00:00:00Z',
      to: '2026-11-01T00:00:00Z',
      viewerMembershipId: ids.membershipId,
    });
    const groupAudienceAfterRemoval = await calendar.listAudience(client, {
      familyId: ids.familyId,
      eventIds: [scopedEvent.rows[0].id],
      viewerMembershipId: ids.membershipId,
    });
    assert.deepEqual(new Set(removedChildTasks.map((row) => row.id)), new Set([privateTask.rows[0].id]));
    assert.deepEqual(new Set(removedChildEvents.map((row) => row.id)), new Set([privateEvent.rows[0].id]));
    assert.deepEqual(new Set(primaryEventsAfterRemoval.map((row) => row.id)), new Set([privateEvent.rows[0].id]));
    assert.deepEqual(groupAudienceAfterRemoval, []);
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

// ---------------------------------------------------------------------------------------
// W5 — screen time, against real PostgreSQL.
//
// The feature families pay for, and the feature where a platform most easily starts lying.
// Every claim the surface makes is checked here from the outside, through the mounted
// routes, with the numbers read back out of the database:
//
//   1. The state is computed, not stored. There is no `blocked` column to go stale, and
//      raising the cap clears a "time is up" state with no unlock call in between.
//   2. A blocked app is blocked at noon and at midnight; an undecided app waits for a
//      parent; a bedtime ends the entertainment and leaves education alone.
//   3. Minutes never shrink. A replay, a retry or a handset reporting a smaller figure
//      cannot reduce what a family is looking at.
//   4. A lock is an event with an author, one live lock per child, released by a person
//      and remembered afterwards.
//   5. Questions expire, answers happen once, and a grant is never larger than the ask.
//   6. The device credential is the only proof of which child is asking - the routes carry
//      no child id, and a body that tries to supply one is refused.
//
// Identity is the only stubbed part (`TestAuthVerifier`); everything else is the real
// surface. The windows are computed with the server's own clock function rather than
// re-derived here, so a test that passes cannot be passing against a different calendar.
// ---------------------------------------------------------------------------------------

const W5_OFFSET_SAFETY_MARGIN_MINUTES = 5;

/**
 * The household both W5 journeys start from.
 *
 * A family with its primary guardian, a second guardian, the child's own account (invited
 * and accepted through the real endpoints, because an account that cannot reach the door is
 * not proof of anything), and the handset whose credential is what proves which child it is.
 *
 * The family's offset is chosen so that their local time is around noon, which keeps the
 * clock away from midnight and means the occasional minute that ticks past mid-test cannot
 * move the day out from under a usage row.
 */
/** A stable idempotency hash for the journeys that call an operation directly. */
function requestFingerprintFor(seed) {
  return createHash('sha256').update(seed).digest('hex');
}

async function seedScreenTimeFamily(baseUrl, client, tag) {
  const created = await jsonRequest(baseUrl, '/v1/families', {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': `${tag}-family` }),
    body: { displayName: 'عائلة وقت الشاشة' },
  });
  assert.equal(created.status, 201);
  const familyId = created.body.family.id;

  const children = await jsonRequest(baseUrl, `/v1/families/${familyId}/children`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': `${tag}-child` }),
    body: { displayName: 'أماني', ageYears: 11, avatarEmoji: '🦁', themeColor: 'sky' },
  });
  assert.equal(children.status, 201);
  const childId = children.body.child.id;

  for (const [subject, role, key] of [
    ['test-co', 'co_guardian', `${tag}-invite-co`],
    ['test-child', 'child', `${tag}-invite-child`],
  ]) {
    const invite = await jsonRequest(baseUrl, `/v1/families/${familyId}/memberships`, {
      method: 'POST',
      headers: authorized('test-primary', { 'idempotency-key': key }),
      body: { role, targetSubject: subject },
    });
    assert.equal(invite.status, 201);
    const accepted = await jsonRequest(
      baseUrl,
      `/v1/families/${familyId}/memberships/${invite.body.membership.id}/accept`,
      { method: 'POST', headers: authorized(subject, { 'idempotency-key': `${key}-accept` }) },
    );
    assert.equal(accepted.status, 200, `${subject} must be able to reach the family`);
  }

  const guardians = await client.query(
    `SELECT target_subject, id FROM family_memberships
      WHERE family_id = $1 AND role IN ('primary_guardian', 'co_guardian')`,
    [familyId],
  );
  const primaryMembershipId = guardians.rows.find((row) => row.target_subject === 'test-primary').id;

  const deviceCredential = `${tag}-device-credential-value-0001`;
  const device = await client.query(
    `INSERT INTO family_child_devices
       (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
     VALUES (gen_random_uuid(), $1, $2, 'Amani Android', $3, NOW())
     RETURNING id`,
    [familyId, childId, createHash('sha256').update(deviceCredential).digest('hex')],
  );

  // Noon in the family's own day, whatever the test runner's clock says. The offset is a
  // stored field on the policy, which is what makes this possible at all.
  const utcMinuteOfDay = new Date().getUTCHours() * 60 + new Date().getUTCMinutes();
  const offsetMinutes = 720 - utcMinuteOfDay;

  return {
    familyId,
    childId,
    offsetMinutes,
    primaryMembershipId,
    deviceId: device.rows[0].id,
    deviceAuth: { authorization: `Device ${deviceCredential}` },
    timezoneOffsetMinutes: offsetMinutes,
  };
}

/** A window that contains the family's present minute, with room for a clock that ticks. */
function windowAroundNow(offsetMinutes, margin = W5_OFFSET_SAFETY_MARGIN_MINUTES) {
  const { minuteOfDay } = familyLocalParts(new Date(), offsetMinutes);
  return {
    startMinute: (minuteOfDay + 1440 - margin) % 1440,
    endMinute: (minuteOfDay + margin) % 1440,
  };
}

/** A one-minute window twelve hours away: a real bedtime that cannot interfere with a test. */
function windowAwayFromNow(offsetMinutes) {
  const { minuteOfDay } = familyLocalParts(new Date(), offsetMinutes);
  return {
    startMinute: (minuteOfDay + 720) % 1440,
    endMinute: (minuteOfDay + 721) % 1440,
  };
}

test('the family sets the minutes, the phone reports what it measured, and only entertainment is counted', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w5a');
        const { familyId, childId, deviceId, deviceAuth } = household;
        const childPath = `/v1/families/${familyId}/children/${childId}`;
        const screenPath = `${childPath}/screen-time`;
        const guard = (key) => authorized('test-primary', { 'idempotency-key': key });

        // 1. Before anybody decides anything, the read publishes the defaults and says so:
        //    `configured: false` with no version. A screen showing a bedtime here is showing
        //    the published default, not a value this family chose.
        const before = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.equal(before.status, 200);
        assert.equal(before.body.childId, childId);
        assert.equal(before.body.policy.configured, false);
        assert.equal(before.body.policy.version, null);
        assert.equal(before.body.policy.dailyLimitMinutes, 0);
        assert.equal(before.body.policy.timezoneOffsetMinutes, 180);
        assert.equal(before.body.state.capMinutes, null, 'no cap means no cap');
        assert.equal(before.body.lock, null);
        assert.equal(before.body.openRequest, null);
        assert.equal(before.body.usage.countableUsedMinutes, 0);

        // 2. Who may read it: the guardians, and nobody else. The child's own account is a
        //    member of the family and still cannot read a screen-time surface that cannot
        //    prove it is theirs; a co-guardian can, because a co-guardian is a parent here.
        const asChild = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-child') });
        assert.equal(asChild.status, 403);
        assert.equal(asChild.body.error.code, 'screen_time_forbidden');
        const asCoGuardian = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-co') });
        assert.equal(asCoGuardian.status, 200);
        const asStranger = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-stranger') });
        assert.equal(asStranger.status, 403);

        // A family cannot reach into another family's child either: the child must belong to
        // the family whose guardian is asking.
        const other = await jsonRequest(baseUrl, '/v1/families', {
          method: 'POST',
          headers: authorized('test-stranger', { 'idempotency-key': 'w5a-other-family' }),
          body: { displayName: 'عائلة أخرى' },
        });
        assert.equal(other.status, 201);
        const otherChild = await jsonRequest(baseUrl, `/v1/families/${other.body.family.id}/children`, {
          method: 'POST',
          headers: authorized('test-stranger', { 'idempotency-key': 'w5a-other-child' }),
          body: { displayName: 'طفل آخر', ageYears: 8, avatarEmoji: '🐬', themeColor: 'mint' },
        });
        assert.equal(otherChild.status, 201);
        const crossFamily = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${otherChild.body.child.id}/screen-time`,
          { headers: authorized('test-primary') },
        );
        assert.equal(crossFamily.status, 404);
        assert.equal(crossFamily.body.error.code, 'child_not_found');

        // 3. The policy: a family sets the cap and their own offset, and the fields they did
        //    not send keep what they had. The default bedtime is still the published one.
        const first = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-1'),
          body: { dailyLimitMinutes: 60, timezoneOffsetMinutes: household.timezoneOffsetMinutes },
        });
        assert.equal(first.status, 200);
        assert.equal(first.body.policy.dailyLimitMinutes, 60);
        assert.equal(first.body.policy.timezoneOffsetMinutes, household.timezoneOffsetMinutes);
        assert.equal(first.body.policy.version, 1);
        assert.equal(first.body.policy.bedtime.startMinute, 1260, 'an untouched field keeps its default');
        assert.equal(first.body.policy.bedtime.endMinute, 360);

        // The same key and the same body is the same intent: the stored answer comes back
        // and the version does not move. The same key with a different body is refused.
        const replay = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-1'),
          body: { dailyLimitMinutes: 60, timezoneOffsetMinutes: household.timezoneOffsetMinutes },
        });
        assert.equal(replay.status, 200);
        assert.equal(replay.body.policy.version, 1);
        const reused = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-1'),
          body: { dailyLimitMinutes: 90 },
        });
        assert.equal(reused.status, 409);
        assert.equal(reused.body.error.code, 'idempotency_key_reused');

        // A window with no length is refused by name, before the database has to say it.
        const emptyWindow = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-empty'),
          body: { bedtime: { startMinute: 600, endMinute: 600 } },
        });
        assert.equal(emptyWindow.status, 400);
        assert.equal(emptyWindow.body.error.code, 'screen_time_window_empty');

        // And a screen that read version 1 may not silently overwrite version 2.
        const bedtime = windowAwayFromNow(household.offsetMinutes);
        const second = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-2'),
          body: { bedtime },
        });
        assert.equal(second.status, 200);
        assert.equal(second.body.policy.version, 2);
        assert.equal(second.body.policy.dailyLimitMinutes, 60, 'the cap survives a bedtime change');
        assert.equal(second.body.policy.bedtime.startMinute, bedtime.startMinute);
        const stale = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-stale'),
          body: { dailyLimitMinutes: 30, expectedVersion: 1 },
        });
        assert.equal(stale.status, 409);
        assert.equal(stale.body.error.code, 'screen_time_stale_version');

        // 4. The handset reports what it measured and what is installed, in one call. The
        //    response is the same state a guardian reads, computed from the same rows.
        const report = (key, body) =>
          jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': key },
            body,
          });
        const firstReport = await report('w5a-report-1', {
          usage: [
            { appId: 'com.example.puzzle', usedMinutes: 30 },
            { appId: 'com.quran.tilawa', usedMinutes: 25 },
          ],
          apps: [
            { appId: 'com.example.puzzle', displayName: 'Puzzle', category: 'games' },
            { appId: 'com.quran.tilawa', displayName: 'تلاوة', category: 'edu' },
          ],
        });
        assert.equal(firstReport.status, 201);
        assert.equal(firstReport.body.childId, childId, 'the credential is what named the child');
        assert.equal(
          firstReport.body.state.countableUsedMinutes,
          30,
          'the Quran app is not entertainment and is not counted',
        );
        assert.equal(firstReport.body.state.remainingMinutes, 30);
        assert.equal(firstReport.body.state.kind, 'limited');
        assert.equal(firstReport.body.reportedRequest, null, 'this call asked for nothing');

        // An app nobody has ruled on is `pending`: visible, undecided, not silently allowed.
        const apps = (await jsonRequest(baseUrl, `${childPath}/apps`, {
          headers: authorized('test-primary'),
        })).body;
        const pending = apps.apps.find((entry) => entry.appId === 'com.example.puzzle');
        assert.equal(pending.rule, null);
        assert.equal(pending.knownOnDevice, true);
        assert.deepEqual(pending.decision, { allowed: false, reasonCode: 'awaiting_decision' });
        assert.equal(pending.countable, true);
        const education = apps.apps.find((entry) => entry.appId === 'com.quran.tilawa');
        assert.equal(education.countable, false, 'education is not entertainment');
        assert.equal(education.rule, null);
        assert.deepEqual(
          education.decision,
          { allowed: false, reasonCode: 'awaiting_decision' },
          'an app nobody has ruled on waits for a parent, whatever category it is',
        );

        // 3b. The rule surface. A limit on an app that does not count is refused by name; a
        //     limit that is reached stops that one app; and `unlimited` buys exemption from
        //     the cap - never from a block, and never from a bedtime.
        const rulePath = (appId) => `/v1/families/${familyId}/children/${childId}/apps/${appId}/rule`;
        const setRule = (appId, key, body) =>
          jsonRequest(baseUrl, rulePath(appId), {
            method: 'PUT',
            headers: guard(key),
            body,
          });
        const freeWithLimit = await setRule('com.example.puzzle', 'w5a-rule-bad', {
          status: 'free',
          limitMinutes: 30,
        });
        assert.equal(freeWithLimit.status, 400);
        assert.equal(freeWithLimit.body.error.code, 'invalid_request');
        const limited = await setRule('com.example.puzzle', 'w5a-rule-limit', {
          status: 'allowed',
          limitMinutes: 20,
        });
        assert.equal(limited.status, 200);
        assert.equal(limited.body.rule.limitMinutes, 20);
        assert.equal(limited.body.knownOnDevice, true);
        const limitReached = (await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/apps`,
          { headers: authorized('test-primary') },
        )).body.apps.find((entry) => entry.appId === 'com.example.puzzle');
        assert.deepEqual(limitReached.decision, { allowed: false, reasonCode: 'app_limit' });
        assert.equal(limitReached.remainingMinutes, 0);

        // A rule for an app the handset has never reported is still a family's decision: it
        // is kept, it is marked as not on the device, and it will apply the moment it is.
        const forGhost = await setRule('com.example.notes', 'w5a-rule-ghost', { status: 'free' });
        assert.equal(forGhost.status, 200);
        assert.equal(forGhost.body.knownOnDevice, false);
        assert.equal(forGhost.body.category, null);

        // The two rules the rest of this journey needs: the game allowed with no limit of its
        // own, and the Quran app allowed - education is not entertainment, so it costs no
        // minutes and only a lock can stop it.
        assert.equal((await setRule('com.example.puzzle', 'w5a-rule-clear', { status: 'allowed' })).status, 200);
        assert.equal((await setRule('com.quran.tilawa', 'w5a-rule-edu', { status: 'allowed' })).status, 200);
        const afterRules = (await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/apps`,
          { headers: authorized('test-primary') },
        )).body;
        assert.deepEqual(
          afterRules.apps.find((entry) => entry.appId === 'com.example.puzzle').decision,
          { allowed: true, reasonCode: null },
        );
        assert.deepEqual(
          afterRules.apps.find((entry) => entry.appId === 'com.quran.tilawa').decision,
          { allowed: true, reasonCode: null },
        );
        assert.equal(afterRules.state.countableUsedMinutes, 30, 'allowing education changed nothing in the cap');

        // The guardian's read and the handset's read are the same answer, compared field by
        // field rather than described: that is the difference between one rule and two.
        const guardianRead = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.deepEqual(guardianRead.body.state, firstReport.body.state);
        assert.deepEqual(guardianRead.body.usage, firstReport.body.usage);

        // 5. Minutes never shrink. A second report - a real one, with its own key - that
        //    carries a smaller number leaves the stored figure alone.
        const shrunk = await report('w5a-report-2', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 10 }],
        });
        assert.equal(shrunk.status, 201);
        assert.equal(shrunk.body.state.countableUsedMinutes, 30);
        // ...and the replay of the first report is the stored first answer, not a second
        // 30 minutes added on top of it.
        const replayedReport = await report('w5a-report-1', {
          usage: [
            { appId: 'com.example.puzzle', usedMinutes: 30 },
            { appId: 'com.quran.tilawa', usedMinutes: 25 },
          ],
          apps: [
            { appId: 'com.example.puzzle', displayName: 'Puzzle', category: 'games' },
            { appId: 'com.quran.tilawa', displayName: 'تلاوة', category: 'edu' },
          ],
        });
        assert.equal(replayedReport.status, 201);
        assert.equal(replayedReport.body.state.countableUsedMinutes, 30);
        const stored = await client.query(
          `SELECT used_minutes FROM family_child_app_usage_daily WHERE child_id = $1 ORDER BY app_id`,
          [childId],
        );
        assert.deepEqual(stored.rows.map((row) => row.used_minutes), [30, 25]);

        // A day the handset could not have measured is refused rather than filed.
        const impossibleDay = await report('w5a-report-old', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 5, date: '2020-01-01' }],
        });
        assert.equal(impossibleDay.status, 400);
        assert.equal(impossibleDay.body.error.code, 'invalid_request');

        // 6. The cap bites, and it bites the entertainment only.
        const exhausted = await report('w5a-report-3', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 60 }],
        });
        assert.equal(exhausted.status, 201);
        assert.equal(exhausted.body.state.kind, 'blocked');
        assert.equal(exhausted.body.state.reasonCode, 'daily_limit');
        assert.equal(exhausted.body.state.remainingMinutes, 0);
        const exhaustedApps = (await jsonRequest(baseUrl, `${childPath}/apps`, {
          headers: authorized('test-primary'),
        })).body;
        assert.deepEqual(
          exhaustedApps.apps.find((entry) => entry.appId === 'com.example.puzzle').decision,
          { allowed: false, reasonCode: 'daily_limit' },
        );
        assert.deepEqual(
          exhaustedApps.apps.find((entry) => entry.appId === 'com.quran.tilawa').decision,
          { allowed: true, reasonCode: null },
          'an exhausted entertainment budget does not stop the Quran app',
        );

        // An app the family exempted from the cap keeps working while the cap is spent - the
        // exemption is about how much, so the state can say "the day's entertainment is over"
        // while this one app still opens. That is exactly what `unlimited` promises.
        const exempted = await setRule('com.example.puzzle', 'w5a-rule-unlimited', {
          status: 'allowed',
          unlimited: true,
        });
        assert.equal(exempted.status, 200);
        const exemptedApps = (await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/apps`,
          { headers: authorized('test-primary') },
        )).body;
        assert.equal(exemptedApps.state.reasonCode, 'daily_limit');
        assert.deepEqual(
          exemptedApps.apps.find((entry) => entry.appId === 'com.example.puzzle').decision,
          { allowed: true, reasonCode: null },
        );
        assert.deepEqual(
          exemptedApps.apps.find((entry) => entry.appId === 'com.quran.tilawa').decision,
          { allowed: true, reasonCode: null },
        );
        assert.equal((await setRule('com.example.puzzle', 'w5a-rule-unlimited-off', { status: 'allowed' })).status, 200);

        // 7. The state is computed, not stored. Raising the cap clears "time is up" with no
        //    unlock call, no dismissal and nothing to go stale in between.
        const raised = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-3'),
          body: { dailyLimitMinutes: 120 },
        });
        assert.equal(raised.status, 200);
        const afterRaise = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.equal(afterRaise.body.state.kind, 'limited');
        assert.equal(afterRaise.body.state.reasonCode, null);
        assert.equal(afterRaise.body.state.remainingMinutes, 60);

        // 8. The family's clock decides. A bedtime that contains their present minute stops
        //    the entertainment and leaves education working - and a school morning behaves
        //    the same way, while the bedtime is the more specific truth when both apply.
        const bedtimeNow = windowAroundNow(household.offsetMinutes);
        const atBedtime = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-bedtime'),
          body: { bedtime: bedtimeNow },
        });
        assert.equal(atBedtime.status, 200);
        const bedtimeApps = (await jsonRequest(baseUrl, `${childPath}/apps`, {
          headers: authorized('test-primary'),
        })).body;
        assert.equal(bedtimeApps.state.reasonCode, 'bedtime');
        assert.deepEqual(
          bedtimeApps.apps.find((entry) => entry.appId === 'com.example.puzzle').decision,
          { allowed: false, reasonCode: 'bedtime' },
        );
        assert.deepEqual(
          bedtimeApps.apps.find((entry) => entry.appId === 'com.quran.tilawa').decision,
          { allowed: true, reasonCode: null },
          'the Quran app survives the bedtime',
        );

        const schoolNow = windowAroundNow(household.offsetMinutes);
        const atSchool = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-school'),
          body: {
            schoolMode: { enabled: true, days: [1, 2, 3, 4, 5, 6, 7], ...schoolNow },
          },
        });
        assert.equal(atSchool.status, 200);
        const bothWindows = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.equal(bothWindows.body.state.reasonCode, 'bedtime', 'the later window is the truth');

        // Move the bedtime away and the school window - which is still around the present
        // minute - is what a family sees.
        const movedBedtime = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-bedtime-2'),
          body: { bedtime: windowAwayFromNow(household.offsetMinutes) },
        });
        assert.equal(movedBedtime.status, 200);
        const schoolOnly = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.equal(schoolOnly.body.state.reasonCode, 'school_mode');
        assert.equal(
          schoolOnly.body.state.date,
          familyLocalParts(new Date(), household.timezoneOffsetMinutes).date,
          "the day is the family's own",
        );
        assert.ok(
          Math.abs(schoolOnly.body.state.minuteOfDay - 720) <= W5_OFFSET_SAFETY_MARGIN_MINUTES,
          'the family is living around noon in their own offset, not the server\'s',
        );

        // Leave the family where the second journey expects them: school mode off, a bedtime
        // twelve hours away, and the cap the guardian last chose.
        const settled = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5a-policy-settled'),
          body: {
            schoolMode: { enabled: false },
            bedtime: windowAwayFromNow(household.offsetMinutes),
          },
        });
        assert.equal(settled.status, 200);
        assert.equal(settled.body.policy.schoolMode.enabled, false);
        assert.equal(
          settled.body.policy.schoolMode.days.length > 0,
          true,
          'turning school mode off does not erase the school week the family chose',
        );

        // 9. The database is the last line of defence, and it holds even when the server is
        //    bypassed. Each of these is a product law, not a coincidence of one code path.
        const policyRow = await client.query(
          `SELECT child_id FROM family_child_screen_time_policies WHERE child_id = $1`,
          [childId],
        );
        assert.equal(policyRow.rowCount, 1, 'the family has exactly one policy row for this child');
        await assert.rejects(
          () => client.query(
            `UPDATE family_child_screen_time_policies SET daily_limit_minutes = 2000 WHERE child_id = $1`,
            [childId],
          ),
          /violates check constraint/i,
          'a day holds 1440 minutes and the schema says so',
        );
        await assert.rejects(
          () => client.query(
            `UPDATE family_child_screen_time_policies SET school_days = '{9}'::smallint[] WHERE child_id = $1`,
            [childId],
          ),
          /violates check constraint/i,
          'a weekday outside 1..7 is not a weekday',
        );
        await assert.rejects(
          () => client.query(
            `UPDATE family_child_screen_time_policies SET bedtime_start_minute = bedtime_end_minute WHERE child_id = $1`,
            [childId],
          ),
          /violates check constraint/i,
          'a window with no length is not a window',
        );
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_child_app_usage_daily (id, family_id, child_id, app_id, usage_date, used_minutes)
             VALUES (gen_random_uuid(), $1, $2, 'com.example.puzzle', CURRENT_DATE, 5)`,
            [familyId, childId],
          ),
          /duplicate key value violates unique constraint/i,
          'one row per app per day is what makes a cumulative figure trustworthy',
        );
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_child_app_rules
               (id, family_id, child_id, app_id, status, limit_minutes, updated_by_membership_id)
             VALUES (gen_random_uuid(), $1, $2, 'com.example.ghost', 'blocked', 30, $3)`,
            [familyId, childId, household.primaryMembershipId],
          ),
          /violates check constraint/i,
          'a limit on an app nobody counts is a number no screen would ever read',
        );

        // The state itself has no column anywhere: the only stored decisions are the ones a
        // person made (a rule, a lock, an answer), which is why nothing can go stale.
        const stateColumns = await client.query(
          `SELECT table_name, column_name FROM information_schema.columns
            WHERE table_name IN (
              'family_child_screen_time_policies', 'family_child_app_rules', 'family_child_apps',
              'family_child_app_usage_daily', 'family_child_lock_state', 'family_child_time_requests')
              AND column_name IN ('state', 'blocked', 'screen_state', 'time_is_up')`,
        );
        assert.equal(stateColumns.rowCount, 0);
      });
    } finally {
      await store.close();
    }
  });
});

test('the lock has an author, the question has an answer, and the credential is the only proof of which child', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w5b');
        const { familyId, childId, deviceId, deviceAuth } = household;
        const childPath = `/v1/families/${familyId}/children/${childId}`;
        const screenPath = `${childPath}/screen-time`;
        const guard = (key) => authorized('test-primary', { 'idempotency-key': key });
        const report = (key, body) =>
          jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': key },
            body,
          });

        // A cap, a bedtime twelve hours away, and the entertainment budget half spent.
        const policy = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5b-policy'),
          body: {
            dailyLimitMinutes: 60,
            timezoneOffsetMinutes: household.timezoneOffsetMinutes,
            bedtime: windowAwayFromNow(household.offsetMinutes),
          },
        });
        assert.equal(policy.status, 200);
        await report('w5b-report', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 30 }],
          apps: [{ appId: 'com.example.puzzle', displayName: 'Puzzle', category: 'games' }],
        });
        // The game gets a plain rule first, so what the lock assertions below observe is the
        // lock and not an app that was still waiting for a parent: `pending` is checked before
        // the clock, which is the point of `pending`.
        const allowedGame = await jsonRequest(
          baseUrl,
          `${childPath}/apps/com.example.puzzle/rule`,
          { method: 'PUT', headers: guard('w5b-rule'), body: { status: 'allowed' } },
        );
        assert.equal(allowedGame.status, 200);

        // 1. The lock. It names the reason and the guardian who pressed it, and it is the one
        //    state that stops everything - education included, because that is what a lock is.
        const locked = await jsonRequest(baseUrl, `${screenPath}/lock`, {
          method: 'POST',
          headers: guard('w5b-lock'),
          body: { reasonCode: 'check_in' },
        });
        assert.equal(locked.status, 200);
        assert.equal(locked.body.created, true);
        assert.equal(locked.body.state.kind, 'blocked');
        assert.equal(locked.body.state.reasonCode, 'instant_lock');
        assert.equal(locked.body.state.lock.reasonCode, 'check_in');
        assert.equal(locked.body.state.lock.lockedByMembershipId, household.primaryMembershipId);
        assert.equal(locked.body.state.since, locked.body.state.lock.lockedAt);
        assert.equal(locked.body.lock.releasedAt, null);
        const lockedApps = (await jsonRequest(baseUrl, `${childPath}/apps`, {
          headers: authorized('test-primary'),
        })).body;
        assert.deepEqual(
          lockedApps.apps.find((entry) => entry.appId === 'com.example.puzzle').decision,
          { allowed: false, reasonCode: 'instant_lock' },
        );

        // Pressing it twice finds the lock that exists rather than stacking a second one.
        const lockedAgain = await jsonRequest(baseUrl, `${screenPath}/lock`, {
          method: 'POST',
          headers: guard('w5b-lock-again'),
          body: { reasonCode: 'parent_lock' },
        });
        assert.equal(lockedAgain.status, 200);
        assert.equal(lockedAgain.body.created, false);
        assert.equal(lockedAgain.body.state.lock.id, locked.body.state.lock.id);
        assert.equal(lockedAgain.body.state.lock.reasonCode, 'check_in', 'the first decision stands');
        const liveLocks = await client.query(
          `SELECT id FROM family_child_lock_state WHERE child_id = $1 AND released_at IS NULL`,
          [childId],
        );
        assert.equal(liveLocks.rowCount, 1);
        // Even with the server out of the way, a second live lock is refused: the guarantee
        // is an index, not a check that could race with itself.
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_child_lock_state
               (id, family_id, child_id, reason_code, locked_by_membership_id)
             VALUES (gen_random_uuid(), $1, $2, 'parent_lock', $3)`,
            [familyId, childId, household.primaryMembershipId],
          ),
          /duplicate key value violates unique constraint|one_live_per_child/i,
        );

        // The child's own handset sees the lock, with the time it started.
        const deviceRead = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
          headers: deviceAuth,
        });
        assert.equal(deviceRead.status, 200);
        assert.equal(deviceRead.body.state.reasonCode, 'instant_lock');
        assert.equal(deviceRead.body.reportedRequest, null);
        assert.equal(deviceRead.body.apps.length, 1);

        // 2. Unlocking is answered honestly: the first call released something, the second
        //    released nothing, and neither is an error. The released episode stays on the
        //    record, because "the phone was off from 21:10" is a fact a family wants later.
        const released = await jsonRequest(baseUrl, `${screenPath}/unlock`, {
          method: 'POST',
          headers: guard('w5b-unlock'),
        });
        assert.equal(released.status, 200);
        assert.equal(released.body.released, true);
        assert.equal(released.body.state.reasonCode, null);
        assert.equal(released.body.state.kind, 'limited');
        const releasedAgain = await jsonRequest(baseUrl, `${screenPath}/unlock`, {
          method: 'POST',
          headers: guard('w5b-unlock-again'),
        });
        assert.equal(releasedAgain.status, 200);
        assert.equal(releasedAgain.body.released, false);
        const lockRows = await client.query(
          `SELECT released_at FROM family_child_lock_state WHERE child_id = $1`,
          [childId],
        );
        assert.equal(lockRows.rowCount, 1, 'the episode is kept, not deleted');
        assert.notEqual(lockRows.rows[0].released_at, null);

        // 3. The question. The child asks from their own handset, and the answer names the
        //    question exactly once: openRequest and reportedRequest are the same fact.
        const asked = await report('w5b-ask', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 30 }],
          request: { requestedMinutes: 20, reasonCode: 'homework_done' },
        });
        assert.equal(asked.status, 201);
        assert.equal(asked.body.reportedRequest.status, 'pending');
        assert.equal(asked.body.reportedRequest.requestedMinutes, 20);
        assert.equal(asked.body.reportedRequest.requestedByKind, 'child');
        assert.equal(asked.body.openRequest.id, asked.body.reportedRequest.id);
        const pendingId = asked.body.openRequest.id;

        // Asking again in another report finds the same open question rather than a second
        // one a parent would have to reconcile.
        const askedAgain = await report('w5b-ask-again', {
          usage: [{ appId: 'com.example.puzzle', usedMinutes: 30 }],
          request: { requestedMinutes: 60 },
        });
        assert.equal(askedAgain.status, 201);
        assert.equal(askedAgain.body.openRequest.id, pendingId);
        assert.equal(askedAgain.body.openRequest.requestedMinutes, 20, 'the question stands as asked');
        const openRows = await client.query(
          `SELECT count(*)::int AS open FROM family_child_time_requests
            WHERE child_id = $1 AND status = 'pending'`,
          [childId],
        );
        assert.equal(openRows.rows[0].open, 1);

        // A guardian asking on the child's behalf finds the question already open and is told
        // which one, instead of queueing a duplicate.
        const guardianAsk = await jsonRequest(baseUrl, `${childPath}/time-requests`, {
          method: 'POST',
          headers: guard('w5b-guardian-ask'),
          body: { requestedMinutes: 15 },
        });
        assert.equal(guardianAsk.status, 409);
        assert.equal(guardianAsk.body.error.code, 'time_request_pending');
        assert.equal(guardianAsk.body.error.details.requestId, pendingId);

        const list = await jsonRequest(baseUrl, `${childPath}/time-requests?status=pending`, {
          headers: authorized('test-primary'),
        });
        assert.equal(list.status, 200);
        assert.equal(list.body.requests.length, 1);
        assert.equal(list.body.requests[0].id, pendingId);

        // 4. The answer. A denial carries no minutes; a grant is never larger than the ask;
        //    the answer happens once.
        const denyWithMinutes = await jsonRequest(
          baseUrl,
          `${childPath}/time-requests/${pendingId}/decision`,
          {
            method: 'POST',
            headers: guard('w5b-deny-minutes'),
            body: { decision: 'deny', grantedMinutes: 5 },
          },
        );
        assert.equal(denyWithMinutes.status, 400);
        assert.equal(denyWithMinutes.body.error.code, 'invalid_request');

        const overGrant = await jsonRequest(baseUrl, `${childPath}/time-requests/${pendingId}/decision`, {
          method: 'POST',
          headers: guard('w5b-over-grant'),
          body: { decision: 'approve', grantedMinutes: 120 },
        });
        assert.equal(overGrant.status, 400);
        assert.equal(overGrant.body.error.code, 'screen_time_grant_exceeds_request');

        const approved = await jsonRequest(baseUrl, `${childPath}/time-requests/${pendingId}/decision`, {
          method: 'POST',
          headers: guard('w5b-approve'),
          body: { decision: 'approve', grantedMinutes: 20 },
        });
        assert.equal(approved.status, 200);
        assert.equal(approved.body.request.status, 'approved');
        assert.equal(approved.body.request.grantedMinutes, 20);
        assert.equal(approved.body.request.decidedByMembershipId, household.primaryMembershipId);

        // The granted minutes extend the day they were granted for, on the state a handset
        // reads as well as the state a parent reads.
        const afterGrant = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
          headers: deviceAuth,
        });
        assert.equal(afterGrant.status, 200);
        assert.equal(afterGrant.body.state.grantedMinutes, 20);
        assert.equal(afterGrant.body.state.remainingMinutes, 50);
        assert.equal(afterGrant.body.openRequest, null);

        const answeredTwice = await jsonRequest(
          baseUrl,
          `${childPath}/time-requests/${pendingId}/decision`,
          {
            method: 'POST',
            headers: guard('w5b-approve-again'),
            body: { decision: 'approve' },
          },
        );
        assert.equal(answeredTwice.status, 409);
        assert.equal(answeredTwice.body.error.code, 'time_request_decided');

        // 5. A question expires by the family's clock, not by a job that might not have run.
        const second = await jsonRequest(baseUrl, `${childPath}/time-requests`, {
          method: 'POST',
          headers: guard('w5b-guardian-ask-2'),
          body: { requestedMinutes: 15 },
        });
        assert.equal(second.status, 201);
        assert.equal(second.body.request.status, 'pending');
        await client.query(
          `UPDATE family_child_time_requests SET expires_at = NOW() - INTERVAL '1 minute' WHERE id = $1`,
          [second.body.request.id],
        );
        const expiredList = await jsonRequest(baseUrl, `${childPath}/time-requests`, {
          headers: authorized('test-primary'),
        });
        assert.equal(expiredList.status, 200, 'the list must answer with the family\'s own requests');
        const expired = expiredList.body.requests.find((entry) => entry.id === second.body.request.id);
        assert.equal(expired.status, 'expired');
        const expiredRead = await jsonRequest(baseUrl, screenPath, { headers: authorized('test-primary') });
        assert.equal(expiredRead.body.openRequest, null, 'an expired question is not waiting for anyone');
        const decideExpired = await jsonRequest(
          baseUrl,
          `${childPath}/time-requests/${second.body.request.id}/decision`,
          { method: 'POST', headers: guard('w5b-approve-expired'), body: { decision: 'approve' } },
        );
        assert.equal(decideExpired.status, 409);
        assert.equal(decideExpired.body.error.code, 'time_request_decided');
        // The database refuses the shape of a half-decided request too.
        await assert.rejects(
          () => client.query(
            `UPDATE family_child_time_requests SET status = 'approved' WHERE id = $1`,
            [second.body.request.id],
          ),
          /violates check constraint/i,
          'approval without minutes is not an approval',
        );
        // A question from a guardian has an author and a question from a handset has none:
        // both directions of the pairing are refused when they disagree.
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_child_time_requests
               (id, family_id, child_id, usage_date, requested_minutes, requested_by_kind,
                expires_at)
             VALUES (gen_random_uuid(), $1, $2, CURRENT_DATE, 10, 'guardian', NOW() + INTERVAL '1 hour')`,
            [familyId, childId],
          ),
          /violates check constraint/i,
          'a request attributed to a guardian must name the guardian',
        );
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_child_time_requests
               (id, family_id, child_id, usage_date, requested_minutes, requested_by_kind,
                requested_by_membership_id, expires_at)
             VALUES (gen_random_uuid(), $1, $2, CURRENT_DATE, 10, 'child', $3, NOW() + INTERVAL '1 hour')`,
            [familyId, childId, household.primaryMembershipId],
          ),
          /violates check constraint/i,
          "a request from the child's own handset does not name a guardian",
        );

        // 6. Extra minutes only exist under a cap. With no cap, "more minutes" is a number
        //    the server would never enforce, so the question is refused rather than recorded.
        const noCap = await jsonRequest(baseUrl, screenPath, {
          method: 'PATCH',
          headers: guard('w5b-policy-nocap'),
          body: { dailyLimitMinutes: 0 },
        });
        assert.equal(noCap.status, 200);
        const askWithoutCap = await jsonRequest(baseUrl, `${childPath}/time-requests`, {
          method: 'POST',
          headers: guard('w5b-ask-nocap'),
          body: { requestedMinutes: 15 },
        });
        assert.equal(askWithoutCap.status, 409);
        assert.equal(askWithoutCap.body.error.code, 'screen_time_no_cap');

        // 7. The device credential is the only proof of which child is reporting, and the
        //    routes carry no child id: a body that tries to supply one is refused, because a
        //    parameter a client can choose would be a way to point this surface at another
        //    family's child.
        const wrongCredential = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
          method: 'GET',
          headers: { authorization: 'Device w5b-not-the-credential-000000000000' },
        });
        assert.equal(wrongCredential.status, 403);
        assert.equal(wrongCredential.body.error.code, 'device_credential_rejected');
        const smuggledChild = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w5b-smuggle' },
          body: { childId, usage: [] },
        });
        assert.equal(smuggledChild.status, 400);
        assert.equal(smuggledChild.body.error.code, 'invalid_request');
        // Revoking goes through the surface, not around it: migration 008 requires a
        // revocation to carry its provenance, which is exactly the law a direct UPDATE here
        // would have to satisfy anyway.
        const revocation = await jsonRequest(
          baseUrl,
          `${childPath}/devices/${deviceId}/revocation`,
          {
            method: 'POST',
            headers: guard('w5b-revoke'),
            body: { reasonCode: 'replaced' },
          },
        );
        assert.equal(revocation.status, 200);
        const revoked = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/screen-time`, {
          headers: deviceAuth,
        });
        assert.equal(revoked.status, 403);
        assert.equal(revoked.body.error.code, 'device_credential_rejected');

        // 8. The trail. Every decision above reached the announcement queue, which is what
        //    lets the family's timeline show what happened rather than what was intended.
        const outbox = await client.query(
          `SELECT DISTINCT event_type FROM family_audit_events WHERE family_id = $1`,
          [familyId],
        );
        const queued = await client.query(
          `SELECT count(*)::int AS n FROM outbox_events
            WHERE aggregate_type = 'family' AND aggregate_id = $1`,
          [familyId],
        );
        assert.ok(queued.rows[0].n > 0, 'the announcement queue carries what the timeline shows');
        assert.ok(
          queued.rows[0].n >= outbox.rowCount,
          'every audit event queued an announcement for the family timeline',
        );
        for (const eventType of [
          'family.screen_time_policy_updated',
          'family.child_screen_locked',
          'family.child_screen_unlocked',
          'family.time_request_created',
          'family.time_request_approved',
        ]) {
          assert.ok(
            outbox.rows.some((row) => row.event_type === eventType),
            `${eventType} must reach the announcement queue`,
          );
        }
      });
    } finally {
      await store.close();
    }
  });
});

// ── W6 — WEB FILTER AND TAMPER RESISTANCE ──────────────────────────────────────────────
//
// The journey this wave has to survive, told the way a family would live it:
//
//   the father turns the categories on and blocks one host;
//   a second guardian's stale screen is refused rather than allowed to overwrite;
//   the child's handset fetches the policy it must apply and gets the same filter;
//   the child asks for one host, the father opens it for ten minutes, and it closes by
//   itself without anybody remembering to close it;
//   the handset reports that a VPN is running - and the family is told that, then told
//   nothing at all once the reports stop, because silence is not health.
//
// Every step runs against real PostgreSQL through the real routes. The two things most
// worth being wrong about are both asserted directly: that an expired approval needs no
// writer to expire it, and that a family is never shown `protected` on the strength of a
// report that stopped coming.

test('the filter a family set is the filter the child’s phone is handed, and a stale screen cannot overwrite it', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w6a');
        const { familyId, childId, deviceId, deviceAuth } = household;

        // 1. The father states the family's filter.
        const saved = await jsonRequest(baseUrl, `/v1/families/${familyId}/children/${childId}/web-filter`, {
          method: 'PATCH',
          headers: authorized('test-primary', { 'idempotency-key': 'w6a-policy-1' }),
          body: {
            level: 'strict',
            categories: ['adults', 'gambling', 'violence', 'social', 'games', 'streaming'],
            blockHosts: ['blocked.example.com'],
            dictionaryKeywords: ['casino'],
            expectedVersion: 0,
          },
        });
        assert.equal(saved.status, 200, JSON.stringify(saved.body));
        assert.deepEqual(saved.body.policy.enabledCategories, [
          'adults', 'gambling', 'violence', 'social', 'games', 'streaming',
        ]);
        assert.equal(saved.body.policy.version, 1, 'the first save is version one');

        // 2. A second guardian whose screen still shows version 0 is refused, so two phones
        //    cannot silently overwrite each other.
        const stale = await jsonRequest(baseUrl, `/v1/families/${familyId}/children/${childId}/web-filter`, {
          method: 'PATCH',
          headers: authorized('test-co', { 'idempotency-key': 'w6a-policy-stale' }),
          body: { categories: ['games'], expectedVersion: 0 },
        });
        assert.equal(stale.status, 409);
        assert.equal(stale.body.error.code, 'web_filter_stale_version');

        // 3. A category the server does not know is refused where it is named, rather than
        //    stored as a switch that does nothing.
        const unknown = await jsonRequest(baseUrl, `/v1/families/${familyId}/children/${childId}/web-filter`, {
          method: 'PATCH',
          headers: authorized('test-primary', { 'idempotency-key': 'w6a-policy-bad-key' }),
          body: { categories: ['crypto'], expectedVersion: 1 },
        });
        assert.equal(unknown.status, 422);
        assert.equal(unknown.body.error.code, 'web_filter_unknown_category');

        // 4. A host on both lists is refused: the block list resolves first, so the allow
        //    entry would be a line on a screen with no effect.
        const bothLists = await jsonRequest(baseUrl, `/v1/families/${familyId}/children/${childId}/web-filter`, {
          method: 'PATCH',
          headers: authorized('test-primary', { 'idempotency-key': 'w6a-policy-both' }),
          body: { allowHosts: ['blocked.example.com'], expectedVersion: 1 },
        });
        assert.equal(bothLists.status, 409);
        assert.equal(bothLists.body.error.code, 'web_filter_host_both_lists');

        // 5. The child's handset fetches the policy it must apply - through its credential,
        //    with no child id anywhere in the request - and gets the same filter.
        const onDevice = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter`, {
          headers: deviceAuth,
        });
        assert.equal(onDevice.status, 200, JSON.stringify(onDevice.body));
        assert.equal(onDevice.body.policy.level, 'strict');
        assert.deepEqual(onDevice.body.policy.blockHosts, ['blocked.example.com']);
        assert.equal(onDevice.body.policy.version, 1);
        assert.deepEqual(onDevice.body.policy.activeTempAllows, [], 'no doors are open yet');

        // 6. The father's preview and the child's filter agree, because both come from the
        //    same decision function: a blocked host, a category, a dictionary word, and a
        //    host nobody has an opinion about.
        const previewOf = async (host) => {
          const response = await jsonRequest(
            baseUrl,
            `/v1/families/${familyId}/children/${childId}/web-filter/evaluate?host=${encodeURIComponent(host)}`,
            { headers: authorized('test-primary') },
          );
          assert.equal(response.status, 200, JSON.stringify(response.body));
          return response.body;
        };
        assert.equal((await previewOf('blocked.example.com')).denySource, 'blocklist');
        assert.equal((await previewOf('games.example.com')).categoryKey, 'games');
        assert.equal((await previewOf('my-casino.example.com')).denySource, 'dictionary');
        assert.equal((await previewOf('school.example.com')).allowed, true);

        // 7. The child asks for one host, through its own door.
        const asked = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter/temp-allow-requests`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w6a-ask-1' },
          body: { host: 'games.example.com', minutes: 15, reason: 'واجب المدرسة' },
        });
        assert.equal(asked.status, 201, JSON.stringify(asked.body));
        const requestId = asked.body.request.id;
        assert.equal(asked.body.request.status, 'pending');
        assert.equal(asked.body.request.state, 'pending');

        // A question already waiting is not asked twice: two identical rows would mean the
        // guardians answer the same question twice and the child gets two doors.
        const askedAgain = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter/temp-allow-requests`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w6a-ask-2' },
          body: { host: 'games.example.com', minutes: 15 },
        });
        assert.equal(askedAgain.status, 409);
        assert.equal(askedAgain.body.error.code, 'web_filter_request_pending');

        // 8. The father opens it for fewer minutes than was asked. The child may not widen
        //    its own question, and the father may not widen it either.
        const answered = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows/${requestId}/decision`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w6a-decide-1' }),
            body: { decision: 'approve', grantedMinutes: 10 },
          },
        );
        assert.equal(answered.status, 200, JSON.stringify(answered.body));
        assert.equal(answered.body.request.state, 'active');
        assert.equal(answered.body.request.grantedMinutes, 10);
        assert.ok(answered.body.request.expiresAt, 'an approval always carries the minute it closes at');

        const widened = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter/temp-allow-requests`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w6a-ask-3' },
          body: { host: 'youtube.com', minutes: 15 },
        });
        assert.equal(widened.status, 201);
        const widenedDecision = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows/${widened.body.request.id}/decision`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w6a-decide-widen' }),
            body: { decision: 'approve', grantedMinutes: 60 },
          },
        );
        assert.equal(widenedDecision.status, 409);
        assert.equal(widenedDecision.body.error.code, 'web_filter_grant_exceeds_request');

        // 9. While the door is open the host is allowed for that child - and the opening is
        //    visible to the handset in the same read it uses for the policy.
        const openNow = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter`, { headers: deviceAuth });
        assert.deepEqual(openNow.body.policy.activeTempAllows, ['games.example.com']);
        assert.equal(
          (await jsonRequest(
            baseUrl,
            `/v1/families/${familyId}/children/${childId}/web-filter/evaluate?host=games.example.com`,
            { headers: authorized('test-primary') },
          )).body.allowed,
          true,
          'an open door is an allow, not a category denial',
        );

        // 10. And it closes with nobody writing anything: the row is moved into the past and
        //     the very next read reports `expired`, because the state is computed from the
        //     clock rather than stored.
        await client.query('UPDATE family_web_filter_temp_allows SET expires_at = NOW() - INTERVAL \'1 minute\' WHERE id = $1', [requestId]);
        const afterTheMinute = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows`,
          { headers: authorized('test-primary') },
        );
        assert.equal(afterTheMinute.status, 200);
        const closed = afterTheMinute.body.requests.find((row) => row.id === requestId);
        assert.equal(closed.status, 'approved', 'nothing rewrote the stored decision');
        assert.equal(closed.state, 'expired', 'the clock is the only thing that had to move');
        assert.deepEqual(afterTheMinute.body.activeHosts, []);
        assert.equal(
          (await jsonRequest(
            baseUrl,
            `/v1/families/${familyId}/children/${childId}/web-filter/evaluate?host=games.example.com`,
            { headers: authorized('test-primary') },
          )).body.denySource,
          'category',
          'once the door shuts, the category is what answers again',
        );

        // 11. An answered question cannot be answered again: a second answer would either
        //     extend a door nobody re-asked for or refuse something already open.
        const answeredTwice = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows/${requestId}/decision`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w6a-decide-again' }),
            body: { decision: 'deny' },
          },
        );
        assert.equal(answeredTwice.status, 409);
        assert.equal(answeredTwice.body.error.code, 'web_filter_request_decided');

        // 12. A guardian may ask on a child's behalf - a child who speaks rather than taps
        //     still gets a record - and only a guardian may answer.
        const onBehalf = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w6a-ask-by-guardian' }),
            body: { host: 'streaming.example.com', minutes: 20 },
          },
        );
        assert.equal(onBehalf.status, 201, JSON.stringify(onBehalf.body));
        const childCannotDecide = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${childId}/web-filter/temp-allows/${onBehalf.body.request.id}/decision`,
          {
            method: 'POST',
            headers: authorized('test-child', { 'idempotency-key': 'w6a-child-decides' }),
            body: { decision: 'approve' },
          },
        );
        assert.equal(childCannotDecide.status, 403, 'a child cannot open its own door');
        assert.equal(childCannotDecide.body.error.code, 'web_filter_forbidden');

        // 13. The handset testifies: a VPN is running. The family is told what was seen, and
        //     told which device saw it.
        const tamper = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/protection-reports`, {
          method: 'POST',
          headers: deviceAuth,
          body: { observedState: 'vpn_active', signals: ['vpn_active', 'proxy_detected'], detail: 'VPN v2' },
        });
        assert.equal(tamper.status, 201, JSON.stringify(tamper.body));
        assert.equal(tamper.body.health.state, 'at_risk');
        assert.equal(tamper.body.health.reason, 'vpn_active');
        assert.deepEqual(tamper.body.health.signals, ['vpn_active', 'proxy_detected']);

        const protection = await jsonRequest(baseUrl, `/v1/families/${familyId}/protection`, {
          headers: authorized('test-primary'),
        });
        assert.equal(protection.status, 200);
        const deviceView = protection.body.devices.find((row) => row.deviceId === deviceId);
        assert.equal(deviceView.state, 'at_risk');
        assert.equal(protection.body.counts.at_risk, 1);
        assert.equal(protection.body.counts.protected, 0);

        // 14. The handset reports again, healthy. The state follows the newest evidence,
        //     not the loudest older one.
        const healed = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/protection-reports`, {
          method: 'POST',
          headers: deviceAuth,
          body: { observedState: 'healthy', signals: [] },
        });
        assert.equal(healed.status, 201);
        assert.equal(healed.body.health.state, 'protected');

        // 15. The evidence is append-only: both reports are still there, so "when did this
        //     start?" has an answer rather than only the newest row.
        const history = await client.query(
          `SELECT observed_state FROM family_device_protection_reports WHERE device_id = $1 ORDER BY reported_at ASC`,
          [deviceId],
        );
        assert.deepEqual(history.rows.map((row) => row.observed_state), ['vpn_active', 'healthy']);

        // 16. Now the reports stop. The newest one is pushed past the freshness window - not
        //     deleted, not rewritten, just older - and the family is no longer told anything
        //     is protected. Silence is not health: this is the assertion the whole wave
        //     exists for.
        await client.query(
          `UPDATE family_device_protection_reports
              SET reported_at = NOW() - INTERVAL '3 hours'
            WHERE device_id = $1`,
          [deviceId],
        );
        const silent = await jsonRequest(baseUrl, `/v1/families/${familyId}/protection`, {
          headers: authorized('test-primary'),
        });
        assert.equal(silent.status, 200);
        const silentView = silent.body.devices.find((row) => row.deviceId === deviceId);
        assert.equal(silentView.state, 'unverified', 'a device that stopped speaking is not protected');
        assert.equal(silentView.reason, 'stale_report');
        assert.ok(silentView.ageMinutes >= 179, 'and the family can see how long the silence has lasted');
        assert.equal(silent.body.counts.protected, 0);
        assert.equal(silent.body.freshnessMinutes, 90);

        // 17. A revoked credential testifies about nothing at all. The cut goes through the
        //     real revocation path rather than a hand-written UPDATE, because migration 101
        //     requires provenance - a reason code and a person - and writing the column
        //     directly is exactly the shortcut that law exists to refuse.
        await deviceRevocationFor(store)({
          principal: { subject: 'test-primary' },
          familyId,
          childId,
          deviceId,
          reasonCode: 'stolen',
          idempotencyKey: 'w6a-revoke-device',
          requestHash: requestFingerprintFor('w6a-revoke-device'),
          correlationId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
        });
        const revoked = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/protection-reports`, {
          method: 'POST',
          headers: deviceAuth,
          body: { observedState: 'healthy', signals: [] },
        });
        assert.equal(revoked.status, 403);
        assert.equal(revoked.body.error.code, 'device_credential_rejected');
        const revokedRead = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/web-filter`, { headers: deviceAuth });
        assert.equal(revokedRead.status, 403, 'a cut-off handset cannot even fetch the filter');

        // 18. Everything the family did left a trail: the policy save, both reports, the
        //     question and the answer, each queued for the family timeline.
        const outbox = await client.query(
          `SELECT event_type FROM outbox_events
            WHERE aggregate_type = 'family' AND aggregate_id = $1`,
          [familyId],
        );
        const events = new Set(outbox.rows.map((row) => row.event_type));
        for (const eventType of [
          'family.web_filter_policy_updated',
          'family.web_filter_temp_allow_requested',
          'family.web_filter_temp_allow_approved',
          'family.device_protection_reported',
        ]) {
          assert.ok(events.has(eventType), `${eventType} must reach the announcement queue`);
        }
        const audit = await client.query(
          `SELECT count(*)::int AS n FROM family_audit_events
            WHERE family_id = $1 AND subject_type IN ('web_filter_policy', 'web_filter_temp_allow', 'device_protection')`,
          [familyId],
        );
        assert.ok(audit.rows[0].n >= 6, 'every command left an audit row, including the refusals that were audited');

        // 19. The schema refuses what the module refuses, from the other side: no approval
        //     without an end, no denial with one - so a row that reads like an open door
        //     cannot exist even if a future writer forgets.
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_web_filter_temp_allows
               (id, family_id, child_id, host, status, requested_minutes, granted_minutes,
                requested_by_membership_id, decided_by_membership_id, decided_at)
             VALUES (gen_random_uuid(), $1, $2, 'no-end.example.com', 'approved', 30, 10, $3, $3, NOW())`,
            [familyId, childId, household.primaryMembershipId],
          ),
          /approval_has_end/,
        );
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_web_filter_temp_allows
               (id, family_id, child_id, host, status, requested_minutes, granted_minutes, expires_at,
                requested_by_membership_id, decided_by_membership_id, decided_at)
             VALUES (gen_random_uuid(), $1, $2, 'denied-open.example.com', 'denied', 30, 10, NOW() + INTERVAL '10 minutes', $3, $3, NOW())`,
            [familyId, childId, household.primaryMembershipId],
          ),
          /denial_opens_nothing/,
        );
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_web_filter_policies (child_id, family_id, level, enabled_categories)
             VALUES ($1, $2, 'balanced', ARRAY['crypto'])`,
            [childId, familyId],
          ),
          /categories_known/,
        );
      });
    } finally {
      await store.close();
    }
  });
});

test('a chore is claimed by a child, confirmed by a guardian, and the points can never be paid twice', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w7a');
        const { familyId, childId, deviceId, deviceAuth, primaryMembershipId } = household;
        const tasksPath = `/v1/families/${familyId}/children/${childId}/tasks`;

        // 1. A guardian states the task and what it pays. From this moment the number lives
        //    on the task, and nothing that follows may restate it.
        const created = await jsonRequest(baseUrl, tasksPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w7a-task-1' }),
          body: { title: 'ترتيب الغرفة', note: 'الملابس في الخزانة', points: 15 },
        });
        assert.equal(created.status, 201, JSON.stringify(created.body));
        const taskId = created.body.task.id;
        assert.equal(created.body.task.points, 15);
        assert.equal(created.body.task.claim, null, 'nobody has said anything about it yet');

        // 2. The child's own handset reads what it has to do and what it has earned - one
        //    read, no child id anywhere, and a balance that starts at a real zero.
        const before = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks`, { headers: deviceAuth });
        assert.equal(before.status, 200, JSON.stringify(before.body));
        assert.equal(before.body.tasks.length, 1);
        assert.equal(before.body.points, 0);
        assert.deepEqual(before.body.entries, []);

        // 3. "I did it" - and nothing moves, because a claim is not an achievement.
        const claimed = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks/${taskId}/claim`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w7a-claim-1' },
          body: { note: 'خلصت' },
        });
        assert.equal(claimed.status, 201, JSON.stringify(claimed.body));
        assert.equal(claimed.body.claim.status, 'pending');
        assert.equal(claimed.body.claim.claimedByDeviceId, deviceId, 'the handset is the author');
        assert.equal(claimed.body.claim.pointsAwarded, null, 'a pending claim has awarded nothing');

        const afterClaim = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks`, { headers: deviceAuth });
        assert.equal(afterClaim.body.points, 0, 'the child pressing the button earned nothing yet');

        const ledgerAfterClaim = await client.query(
          `SELECT COUNT(*)::int AS entries FROM family_point_ledger WHERE family_id = $1 AND child_id = $2`,
          [familyId, childId],
        );
        assert.equal(ledgerAfterClaim.rows[0].entries, 0, 'the ledger is untouched by a claim');

        // 4. A second claim while one is open is refused rather than queued. The partial
        //    unique index is what makes this true even if two presses arrive together.
        const second = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks/${taskId}/claim`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w7a-claim-2' },
        });
        assert.equal(second.status, 409);
        assert.equal(second.body.error.code, 'task_claim_pending');

        // 5. The guardian's word. Note the body: a decision and a note, and no number.
        const confirmed = await jsonRequest(baseUrl, `${tasksPath}/${taskId}/decision`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w7a-decide-1' }),
          body: { decision: 'confirm' },
        });
        assert.equal(confirmed.status, 200, JSON.stringify(confirmed.body));
        assert.equal(confirmed.body.task.claim.status, 'confirmed');
        assert.equal(confirmed.body.task.claim.pointsAwarded, 15, 'copied from the task');
        assert.equal(confirmed.body.awarded.points, 15);
        assert.equal(confirmed.body.points.points, 15);

        const afterConfirm = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks`, { headers: deviceAuth });
        assert.equal(afterConfirm.body.points, 15, 'the child sees the points the guardian confirmed');
        assert.equal(afterConfirm.body.entries.length, 1);
        assert.equal(afterConfirm.body.entries[0].claimId, confirmed.body.task.claim.id);

        // 6. Answering again is refused, so a guardian who taps twice on a slow phone does
        //    not pay twice - and a fresh idempotency key does not open a second door.
        const again = await jsonRequest(baseUrl, `${tasksPath}/${taskId}/decision`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w7a-decide-2' }),
          body: { decision: 'confirm' },
        });
        assert.equal(again.status, 409);
        assert.equal(again.body.error.code, 'task_claim_not_pending');

        // 7. And the storage layer refuses it too, which is what makes the refusal a rule
        //    rather than a code path: the same claim cannot produce a second entry.
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_point_ledger (id, family_id, child_id, points, reason, claim_id, awarded_by_membership_id)
             VALUES (gen_random_uuid(), $1, $2, 15, 'task_confirmed', $3, $4)`,
            [familyId, childId, confirmed.body.task.claim.id, primaryMembershipId],
          ),
          /one_entry_per_claim/,
        );

        // 8. A number the client tries to send is refused as an unknown field: the reward is
        //    not something a caller may restate, and pretending otherwise would be the whole
        //    failure this wave exists to prevent.
        const deniedByWhom = await jsonRequest(baseUrl, `${tasksPath}/${taskId}/decision`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w7a-decide-points' }),
          body: { decision: 'confirm', points: 200 },
        });
        assert.equal(deniedByWhom.status, 400);
        assert.equal(deniedByWhom.body.error.code, 'invalid_request');

        // 9. The second cycle: the child claims again, and this time the guardian declines.
        //    Nothing is awarded, nothing is subtracted, and the task stays open.
        const claimedAgain = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks/${taskId}/claim`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w7a-claim-3' },
          body: { note: 'الثانية' },
        });
        assert.equal(claimedAgain.status, 201, 'a declined task can be claimed again');
        const declined = await jsonRequest(baseUrl, `${tasksPath}/${taskId}/decision`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w7a-decide-3' }),
          body: { decision: 'decline', note: 'الملابس ما زالت على الأرض' },
        });
        assert.equal(declined.status, 200, JSON.stringify(declined.body));
        assert.equal(declined.body.awarded, null, 'a decline awards nothing at all');
        assert.equal(declined.body.task.claim.status, 'declined');
        assert.equal(declined.body.task.claim.pointsAwarded, null);
        assert.equal(declined.body.points.points, 15, 'the balance is exactly what was earned');

        const afterDecline = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks`, { headers: deviceAuth });
        assert.equal(afterDecline.body.points, 15);
        assert.equal(afterDecline.body.entries.length, 1, 'a refusal wrote no entry');

        const taskRow = await client.query(
          `SELECT t.status AS task_status, c.status AS claim_status
             FROM family_tasks t
             JOIN family_task_claims c ON c.task_id = t.id AND c.status = 'declined'
            WHERE t.id = $1`,
          [taskId],
        );
        assert.equal(taskRow.rows[0].task_status, 'open', 'the child can try again tomorrow');

        // 10. The schema itself refuses half a decision. A pending claim cannot carry a
        //     number and a decision time, and a declined one cannot carry a number at all -
        //     so a future code path that tried either is refused by the database rather than
        //     by a convention someone has to remember.
        const openCycle = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks/${taskId}/claim`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w7a-claim-4' },
        });
        assert.equal(openCycle.status, 201, 'the task is still open for this child');
        await assert.rejects(
          () => client.query(
            `UPDATE family_task_claims SET points_awarded = 15 WHERE id = $1`,
            [openCycle.body.claim.id],
          ),
          /pending_unanswered/,
        );
        await assert.rejects(
          () => client.query(
            `UPDATE family_task_claims SET status = 'declined', decided_by_membership_id = $2,
                    decided_at = NOW(), points_awarded = 3 WHERE id = $1`,
            [openCycle.body.claim.id, primaryMembershipId],
          ),
          /declined_awards_nothing/,
        );

        // 11. The device credential is the only proof of which child is asking.
        const wrongCredential = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/tasks`, {
          headers: { authorization: `Device ${'z'.repeat(32)}` },
        });
        assert.equal(wrongCredential.status, 403);
        assert.equal(wrongCredential.body.error.code, 'device_credential_rejected');

        // 12. A child may not read the family's tasks as a guardian, and may not answer them.
        const childReading = await jsonRequest(baseUrl, tasksPath, { headers: authorized('test-child') });
        assert.equal(childReading.status, 403);
        assert.equal(childReading.body.error.code, 'task_forbidden');
        const childAnswering = await jsonRequest(baseUrl, `${tasksPath}/${taskId}/decision`, {
          method: 'POST',
          headers: authorized('test-child', { 'idempotency-key': 'w7a-child-decide' }),
          body: { decision: 'confirm' },
        });
        assert.equal(childAnswering.status, 403);
        assert.equal(childAnswering.body.error.code, 'task_forbidden');

        // 13. And what the family reads is what the ledger holds: one entry, fifteen points,
        //     attributed to the guardian who confirmed it.
        const points = await jsonRequest(baseUrl, `/v1/families/${familyId}/children/${childId}/points`, {
          headers: authorized('test-primary'),
        });
        assert.equal(points.status, 200);
        assert.equal(points.body.points, 15);
        assert.equal(points.body.entries[0].awardedByMembershipId, primaryMembershipId);
      });
    } finally {
      await store.close();
    }
  });
});

// ── W8 — THE FAMILY CALENDAR, AGAINST REAL POSTGRESQL ─────────────────────────────────────
//
// The wave's subject is not protection but attendance, and that is where a family product can
// start inventing facts. This journey drives the real HTTP surface against the real schema and
// checks the four claims a calendar app has to be able to make without flinching:
//
//   1. What the family agreed to is what every reader sees - the same audience, the same
//      answer, the same cancellation - because there is one row and no second copy of a fact.
//   2. An answer has exactly one author, and a handset answers only for its own child. The
//      sibling test here is not decorative: it is the difference between a family app and a
//      surveillance tool.
//   3. What happened is recorded after it happened, by a person, and a retry of that tap
//      cannot move the moment it was recorded.
//   4. The schema refuses from below what the module refuses from above, so a future code path
//      that forgets a rule is stopped by the database rather than by a convention.

test('a family states an evening, a child answers from their own handset, and what happened is recorded after it did', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w8a');
        const { familyId, childId, deviceId, deviceAuth, primaryMembershipId } = household;
        const eventsPath = `/v1/families/${familyId}/events`;
        const now = Date.now();
        const windowQuery = `?from=${new Date(now - 24 * 3600 * 1000).toISOString()}&to=${new Date(now + 72 * 3600 * 1000).toISOString()}`;

        // A second child, so this journey can prove the handset cannot answer for a sibling.
        const sibling = await jsonRequest(baseUrl, `/v1/families/${familyId}/children`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-sibling' }),
          body: { displayName: 'بشير', ageYears: 13, avatarEmoji: '🐯', themeColor: 'teal' },
        });
        assert.equal(sibling.status, 201, JSON.stringify(sibling.body));
        const siblingId = sibling.body.child.id;
        const guardians = await client.query(
          `SELECT target_subject, id FROM family_memberships
            WHERE family_id = $1 AND role IN ('primary_guardian', 'co_guardian')`,
          [familyId],
        );
        const coMembershipId = guardians.rows.find((row) => row.target_subject === 'test-co').id;

        // 1. A guardian states the evening and names who it is for, in one request. The
        //    audience is written by the same transaction as the plan, so no reader can ever
        //    observe an event that nobody was invited to.
        const startsAt = new Date(now + 26 * 3600 * 1000).toISOString();
        const endsAt = new Date(now + 28 * 3600 * 1000).toISOString();
        const createBody = {
          title: 'زيارة الجدّ',
          note: 'نأخذ الكيك',
          location: 'بيت الجدّ',
          startsAt,
          endsAt,
          allDay: false,
          reminderMinutes: 60,
          childIds: [childId, siblingId],
        };
        const created = await jsonRequest(baseUrl, eventsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-event' }),
          body: createBody,
        });
        assert.equal(created.status, 201, JSON.stringify(created.body));
        const eventId = created.body.event.id;
        assert.equal(created.body.event.version, 1);
        assert.equal(created.body.event.status, 'scheduled');
        assert.equal(created.body.event.audience.length, 2, 'both children were invited');
        assert.equal(created.body.event.createdByMembershipId, primaryMembershipId);
        assert.equal(created.body.event.reminderMinutes, 60, 'a recorded preference');
        // The reminder is a preference, not a delivery: nothing in the payload says a phone
        // was told anything, because this wave has no way to know.
        assert.equal(
          /notif|deliver|sent|push|seen/i.test(JSON.stringify(created.body.event)),
          false,
          'an event payload that mentioned delivery would be claiming something nobody measured',
        );

        // 2. Replaying the request with the same key is the same evening, not a second one.
        const replayed = await jsonRequest(baseUrl, eventsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-event' }),
          body: createBody,
        });
        assert.ok([200, 201].includes(replayed.status), `replay answered ${replayed.status}`);
        assert.equal(replayed.body.event.id, eventId);
        const eventCount = await client.query(
          `SELECT COUNT(*)::int AS n FROM family_events WHERE family_id = $1`,
          [familyId],
        );
        assert.equal(eventCount.rows[0].n, 1, 'a replayed event created a second plan');

        // 3. The guardian's calendar for the week shows the plan with its invitations - the
        //    family asks "what is on, and who is coming", which is one question.
        const listed = await jsonRequest(baseUrl, `${eventsPath}${windowQuery}`, {
          headers: authorized('test-primary'),
        });
        assert.equal(listed.status, 200, JSON.stringify(listed.body));
        assert.equal(listed.body.events.length, 1);
        assert.equal(listed.body.events[0].audience.length, 2);
        assert.equal(listed.body.events[0].audience[0].response, null, 'nobody has answered yet');

        // 4. The child's own handset sees the invitation - and sees no list of siblings.
        const deviceRead = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events${windowQuery}`, {
          headers: deviceAuth,
        });
        assert.equal(deviceRead.status, 200, JSON.stringify(deviceRead.body));
        assert.equal(deviceRead.body.events.length, 1);
        assert.equal(deviceRead.body.events[0].id, eventId);
        assert.equal('audience' in deviceRead.body.events[0], false);
        assert.equal(
          JSON.stringify(deviceRead.body).includes(siblingId),
          false,
          "the child's own payload must not name their sibling",
        );

        // 5. The child answers "no" from their own handset. A no is stored as completely as a
        //    yes: same row, same author, same moment, note and all.
        const declined = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events/${eventId}/response`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w8a-answer-1' },
          body: { response: 'declined', note: 'عندي تدريب' },
        });
        assert.equal(declined.status, 200, JSON.stringify(declined.body));
        assert.equal(declined.body.response.response, 'declined');
        assert.equal(declined.body.response.note, 'عندي تدريب');
        assert.equal(declined.body.response.respondedByDeviceId, deviceId);
        assert.equal(declined.body.response.respondedByMembershipId, null, 'exactly one author');

        // 6. A second answer is a change of mind on the same row, not a second voice.
        const accepted = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events/${eventId}/response`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w8a-answer-2' },
          body: { response: 'accepted' },
        });
        assert.equal(accepted.status, 200, JSON.stringify(accepted.body));
        assert.equal(accepted.body.response.response, 'accepted');
        const answerRows = await client.query(
          `SELECT COUNT(*)::int AS n FROM family_event_responses
            WHERE event_id = $1 AND child_id = $2`,
          [eventId, childId],
        );
        assert.equal(answerRows.rows[0].n, 1, 'one child, one answer, however many times they changed it');

        // 7. An event the sibling alone is invited to. The handset of the other child cannot
        //    answer it, and could not even if a future code path let the request through: the
        //    response table's foreign key points at the invitation row.
        const siblingEvent = await jsonRequest(baseUrl, eventsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-sibling-event' }),
          body: {
            title: 'تدريب بشير',
            startsAt,
            endsAt,
            childIds: [siblingId],
          },
        });
        assert.equal(siblingEvent.status, 201, JSON.stringify(siblingEvent.body));
        const siblingEventId = siblingEvent.body.event.id;
        const stolen = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events/${siblingEventId}/response`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w8a-steal' },
          body: { response: 'declined' },
        });
        assert.equal(stolen.status, 403, JSON.stringify(stolen.body));
        assert.equal(stolen.body.error.code, 'event_not_invited');
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_event_responses
               (id, family_id, event_id, child_id, response, note, responded_by_device_id)
             VALUES (gen_random_uuid(), $1, $2, $3, 'declined', '', $4)`,
            [familyId, siblingEventId, childId, deviceId],
          ),
          /family_event_responses_invited_fk/,
          'storage must refuse an answer to an invitation that was never issued',
        );

        // 8. The guardian records the answer the sibling gave in words. The author of that row
        //    is the guardian, and no field in the request can say otherwise.
        const forSibling = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/children/${siblingId}/events/${siblingEventId}/response`,
          {
            method: 'POST',
            headers: authorized('test-co', { 'idempotency-key': 'w8a-sibling-answer' }),
            body: { response: 'accepted', note: 'قال إنه سيأتي' },
          },
        );
        assert.equal(forSibling.status, 200, JSON.stringify(forSibling.body));
        assert.equal(forSibling.body.response.respondedByMembershipId, coMembershipId);
        assert.equal(forSibling.body.response.respondedByDeviceId, null);

        // 9. An edit states the version it read. The first one lands; the second guardian's
        //    stale screen collides loudly instead of silently rewriting the evening.
        const moved = await jsonRequest(baseUrl, `${eventsPath}/${eventId}`, {
          method: 'PATCH',
          headers: authorized('test-co'),
          body: { version: 1, location: 'بيت العمّ' },
        });
        assert.equal(moved.status, 200, JSON.stringify(moved.body));
        assert.equal(moved.body.event.version, 2);
        assert.equal(moved.body.event.location, 'بيت العمّ');
        const stale = await jsonRequest(baseUrl, `${eventsPath}/${eventId}`, {
          method: 'PATCH',
          headers: authorized('test-primary'),
          body: { version: 1, location: 'مكان آخر' },
        });
        assert.equal(stale.status, 409, JSON.stringify(stale.body));
        assert.equal(stale.body.error.code, 'event_stale_version');

        // 10. A child who already answered cannot be unticked out of the plan - an answer is a
        //     fact with an author, and an edit may not delete it by deleting its row. And the
        //     refusal undoes the whole edit, version bump included, because it is one
        //     transaction and not a series of hopeful statements.
        const uninvite = await jsonRequest(baseUrl, `${eventsPath}/${eventId}`, {
          method: 'PATCH',
          headers: authorized('test-primary'),
          body: { version: 2, childIds: [siblingId] },
        });
        assert.equal(uninvite.status, 409, JSON.stringify(uninvite.body));
        assert.equal(uninvite.body.error.code, 'event_audience_answered');
        const survived = await client.query(
          `SELECT version, location FROM family_events WHERE id = $1`,
          [eventId],
        );
        assert.equal(survived.rows[0].version, 2, 'the refused edit must not have moved the version');
        assert.equal(survived.rows[0].location, 'بيت العمّ');
        const audienceAfter = await client.query(
          `SELECT COUNT(*)::int AS n FROM family_event_audience WHERE event_id = $1`,
          [eventId],
        );
        assert.equal(audienceAfter.rows[0].n, 2, 'nobody was quietly removed');

        // 11. Attendance before the event starts: there is nothing to record yet, only
        //     something to promise - and this surface does not store promises about people.
        const early = await jsonRequest(baseUrl, `${eventsPath}/${eventId}/attendance`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-early' }),
          body: { childId, attended: true },
        });
        assert.equal(early.status, 409, JSON.stringify(early.body));
        assert.equal(early.body.error.code, 'event_not_started');

        // 12. An event that has just begun may have what happened recorded - by a person.
        const beganStarts = new Date(now - 2 * 60 * 1000).toISOString();
        const beganEnds = new Date(now + 60 * 60 * 1000).toISOString();
        const beganEvent = await jsonRequest(baseUrl, eventsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-began' }),
          body: { title: 'العشاء العائلي', startsAt: beganStarts, endsAt: beganEnds, childIds: [childId, siblingId] },
        });
        assert.equal(beganEvent.status, 201, JSON.stringify(beganEvent.body));
        const beganId = beganEvent.body.event.id;
        const attended = await jsonRequest(baseUrl, `${eventsPath}/${beganId}/attendance`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-attend' }),
          body: { childId, attended: true },
        });
        assert.equal(attended.status, 200, JSON.stringify(attended.body));
        assert.equal(attended.body.attendance.attended, true);
        assert.equal(attended.body.attendance.recordedByMembershipId, primaryMembershipId);

        // A flaky tap replayed: the same fact, and the moment it was recorded cannot move,
        // because `recorded_at` is part of what the family said happened.
        const retried = await jsonRequest(baseUrl, `${eventsPath}/${beganId}/attendance`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-attend' }),
          body: { childId, attended: true },
        });
        assert.equal(retried.body.attendance.recordedAt, attended.body.attendance.recordedAt);
        const attendanceRows = await client.query(
          `SELECT COUNT(*)::int AS n FROM family_event_attendance WHERE event_id = $1`,
          [beganId],
        );
        assert.equal(attendanceRows.rows[0].n, 1, 'one child, one attendance record');

        // And the child who did not come is recorded as fully as the one who did: an absence
        // is not the absence of a record.
        const absent = await jsonRequest(baseUrl, `${eventsPath}/${beganId}/attendance`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-attend-absent' }),
          body: { childId: siblingId, attended: false, note: 'كان مريضاً' },
        });
        assert.equal(absent.status, 200, JSON.stringify(absent.body));
        assert.equal(absent.body.attendance.attended, false);
        assert.equal(absent.body.attendance.note, 'كان مريضاً');

        // A child may not record what happened, even about themselves: presence stated by a
        // guardian is a family's record, presence inferred from a phone is surveillance.
        const childRecording = await jsonRequest(baseUrl, `${eventsPath}/${beganId}/attendance`, {
          method: 'POST',
          headers: authorized('test-child', { 'idempotency-key': 'w8a-child-attend' }),
          body: { childId, attended: true },
        });
        assert.equal(childRecording.status, 403, JSON.stringify(childRecording.body));
        assert.equal(childRecording.body.error.code, 'event_forbidden');

        // 13. The handset reads what was recorded about its own child, and nothing about the
        //     sibling whose absence was recorded in the same event.
        const afterFacts = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events${windowQuery}`, {
          headers: deviceAuth,
        });
        const ownEvent = afterFacts.body.events.find((entry) => entry.id === eventId);
        assert.equal(ownEvent.response.response, 'accepted', 'the change of mind is what the child sees');
        const ownAttendance = afterFacts.body.events.find((entry) => entry.id === beganId);
        assert.equal(ownAttendance.attendance.attended, true);
        assert.equal(
          JSON.stringify(afterFacts.body).includes('كان مريضاً'),
          false,
          "the sibling's absence is not this child's business",
        );

        // 14. Calling the training off: an act with an author, a reason and a moment - once.
        const cancelled = await jsonRequest(baseUrl, `${eventsPath}/${siblingEventId}/cancel`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-cancel' }),
          body: { reason: 'المدرّب مريض' },
        });
        assert.equal(cancelled.status, 200, JSON.stringify(cancelled.body));
        assert.equal(cancelled.body.event.status, 'cancelled');
        assert.equal(cancelled.body.event.cancelReason, 'المدرّب مريض');
        assert.equal(cancelled.body.event.cancelledByMembershipId, primaryMembershipId);
        assert.ok(cancelled.body.event.cancelledAt, 'a cancellation has a moment');
        assert.equal(cancelled.body.event.audience.length, 1, 'the invitation survives the cancellation');
        assert.equal(
          cancelled.body.event.audience[0].response.response,
          'accepted',
          'and so does the answer that was given before it was called off',
        );
        const cancellingAgain = await jsonRequest(baseUrl, `${eventsPath}/${siblingEventId}/cancel`, {
          method: 'POST',
          headers: authorized('test-co', { 'idempotency-key': 'w8a-cancel-2' }),
          body: { reason: 'وأيضاً' },
        });
        assert.equal(cancellingAgain.status, 409, JSON.stringify(cancellingAgain.body));
        assert.equal(cancellingAgain.body.error.code, 'event_already_cancelled');

        // A cancelled event is not edited, and nothing is recorded about it.
        const editCancelled = await jsonRequest(baseUrl, `${eventsPath}/${siblingEventId}`, {
          method: 'PATCH',
          headers: authorized('test-primary'),
          body: { version: 1, title: 'شيء آخر' },
        });
        assert.equal(editCancelled.status, 409, JSON.stringify(editCancelled.body));
        assert.equal(editCancelled.body.error.code, 'event_cancelled');
        const attendanceOnCancelled = await jsonRequest(baseUrl, `${eventsPath}/${siblingEventId}/attendance`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w8a-cancelled-attend' }),
          body: { childId: siblingId, attended: true },
        });
        assert.equal(attendanceOnCancelled.status, 409, JSON.stringify(attendanceOnCancelled.body));
        assert.equal(attendanceOnCancelled.body.error.code, 'event_cancelled');

        // 15. The calendar still shows what was called off, with the reason - a hidden
        //     cancellation is a child standing at the door.
        const afterCancel = await jsonRequest(baseUrl, `${eventsPath}${windowQuery}`, {
          headers: authorized('test-primary'),
        });
        assert.equal(afterCancel.body.events.length, 3);
        const shown = afterCancel.body.events.find((entry) => entry.id === siblingEventId);
        assert.equal(shown.status, 'cancelled');
        assert.equal(shown.cancelReason, 'المدرّب مريض');

        // 16. The child cannot read the family calendar as a guardian, and a handset that
        //     cannot prove its credential proves nothing at all.
        const childReading = await jsonRequest(baseUrl, `${eventsPath}${windowQuery}`, {
          headers: authorized('test-child'),
        });
        assert.equal(childReading.status, 403, JSON.stringify(childReading.body));
        assert.equal(childReading.body.error.code, 'event_forbidden');
        const wrongCredential = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/events${windowQuery}`, {
          headers: { authorization: `Device ${'z'.repeat(32)}` },
        });
        assert.equal(wrongCredential.status, 403, JSON.stringify(wrongCredential.body));
        assert.equal(wrongCredential.body.error.code, 'device_credential_rejected');

        // 17. The schema refuses from below what the module refuses from above.
        //   a. An event that ends before it starts is a typo wearing a schedule's clothes.
        await assert.rejects(
          () => client.query(
            `INSERT INTO family_events (id, family_id, title, starts_at, ends_at, created_by_membership_id)
             VALUES (gen_random_uuid(), $1, 'قلب الساعة', NOW() + INTERVAL '2 hours', NOW() + INTERVAL '1 hour', $2)`,
            [familyId, primaryMembershipId],
          ),
          /family_events_instant_ordered/,
        );
        //   b. A cancellation that is missing its author, its reason or its moment is not a
        //      cancellation: the three arrive together or not at all.
        await assert.rejects(
          () => client.query(`UPDATE family_events SET status = 'cancelled' WHERE id = $1`, [eventId]),
          /family_events_cancellation_complete/,
        );
        //   c. An answer with two authors cannot exist, whoever writes it.
        await assert.rejects(
          () => client.query(
            `UPDATE family_event_responses SET responded_by_membership_id = $1
              WHERE event_id = $2 AND child_id = $3`,
            [primaryMembershipId, eventId, childId],
          ),
          /family_event_responses_one_author/,
        );
        //   d. A reminder outside what a day can hold is refused by the column itself.
        await assert.rejects(
          () => client.query(`UPDATE family_events SET reminder_minutes = 99999 WHERE id = $1`, [eventId]),
          /reminder_minutes/,
        );
        //   e. Attendance always has an author: a claim about the past without a person who
        //      made it is exactly the kind of row this product refuses to hold.
        await assert.rejects(
          () => client.query(
            `UPDATE family_event_attendance SET recorded_by_membership_id = NULL WHERE event_id = $1`,
            [beganId],
          ),
          /not-null/,
        );
        //   f. And there is no table of reminders sent, no notification log and no "seen"
        //      receipt: the wave that can honestly claim delivery will store delivery.
        const noNotificationTable = await client.query(
          `SELECT to_regclass('public.family_event_notifications') AS name`,
        );
        assert.equal(noNotificationTable.rows[0].name, null);

        // 18. What the family reads last is what storage holds: three plans, one of them
        //     cancelled with its author, two answers each with exactly one author, and the
        //     attendance that was actually recorded - by a person, after the fact.
        const final = await client.query(
          `SELECT e.status,
                  (SELECT COUNT(*)::int FROM family_event_responses r WHERE r.event_id = e.id) AS answers,
                  (SELECT COUNT(*)::int FROM family_event_attendance a WHERE a.event_id = e.id) AS attendance
             FROM family_events e
            WHERE e.family_id = $1
            ORDER BY e.title`,
          [familyId],
        );
        assert.equal(final.rows.length, 3);
        assert.equal(final.rows.filter((row) => row.status === 'cancelled').length, 1);
        // The evening carries one answer - the child's own, from their handset - and no
        // attendance, because it has not happened yet. The began dinner carries two
        // attendance records and no answers: nobody answers what is already over. And the
        // cancelled training keeps the one answer it received before it was called off.
        // Each fact landed on the event it belongs to and nowhere else.
        assert.deepEqual(
          final.rows.map((row) => [row.answers, row.attendance]).sort((left, right) => left[0] - right[0]),
          [[0, 2], [1, 0], [1, 0]],
          'answers and attendance are per event, and each lands where it was recorded',
        );
        const authors = await client.query(
          `SELECT r.child_id, r.responded_by_device_id, r.responded_by_membership_id
             FROM family_event_responses r
            WHERE r.family_id = $1
            ORDER BY r.child_id`,
          [familyId],
        );
        assert.equal(authors.rows.length, 2);
        for (const row of authors.rows) {
          assert.equal(
            (row.responded_by_device_id == null) !== (row.responded_by_membership_id == null),
            true,
            'exactly one author per answer, in storage and not only in the module',
          );
        }
      });
    } finally {
      await store.close();
    }
  });
});

// ── W9 — THE FAMILY CHAT, AGAINST REAL POSTGRESQL ─────────────────────────────────────────
//
// The wave whose subject is the one thing a family writes down about each other. This journey
// drives the real HTTP surface against the real schema and checks the five claims a family chat
// has to be able to make without flinching:
//
//   1. The room is the permission. A guardian in the household room reads it; the same guardian
//      is answered as if a room they were not added to did not exist - and a child's handset
//      cannot reach the household room at all.
//   2. An author comes from how the request arrived. The handset writes as its own child, the
//      person as their membership, and neither can write in a room that does not name them.
//   3. Ordering is the server's, and a resend is the same message: one row, one sequence number,
//      `replayed: true` - not a second copy of what somebody said.
//   4. An edit is visible and deletion is a right: the author edits and the old body survives in
//      the revisions table; only the author deletes, and the deleted row keeps its sequence and
//      its trace while the text is gone.
//   5. The schema refuses from below what the module refuses from above - a message from outside
//      the room and a live message with no text are both stopped by the database itself.

test('a family talks in a room it was added to, the child answers from their own handset, and the trace outlives the text', { skip }, async () => {
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
        const household = await seedScreenTimeFamily(baseUrl, client, 'w9a');
        const { familyId, childId, primaryMembershipId, deviceId, deviceAuth } = household;
        const threadsPath = `/v1/families/${familyId}/chat/threads`;
        const invitedGuardian = await jsonRequest(
          baseUrl,
          `/v1/families/${familyId}/memberships`,
          {
            method: 'POST',
            headers: authorized('test-primary', {
              'idempotency-key': 'w9a-invite-pending-guardian',
            }),
            body: { role: 'co_guardian', targetSubject: 'test-pending-guardian' },
          },
        );
        assert.equal(invitedGuardian.status, 201);
        assert.equal(invitedGuardian.body.membership.status, 'invited');
        const pendingMembershipId = invitedGuardian.body.membership.id;
        const guardians = await client.query(
          `SELECT id, target_subject, status FROM family_memberships
            WHERE family_id = $1 AND role IN ('primary_guardian', 'co_guardian')`,
          [familyId],
        );
        const coMembershipId = guardians.rows.find((row) => row.target_subject === 'test-co').id;
        const selectedGuardians = await jsonRequest(baseUrl, threadsPath, {
          method: 'POST',
          headers: authorized('test-primary', {
            'idempotency-key': 'w9a-client-selected-guardians',
          }),
          body: { kind: 'family', participantMembershipIds: [coMembershipId] },
        });
        assert.equal(selectedGuardians.status, 400);
        assert.equal(selectedGuardians.body.error.code, 'invalid_request');

        // 1. The household room is opened with every active guardian in the same transaction,
        //    while the unaccepted invitation is excluded by the server-side active roster.
        const householdRoom = await jsonRequest(baseUrl, threadsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-household' }),
          body: { kind: 'family', title: 'العائلة' },
        });
        assert.equal(householdRoom.status, 201, JSON.stringify(householdRoom.body));
        const householdThreadId = householdRoom.body.thread.id;
        assert.equal(householdRoom.body.thread.kind, 'family');
        assert.deepEqual(
          householdRoom.body.thread.participants.map((entry) => entry.id).sort(),
          [primaryMembershipId, coMembershipId].sort(),
        );
        assert.equal(
          householdRoom.body.thread.participants.some(
            (entry) => entry.id === pendingMembershipId,
          ),
          false,
        );
        assert.equal(householdRoom.body.thread.participants.every((entry) => entry.isSelf === (entry.id === primaryMembershipId)), true);

        // 2. The child's own room names exactly that child, and the server adds every active
        //    guardian in the family without asking the client to choose members. A room that
        //    names no child cannot be a child conversation, and one that names two is refused.
        const twoChildren = await jsonRequest(baseUrl, `/v1/families/${familyId}/children`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-sibling' }),
          body: { displayName: 'بشير', ageYears: 13, avatarEmoji: '🐯', themeColor: 'teal' },
        });
        assert.equal(twoChildren.status, 201);
        const siblingId = twoChildren.body.child.id;
        const tooManyChildren = await jsonRequest(baseUrl, threadsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-two-children' }),
          body: { kind: 'child', title: 'الأولاد', childIds: [childId, siblingId] },
        });
        assert.equal(tooManyChildren.status, 422, JSON.stringify(tooManyChildren.body));
        assert.equal(tooManyChildren.body.error.code, 'chat_child_thread_needs_one_child');

        const childRoom = await jsonRequest(baseUrl, threadsPath, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-child-room' }),
          body: { kind: 'child', title: 'أماني', childIds: [childId] },
        });
        assert.equal(childRoom.status, 201, JSON.stringify(childRoom.body));
        const childThreadId = childRoom.body.thread.id;
        assert.deepEqual(
          childRoom.body.thread.participants.map((entry) => `${entry.kind}:${entry.id}`).sort(),
          [
            `child:${childId}`,
            `membership:${primaryMembershipId}`,
            `membership:${coMembershipId}`,
          ].sort(),
        );

        // 3. THE ROOM IS THE PERMISSION. The active co-guardian sees both rooms because the
        //    server added them to each room at creation, not because a client selected them.
        const coRooms = await jsonRequest(baseUrl, threadsPath, { headers: authorized('test-co') });
        assert.equal(coRooms.status, 200);
        assert.deepEqual(
          coRooms.body.threads.map((thread) => thread.id).sort(),
          [householdThreadId, childThreadId].sort(),
        );
        const coReadsChildRoom = await jsonRequest(
          baseUrl,
          `${threadsPath}/${childThreadId}/messages`,
          { headers: authorized('test-co') },
        );
        assert.equal(coReadsChildRoom.status, 200, JSON.stringify(coReadsChildRoom.body));
        assert.deepEqual(coReadsChildRoom.body.messages, []);

        // 4. The child's handset cannot reach the household room either. It is a member of its
        //    own room and of nothing else.
        const deviceRooms = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/chat/threads`, {
          headers: deviceAuth,
        });
        assert.equal(deviceRooms.status, 200);
        assert.deepEqual(deviceRooms.body.threads.map((thread) => thread.id), [childThreadId]);
        const deviceReadsHousehold = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/chat/threads/${householdThreadId}/messages`,
          { headers: deviceAuth },
        );
        assert.equal(deviceReadsHousehold.status, 404);
        const deviceWritesHousehold = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/chat/threads/${householdThreadId}/messages`,
          {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': 'w9a-device-household' },
            body: { body: 'مرحباً', clientMessageId: 'device-msg-0001' },
          },
        );
        assert.equal(deviceWritesHousehold.status, 404);

        // 5. The server owns the order, and a resend is the same message: one row, one sequence
        //    number, `replayed: true`.
        const firstMessage = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-message-1' }),
          body: { body: 'السلام عليكم', clientMessageId: 'client-message-0001' },
        });
        assert.equal(firstMessage.status, 201, JSON.stringify(firstMessage.body));
        assert.equal(firstMessage.body.message.seq, 1);
        assert.equal(firstMessage.body.message.authorKind, 'membership');
        assert.equal(firstMessage.body.message.authorId, primaryMembershipId);
        assert.equal(firstMessage.body.replayed, false);
        assert.equal(firstMessage.body.message.readCount, 0);

        const resend = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/messages`, {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'w9a-message-1-retry' }),
          body: { body: 'السلام عليكم', clientMessageId: 'client-message-0001' },
        });
        assert.equal(resend.status, 201);
        assert.equal(resend.body.replayed, true);
        assert.equal(resend.body.message.id, firstMessage.body.message.id);
        assert.equal(resend.body.message.seq, 1);
        const storedCount = await client.query(
          `SELECT COUNT(*)::int AS total FROM family_chat_messages WHERE thread_id = $1`,
          [householdThreadId],
        );
        assert.equal(storedCount.rows[0].total, 1, 'a resend must not store a second message');

        // 6. A receipt is aggregate and excludes the author. The co-guardian reads, marks
        //    themselves read, and the message's readCount becomes 1 - the author never counts.
        const coReads = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/messages`, {
          headers: authorized('test-co'),
        });
        assert.equal(coReads.status, 200);
        assert.equal(coReads.body.messages.length, 1);
        assert.equal(coReads.body.messages[0].readCount, 0);
        assert.equal(coReads.body.readState.lastReadSeq, 0);
        const coMarksRead = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/reads`, {
          method: 'POST',
          headers: authorized('test-co', { 'idempotency-key': 'w9a-read-1' }),
          body: { readSeq: 1 },
        });
        assert.equal(coMarksRead.status, 200);
        assert.equal(coMarksRead.body.readState.lastReadSeq, 1);
        const afterRead = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/messages`, {
          headers: authorized('test-primary'),
        });
        assert.equal(afterRead.body.messages[0].readCount, 1);
        assert.equal(afterRead.body.threads, undefined);

        // The list a guardian opens shows the room, its unread count and the preview of what was
        // last said - read from the message's own columns, not from the thread row's identity.
        const primaryRooms = await jsonRequest(baseUrl, threadsPath, { headers: authorized('test-primary') });
        assert.equal(primaryRooms.status, 200);
        const householdPreview = primaryRooms.body.threads.find((thread) => thread.id === householdThreadId);
        assert.equal(householdPreview.lastMessage.id, firstMessage.body.message.id);
        assert.equal(householdPreview.lastMessage.seq, 1);
        assert.equal(householdPreview.lastMessage.body, 'السلام عليكم');
        assert.equal(householdPreview.lastMessage.authorId, primaryMembershipId);
        // One reader: the co-guardian marked themselves read, and the author is not counted among
        // the readers of their own words.
        assert.equal(householdPreview.lastMessage.readCount, 1);

        // A read mark cannot pass the newest message: the server refuses rather than clamps.
        const readAhead = await jsonRequest(baseUrl, `${threadsPath}/${householdThreadId}/reads`, {
          method: 'POST',
          headers: authorized('test-co', { 'idempotency-key': 'w9a-read-ahead' }),
          body: { readSeq: 900 },
        });
        assert.equal(readAhead.status, 409);
        assert.equal(readAhead.body.error.code, 'chat_read_ahead');
        const unchanged = await client.query(
          `SELECT last_read_seq FROM family_chat_thread_members
            WHERE thread_id = $1 AND participant_id = $2`,
          [householdThreadId, coMembershipId],
        );
        assert.equal(Number(unchanged.rows[0].last_read_seq), 1);

        // 7. Only the author edits, and the edit states the revision it read. The co-guardian is
        //    in the room and is still refused - membership is not authorship.
        const foreignEdit = await jsonRequest(
          baseUrl,
          `${threadsPath}/${householdThreadId}/messages/${firstMessage.body.message.id}`,
          {
            method: 'PATCH',
            headers: authorized('test-co'),
            body: { body: 'شيء آخر', revision: 1 },
          },
        );
        assert.equal(foreignEdit.status, 403);
        assert.equal(foreignEdit.body.error.code, 'chat_not_author');

        const staleEdit = await jsonRequest(
          baseUrl,
          `${threadsPath}/${householdThreadId}/messages/${firstMessage.body.message.id}`,
          {
            method: 'PATCH',
            headers: authorized('test-primary'),
            body: { body: 'وعليكم السلام ورحمة الله', revision: 2 },
          },
        );
        assert.equal(staleEdit.status, 409);
        assert.equal(staleEdit.body.error.code, 'chat_message_stale_revision');

        const edited = await jsonRequest(
          baseUrl,
          `${threadsPath}/${householdThreadId}/messages/${firstMessage.body.message.id}`,
          {
            method: 'PATCH',
            headers: authorized('test-primary'),
            body: { body: 'وعليكم السلام ورحمة الله', revision: 1 },
          },
        );
        assert.equal(edited.status, 200, JSON.stringify(edited.body));
        assert.equal(edited.body.message.revision, 2);
        assert.equal(edited.body.message.body, 'وعليكم السلام ورحمة الله');
        assert.notEqual(edited.body.message.editedAt, null);
        // The body it replaced is kept, so the edit is provable rather than a silent rewrite.
        const revisions = await client.query(
          `SELECT revision, body, edited_by_kind, edited_by_id
             FROM family_chat_message_revisions WHERE message_id = $1 ORDER BY revision`,
          [firstMessage.body.message.id],
        );
        assert.deepEqual(revisions.rows.map((row) => [row.revision, row.body, row.edited_by_kind, row.edited_by_id]), [
          [1, 'السلام عليكم', 'membership', primaryMembershipId],
        ]);

        // 8. The child speaks in their own room, from the handset that proves which child it is.
        const childMessage = await jsonRequest(baseUrl, `/v1/devices/${deviceId}/chat/threads/${childThreadId}/messages`, {
          method: 'POST',
          headers: { ...deviceAuth, 'idempotency-key': 'w9a-child-message' },
          body: { body: 'وصلتُ إلى البيت', clientMessageId: 'child-message-0001' },
        });
        assert.equal(childMessage.status, 201, JSON.stringify(childMessage.body));
        assert.equal(childMessage.body.message.authorKind, 'child');
        assert.equal(childMessage.body.message.authorId, childId);
        assert.equal(childMessage.body.message.seq, 1);

        // 9. Only the author deletes their own words - and the guardian who is in the room is
        //    still refused. This is the refusal that makes this product different.
        const guardianDeletesChildWords = await jsonRequest(
          baseUrl,
          `${threadsPath}/${childThreadId}/messages/${childMessage.body.message.id}/deletion`,
          {
            method: 'POST',
            headers: authorized('test-primary', { 'idempotency-key': 'w9a-guardian-delete' }),
          },
        );
        assert.equal(guardianDeletesChildWords.status, 403);
        assert.equal(guardianDeletesChildWords.body.error.code, 'chat_not_author');

        const childDeletesOwn = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/chat/threads/${childThreadId}/messages/${childMessage.body.message.id}/deletion`,
          {
            method: 'POST',
            headers: { ...deviceAuth, 'idempotency-key': 'w9a-child-delete' },
          },
        );
        assert.equal(childDeletesOwn.status, 200, JSON.stringify(childDeletesOwn.body));
        assert.equal(childDeletesOwn.body.message.body, null);
        assert.equal(childDeletesOwn.body.message.seq, 1);
        assert.equal(childDeletesOwn.body.message.deletedByKind, 'child');
        assert.equal(childDeletesOwn.body.message.deletedById, childId);
        // The text is gone from the row itself, and the trace is what remains.
        const deletedRow = await client.query(
          `SELECT body, seq, deleted_at, deleted_by_id FROM family_chat_messages WHERE id = $1`,
          [childMessage.body.message.id],
        );
        assert.equal(deletedRow.rows[0].body, '');
        assert.equal(Number(deletedRow.rows[0].seq), 1);
        assert.notEqual(deletedRow.rows[0].deleted_at, null);
        assert.equal(deletedRow.rows[0].deleted_by_id, childId);
        // And the room still shows the shape of the conversation, with the text gone.
        const childRoomAfter = await jsonRequest(
          baseUrl,
          `/v1/devices/${deviceId}/chat/threads/${childThreadId}/messages`,
          { headers: deviceAuth },
        );
        assert.equal(childRoomAfter.body.messages.length, 1);
        assert.equal(childRoomAfter.body.messages[0].deleted, true);
        assert.equal(childRoomAfter.body.messages[0].body, null);

        // 10. The schema refuses from below what the module refuses from above: a message whose
        //     author is not a member of the thread, and a live message with no text.
        await assert.rejects(
          client.query(
            `INSERT INTO family_chat_messages
               (id, family_id, thread_id, seq, author_kind, author_id, body, client_message_id)
             VALUES (gen_random_uuid(), $1, $2, 2, 'membership', $3, 'من خارج الغرفة', 'outside-message-1')`,
            [familyId, childThreadId, pendingMembershipId],
          ),
          (error) => error.code === '23503' && /family_chat_messages_author_fk/.test(error.constraint),
        );
        await assert.rejects(
          client.query(
            `UPDATE family_chat_messages SET body = '' WHERE id = $1`,
            [firstMessage.body.message.id],
          ),
          (error) => error.code === '23514' && /family_chat_messages_lifecycle_complete/.test(error.constraint),
        );

        // 11. Every act left a trace in the audit envelope, including the deletion - a family
        //     that cannot see that something was removed has not been told the truth.
        const audited = await client.query(
          `SELECT event_type, COUNT(*)::int AS total FROM family_audit_events
            WHERE family_id = $1 AND event_type LIKE 'family.chat_%'
            GROUP BY event_type ORDER BY event_type`,
          [familyId],
        );
        const byType = new Map(audited.rows.map((row) => [row.event_type, row.total]));
        assert.ok((byType.get('family.chat_thread_created') ?? 0) >= 2);
        assert.ok((byType.get('family.chat_message_sent') ?? 0) >= 2);
        assert.equal(byType.get('family.chat_message_edited') ?? 0, 1);
        assert.equal(byType.get('family.chat_message_deleted') ?? 0, 1);
        assert.equal(byType.get('family.chat_read_marked') ?? 0, 1);
      });
    } finally {
      await store.close();
    }
  });
});
