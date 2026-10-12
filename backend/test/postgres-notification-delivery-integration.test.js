// S1 notification delivery against real PostgreSQL. The sender is a deterministic FCM fake, but
// migrations, constraints, commit hooks, outbox claims, preferences and delivery writes use PG.
// Gated by DATABASE_URL; backend_ci.yml runs this against PostgreSQL 16 after applying all migrations.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import pg from 'pg';
import { NotificationDispatcher } from '../src/notification-dispatcher.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');

const FAMILY = 'aaaaaaaa-1111-4111-8111-111111111111';
const ACCOUNT = 'bbbbbbbb-2222-4222-8222-222222222222';
const MEMBERSHIP = 'cccccccc-3333-4333-8333-333333333333';
const CHILD = 'dddddddd-4444-4444-8444-444444444444';
const ALERT = 'eeeeeeee-5555-4555-8555-555555555555';
const REGISTRATION = '11111111-7777-4777-8777-777777777777';
const TOKEN = 'fcm-token-0123456789abcdef0123456789abcdef';
const GEOFENCE_OUTBOX = '22222222-8888-4888-8888-888888888888';
const SOS_OUTBOX = '33333333-9999-4999-8999-999999999999';
const UNREGISTERED_OUTBOX = '44444444-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

function databaseUrl(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_s1_${process.pid}_${randomUUID().replaceAll('-', '').slice(0, 12)}`;
  try {
    await admin.query(`CREATE DATABASE ${name}`);
    const client = new Client({ connectionString: databaseUrl(DATABASE_URL, name) });
    await client.connect();
    let store;
    try {
      await applyMigrations({
        client,
        migrations: FOUNDATION_SCHEMA_MIGRATIONS,
        readVerifiedMigration: async (migration) => {
          const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
          assert.equal(createHash('sha256').update(sql).digest('hex'), migration.sha256,
            `${migration.name} must match its recorded checksum`);
          return sql;
        },
      });
      store = new PostgresFoundationStore({
        connectionString: databaseUrl(DATABASE_URL, name),
        guardianTransferTtlHours: 72,
      });
      await run(client, store);
    } finally {
      if (store) await store.close();
      await client.end();
    }
  } finally {
    await admin.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
    await admin.end();
  }
}

async function seedFamily(client) {
  await client.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 's1-real-pg-subject')`, [ACCOUNT]);
  await client.query(`INSERT INTO families (id, display_name) VALUES ($1, 'S1 delivery test')`, [FAMILY]);
  await client.query(
    `INSERT INTO family_memberships
       (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES ($1, $2, $3, 's1-real-pg-subject', 'primary_guardian', 'active', NOW())`,
    [MEMBERSHIP, FAMILY, ACCOUNT],
  );
  await client.query(`UPDATE families SET primary_membership_id=$2 WHERE id=$1`, [FAMILY, MEMBERSHIP]);
  await client.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES ($1, $2, 'ليان', 10)`,
    [CHILD, FAMILY],
  );
  await client.query(
    `INSERT INTO family_push_registrations
       (id, family_id, membership_id, token, platform, locale)
     VALUES ($1, $2, $3, $4, 'android', 'ar')`,
    [REGISTRATION, FAMILY, MEMBERSHIP, TOKEN],
  );
}

async function insertCommittedOutbox(store, dispatches, { id, type, copyKey, payload }) {
  await store.withTransaction((client) => client.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, $3, $4, $5, $6::jsonb)`,
    [id, FAMILY, randomUUID(), type, copyKey, JSON.stringify(payload)],
  ));
  const pending = dispatches.get(id);
  assert.ok(pending, 'the store must invoke the dispatcher only after COMMIT');
  return pending;
}

