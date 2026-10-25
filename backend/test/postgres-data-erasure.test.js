// Safety slice 3 — retention and erasure on real PostgreSQL. Gated by DATABASE_URL like
// every PostgreSQL test; CI runs it in backend_ci.yml.
//
// What it must prove, because only a real database can:
//   1. The retention window is the owner's 90 days, and the prune that enforces it is
//      proved with an INJECTED CLOCK — observing a ninety-day window must not mean
//      waiting ninety days, and it must not mean trusting a unit test's fake either.
//      A sample the crossing log points at, and a sample an incident points at, outlive
//      the window: an event whose measurement is gone is an event nobody can check.
//   2. The guardian's erasure demand really deletes — trail, crossings, snapshots — in
//      the order the foreign keys force; the incident keeps its row and loses only the
//      reference; the audit trail says "deleted" and carries no content; consent is
//      untouched, because stopping collection is withdrawal, not erasure.
//   3. A revocation really deletes what the cut-off handset had reported, scoped to
//      that device: a sibling child's trail is not this device's business.
//   4. Removing a child archives the profile with provenance, freezes the consent
//      ledger by withdrawal, cuts every handset off, erases every location fact — one
//      transaction — and the archived child then leaves every read and refuses every
//      new write.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { createApp } from '../src/app.js';
import { LOCATION_RETENTION_DAYS, createLocationSurface, postgresLocationPort } from '../src/location-telemetry.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore, capabilityMatches } from '../src/store/postgres-foundation-store.js';
import { TestAuthVerifier } from './memory-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const DAY_MS = 24 * 60 * 60 * 1000;

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
  const name = `familyos_erasure_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
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
  const membership = await client.query(
    `SELECT id FROM family_memberships WHERE family_id = $1 AND target_subject = $2`,
    [familyId, guardian],
  );
  return {
    familyId,
    childId,
    deviceId: device.rows[0].id,
    deviceCredential,
    membershipId: membership.rows[0].id,
    asDevice: (key) => ({
      authorization: `Device ${deviceCredential}`,
      ...(key ? { 'idempotency-key': key } : {}),
    }),
  };
}

/** An active co-guardian, through the real invitation flow. */
async function seedCoGuardian(baseUrl, familyId, tag) {
  const invited = await call(baseUrl, `/v1/families/${familyId}/memberships`, {
    method: 'POST',
    headers: authorized('test-primary', { 'idempotency-key': `${tag}-invite` }),
    body: { role: 'co_guardian', targetSubject: 'test-co-guardian' },
  });
  assert.equal(invited.status, 201, JSON.stringify(invited.body));
  const accepted = await call(baseUrl, `/v1/families/${familyId}/memberships/${invited.body.membership.id}/accept`, {
    method: 'POST',
    headers: authorized('test-co-guardian', { 'idempotency-key': `${tag}-accept` }),
  });
  assert.equal(accepted.status, 200, JSON.stringify(accepted.body));
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

/** Grants the child's location consent over HTTP, the way the handset does at setup. */
async function grantConsent(baseUrl, h, key) {
  const granted = await call(baseUrl, `/v1/devices/${h.deviceId}/consents`, {
    method: 'POST',
    headers: h.asDevice(key),
    body: { capability: 'location', textVersion: '2026-10-10' },
  });
  assert.equal(granted.status, 201, JSON.stringify(granted.body));
}

/** A zone, a crossing pointing at one fix, and an incident pointing at another. */
async function seedDerivedRecords(client, h, { crossingFixId, incidentFixId }) {
  const zone = await client.query(
    `INSERT INTO family_safe_zones
       (id, family_id, name, geometry_kind, center_lat, center_lng, radius_meters, created_by_membership_id)
     VALUES (gen_random_uuid(), $1, 'مدرسة', 'CIRCLE', 15.3694, 44.191, 200, $2)
     RETURNING id`,
    [h.familyId, h.membershipId],
  );
  await client.query(
    `INSERT INTO family_geofence_events
       (id, family_id, zone_id, child_id, device_id, fix_id, kind, baseline, zone_version, occurred_at)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, 'ENTER', TRUE, 1, NOW())`,
    [h.familyId, zone.rows[0].id, h.childId, h.deviceId, crossingFixId],
  );
  await client.query(
    `INSERT INTO family_sos_alerts
       (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
        location_class, connection_class, fix_id)
     VALUES (gen_random_uuid(), $1, $2, 'guardian', $3, NOW(), 'unavailable', 'offline', $4)`,
    [h.familyId, h.childId, h.membershipId, incidentFixId],
  );
}

/** Gives the device a full latest-telemetry snapshot, the way a telemetry report does. */
async function seedDeviceSnapshot(client, deviceId) {
  await client.query(
    `UPDATE family_child_devices
        SET battery_level = 80, battery_status = 'charging',
            location_lat = 15.3694, location_lng = 44.191, location_label = 'GPS',
            last_seen_at = NOW()
      WHERE id = $1`,
    [deviceId],
  );
}

function appWith(store) {
  return createApp({
    store,
    authVerifier: new TestAuthVerifier(),
    readiness: () => ({ ready: true, missing: [] }),
  });
}

function storeFor(client) {
  const store = new PostgresFoundationStore({
    connectionString: withDatabase(DATABASE_URL, client.database),
  });
  openStores.add(store);
  return store;
}

const countFixes = async (client, familyId) =>
  (await client.query(`SELECT count(*)::int AS n FROM family_child_location_fixes WHERE family_id = $1`, [familyId]))
    .rows[0].n;

// ── 1. Retention: 90 days, proved with an injected clock ─────────────────────────────

test(
  'the trail is bounded at the owner\'s ninety days, and the samples the safety record points at outlive the window',
  { skip },
  async () => {
    assert.equal(LOCATION_RETENTION_DAYS, 90, 'the owner decided 90 days on 2026-10-10');
    await withFreshDatabase(async (client) => {
      await migrate(client);
      const store = storeFor(client);
      await withServer(appWith(store), async (baseUrl) => {
        const h = await seedHousehold(baseUrl, client, 'retention');
        await client.query(
          `INSERT INTO family_child_consents
             (family_id, child_id, capability, text_version, granted_by_device_id)
           VALUES ($1, $2, 'location', '2026-10-10', $3)`,
          [h.familyId, h.childId, h.deviceId],
        );

        // The injected clock is anchored 200 days in the past so every `recorded_at`
        // this journey writes is still in the past for the database's own `received_at`
        // — a fix from the future is refused by the schema, and rightly so.
        const t0 = new Date(Date.now() - 200 * DAY_MS);
        const surfaceAt = (when) =>
          createLocationSurface({
            port: postgresLocationPort(store, { credentialMatches: capabilityMatches }),
            now: () => when,
          });
        const t0Surface = surfaceAt(t0);
        let seq = 0;
        const ingestAt = (surface, recordedAt) =>
          surface.ingestFix({
            principal: null,
            deviceCredential: h.deviceCredential,
            deviceId: h.deviceId,
            fix: {
              fixId: randomUUID(),
              acquisition: 'located',
              latitude: 15.3694,
              longitude: 44.191,
              accuracyMeters: 12,
              integritySoftWarning: false,
              recordedAt: recordedAt.toISOString(),
            },
            idempotencyKey: `retention-${(seq += 1)}`,
            requestHash: sha256Hex(`retention-${seq}`),
            correlationId: randomUUID(),
          });

        // Three samples inside the window as t0 sees it: one plain, one that will be
        // named by a crossing, one that will be named by an incident.
        const plain = await ingestAt(t0Surface, new Date(t0.getTime() - 2 * DAY_MS));
        const crossing = await ingestAt(t0Surface, new Date(t0.getTime() - 1 * DAY_MS));
        const incident = await ingestAt(t0Surface, new Date(t0.getTime() - 3 * DAY_MS));
        for (const result of [plain, crossing, incident]) {
          assert.equal(result.pruned, 0, 'nothing inside the window may be pruned');
        }
        await seedDerivedRecords(client, h, {
          crossingFixId: crossing.fix.id,
          incidentFixId: incident.fix.id,
        });
        assert.equal(await countFixes(client, h.familyId), 3);

        // A hundred days pass. The next write carries the prune with it, as every write
        // does — this is the injected clock, not a waited one.
        const aged = new Date(t0.getTime() + 100 * DAY_MS);
        const fresh = await ingestAt(surfaceAt(aged), new Date(aged.getTime() - 60_000));
        assert.equal(fresh.pruned, 1, 'exactly the unreferenced expired sample is deleted');

        const survivors = await client.query(
          `SELECT id FROM family_child_location_fixes WHERE family_id = $1 ORDER BY recorded_at ASC`,
          [h.familyId],
        );
        assert.deepEqual(
          survivors.rows.map((row) => row.id),
          [incident.fix.id, crossing.fix.id, fresh.fix.id],
          'the samples the crossing log and the incident point at outlive the window; the plain one does not',
        );

        // And the window the prune walked is the owner's: a sample one day inside it
        // survives the very same write.
        const justInside = await ingestAt(
          surfaceAt(aged),
          new Date(aged.getTime() - (LOCATION_RETENTION_DAYS - 1) * DAY_MS),
        );
        assert.equal(justInside.pruned, 0);
        assert.equal(await countFixes(client, h.familyId), 4);
      });
    });
  },
);

// ── 2. The guardian's erasure demand ─────────────────────────────────────────────────

test('the erasure demand really deletes, keeps the incident, audits without content, and never touches consent', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = storeFor(client);
    await withServer(appWith(store), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'erase');
      const outsider = await seedHousehold(baseUrl, client, 'erase-outsider', 'test-outsider');
      await seedCoGuardian(baseUrl, h.familyId, 'erase');
      await grantConsent(baseUrl, h, 'erase-grant');

      const first = fixBody();
      const second = fixBody();
      for (const fix of [first, second]) {
        const posted = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
          method: 'POST',
          headers: h.asDevice(`erase-fix-${fix.fixId}`),
          body: fix,
        });
        assert.equal(posted.status, 201, JSON.stringify(posted.body));
      }
      await seedDerivedRecords(client, h, {
        crossingFixId: first.fixId,
        incidentFixId: second.fixId,
      });
      await seedDeviceSnapshot(client, h.deviceId);

      // A co-guardian may READ the trail but may not delete it: the destructive act is
      // narrower than the read, exactly as in revocation.
      const asCoGuardian = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-co-guardian', { 'idempotency-key': 'erase-co' }),
      });
      assert.equal(asCoGuardian.status, 403);
      assert.equal(await countFixes(client, h.familyId), 2, 'a refused demand deleted nothing');

      // Nor may a primary guardian of another family.
      const asOutsider = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-outsider', { 'idempotency-key': 'erase-out' }),
      });
      assert.equal(asOutsider.status, 403);

      // A child who was never in this family is not found, not refused.
      const unknown = await call(baseUrl, `/v1/families/${h.familyId}/children/${randomUUID()}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'erase-unknown' }),
      });
      assert.equal(unknown.status, 404);
      assert.equal(unknown.body.error.code, 'family_child_not_found');

      // The demand itself.
      const erased = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'erase-1' }),
      });
      assert.equal(erased.status, 200, JSON.stringify(erased.body));
      assert.deepEqual(erased.body.erased, {
        locationFixes: 2,
        geofenceEvents: 1,
        deviceSnapshots: 1,
        sosFixReferences: 1,
      });

      // Really deleted, in the database, not only in the answer.
      assert.equal(await countFixes(client, h.familyId), 0);
      const events = await client.query(
        `SELECT count(*)::int AS n FROM family_geofence_events WHERE family_id = $1`,
        [h.familyId],
      );
      assert.equal(events.rows[0].n, 0);
      const device = await client.query(
        `SELECT location_lat, location_lng, location_label, last_seen_at, credential_revoked_at
           FROM family_child_devices WHERE id = $1`,
        [h.deviceId],
      );
      assert.equal(device.rows[0].location_lat, null);
      assert.equal(device.rows[0].location_lng, null);
      assert.equal(device.rows[0].location_label, null);
      assert.notEqual(device.rows[0].last_seen_at, null, 'a time is not a position; the honest fact stays');
      assert.equal(device.rows[0].credential_revoked_at, null, 'erasure is not revocation');

      // The incident kept its row and lost only the reference.
      const alerts = await client.query(
        `SELECT id, fix_id FROM family_sos_alerts WHERE family_id = $1`,
        [h.familyId],
      );
      assert.equal(alerts.rows.length, 1);
      assert.equal(alerts.rows[0].fix_id, null);

      // Consent is untouched: the child's handset may still report, and the new fix is
      // accepted. One button must not silently do the other's job.
      const sharing = await call(baseUrl, `/v1/devices/${h.deviceId}/location-sharing`, { headers: h.asDevice() });
      assert.equal(sharing.body.capabilities.location.state, 'granted');
      const after = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
        method: 'POST',
        headers: h.asDevice('erase-fix-after'),
        body: fixBody(),
      });
      assert.equal(after.status, 201, JSON.stringify(after.body));

      // The audit trail says "deleted" — one row, event type and subject only — and is
      // not an announcement: no outbox row carries it.
      const audits = await client.query(
        `SELECT actor_membership_id, subject_id, subject_type FROM family_audit_events
          WHERE family_id = $1 AND event_type = 'family.child_location_erased'`,
        [h.familyId],
      );
      assert.equal(audits.rows.length, 1);
      assert.equal(audits.rows[0].subject_id, h.childId);
      assert.equal(audits.rows[0].subject_type, 'family_child');
      const announced = await client.query(
        `SELECT count(*)::int AS n FROM outbox_events
          WHERE aggregate_id = $1 AND event_type = 'family.child_location_erased'`,
        [h.familyId],
      );
      assert.equal(announced.rows[0].n, 0);

      // A retry with the same key replays the first answer; a fresh demand over data
      // that is already gone answers honest zeros — plus the one new fix from above.
      const replayed = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'erase-1' }),
      });
      assert.equal(replayed.status, 200);
      assert.deepEqual(replayed.body, erased.body);
      const freshDemand = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'erase-2' }),
      });
      assert.equal(freshDemand.status, 200);
      assert.deepEqual(freshDemand.body.erased, {
        locationFixes: 1,
        geofenceEvents: 0,
        deviceSnapshots: 0,
        sosFixReferences: 0,
      });
      assert.equal(await countFixes(client, h.familyId), 0);
      assert.equal(await countFixes(client, outsider.familyId), 0, 'the other family was never involved');
    });
  });
});

