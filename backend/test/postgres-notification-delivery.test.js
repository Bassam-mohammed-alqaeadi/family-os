// S1 notification delivery against PGlite. The provider is a deterministic fake, but SQL,
// constraints, outbox leases, preference filtering, delivery attempts and token removal are real.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { PGlite } from '@electric-sql/pglite';
import { NotificationDispatcher } from '../src/notification-dispatcher.js';
import { FcmDeliveryError } from '../src/fcm-sender.js';
import { postgresLocationPort } from '../src/location-telemetry.js';

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
  '123_notification_retries.sql','124_geofence_notification_payload_minimization.sql',
  // Kept in sync by hand, and 135 had drifted out of it: the dispatcher joins
  // family_customization_profiles for the family's digits, so this harness must
  // create that table or it is testing a schema production no longer has.
  '135_family_customization_profile.sql',
];

const FAMILY = 'aaaaaaaa-1111-4111-8111-111111111111';
const ACCOUNT = 'bbbbbbbb-2222-4222-8222-222222222222';
const MEMBERSHIP = 'cccccccc-3333-4333-8333-333333333333';
const CHILD = 'dddddddd-4444-4444-8444-444444444444';
const DEVICE = 'abababab-2222-4222-8222-222222222222';
const ALERT = 'eeeeeeee-5555-4555-8555-555555555555';
const ZONE = 'ffffffff-6666-4666-8666-666666666666';
const REGISTRATION = '11111111-7777-4777-8777-777777777777';
const TOKEN = 'fcm-token-0123456789abcdef0123456789abcdef';
const OUTBOX = '22222222-8888-4888-8888-888888888888';
const SOS_OUTBOX = '33333333-9999-4999-8999-999999999999';
const UNKNOWN_OUTBOX = '44444444-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HEALTHY_PROTECTION_OUTBOX = '55555555-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const RISK_PROTECTION_OUTBOX = '66666666-cccc-4ccc-8ccc-cccccccccccc';

async function freshDb() {
  const db = new PGlite();
  for (const name of migrations) await db.exec(readFileSync(join(migrationsDir, name), 'utf8'));
  return db;
}

async function seedFamily(db, { locale = 'ar', token = TOKEN, numerals = 'eastern' } = {}) {
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
    `INSERT INTO family_safe_zones
       (id, family_id, name, geometry_kind, center_lat, center_lng, radius_meters, created_by_membership_id)
     VALUES ($1, $2, 'المدرسة', 'CIRCLE', 15, 44, 250, $3)`,
    [ZONE, FAMILY, MEMBERSHIP],
  );
  await db.query(
    `INSERT INTO family_push_registrations
       (id, family_id, membership_id, token, platform, locale)
     VALUES ($1, $2, $3, $4, 'android', $5)`,
    [REGISTRATION, FAMILY, MEMBERSHIP, token, locale],
  );
  // How this family writes its digits is a customization fact stored on the family
  // profile, and the dispatcher joins that table. So every Arabic assertion below
  // that expects ٦:٢٠ can only pass while that join is live — a profile nobody
  // reads would turn them Western and this file would say so.
  await db.query(
    `INSERT INTO family_customization_profiles
       (family_id, numerals, updated_by_membership_id)
     VALUES ($1, $2, $3)`,
    [FAMILY, numerals, MEMBERSHIP],
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
      occurredAt: '2026-05-10T06:20:00.000Z',
    })],
  );
}

