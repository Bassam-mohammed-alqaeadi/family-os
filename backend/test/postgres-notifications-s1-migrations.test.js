// S1 notifications — migrations 120–124 apply cleanly on a real-Postgres-compatible
// runtime and the CHECK/UNIQUE laws they promise actually fire. Mirrors the S0 spine
// file: CI runs every migration against PostgreSQL 16 in the `migration-and-integration`
// job; this unit-level file runs in the default `npm test` gate (no DATABASE_URL needed)
// so a broken law catches the author before push.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { PGlite } from '@electric-sql/pglite';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MIG_DIR = join(__dirname, '..', 'db', 'migrations');

const MIGRATIONS = [
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
];

const FAMILY = '00000000-0000-4000-8000-000000000001';
const MEMBERSHIP = '00000000-0000-4000-8000-000000000002';
const DEVICE = '00000000-0000-4000-8000-000000000003';
const TOKEN = 'fcm-token-0123456789abcdef0123456789abcdef';

async function freshDb({ through = null } = {}) {
  const db = new PGlite();
  await db.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY, checksum TEXT NOT NULL, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`);
  await db.exec(`SELECT pg_try_advisory_lock(hashtext('family-os-schema-migrations-v1'))`);
  for (const name of MIGRATIONS) {
    await db.exec(readFileSync(join(MIG_DIR, name), 'utf8'));
    await db.query(`INSERT INTO schema_migrations (name, checksum) VALUES ($1, 'sha')`, [name]);
    if (name === through) break;
  }
  return db;
}

test('all 33 migrations apply to an empty database in order', async () => {
  const db = await freshDb();
  const tables = await db.query(`SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename`);
  const names = tables.rows.map(r => r.tablename);
  assert.ok(names.includes('family_notification_preferences'),
    'family_notification_preferences must exist after migrations 120–124');
  const cols = await db.query(`SELECT column_name FROM information_schema.columns
     WHERE table_name='family_push_registrations' AND column_name='device_id'`);
  assert.equal(cols.rowCount, 1, 'push registrations must grow device_id in migration 120');
  await db.close();
});

test('123 adds bounded attempt history and retry evidence for notifications', async () => {
  const db = await freshDb();
  const columns = await db.query(`SELECT column_name FROM information_schema.columns
     WHERE table_name='outbox_delivery_attempts'`);
  const columnNames = new Set(columns.rows.map((row) => row.column_name));
  for (const name of ['attempt_number', 'retry_after_at', 'recipient_membership_id']) {
    assert.ok(columnNames.has(name), `${name} must be durable on each provider attempt`);
  }
  for (const name of [
    'outbox_delivery_attempts_outcome_check',
    'outbox_delivery_attempts_attempt_number_bounded',
    'outbox_delivery_attempts_outcome_evidence',
    'outbox_delivery_attempts_one_per_attempt',
  ]) {
    const result = await db.query(`SELECT conname FROM pg_constraint WHERE conname=$1`, [name]);
    assert.equal(result.rowCount, 1, `${name} must exist`);
  }
  const oldUnique = await db.query(
    `SELECT conname FROM pg_constraint WHERE conname='outbox_delivery_attempts_one_per_registration'`,
  );
  assert.equal(oldUnique.rowCount, 0, 'multiple numbered attempts must be possible for one registration');
  await db.close();
});

test('123 preserves legacy failed attempts as ambiguous instead of replaying them', async () => {
  const db = await freshDb({ through: '122_family_notification_preferences.sql' });
  const inserted = await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES (gen_random_uuid(), 'family', gen_random_uuid(), gen_random_uuid(),
             'family.sos_alert_raised', 'sos.raised', '{}'::jsonb)
     RETURNING id`,
  );
  await db.query(
    `INSERT INTO outbox_delivery_attempts
       (outbox_id, registration_id, copy_key, outcome, failure_reason)
     VALUES ($1, gen_random_uuid(), 'sos.raised', 'failed', 'legacy_failure')`,
    [inserted.rows[0].id],
  );
  await db.exec(readFileSync(join(MIG_DIR, '123_notification_retries.sql'), 'utf8'));
  const { rows } = await db.query(
    `SELECT attempt_number, outcome, failure_reason, retry_after_at
       FROM outbox_delivery_attempts WHERE outbox_id=$1`,
    [inserted.rows[0].id],
  );
  assert.deepEqual(rows[0], {
    attempt_number: 1, outcome: 'ambiguous', failure_reason: 'legacy_failure', retry_after_at: null,
  });
  await db.close();
});

