// S1 notification delivery against PGlite. The provider is a deterministic fake, but SQL,
// constraints, outbox leases, preference filtering, delivery attempts and token removal are real.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { PGlite } from '@electric-sql/pglite';
import { NotificationDispatcher } from '../src/notification-dispatcher.js';

const here = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(here, '..', 'db', 'migrations');
const migrations = [
  '001_foundation.sql','002_membership_lifecycle.sql','003_guardian_continuity.sql',
  '004_audit_correlation.sql','005_family_children_roster.sql','006_family_child_presentation.sql',
  '007_device_telemetry.sql','008_native_device_pairing.sql','100_ai_events.sql',
  '101_device_lifecycle.sql','102_safe_zones.sql','103_location_stream.sql',
  '104_sos_emergency.sql','105_screen_time.sql','106_web_filter.sql',
  '107_family_tasks.sql','108_family_calendar.sql','109_family_chat.sql',
  '110_collaboration_flexibility.sql','111_collaboration_audiences.sql',
  '112_family_chat_realtime_media.sql','113_family_push_registrations.sql',
  '114_child_consents.sql','115_family_invite_codes.sql','116_location_retention_erasure.sql',
  '117_device_capabilities.sql','118_command_lifecycle.sql','119_ai_events_security_envelope.sql',
  '120_device_push_registrations.sql','121_delivery_states.sql','122_family_notification_preferences.sql',
];

const FAMILY = 'aaaaaaaa-1111-4111-8111-111111111111';
const ACCOUNT = 'bbbbbbbb-2222-4222-8222-222222222222';
const MEMBERSHIP = 'cccccccc-3333-4333-8333-333333333333';
const CHILD = 'dddddddd-4444-4444-8444-444444444444';
const ALERT = 'eeeeeeee-5555-4555-8555-555555555555';
const ZONE = 'ffffffff-6666-4666-8666-666666666666';
const REGISTRATION = '11111111-7777-4777-8777-777777777777';
const TOKEN = 'fcm-token-0123456789abcdef0123456789abcdef';
const OUTBOX = '22222222-8888-4888-8888-888888888888';
const SOS_OUTBOX = '33333333-9999-4999-8999-999999999999';
const UNKNOWN_OUTBOX = '44444444-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

async function freshDb() {
  const db = new PGlite();
  for (const name of migrations) await db.exec(readFileSync(join(migrationsDir, name), 'utf8'));
  return db;
}

async function seedFamily(db, { locale = 'ar', token = TOKEN } = {}) {
  await db.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 'notification-test-subject')`, [ACCOUNT]);
  await db.query(`INSERT INTO families (id, display_name) VALUES ($1, 'عائلة الاختبار')`, [FAMILY]);
  await db.query(
    `INSERT INTO family_memberships
       (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES ($1, $2, $3, 'notification-test-subject', 'primary_guardian', 'active', NOW())`,
    [MEMBERSHIP, FAMILY, ACCOUNT],
  );
  await db.query(`UPDATE families SET primary_membership_id=$2 WHERE id=$1`, [FAMILY, MEMBERSHIP]);
  await db.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES ($1, $2, 'ليان', 10)`,
    [CHILD, FAMILY],
  );
  await db.query(
    `INSERT INTO family_push_registrations
       (id, family_id, membership_id, token, platform, locale)
     VALUES ($1, $2, $3, $4, 'android', $5)`,
    [REGISTRATION, FAMILY, MEMBERSHIP, token, locale],
  );
}

function clientFactory(db) {
  return async () => ({ query: db.query.bind(db), release() {} });
}

function fakeSender({ result = 'sent', messageId = 'projects/family-os-test/messages/42' } = {}) {
  const calls = [];
  return {
    calls,
    async send(args) {
      calls.push(args);
      if (result === 'sent') args.onAccepted?.(messageId);
      return result;
    },
  };
}