async function insertSosEvent(db, { membershipIds = [MEMBERSHIP], outboxId = SOS_OUTBOX } = {}) {
  await db.query(
    `INSERT INTO family_sos_alerts
       (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
        location_class, connection_class)
     VALUES ($1, $2, $3, 'guardian', $4, '2026-05-10T15:45:00Z', 'unavailable', 'online')`,
    [ALERT, FAMILY, CHILD, MEMBERSHIP],
  );
  for (const membershipId of membershipIds) {
    await db.query(
      `INSERT INTO family_sos_alert_deliveries
         (id, alert_id, family_id, recipient_kind, recipient_membership_id, channel, delivery_state)
       VALUES (gen_random_uuid(), $1, $2, 'guardian', $3, 'push', 'recorded')`,
      [ALERT, FAMILY, membershipId],
    );
  }
  await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, gen_random_uuid(), 'family.sos_alert_raised', 'sos.raised', $3::jsonb)`,
    [outboxId, FAMILY, JSON.stringify({ subjectType: 'sos_alert', subjectId: ALERT })],
  );
}

test('the geofence producer persists identifiers and event time, never zone labels or coordinates', async () => {
  const db = await freshDb();
  const locationPort = postgresLocationPort({}, { credentialMatches: () => true });
  await locationPort.notify(db, {
    familyId: FAMILY,
    zoneId: ZONE,
    zoneName: 'Secret home label',
    childId: CHILD,
    deviceId: DEVICE,
    fixId: '77777777-8888-4888-8888-888888888888',
    kind: 'ENTER',
    zoneVersion: 3,
    occurredAt: '2026-05-10T06:20:00.000Z',
    latitude: 15.3,
    longitude: 44.2,
    correlationId: '99999999-8888-4888-8888-888888888888',
  });
  const { rows } = await db.query(
    `SELECT payload FROM outbox_events WHERE event_type='family.geofence_entered'`,
  );
  assert.equal(rows.length, 1);
  assert.deepEqual(rows[0].payload, {
    zoneId: ZONE,
    childId: CHILD,
    occurredAt: '2026-05-10T06:20:00.000Z',
  });
  for (const key of ['zoneName', 'latitude', 'longitude', 'deviceId', 'fixId', 'zoneVersion']) {
    assert.equal(Object.hasOwn(rows[0].payload, key), false);
  }
  await db.close();
});

test('120–124 apply and enforce registration, delivery, retry, and payload laws', async () => {
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
  assert.equal(sender.calls[0].body, 'دخل المنطقة الآمنة الساعة ٦:٢٠ ص بتوقيت UTC');
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
  for (const key of ['zoneName', 'latitude', 'longitude', 'locationLat', 'locationLng', 'coordinates']) {
    assert.equal(Object.hasOwn(source.rows[0].payload, key), false,
      `geofence notification payload must not persist ${key}`);
  }
  await db.close();
});

test('the same Arabic sentence keeps Western digits for a family that chose them', async () => {
  // The other half of one rule, through real SQL: the digits in a push line come
  // from the family profile, so the family that never picked Eastern is not
  // silently restyled by its handset language.
  const db = await freshDb();
  await seedFamily(db, { numerals: 'western' });
  await insertGeofenceOutbox(db);
  const sender = fakeSender();
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db), {
    now: () => new Date('2026-05-10T06:21:00.000Z'),
  });

  assert.equal((await dispatcher.notify(OUTBOX, 'family.geofence_entered')).status, 'delivered');
  assert.equal(sender.calls[0].body, 'دخل المنطقة الآمنة الساعة 6:20 ص بتوقيت UTC');
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
  assert.equal(sender.calls[0].body, 'Pressed the SOS button at 3:45 PM UTC');
  assert.equal(sender.calls[0].urgency, 'alert');
  const delivery = await db.query(`SELECT delivery_state, reason_code, delivered_at, fcm_message_id
    FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`, [ALERT]);
  assert.equal(delivery.rows[0].delivery_state, 'delivered');
  assert.equal(delivery.rows[0].reason_code, null);
  assert.equal(delivery.rows[0].fcm_message_id, 'projects/family-os-test/messages/sos-3');
  await db.close();
});

test('a transient provider failure is retried after persisted backoff without replaying accepted SOS delivery', async () => {
  const db = await freshDb();
  await seedFamily(db, { locale: 'en' });
  await insertSosEvent(db);
  const calls = [];
  const sender = {
    async send(args) {
      calls.push(args);
      if (calls.length === 1) throw new FcmDeliveryError('transient', 'provider_unavailable');
      args.onAccepted?.('projects/family-os-test/messages/retry-success');
      return 'sent';
    },
  };
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));

  const first = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(first.status, 'retry_scheduled');
  const attempt = await db.query(
    `SELECT attempt_number, outcome, retry_after_at > NOW() AS backoff_pending
       FROM outbox_delivery_attempts WHERE outbox_id=$1`,
    [SOS_OUTBOX],
  );
  assert.deepEqual(attempt.rows[0], {
    attempt_number: 1, outcome: 'retryable_failure', backoff_pending: true,
  });
  const outbox = await db.query(
    `SELECT status, available_at > NOW() AS backoff_pending FROM outbox_events WHERE id=$1`,
    [SOS_OUTBOX],
  );
  assert.deepEqual(outbox.rows[0], { status: 'pending', backoff_pending: true });

  // No further HTTP request or manual sweep is made: the one-shot timer must wake the
  // durable outbox after its persisted backoff expires while the process stays alive.
  await new Promise((resolve) => setTimeout(resolve, 6_500));
  const retryState = await db.query(
    'SELECT status FROM outbox_events WHERE id=$1', [SOS_OUTBOX],
  );
  assert.equal(retryState.rows[0].status, 'delivered');
  assert.equal(calls.length, 2);
  const retry = { processed: 1, results: [{ status: 'delivered' }] };
  assert.equal(retry.processed, 1);
  assert.equal(retry.results[0].status, 'delivered');
  assert.equal(calls.length, 2);
  const attempts = await db.query(
    `SELECT attempt_number, outcome, provider_message_id
       FROM outbox_delivery_attempts WHERE outbox_id=$1 ORDER BY attempt_number`,
    [SOS_OUTBOX],
  );
  assert.deepEqual(attempts.rows, [
    { attempt_number: 1, outcome: 'retryable_failure', provider_message_id: null },
    { attempt_number: 2, outcome: 'delivered', provider_message_id: 'projects/family-os-test/messages/retry-success' },
  ]);

  const duplicate = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(duplicate.claimed, false);
  assert.equal(calls.length, 2, 'a durable acceptance must not be sent a second time');
  await db.close();
});

test('transient delivery retries are capped at five attempts', async () => {
  const db = await freshDb();
  await seedFamily(db);
  await insertSosEvent(db);
  let calls = 0;
  const sender = {
    async send() {
      calls += 1;
      throw new FcmDeliveryError('transient', 'provider_unavailable');
    },
  };
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));
  let result = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(result.status, 'retry_scheduled');

  for (let completedAttempt = 1; completedAttempt < 5; completedAttempt += 1) {
    await db.query(`UPDATE outbox_events SET available_at=NOW() - INTERVAL '1 second' WHERE id=$1`, [SOS_OUTBOX]);
    await db.query(
      `UPDATE outbox_delivery_attempts SET retry_after_at=NOW() - INTERVAL '1 second'
        WHERE outbox_id=$1 AND outcome='retryable_failure'`,
      [SOS_OUTBOX],
    );
    const sweep = await dispatcher.sweep({ limit: 1 });
    result = sweep.results[0];
    assert.equal(sweep.processed, 1);
    assert.equal(result.status, completedAttempt === 4 ? 'failed' : 'retry_scheduled');
  }
  assert.equal(calls, 5);
  const attempts = await db.query(
    `SELECT attempt_number, outcome, failure_reason
       FROM outbox_delivery_attempts WHERE outbox_id=$1 ORDER BY attempt_number`,
    [SOS_OUTBOX],
  );
  assert.deepEqual(attempts.rows, [
    { attempt_number: 1, outcome: 'retryable_failure', failure_reason: 'provider_unavailable' },
    { attempt_number: 2, outcome: 'retryable_failure', failure_reason: 'provider_unavailable' },
    { attempt_number: 3, outcome: 'retryable_failure', failure_reason: 'provider_unavailable' },
    { attempt_number: 4, outcome: 'retryable_failure', failure_reason: 'provider_unavailable' },
    { attempt_number: 5, outcome: 'permanent_failure', failure_reason: 'retry_exhausted' },
  ]);
  const delivery = await db.query(
    `SELECT delivery_state, reason_code FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`,
    [ALERT],
  );
  assert.deepEqual(delivery.rows[0], { delivery_state: 'failed', reason_code: 'retry_exhausted' });
  await db.close();
});

test('a removed registration terminates its scheduled retry instead of leaving SOS delivery pending', async () => {
  const db = await freshDb();
  await seedFamily(db);
  await insertSosEvent(db);
  let calls = 0;
  const sender = {
    async send() {
      calls += 1;
      throw new FcmDeliveryError('transient', 'provider_unavailable');
    },
  };
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));

  const first = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(first.status, 'retry_scheduled');
  await db.query(`DELETE FROM family_push_registrations WHERE id=$1`, [REGISTRATION]);
  await db.query(`UPDATE outbox_events SET available_at=NOW() - INTERVAL '1 second' WHERE id=$1`, [SOS_OUTBOX]);
  await db.query(
    `UPDATE outbox_delivery_attempts SET retry_after_at=NOW() - INTERVAL '1 second'
      WHERE outbox_id=$1 AND outcome='retryable_failure'`,
    [SOS_OUTBOX],
  );

  const retry = await dispatcher.sweep({ limit: 1 });
  assert.equal(retry.processed, 1);
  assert.equal(retry.results[0].status, 'failed');
  assert.equal(calls, 1, 'a retry is not sent to a registration that no longer exists');
  const attempt = await db.query(
    `SELECT outcome, failure_reason, retry_after_at FROM outbox_delivery_attempts WHERE outbox_id=$1`,
    [SOS_OUTBOX],
  );
  assert.deepEqual(attempt.rows[0], {
    outcome: 'permanent_failure', failure_reason: 'registration_unavailable', retry_after_at: null,
  });
  const delivery = await db.query(
    `SELECT delivery_state, reason_code FROM family_sos_alert_deliveries WHERE alert_id=$1 AND channel='push'`,
    [ALERT],
  );
  assert.deepEqual(delivery.rows[0], { delivery_state: 'failed', reason_code: 'registration_unavailable' });
  const outbox = await db.query(`SELECT status FROM outbox_events WHERE id=$1`, [SOS_OUTBOX]);
  assert.equal(outbox.rows[0].status, 'failed');
  await db.close();
});

test('SOS with no active registrations fails every push recipient instead of leaving recorded rows', async () => {
  const db = await freshDb();
  await seedFamily(db);
  await db.query(`DELETE FROM family_push_registrations WHERE family_id=$1`, [FAMILY]);
  await insertSosEvent(db);
  const sender = fakeSender();
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));

  const result = await dispatcher.notify(SOS_OUTBOX, 'family.sos_alert_raised');
  assert.equal(result.status, 'failed');
  assert.equal(result.reason, 'no_active_registration');
  assert.equal(sender.calls.length, 0);
  const delivery = await db.query(
    `SELECT delivery_state, reason_code FROM family_sos_alert_deliveries
      WHERE alert_id=$1 AND channel='push'`,
    [ALERT],
  );
  assert.deepEqual(delivery.rows[0], { delivery_state: 'failed', reason_code: 'push_registration_absent' });
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

test('healthy protection reports are skipped; a tamper observation alerts the guardian without overclaiming', async () => {
  const db = await freshDb();
  await seedFamily(db);
  await db.query(
    `INSERT INTO family_child_devices (id, family_id, child_id, device_label)
     VALUES ($1, $2, $3, 'Layan Android')`,
    [DEVICE, FAMILY, CHILD],
  );
  for (const [id, observedState, time] of [
    [HEALTHY_PROTECTION_OUTBOX, 'healthy', '2026-05-10T10:00:00.000Z'],
    [RISK_PROTECTION_OUTBOX, 'vpn_active', '2026-05-10T11:00:00.000Z'],
  ]) {
    await db.query(
      `INSERT INTO outbox_events
         (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
       VALUES ($1, 'family', $2, gen_random_uuid(), 'family.device_protection_reported', 'protection.reported', $3::jsonb)`,
      [id, FAMILY, JSON.stringify({ deviceId: DEVICE, occurredAt: time, observedState })],
    );
  }
  const sender = fakeSender();
  const dispatcher = new NotificationDispatcher(sender, clientFactory(db));

  const healthy = await dispatcher.notify(HEALTHY_PROTECTION_OUTBOX, 'family.device_protection_reported');
  assert.deepEqual(healthy, {
    outboxId: HEALTHY_PROTECTION_OUTBOX,
    status: 'skipped',
    reason: 'protection_observation_not_alertable',
  });
  assert.equal(sender.calls.length, 0, 'a healthy observation must not say protection is disabled');

  const atRisk = await dispatcher.notify(RISK_PROTECTION_OUTBOX, 'family.device_protection_reported');
  assert.equal(atRisk.status, 'delivered');
  assert.equal(sender.calls.length, 1);
  assert.equal(sender.calls[0].title, 'حالة الحماية على جهاز ليان تحتاج إلى مراجعة');
  assert.equal(sender.calls[0].body, 'أبلغ الجهاز عن مؤشر يؤثر في الحماية الساعة ١١:٠٠ ص بتوقيت UTC');
  assert.equal(sender.calls[0].urgency, 'high');
  assert.equal(sender.calls[0].channelId, 'familyos_protection_alerts');
  assert.deepEqual(sender.calls[0].data, {
    type: 'family.device_protection_reported',
    childId: CHILD,
    deviceId: DEVICE,
    copyKey: 'protection.reported',
    occurredAt: '2026-05-10T11:00:00.000Z',
  });
  const statuses = await db.query(
    `SELECT id, status, failure_reason FROM outbox_events
      WHERE id = ANY($1::uuid[]) ORDER BY id`,
    [[HEALTHY_PROTECTION_OUTBOX, RISK_PROTECTION_OUTBOX]],
  );
  assert.deepEqual(statuses.rows.map((row) => [row.id, row.status, row.failure_reason]), [
    [HEALTHY_PROTECTION_OUTBOX, 'skipped', 'protection_observation_not_alertable'],
    [RISK_PROTECTION_OUTBOX, 'delivered', null],
  ]);
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