test('124 removes legacy zone labels and coordinates from persisted geofence payloads', async () => {
  const db = await freshDb({ through: '123_notification_retries.sql' });
  const childId = '00000000-0000-4000-8000-000000000011';
  const zoneId = '00000000-0000-4000-8000-000000000012';
  const inserted = await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES (gen_random_uuid(), 'family', gen_random_uuid(), gen_random_uuid(),
             'family.geofence_entered', 'geofence.entered', $1::jsonb)
     RETURNING id`,
    [JSON.stringify({
      childId, zoneId, zoneName: 'Private place', latitude: 15.3, longitude: 44.2,
      deviceId: '00000000-0000-4000-8000-000000000013',
      fixId: '00000000-0000-4000-8000-000000000014',
      kind: 'ENTER', zoneVersion: 2, occurredAt: '2026-05-10T06:20:00.000Z',
    })],
  );
  await db.exec(readFileSync(join(MIG_DIR, '124_geofence_notification_payload_minimization.sql'), 'utf8'));
  const { rows } = await db.query(`SELECT payload FROM outbox_events WHERE id=$1`, [inserted.rows[0].id]);
  assert.deepEqual(rows[0].payload, { childId, zoneId, occurredAt: '2026-05-10T06:20:00.000Z' });
  await db.close();
});

test('120 CHECK: a registration names exactly one owner (membership XOR device)', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE reg_test (LIKE family_push_registrations INCLUDING ALL)`);

  // Membership-only and device-only are the two honest shapes.
  await db.exec(`
    INSERT INTO reg_test (family_id, membership_id, token, platform, locale)
    VALUES ('${FAMILY}','${MEMBERSHIP}','${TOKEN}','android','ar')`);
  await db.exec(`
    INSERT INTO reg_test (family_id, device_id, token, platform, locale)
    VALUES ('${FAMILY}','${DEVICE}','${TOKEN}-device','android','ar')`);

  // Both owners at once is not a registration.
  await assert.rejects(() => db.exec(`
    INSERT INTO reg_test (family_id, membership_id, device_id, token, platform, locale)
    VALUES ('${FAMILY}','${MEMBERSHIP}','${DEVICE}','${TOKEN}-both','android','ar')`),
    /family_push_registrations_owner_xor/);

  // Neither owner is not a registration either (the old NOT NULL is gone; the XOR
  // must carry the law now).
  await assert.rejects(() => db.exec(`
    INSERT INTO reg_test (family_id, token, platform, locale)
    VALUES ('${FAMILY}','${TOKEN}-neither','android','ar')`),
    /family_push_registrations_owner_xor/);
  await db.close();
});

test('120 membership_id is nullable once the XOR law exists', async () => {
  const db = await freshDb();
  const col = await db.query(`SELECT is_nullable FROM information_schema.columns
    WHERE table_name='family_push_registrations' AND column_name='membership_id'`);
  assert.equal(col.rows[0].is_nullable, 'YES',
    'device-owned registrations must be storable without a membership');
  await db.close();
});

test('121 CHECK: delivered is a claim that must carry FCM evidence', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE del_test (LIKE family_sos_alert_deliveries INCLUDING ALL)`);
  const base = `(id, alert_id, family_id, recipient_kind, recipient_membership_id, channel, delivery_state, reason_code, delivered_at, fcm_message_id)`;
  const row = (state, { reason = null, at = null, evidence = null } = {}) =>
    `INSERT INTO del_test ${base}
     VALUES (gen_random_uuid(), gen_random_uuid(), '${FAMILY}', 'guardian', '${MEMBERSHIP}',
             'push', '${state}', ${reason ? `'${reason}'` : 'NULL'},
             ${at ? `NOW()` : 'NULL'}, ${evidence ? `'${evidence}'` : 'NULL'})`;

  // The two original states keep working exactly as before.
  await db.exec(row('recorded'));
  await db.exec(row('not_configured', { reason: 'push_not_configured' }));

  // A delivered row without its proof is a lie, in either direction.
  await assert.rejects(() => db.exec(row('delivered')),
    /family_sos_alert_deliveries_delivered_evidence/);
  await assert.rejects(() => db.exec(row('delivered', { at: new Date().toISOString() })),
    /family_sos_alert_deliveries_delivered_evidence/);

  // Proof without a delivered state is equally forbidden.
  await assert.rejects(() => db.exec(row('recorded', { evidence: 'projects/_/messages/1' })),
    /family_sos_alert_deliveries_evidence_pair/);

  // With both proofs the claim is storable.
  await db.exec(row('delivered', { at: new Date().toISOString(), evidence: 'projects/_/messages/1' }));

  // Failed names its reason; a reasonless failure is not honest.
  await assert.rejects(() => db.exec(row('failed')),
    /family_sos_alert_deliveries_reason_pair/);
  await db.exec(row('failed', { reason: 'unregistered' }));

  // The old pairing law is gone: a reason on a recorded row is now refused by the
  // wider law (it used to be refused by a narrower one).
  await assert.rejects(() => db.exec(row('recorded', { reason: 'leftover' })),
    /family_sos_alert_deliveries_reason_pair/);

  // No invented states.
  await assert.rejects(() => db.exec(row('sent')),
    /family_sos_alert_deliveries_state_known/);
  await db.close();
});

test('122 preferences: one row per membership, quiet hours come as a pair', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE pref_test (LIKE family_notification_preferences INCLUDING ALL)`);

  // The honest defaults: no quiet, push allowed, interrupt.
  await db.exec(`
    INSERT INTO pref_test (family_id, membership_id)
    VALUES ('${FAMILY}','${MEMBERSHIP}')`);

  // A second row for the same membership is a retry, not a second preference.
  // (A LIKE-copied table reports the unique index's own name, not the constraint's.)
  await assert.rejects(() => db.exec(`
    INSERT INTO pref_test (family_id, membership_id)
    VALUES ('${FAMILY}','${MEMBERSHIP}')`),
    /duplicate key value violates unique constraint/);

  // Quiet hours are both ends or nothing.
  await assert.rejects(() => db.exec(`
    INSERT INTO pref_test (family_id, membership_id, quiet_hours_enabled, quiet_hours_start)
    VALUES ('${FAMILY}','00000000-0000-4000-8000-000000000009', TRUE, '21:00')`),
    /family_notification_preferences_quiet_pair/);
  await db.exec(`
    INSERT INTO pref_test (family_id, membership_id, quiet_hours_enabled, quiet_hours_start, quiet_hours_end)
    VALUES ('${FAMILY}','00000000-0000-4000-8000-000000000009', TRUE, '21:00', '07:00')`);

  // The delivery mode is a closed vocabulary.
  await assert.rejects(() => db.exec(`
    INSERT INTO pref_test (family_id, membership_id, delivery_mode)
    VALUES ('${FAMILY}','00000000-0000-4000-8000-00000000000a', 'whenever')`),
    /delivery_mode_check|family_notification_preferences/);
  await db.close();
});