// ── 3. A revocation really deletes ───────────────────────────────────────────────────

test('cutting a device off deletes its trail and empties its snapshot — and leaves a sibling child alone', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = storeFor(client);
    await withServer(appWith(store), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'revoke-erase');
      await grantConsent(baseUrl, h, 'revoke-erase-grant');

      // A sibling child with her own handset and her own trail.
      const sibling = await call(baseUrl, `/v1/families/${h.familyId}/children`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'revoke-erase-sibling' }),
        body: { displayName: 'أخوها', ageYears: 7, avatarEmoji: '🦊', themeColor: 'mint' },
      });
      assert.equal(sibling.status, 201);
      const siblingId = sibling.body.child.id;
      const siblingCredential = 'revoke-erase-sibling-credential-0001';
      const siblingDevice = await client.query(
        `INSERT INTO family_child_devices
           (id, family_id, child_id, device_label, credential_hash, credential_issued_at)
         VALUES (gen_random_uuid(), $1, $2, 'Sibling Android', $3, NOW()) RETURNING id`,
        [h.familyId, siblingId, sha256Hex(siblingCredential)],
      );
      await client.query(
        `INSERT INTO family_child_consents
           (family_id, child_id, capability, text_version, granted_by_device_id)
         VALUES ($1, $2, 'location', '2026-10-10', $3)`,
        [h.familyId, siblingId, siblingDevice.rows[0].id],
      );
      const siblingFix = fixBody();
      const siblingPosted = await call(baseUrl, `/v1/devices/${siblingDevice.rows[0].id}/location-fixes`, {
        method: 'POST',
        headers: { authorization: `Device ${siblingCredential}`, 'idempotency-key': 'revoke-erase-sibling-fix', 'content-type': 'application/json' },
        body: siblingFix,
      });
      assert.equal(siblingPosted.status, 201, JSON.stringify(siblingPosted.body));

      // The device that will be cut off: a trail, a crossing, an incident reference,
      // and a last-known-position snapshot.
      const reported = fixBody();
      const posted = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
        method: 'POST',
        headers: h.asDevice(`revoke-erase-fix-${reported.fixId}`),
        body: reported,
      });
      assert.equal(posted.status, 201, JSON.stringify(posted.body));
      await seedDerivedRecords(client, h, {
        crossingFixId: reported.fixId,
        incidentFixId: reported.fixId,
      });
      await seedDeviceSnapshot(client, h.deviceId);
      await seedDeviceSnapshot(client, siblingDevice.rows[0].id);

      const revoked = await call(
        baseUrl,
        `/v1/families/${h.familyId}/children/${h.childId}/devices/${h.deviceId}/revocation`,
        {
          method: 'POST',
          headers: authorized('test-primary', { 'idempotency-key': 'revoke-erase-1' }),
          body: { reasonCode: 'lost' },
        },
      );
      assert.equal(revoked.status, 200, JSON.stringify(revoked.body));
      assert.deepEqual(revoked.body.erased, {
        locationFixes: 1,
        geofenceEvents: 1,
        sosFixReferences: 1,
        deviceSnapshots: 1,
      });

      // The cut-off device's trail is gone; the sibling's is untouched.
      const remaining = await client.query(
        `SELECT device_id FROM family_child_location_fixes WHERE family_id = $1`,
        [h.familyId],
      );
      assert.deepEqual(remaining.rows.map((row) => row.device_id), [siblingDevice.rows[0].id]);
      const cutDevice = await client.query(
        `SELECT location_lat, location_lng, location_label FROM family_child_devices WHERE id = $1`,
        [h.deviceId],
      );
      assert.deepEqual(
        [cutDevice.rows[0].location_lat, cutDevice.rows[0].location_lng, cutDevice.rows[0].location_label],
        [null, null, null],
      );
      const siblingRow = await client.query(
        `SELECT location_lat FROM family_child_devices WHERE id = $1`,
        [siblingDevice.rows[0].id],
      );
      assert.notEqual(siblingRow.rows[0].location_lat, null, 'the sibling\'s snapshot is not this device\'s business');

      // The incident stays, without its sample; the crossing goes with the trail it was
      // derived from; the erasure leaves its own audit row.
      const alerts = await client.query(`SELECT fix_id FROM family_sos_alerts WHERE family_id = $1`, [h.familyId]);
      assert.equal(alerts.rows.length, 1);
      assert.equal(alerts.rows[0].fix_id, null);
      const events = await client.query(
        `SELECT count(*)::int AS n FROM family_geofence_events WHERE family_id = $1`,
        [h.familyId],
      );
      assert.equal(events.rows[0].n, 0);
      const erasureAudit = await client.query(
        `SELECT count(*)::int AS n FROM family_audit_events
          WHERE family_id = $1 AND event_type = 'family.child_device_location_erased'`,
        [h.familyId],
      );
      assert.equal(erasureAudit.rows[0].n, 1);
    });
  });
});