async function insertGeofenceOutbox(db, { id = OUTBOX, copyKey = 'geofence.entered' } = {}) {
  await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, gen_random_uuid(), 'family.geofence_entered', $3, $4::jsonb)`,
    [id, FAMILY, copyKey, JSON.stringify({
      childId: CHILD,
      zoneId: ZONE,
      zoneName: 'المدرسة',
      occurredAt: '2026-05-10T06:20:00.000Z',
    })],
  );
}

test('120–122 apply and enforce owner XOR, notification copy keys, and never-silence safety keys', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE registration_test (LIKE family_push_registrations INCLUDING ALL)`);
  await assert.rejects(() => db.query(`
    INSERT INTO registration_test (family_id, membership_id, device_id, token, platform, locale)
    VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), '${TOKEN}', 'android', 'ar')`),
  /family_push_registrations_owner_xor/);
  await assert.rejects(() => db.query(`
    INSERT INTO registration_test (family_id, token, platform, locale)
    VALUES (gen_random_uuid(), '${TOKEN}-neither', 'android', 'ar')`),
  /family_push_registrations_owner_xor/);

  await assert.rejects(() => db.query(`
    INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), 'family', gen_random_uuid(), 'family.geofence_entered', '{}'::jsonb)`),
  /outbox_events_copy_key_pair/);

  await db.exec(`CREATE TEMP TABLE preference_test (LIKE family_notification_preferences INCLUDING ALL)`);
  for (const key of ['sos.raised', 'geofence.entered', 'geofence.exited', 'protection.reported']) {
    await assert.rejects(() => db.query(
      `INSERT INTO preference_test (family_id, membership_id, disabled_copy_keys)
       VALUES (gen_random_uuid(), gen_random_uuid(), ARRAY[$1]::text[])`,
      [key],
    ), /family_notification_preferences_never_silence_safety/);
  }
  await db.close();
});

test('a committed Arabic geofence event is formatted, routed to FCM, and recorded as delivered', async () => {
  const db = await freshDb();
  await seedFamily(db);
  await insertGeofenceOutbox(db);
  const sender = fakeSender();
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db), {
    now: () => new Date('2026-05-10T06:21:00.000Z'),
  });

  const result = await dispatcher.notify(OUTBOX, 'family.geofence_entered');
  assert.equal(result.status, 'delivered');
  assert.equal(result.deliveredCount, 1);
  assert.equal(sender.calls.length, 1);
  assert.equal(sender.calls[0].title, 'ليان وصل إلى المدرسة');
  assert.equal(sender.calls[0].body, 'دخل المنطقة الآمنة الساعة ٦:٢٠ ص');
  assert.equal(sender.calls[0].ttlSeconds, 1800);
  assert.equal(sender.calls[0].urgency, 'alert');
  assert.equal(sender.calls[0].channelId, 'familyos_geofence_alerts');
  assert.deepEqual(sender.calls[0].data, {
    type: 'family.geofence_entered',
    childId: CHILD,
    zoneId: ZONE,
    copyKey: 'geofence.entered',
    occurredAt: '2026-05-10T06:20:00.000Z',
  });

  const outbox = await db.query(`SELECT status, failure_reason, delivered_at, copy_key FROM outbox_events WHERE id=$1`, [OUTBOX]);
  assert.deepEqual(outbox.rows[0], {
    status: 'delivered', failure_reason: null, delivered_at: new Date('2026-05-10T06:21:00.000Z'), copy_key: 'geofence.entered',
  });
  const attempts = await db.query(`SELECT copy_key, outcome, provider_message_id, failure_reason FROM outbox_delivery_attempts WHERE outbox_id=$1`, [OUTBOX]);
  assert.deepEqual(attempts.rows, [{
    copy_key: 'geofence.entered', outcome: 'delivered',
    provider_message_id: 'projects/family-os-test/messages/42', failure_reason: null,
  }]);
  const source = await db.query(`SELECT payload FROM outbox_events WHERE id=$1`, [OUTBOX]);
  assert.equal(JSON.stringify(source.rows[0].payload).includes('ليان'), false,
    'the child name must be resolved from family_children at send time, not stored in the outbox');
  await db.close();
});