test('122 CHECK: a notification outbox event cannot omit its reviewed copy key', async () => {
  const db = await freshDb();
  await assert.rejects(() => db.query(`
    INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, payload)
    VALUES (gen_random_uuid(), 'family', gen_random_uuid(), 'family.sos_alert_raised', '{}'::jsonb)`),
  /outbox_events_copy_key_pair/);

  await db.query(`
    INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, copy_key, payload)
    VALUES (gen_random_uuid(), 'family', gen_random_uuid(), 'family.sos_alert_raised', 'sos.raised', '{}'::jsonb)`);
  await db.close();
});

test('122 CHECK: safety copy keys can never be disabled by preferences', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE pref_test (LIKE family_notification_preferences INCLUDING ALL)`);
  await assert.rejects(() => db.query(`
    INSERT INTO pref_test (family_id, membership_id, disabled_copy_keys)
    VALUES ('${FAMILY}','${MEMBERSHIP}', ARRAY['sos.raised'])`),
  /family_notification_preferences_never_silence_safety/);
  await assert.rejects(() => db.query(`
    INSERT INTO pref_test (family_id, membership_id, disabled_copy_keys)
    VALUES ('${FAMILY}','${MEMBERSHIP}', ARRAY['geofence.exited'])`),
  /family_notification_preferences_never_silence_safety/);
  await assert.rejects(() => db.query(`
    INSERT INTO pref_test (family_id, membership_id, disabled_copy_keys)
    VALUES ('${FAMILY}','${MEMBERSHIP}', ARRAY['protection.reported'])`),
  /family_notification_preferences_never_silence_safety/);
  await db.close();
});

test('120–124 named constraints exist on the real tables', async () => {
  const db = await freshDb();
  const needed = [
    'family_push_registrations_owner_xor',
    'family_push_registrations_device_fk',
    'family_sos_alert_deliveries_state_known',
    'family_sos_alert_deliveries_reason_pair',
    'family_sos_alert_deliveries_delivered_evidence',
    'family_sos_alert_deliveries_evidence_pair',
    'family_notification_preferences_one_per_membership',
    'family_notification_preferences_quiet_pair',
    'family_notification_preferences_never_silence_safety',
    'outbox_events_copy_key_pair',
    'outbox_events_failure_reason_pair',
    'outbox_events_delivered_at_pair',
    'outbox_delivery_attempts_outcome_check',
    'outbox_delivery_attempts_attempt_number_bounded',
    'outbox_delivery_attempts_outcome_evidence',
    'outbox_delivery_attempts_one_per_attempt',
  ];
  for (const name of needed) {
    const r = await db.query(`SELECT conname FROM pg_constraint WHERE conname=$1`, [name]);
    assert.equal(r.rowCount, 1, `${name} must exist after migrations 120–124`);
  }
  const gone = await db.query(`SELECT conname FROM pg_constraint WHERE conname='family_sos_alert_deliveries_reason_paired'`);
  assert.equal(gone.rowCount, 0, 'the narrow reason law must be replaced, not doubled');
  const tables = await db.query(`SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename='outbox_delivery_attempts'`);
  assert.equal(tables.rowCount, 1, 'outbox_delivery_attempts must exist after migrations 120–124');
  await db.close();
});