// ── 4. Removing a child from the family ──────────────────────────────────────────────

test('removal archives with provenance, freezes consent, cuts the handset off, really deletes, and closes every read', { skip }, async () => {
  await withFreshDatabase(async (client) => {
    await migrate(client);
    const store = storeFor(client);
    await withServer(appWith(store), async (baseUrl) => {
      const h = await seedHousehold(baseUrl, client, 'remove');
      await seedCoGuardian(baseUrl, h.familyId, 'remove');
      await grantConsent(baseUrl, h, 'remove-grant');

      const reported = fixBody();
      const posted = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
        method: 'POST',
        headers: h.asDevice(`remove-fix-${reported.fixId}`),
        body: reported,
      });
      assert.equal(posted.status, 201, JSON.stringify(posted.body));
      await seedDerivedRecords(client, h, {
        crossingFixId: reported.fixId,
        incidentFixId: reported.fixId,
      });
      await seedDeviceSnapshot(client, h.deviceId);

      // A co-guardian cannot remove a child from the family.
      const asCoGuardian = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}`, {
        method: 'DELETE',
        headers: authorized('test-co-guardian', { 'idempotency-key': 'remove-co' }),
      });
      assert.equal(asCoGuardian.status, 403);
      const stillThere = await client.query(
        `SELECT archived_at FROM family_children WHERE id = $1`,
        [h.childId],
      );
      assert.equal(stillThere.rows[0].archived_at, null);

      // The removal itself.
      const removed = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}`, {
        method: 'DELETE',
        headers: authorized('test-primary', { 'idempotency-key': 'remove-1' }),
      });
      assert.equal(removed.status, 200, JSON.stringify(removed.body));
      assert.equal(removed.body.child.id, h.childId);
      assert.notEqual(removed.body.child.archivedAt, null);
      assert.deepEqual(removed.body.erased, {
        locationFixes: 1,
        geofenceEvents: 1,
        deviceSnapshots: 1,
        sosFixReferences: 1,
      });
      assert.equal(removed.body.consentsWithdrawn, 1);
      assert.equal(removed.body.devicesRevoked, 1);

      // The profile kept its provenance: who removed the child, and when.
      const archived = await client.query(
        `SELECT archived_at, archived_by_membership_id, version FROM family_children WHERE id = $1`,
        [h.childId],
      );
      assert.notEqual(archived.rows[0].archived_at, null);
      assert.equal(archived.rows[0].archived_by_membership_id, h.membershipId);

      // The consent ledger froze by withdrawal — the row stays, because who agreed to
      // what and when is compliance evidence, not location data.
      const consents = await client.query(
        `SELECT withdrawn_at, withdrawn_by_membership_id FROM family_child_consents WHERE child_id = $1`,
        [h.childId],
      );
      assert.equal(consents.rows.length, 1);
      assert.notEqual(consents.rows[0].withdrawn_at, null);
      assert.equal(consents.rows[0].withdrawn_by_membership_id, h.membershipId);

      // The handset was cut off inside the same act.
      const device = await client.query(
        `SELECT credential_revoked_at, revoked_by_membership_id, location_lat
           FROM family_child_devices WHERE id = $1`,
        [h.deviceId],
      );
      assert.notEqual(device.rows[0].credential_revoked_at, null);
      assert.equal(device.rows[0].revoked_by_membership_id, h.membershipId);
      assert.equal(device.rows[0].location_lat, null);

      // The location data is really gone; the incident kept its row.
      assert.equal(await countFixes(client, h.familyId), 0);
      const alerts = await client.query(`SELECT fix_id FROM family_sos_alerts WHERE family_id = $1`, [h.familyId]);
      assert.equal(alerts.rows.length, 1);
      assert.equal(alerts.rows[0].fix_id, null);

      // The archived child leaves every read…
      const roster = await call(baseUrl, `/v1/families/${h.familyId}/children`, {
        headers: authorized('test-primary'),
      });
      assert.deepEqual(roster.body.children, []);
      const map = await call(baseUrl, `/v1/families/${h.familyId}/location`, {
        headers: authorized('test-primary'),
      });
      assert.deepEqual(map.body.children, []);
      const history = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/location-history`, {
        headers: authorized('test-primary'),
      });
      assert.equal(history.status, 404, 'an archived child is not found-with-nothing; they are not found');

      // …refuses every new write…
      const pairing = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/device-pairings`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'remove-pairing-after' }),
        body: { deviceLabel: 'جهاز آخر' },
      });
      assert.equal(pairing.status, 404);
      assert.equal(pairing.body.error.code, 'family_child_not_found');

      // …and the handset of a child who is gone cannot keep reporting.
      const stillReporting = await call(baseUrl, `/v1/devices/${h.deviceId}/location-fixes`, {
        method: 'POST',
        headers: h.asDevice('remove-fix-after'),
        body: fixBody(),
      });
      assert.equal(stillReporting.status, 401);
      assert.equal(stillReporting.body.error.code, 'invalid_device_credential');

      // A retry with the same key replays the first removal; a second removal under a
      // new key is refused rather than overwriting the original provenance.
      const replayed = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}`, {
        method: 'DELETE',
        headers: authorized('test-primary', { 'idempotency-key': 'remove-1' }),
      });
      assert.equal(replayed.status, 200);
      assert.deepEqual(replayed.body, removed.body);
      const second = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}`, {
        method: 'DELETE',
        headers: authorized('test-primary', { 'idempotency-key': 'remove-2' }),
      });
      assert.equal(second.status, 409);
      assert.equal(second.body.error.code, 'child_already_archived');

      // The erasure demand still reaches the archived child, and answers honest zeros.
      const eraseAfter = await call(baseUrl, `/v1/families/${h.familyId}/children/${h.childId}/data-erasure`, {
        method: 'POST',
        headers: authorized('test-primary', { 'idempotency-key': 'remove-erase-after' }),
      });
      assert.equal(eraseAfter.status, 200);
      assert.deepEqual(eraseAfter.body.erased, {
        locationFixes: 0,
        geofenceEvents: 0,
        deviceSnapshots: 0,
        sosFixReferences: 0,
      });

      // The removal was announced to the family; the erasure inside it was only a fact.
      const audits = await client.query(
        `SELECT event_type, count(*)::int AS n FROM family_audit_events
          WHERE family_id = $1 AND event_type IN ('family.child_archived', 'family.child_location_erased')
          GROUP BY event_type ORDER BY event_type`,
        [h.familyId],
      );
      assert.deepEqual(
        audits.rows.map((row) => [row.event_type, row.n]),
        [
          ['family.child_archived', 1],
          ['family.child_location_erased', 2],
        ],
      );
      const outbox = await client.query(
        `SELECT event_type, count(*)::int AS n FROM outbox_events
          WHERE aggregate_id = $1 AND event_type IN ('family.child_archived', 'family.child_location_erased')
          GROUP BY event_type ORDER BY event_type`,
        [h.familyId],
      );
      assert.deepEqual(
        outbox.rows.map((row) => [row.event_type, row.n]),
        [['family.child_archived', 1]],
        'the removal is the family event; the deletion is a fact about data',
      );
    });
  });
});
