// S1 notification delivery against real PostgreSQL. DATABASE_URL gates these tests; CI applies
// every migration to PostgreSQL 16 and runs this file in the migration-and-integration job.
// The FCM transport is deterministic, but claims, row locks, outbox state, attempt evidence,
// SOS delivery evidence and preference constraints are all exercised by PostgreSQL itself.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import pg from 'pg';
import { applyMigrations } from '../src/migration-runner.js';
import { NotificationDispatcher } from '../src/notification-dispatcher.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';

const { Client, Pool } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const FAMILY = 'aaaaaaaa-1111-4111-8111-111111111111';
const ACCOUNT = 'bbbbbbbb-2222-4222-8222-222222222222';
const MEMBERSHIP = 'cccccccc-3333-4333-8333-333333333333';
const CHILD = 'dddddddd-4444-4444-8444-444444444444';
const DEVICE = 'abababab-2222-4222-8222-222222222222';
const ALERT = 'eeeeeeee-5555-4555-8555-555555555555';
const REGISTRATION = '11111111-7777-4777-8777-777777777777';
const SOS_OUTBOX = '22222222-8888-4888-8888-888888888888';
const HEALTHY_PROTECTION_OUTBOX = '44444444-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const RISK_PROTECTION_OUTBOX = '55555555-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const UNKNOWN_OUTBOX = '33333333-9999-4999-8999-999999999999';
const TOKEN = 'fcm-token-0123456789abcdef0123456789abcdef';
const MIGRATIONS_SHA = (bytes) => createHash('sha256').update(bytes).digest('hex');