test('S1 commit hook delivers Arabic geofence and SOS, then removes an unregistered token', { skip }, async () => {
  await withFreshDatabase(async (client, store) => {
    await seedFamily(client);
    const calls = [];
    const sender = {
      async send(args) {
        calls.push(args);
        if (args.data.type === 'family.geofence_exited') return 'unregistered';
        args.onAccepted?.(`projects/family-os-s1-test/messages/${args.data.type.replaceAll('.', '-')}`);
        return 'sent';
      },
    };
    const dispatcher = new NotificationDispatcher(sender, () => store.pool.connect());
    const dispatches = new Map();
    store.setOutboxListener((id, type) => {
      const delivery = dispatcher.notify(id, type);
      dispatches.set(id, delivery);
      return delivery;
    });

    const geofence = insertCommittedOutbox(store, dispatches, {
      id: GEOFENCE_OUTBOX,
      type: 'family.geofence_entered',
      copyKey: 'geofence.entered',
      payload: {
        childId: CHILD,
        zoneId: 'ffffffff-6666-4666-8666-666666666666',
        zoneName: 'المدرسة',
        occurredAt: '2026-05-10T06:20:00.000Z',
      },
    });
    const geofenceResult = await geofence;
    assert.equal(geofenceResult.status, 'delivered');
    assert.equal(calls[0].title, 'ليان وصل إلى المدرسة');
    assert.equal(calls[0].body, 'دخل المنطقة الآمنة الساعة ٦:٢٠ ص');
    assert.equal(calls[0].urgency, 'alert');
    assert.equal(calls[0].channelId, 'familyos_geofence_alerts');

    await client.query(
      `INSERT INTO family_sos_alerts
         (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
          location_class, connection_class)
       VALUES ($1, $2, $3, 'guardian', $4, '2026-05-10T15:45:00Z', 'unavailable', 'online')`,
      [ALERT, FAMILY, CHILD, MEMBERSHIP],
    );
    await client.query(
      `INSERT INTO family_sos_alert_deliveries
         (id, alert_id, family_id, recipient_kind, recipient_membership_id, channel, delivery_state)
       VALUES (gen_random_uuid(), $1, $2, 'guardian', $3, 'push', 'recorded')`,
      [ALERT, FAMILY, MEMBERSHIP],
    );
    await client.query(
      `INSERT INTO family_notification_preferences
         (family_id, membership_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
          push_allowed, delivery_mode)
       VALUES ($1, $2, TRUE, '21:00', '07:00', FALSE, 'history_only')`,
      [FAMILY, MEMBERSHIP],
    );
    const sosResult = await insertCommittedOutbox(store, dispatches, {
      id: SOS_OUTBOX,
      type: 'family.sos_alert_raised',
      copyKey: 'sos.raised',
      payload: { subjectType: 'sos_alert', subjectId: ALERT },
    });
    assert.equal(sosResult.status, 'delivered');
    assert.equal(calls[1].title, 'استغاثة من ليان');
    assert.equal(calls[1].body, 'ضغط زر الاستغاثة الساعة ٣:٤٥ م');
    assert.equal(calls[1].urgency, 'alert');

    const sosDelivery = await client.query(
      `SELECT delivery_state, reason_code, fcm_message_id
         FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`,
      [ALERT],
    );
    assert.deepEqual(sosDelivery.rows, [{
      delivery_state: 'delivered',
      reason_code: null,
      fcm_message_id: 'projects/family-os-s1-test/messages/family-sos_alert_raised',
    }]);

    const unregistered = await insertCommittedOutbox(store, dispatches, {
      id: UNREGISTERED_OUTBOX,
      type: 'family.geofence_exited',
      copyKey: 'geofence.exited',
      payload: {
        childId: CHILD,
        zoneId: 'ffffffff-6666-4666-8666-666666666666',
        zoneName: 'المدرسة',
        occurredAt: '2026-05-10T06:25:00.000Z',
      },
    });
    const unregisteredResult = await unregistered;
    assert.equal(unregisteredResult.status, 'failed');
    assert.equal(unregisteredResult.removedCount, 1);
    const registrations = await client.query(
      `SELECT count(*)::int AS count FROM family_push_registrations WHERE id=$1`,
      [REGISTRATION],
    );
    assert.equal(registrations.rows[0].count, 0);
    const attempt = await client.query(
      `SELECT outcome, provider_message_id, failure_reason
         FROM outbox_delivery_attempts WHERE outbox_id=$1`,
      [UNREGISTERED_OUTBOX],
    );
    assert.deepEqual(attempt.rows, [{ outcome: 'unregistered', provider_message_id: null, failure_reason: null }]);

    const outbox = await client.query(
      `SELECT status, failure_reason FROM outbox_events WHERE id = ANY($1::uuid[]) ORDER BY id`,
      [[GEOFENCE_OUTBOX, SOS_OUTBOX, UNREGISTERED_OUTBOX]],
    );
    assert.equal(outbox.rows.length, 3);
    assert.ok(outbox.rows.some((row) => row.status === 'delivered' && row.failure_reason === null));
    assert.ok(outbox.rows.some((row) => row.status === 'failed' && row.failure_reason === 'all_tokens_unregistered'));
    assert.equal(calls.length, 3);
  });
});