test('SOS overrides quiet/digest/history preferences and writes provider evidence to SOS delivery', async () => {
  const db = await freshDb();
  await seedFamily(db, { locale: 'en' });
  await db.query(
    `INSERT INTO family_sos_alerts
       (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
        location_class, connection_class)
     VALUES ($1, $2, $3, 'guardian', $4, '2026-05-10T15:45:00Z', 'unavailable', 'online')`,
    [ALERT, FAMILY, CHILD, MEMBERSHIP],
  );
  await db.query(
    `INSERT INTO family_sos_alert_deliveries
       (id, alert_id, family_id, recipient_kind, recipient_membership_id,
        channel, delivery_state)
     VALUES (gen_random_uuid(), $1, $2, 'guardian', $3, 'push', 'recorded')`,
    [ALERT, FAMILY, MEMBERSHIP],
  );
  await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, gen_random_uuid(), 'family.sos_alert_raised', 'sos.raised', $3::jsonb)`,
    [SOS_OUTBOX, FAMILY, JSON.stringify({ subjectType: 'sos_alert', subjectId: ALERT })],
  );
  await db.query(
    `INSERT INTO family_notification_preferences
       (family_id, membership_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
        push_allowed, delivery_mode)
     VALUES ($1, $2, TRUE, '21:00', '07:00', FALSE, 'history_only')`,
    [FAMILY, MEMBERSHIP],
  );
  const sender = fakeSender({ messageId: 'projects/family-os-test/messages/sos-3' });
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db), {
    now: () => new Date('2026-05-10T15:46:00.000Z'),
  });

  const result = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(result.status, 'delivered');
  assert.equal(sender.calls.length, 1, 'SOS is not muted by quiet hours, push toggle, or history-only mode');
  assert.equal(sender.calls[0].title, 'ليان needs help');
  assert.equal(sender.calls[0].body, 'Pressed the SOS button at 3:45 PM');
  assert.equal(sender.calls[0].urgency, 'alert');
  const delivery = await db.query(`SELECT delivery_state, reason_code, delivered_at, fcm_message_id
    FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`, [ALERT]);
  assert.equal(delivery.rows[0].delivery_state, 'delivered');
  assert.equal(delivery.rows[0].reason_code, null);
  assert.equal(delivery.rows[0].fcm_message_id, 'projects/family-os-test/messages/sos-3');
  await db.close();
});

test('FCM unregistered result is recorded without token data and removes that registration', async () => {
  const db = await freshDb();
  await seedFamily(db, { locale: 'ar' });
  await insertGeofenceOutbox(db);
  const sender = fakeSender({ result: 'unregistered' });
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));

  const result = await dispatcher.notify(OUTBOX, 'family.geofence_entered');
  assert.equal(result.status, 'failed');
  assert.equal(result.removedCount, 1);
  assert.equal(result.failedCount, 0);
  const registrations = await db.query(`SELECT count(*)::int AS count FROM family_push_registrations`);
  assert.equal(registrations.rows[0].count, 0);
  const attempts = await db.query(`SELECT outcome, failure_reason, provider_message_id FROM outbox_delivery_attempts WHERE outbox_id=$1`, [OUTBOX]);
  assert.deepEqual(attempts.rows, [{ outcome: 'unregistered', failure_reason: null, provider_message_id: null }]);
  const outbox = await db.query(`SELECT status, failure_reason FROM outbox_events WHERE id=$1`, [OUTBOX]);
  assert.deepEqual(outbox.rows[0], { status: 'failed', failure_reason: 'all_tokens_unregistered' });
  await db.close();
});

test('unknown outbox events are failed closed, logged, and rethrown', async () => {
  const db = await freshDb();
  await db.query(
    `INSERT INTO outbox_events (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, gen_random_uuid(), 'family.future_event', NULL, '{}'::jsonb)`,
    [UNKNOWN_OUTBOX, FAMILY],
  );
  const dispatcher = new NotificationDispatcher(fakeSender(), clientFactory(db));

  await assert.rejects(dispatcher.notify(UNKNOWN_OUTBOX, 'family.future_event'), /unclassified_outbox_event_type/);
  const failed = await db.query(`SELECT status, failure_reason FROM outbox_events WHERE id=$1`, [UNKNOWN_OUTBOX]);
  assert.deepEqual(failed.rows[0], { status: 'failed', failure_reason: 'unclassified_event_type' });
  await db.close();
});