function withDatabase(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_notify_${process.pid}_${randomUUID().replaceAll('-', '').slice(0, 12)}`;
  let client;
  let pool;
  try {
    await admin.query(`CREATE DATABASE "${name}"`);
    const connectionString = withDatabase(DATABASE_URL, name);
    client = new Client({ connectionString });
    await client.connect();
    pool = new Pool({ connectionString, max: 4 });
    await applyMigrations({
      client,
      migrations: FOUNDATION_SCHEMA_MIGRATIONS,
      readVerifiedMigration: async (migration) => {
        const sql = await readFile(join(migrationDirectory, migration.name));
        assert.equal(MIGRATIONS_SHA(sql), migration.sha256, `${migration.name} must match its recorded checksum`);
        return sql.toString('utf8');
      },
    });
    await run({ client, pool });
  } finally {
    if (pool) await pool.end();
    if (client) await client.end();
    await admin.query(`DROP DATABASE IF EXISTS "${name}" WITH (FORCE)`);
    await admin.end();
  }
}

async function seedGuardianAndChild(client) {
  await client.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 's1-notification-postgres-test')`, [ACCOUNT]);
  await client.query(`INSERT INTO families (id, display_name) VALUES ($1, 'عائلة الاختبار')`, [FAMILY]);
  await client.query(
    `INSERT INTO family_memberships
       (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES ($1, $2, $3, 's1-notification-postgres-test', 'primary_guardian', 'active', NOW())`,
    [MEMBERSHIP, FAMILY, ACCOUNT],
  );
  await client.query(`UPDATE families SET primary_membership_id=$2 WHERE id=$1`, [FAMILY, MEMBERSHIP]);
  await client.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES ($1, $2, 'ليان', 10)`,
    [CHILD, FAMILY],
  );
  await client.query(
    `INSERT INTO family_child_devices (id, family_id, child_id, device_label)
     VALUES ($1, $2, $3, 'Layan Android')`,
    [DEVICE, FAMILY, CHILD],
  );
  await client.query(
    `INSERT INTO family_push_registrations
       (id, family_id, membership_id, token, platform, locale)
     VALUES ($1, $2, $3, $4, 'android', 'ar')`,
    [REGISTRATION, FAMILY, MEMBERSHIP, TOKEN],
  );
}

function acceptedSender() {
  const calls = [];
  return {
    calls,
    async send(args) {
      calls.push(args);
      args.onAccepted?.(`projects/family-os-test/messages/postgres-${calls.length}`);
      return 'sent';
    },
  };
}

test('real PostgreSQL delivers an SOS despite quiet/history preferences and records FCM evidence', { skip }, async () => {
  await withFreshDatabase(async ({ client, pool }) => {
    await seedGuardianAndChild(client);
    await client.query(
      `INSERT INTO family_sos_alerts
         (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
          location_class, connection_class)
       VALUES ($1, $2, $3, 'guardian', $4, '2026-05-10T15:45:00Z', 'unavailable', 'online')`,
      [ALERT, FAMILY, CHILD, MEMBERSHIP],
    );
    await client.query(
      `INSERT INTO family_sos_alert_deliveries
         (id, alert_id, family_id, recipient_kind, recipient_membership_id,
          channel, delivery_state)
       VALUES (gen_random_uuid(), $1, $2, 'guardian', $3, 'push', 'recorded')`,
      [ALERT, FAMILY, MEMBERSHIP],
    );
    await client.query(
      `INSERT INTO outbox_events
         (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
       VALUES ($1, 'family', $2, gen_random_uuid(), 'family.sos_alert_raised', 'sos.raised', $3::jsonb)`,
      [SOS_OUTBOX, FAMILY, JSON.stringify({ subjectType: 'sos_alert', subjectId: ALERT })],
    );
    await client.query(
      `INSERT INTO family_notification_preferences
         (family_id, membership_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
          push_allowed, delivery_mode)
       VALUES ($1, $2, TRUE, '21:00', '07:00', FALSE, 'history_only')`,
      [FAMILY, MEMBERSHIP],
    );

    const sender = acceptedSender();
    const deliveredAt = new Date('2026-05-10T15:46:00.000Z');
    const dispatcher = new NotificationDispatcher(sender, () => pool.connect(), { now: () => deliveredAt });
    const result = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');

    assert.equal(result.status, 'delivered');
    assert.equal(sender.calls.length, 1, 'SOS must bypass quiet hours, push_allowed=false, and history_only');
    assert.equal(sender.calls[0].title, 'استغاثة من ليان');
    assert.equal(sender.calls[0].body, 'ضغط زر الاستغاثة الساعة ٣:٤٥ م');
    assert.equal(sender.calls[0].urgency, 'alert');
    assert.deepEqual(sender.calls[0].data, {
      type: 'family.sos_alert_raised',
      alertId: ALERT,
      childId: CHILD,
      copyKey: 'sos.raised',
      occurredAt: '2026-05-10T15:45:00.000Z',
    });
    assert.equal(JSON.stringify(sender.calls[0]).includes('latitude'), false);
    assert.equal(JSON.stringify(sender.calls[0]).includes('longitude'), false);

    const outbox = await client.query(
      `SELECT status, failure_reason, delivered_at FROM outbox_events WHERE id=$1`,
      [SOS_OUTBOX],
    );
    assert.deepEqual(outbox.rows[0], {
      status: 'delivered', failure_reason: null, delivered_at: deliveredAt,
    });
    const attempts = await client.query(
      `SELECT outcome, provider_message_id, failure_reason FROM outbox_delivery_attempts WHERE outbox_id=$1`,
      [SOS_OUTBOX],
    );
    assert.deepEqual(attempts.rows, [{
      outcome: 'delivered', provider_message_id: 'projects/family-os-test/messages/postgres-1', failure_reason: null,
    }]);
    const delivery = await client.query(
      `SELECT delivery_state, reason_code, delivered_at, fcm_message_id
         FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`,
      [ALERT],
    );
    assert.deepEqual(delivery.rows[0], {
      delivery_state: 'delivered', reason_code: null, delivered_at: deliveredAt,
      fcm_message_id: 'projects/family-os-test/messages/postgres-1',
    });
    const payload = await client.query(`SELECT payload FROM outbox_events WHERE id=$1`, [SOS_OUTBOX]);
    assert.equal(JSON.stringify(payload.rows[0].payload).includes('ليان'), false,
      'the child name must be resolved at dispatch time, not persisted in the outbox');

    for (const [id, observedState, time] of [
      [HEALTHY_PROTECTION_OUTBOX, 'healthy', '2026-05-10T16:00:00.000Z'],
      [RISK_PROTECTION_OUTBOX, 'vpn_active', '2026-05-10T16:01:00.000Z'],
    ]) {
      await client.query(
        `INSERT INTO outbox_events
           (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
         VALUES ($1, 'family', $2, gen_random_uuid(), 'family.device_protection_reported', 'protection.reported', $3::jsonb)`,
        [id, FAMILY, JSON.stringify({ deviceId: DEVICE, observedState, occurredAt: time })],
      );
    }
    const healthy = await dispatcher.notify(HEALTHY_PROTECTION_OUTBOX, 'family.device_protection_reported');
    assert.deepEqual(healthy, {
      outboxId: HEALTHY_PROTECTION_OUTBOX,
      status: 'skipped',
      reason: 'protection_observation_not_alertable',
    });
    assert.equal(sender.calls.length, 1, 'a healthy report must not be announced as disabled protection');

    const atRisk = await dispatcher.notify(RISK_PROTECTION_OUTBOX, 'family.device_protection_reported');
    assert.equal(atRisk.status, 'delivered');
    assert.equal(sender.calls.length, 2);
    assert.equal(sender.calls[1].title, 'حالة الحماية على جهاز ليان تحتاج إلى مراجعة');
    assert.equal(sender.calls[1].body, 'أبلغ الجهاز عن مؤشر يؤثر في الحماية الساعة ٤:٠١ م');
    assert.equal(sender.calls[1].urgency, 'high');
    assert.deepEqual(sender.calls[1].data, {
      type: 'family.device_protection_reported',
      childId: CHILD,
      deviceId: DEVICE,
      copyKey: 'protection.reported',
      occurredAt: '2026-05-10T16:01:00.000Z',
    });
    const protectionStatus = await client.query(
      `SELECT id, status, failure_reason FROM outbox_events
        WHERE id = ANY($1::uuid[]) ORDER BY id`,
      [[HEALTHY_PROTECTION_OUTBOX, RISK_PROTECTION_OUTBOX]],
    );
    assert.deepEqual(protectionStatus.rows.map((row) => [row.id, row.status, row.failure_reason]), [
      [HEALTHY_PROTECTION_OUTBOX, 'skipped', 'protection_observation_not_alertable'],
      [RISK_PROTECTION_OUTBOX, 'delivered', null],
    ]);
  });
});

test('real PostgreSQL fails closed for an unknown outbox type and retains a safe reason', { skip }, async () => {
  await withFreshDatabase(async ({ client, pool }) => {
    await client.query(
      `INSERT INTO outbox_events
         (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
       VALUES ($1, 'family', $2, gen_random_uuid(), 'family.future_event', NULL, '{}'::jsonb)`,
      [UNKNOWN_OUTBOX, FAMILY],
    );
    const dispatcher = new NotificationDispatcher(acceptedSender(), () => pool.connect());
    await assert.rejects(
      dispatcher.notify(UNKNOWN_OUTBOX, 'family.future_event'),
      /unclassified_outbox_event_type/,
    );
    const failed = await client.query(
      `SELECT status, failure_reason FROM outbox_events WHERE id=$1`,
      [UNKNOWN_OUTBOX],
    );
    assert.deepEqual(failed.rows[0], { status: 'failed', failure_reason: 'unclassified_event_type' });
  });
});
