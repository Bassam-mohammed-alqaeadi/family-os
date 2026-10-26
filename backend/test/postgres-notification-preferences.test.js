// Launch closure, slice س٣ — the door and the engine, on a real PostgreSQL engine.
//
// Migration 122 stored a guardian's wishes, migration 136 built the reader that honours them, and
// this file proves the two halves are wired to each other rather than each proving itself: a choice
// written through `PATCH …/me/notification-preferences` is the same row `notification-gating.js`
// consults, in the same units, with the same consequence. The last thing this suite would tolerate
// is a screen that writes a decoration and a gate that reads a different table.
//
// Everything SQL is real: the floors in migrations 122/136/137 fire by name, the version
// compare-and-set is a locked statement, and the audit row for a preference write is proven to
// carry no push. The provider is the only fake, because no credential belongs in a test.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { PGlite } from '@electric-sql/pglite';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';
import { NotificationDispatcher } from '../src/notification-dispatcher.js';
import { notificationPreferencesFor } from '../src/notification-preferences.js';

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
  '135_family_customization_profile.sql','136_notification_delivery_gating.sql',
  '137_notification_preferences_versioning.sql',
];

const FAMILY = 'a1a1a1a1-1111-4111-8111-111111111111';
const PRIMARY = 'b1b1b1b1-1111-4111-8111-111111111111';
const CO = 'c2c2c2c2-2222-4222-8222-222222222222';
const CHILD = 'd3d3d3d3-3333-4333-8333-333333333333';
const CHILD_ROSTER = 'e4e4e4e4-4444-4444-8444-444444444444';
const ACCOUNT_PRIMARY = 'f5f5f5f5-5555-4555-8555-555555555555';
const ACCOUNT_CO = '06060606-6666-4666-8666-666666666666';
const ACCOUNT_CHILD = '17171717-7777-4777-8777-777777777777';
const REG_PRIMARY = '28282828-8888-4888-8888-888888888881';
const REG_CO = '28282828-8888-4888-8888-888888888882';
const TOKEN_PRIMARY = 'fcm-token-primary-0123456789abcdef0123456789';
const TOKEN_CO = 'fcm-token-co-0123456789abcdef0123456789abcdef00';

const principal = (subject) => ({ subject });

async function freshDb() {
  const db = new PGlite();
  for (const name of migrations) await db.exec(readFileSync(join(migrationsDir, name), 'utf8'));
  await db.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 'pref-primary')`, [ACCOUNT_PRIMARY]);
  await db.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 'pref-co')`, [ACCOUNT_CO]);
  await db.query(`INSERT INTO accounts (id, oidc_subject) VALUES ($1, 'pref-child')`, [ACCOUNT_CHILD]);
  await db.query(`INSERT INTO families (id, display_name) VALUES ($1, 'أسرةُ البوّابة')`, [FAMILY]);
  await db.query(
    `INSERT INTO family_memberships
       (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES ($1, $2, $3, 'pref-primary', 'primary_guardian', 'active', NOW()),
            ($4, $2, $5, 'pref-co', 'co_guardian', 'active', NOW()),
            ($6, $2, $7, 'pref-child', 'child', 'active', NOW())`,
    [PRIMARY, FAMILY, ACCOUNT_PRIMARY, CO, ACCOUNT_CO, CHILD, ACCOUNT_CHILD],
  );
  await db.query(`UPDATE families SET primary_membership_id = $2 WHERE id = $1`, [FAMILY, PRIMARY]);
  await db.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES ($1, $2, 'ليان', 9)`,
    [CHILD_ROSTER, FAMILY],
  );
  for (const [registration, membership, token] of [
    [REG_PRIMARY, PRIMARY, TOKEN_PRIMARY], [REG_CO, CO, TOKEN_CO],
  ]) {
    await db.query(
      `INSERT INTO family_push_registrations
         (id, family_id, membership_id, token, platform, locale)
       VALUES ($1, $2, $3, $4, 'android', 'ar')`,
      [registration, FAMILY, membership, token],
    );
  }
  return db;
}

function storeFor(db) {
  return new PostgresFoundationStore({
    pool: {
      async query(text, params) { return db.query(text, params); },
      async connect() { return { query: (text, params) => db.query(text, params), release() {} }; },
      async end() {},
    },
  });
}

/** The claim the gate can act on: the ordinary alert promoted in migration 136. */
async function insertClaim(db, outboxId) {
  await db.query(
    `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, copy_key, payload)
     VALUES ($1, 'family', $2, gen_random_uuid(), 'family.task_claimed', 'task.claimed', $3::jsonb)`,
    [outboxId, FAMILY, JSON.stringify({ childId: CHILD_ROSTER, audienceThreadId: null })],
  );
}

function recordingSender() {
  const calls = [];
  return {
    calls,
    async send(args) {
      calls.push(args);
      args.onAccepted?.(`projects/pref-test/messages/${calls.length}`);
      return 'sent';
    },
  };
}

async function decisionsFor(db, outboxId) {
  const { rows } = await db.query(
    `SELECT membership_id, decision, reason, blocked_by
       FROM outbox_delivery_decisions WHERE outbox_id = $1
      ORDER BY membership_id ASC`,
    [outboxId],
  );
  return rows;
}

test('what the door writes is what the gate reads — the same row, the same units, the same result', async () => {
  const db = await freshDb();
  const store = storeFor(db);
  const preferences = notificationPreferencesFor(store);

  const first = await preferences.update({
    principal: principal('pref-primary'),
    familyId: FAMILY,
    change: {
      quietHoursEnabled: true, quietStartMinutes: 22 * 60, quietEndMinutes: 7 * 60,
      quietHoursOffsetMinutes: 180,
    },
    expectedVersion: 0,
    correlationId: randomUUID(),
  });
  assert.equal(first.preferences.version, 1, 'a row that exists has been written once');
  assert.equal(first.preferences.source, 'stored');
  assert.equal(first.preferences.quietStartMinutes, 1_320, 'minutes of day survive the round trip as minutes');
  assert.equal(first.preferences.quietHoursOffsetMinutes, 180);

  // 22:30 UTC is 01:30 for this guardian — inside the window the door just wrote.
  const inside = randomUUID();
  await insertClaim(db, inside);
  const sender = recordingSender();
  const dispatcher = new NotificationDispatcher(sender, async () => ({
    query: (text, params) => db.query(text, params), release() {},
  }), { now: () => new Date('2026-10-26T22:30:00Z') });
  const quietRun = await dispatcher.notify(inside, 'family.task_claimed');
  assert.equal(quietRun.status, 'delivered',
    'one guardian asleep and one awake is a delivery for the family, not a skip for the event');
  assert.deepEqual((await decisionsFor(db, inside)).filter((r) => r.membership_id === PRIMARY), [
    { membership_id: PRIMARY, decision: 'suppressed', reason: 'quiet_hours', blocked_by: null },
  ]);
  assert.deepEqual(sender.calls.map((call) => call.token), [TOKEN_CO],
    'the co-guardian who chose nothing is still told');

  // The same instant, one field changed through the door: the guardian flies west.
  await preferences.update({
    principal: principal('pref-primary'), familyId: FAMILY,
    change: { quietHoursOffsetMinutes: -300 }, expectedVersion: 1, correlationId: randomUUID(),
  });
  const awake = randomUUID();
  await insertClaim(db, awake);
  await dispatcher.notify(awake, 'family.task_claimed');
  // The sender keeps its history across both runs, so the second run's calls are the tail. They
  // arrive in membership order, which is why the primary — silenced an hour ago — comes first here.
  assert.deepEqual(sender.calls.slice(1).map((call) => call.token), [TOKEN_PRIMARY, TOKEN_CO],
    'an offset is the only thing that moved, so the alert now reaches both handsets');
  assert.deepEqual(await decisionsFor(db, awake), [], 'no silence, so no ledger row');

  const row = await db.query(
    `SELECT quiet_hours_start, quiet_hours_end, quiet_hours_offset_minutes, version
       FROM family_notification_preferences WHERE family_id = $1 AND membership_id = $2`,
    [FAMILY, PRIMARY],
  );
  assert.deepEqual(row.rows[0], {
    quiet_hours_start: '22:00:00', quiet_hours_end: '07:00:00',
    quiet_hours_offset_minutes: -300, version: 2,
  }, '1320 minutes is 22:00 on the guardian’s face, and the version advanced once per write');
  await db.close();
});

test('two guardians, two rows: one adult’s night is not another’s', async () => {
  const db = await freshDb();
  const preferences = notificationPreferencesFor(storeFor(db));
  await preferences.update({
    principal: principal('pref-primary'), familyId: FAMILY,
    change: { disabledCopyKeys: ['task.claimed'] }, expectedVersion: 0, correlationId: randomUUID(),
  });
  const { rows } = await db.query(
    `SELECT membership_id, disabled_copy_keys FROM family_notification_preferences WHERE family_id = $1`,
    [FAMILY],
  );
  assert.deepEqual(rows, [{ membership_id: PRIMARY, disabled_copy_keys: ['task.claimed'] }],
    'the co-guardian has no row, and none was created for them by this write');

  const outbox = randomUUID();
  await insertClaim(db, outbox);
  const sender = recordingSender();
  const dispatcher = new NotificationDispatcher(sender, async () => ({
    query: (text, params) => db.query(text, params), release() {},
  }), { now: () => new Date('2026-10-26T12:00:00Z') });
  const result = await dispatcher.notify(outbox, 'family.task_claimed');
  assert.equal(result.status, 'delivered');
  assert.deepEqual(sender.calls.map((call) => call.token), [TOKEN_CO]);
  assert.deepEqual(await decisionsFor(db, outbox), [
    { membership_id: PRIMARY, decision: 'suppressed', reason: 'copy_muted', blocked_by: null },
  ]);
  await db.close();
});

test('the version makes a lost read a refusal, never a silent overwrite', async () => {
  const db = await freshDb();
  const preferences = notificationPreferencesFor(storeFor(db));
  const opened = await preferences.update({
    principal: principal('pref-primary'), familyId: FAMILY,
    change: { pushAllowed: false }, expectedVersion: 0, correlationId: randomUUID(),
  });
  assert.equal(opened.preferences.pushAllowed, false);

  await assert.rejects(
    preferences.update({
      principal: principal('pref-primary'), familyId: FAMILY,
      change: { pushAllowed: true }, expectedVersion: 0, correlationId: randomUUID(),
    }),
    (error) => error.status === 409 && error.code === 'notification_preferences_stale_version',
    'the second handset read version 0 too, and must be told to re-read rather than win',
  );

  const stored = await db.query(
    `SELECT push_allowed, version FROM family_notification_preferences
      WHERE family_id = $1 AND membership_id = $2`,
    [FAMILY, PRIMARY],
  );
  assert.deepEqual(stored.rows[0], { push_allowed: false, version: 1 });
  await db.close();
});

test('a child has no row to write, and a stranger has no row to read', async () => {
  const db = await freshDb();
  const preferences = notificationPreferencesFor(storeFor(db));
  await assert.rejects(
    preferences.update({
      principal: principal('pref-child'), familyId: FAMILY,
      change: { pushAllowed: false }, expectedVersion: 0, correlationId: randomUUID(),
    }),
    (error) => error.status === 403
      && error.code === 'notification_preferences_guardian_only',
  );
  await assert.rejects(
    preferences.read({ principal: principal('nobody-in-this-family'), familyId: FAMILY }),
    (error) => error.status === 403 && error.code === 'family_access_denied',
  );
  const { rows } = await db.query(
    `SELECT count(*)::int AS written FROM family_notification_preferences`,
  );
  assert.equal(rows[0].written, 0, 'a refusal writes nothing, not even an empty row');
  await db.close();
});

test('the module refuses with the name of the law before the constraint is reached', async () => {
  const db = await freshDb();
  const preferences = notificationPreferencesFor(storeFor(db));
  const attempts = [
    [{ quietHoursEnabled: true, quietStartMinutes: 1_320 }, 400, 'notification_preferences_quiet_pair_required'],
    [{ quietHoursEnabled: true, quietStartMinutes: 1_440, quietEndMinutes: 60 }, 400, 'notification_preferences_minute_out_of_day'],
    [{ deliveryMode: 'silence_everything' }, 400, 'notification_preferences_delivery_mode_invalid'],
    [{ disabledCopyKeys: ['sos.raised'] }, 403, 'notification_preferences_safety_never_muted'],
    [{ disabledCopyKeys: ['homework.reminder'] }, 400, 'notification_preferences_unknown_copy_key'],
    [{ quietHoursOffsetMinutes: 900 }, 400, 'notification_preferences_offset_invalid'],
  ];
  for (const [change, status, code] of attempts) {
    await assert.rejects(
      preferences.update({
        principal: principal('pref-primary'), familyId: FAMILY, change, expectedVersion: 0,
        correlationId: randomUUID(),
      }),
      (error) => error.status === status && error.code === code,
      `${code} must be the refusal for ${JSON.stringify(change)}`,
    );
  }
  const { rows } = await db.query(`SELECT count(*)::int AS written FROM family_notification_preferences`);
  assert.equal(rows[0].written, 0);
  await db.close();
});

test('the database is the last word: the same four floors, without the module in the room', async () => {
  const db = await freshDb();
  const cases = [
    [`INSERT INTO family_notification_preferences (family_id, membership_id, quiet_hours_enabled, quiet_hours_start)
       VALUES ($1, $2, TRUE, '22:00')`, 'quiet_pair', [FAMILY, CO]],
    [`INSERT INTO family_notification_preferences (family_id, membership_id, version)
       VALUES ($1, $2, 0)`, 'version_positive', [FAMILY, CO]],
    [`INSERT INTO family_notification_preferences (family_id, membership_id, disabled_copy_keys)
       VALUES ($1, $2, ARRAY['geofence.entered'])`, 'never_silence_safety', [FAMILY, CO]],
    [`UPDATE family_notification_preferences SET quiet_hours_offset_minutes = 901 WHERE family_id = $1`,
      'offset_bounded', [FAMILY]],
  ];
  // The last case needs a row to update, so seed one first through the only legal door: SQL.
  await db.query(
    `INSERT INTO family_notification_preferences (family_id, membership_id, quiet_hours_offset_minutes)
     VALUES ($1, $2, 0)`,
    [FAMILY, PRIMARY],
  );
  for (const [sql, constraint, params] of cases) {
    await assert.rejects(db.query(sql, params), new RegExp(constraint),
      `${constraint} must be the database's own refusal`);
  }
  await db.close();
});

test('a preference write is a fact about the family, not a notification', async () => {
  const db = await freshDb();
  const preferences = notificationPreferencesFor(storeFor(db));
  const correlationId = randomUUID();
  await preferences.update({
    principal: principal('pref-primary'), familyId: FAMILY,
    change: { childRequestsEnabled: false, quietHoursOffsetMinutes: 180 },
    expectedVersion: 0, correlationId,
  });
  const audit = await db.query(
    `SELECT event_type, subject_type FROM family_audit_events WHERE correlation_id = $1`,
    [correlationId],
  );
  assert.deepEqual(audit.rows, [{
    event_type: 'family.notification_preferences_updated', subject_type: 'family_notification_preferences',
  }]);
  const outbox = await db.query(
    `SELECT copy_key, status, payload -> 'changed' AS changed
       FROM outbox_events WHERE correlation_id = $1`,
    [correlationId],
  );
  assert.equal(outbox.rows.length, 1);
  assert.equal(outbox.rows[0].copy_key, null,
    'no copy key means no push: the outbox row is the audit trail, not an alert');
  assert.deepEqual(outbox.rows[0].changed, ['childRequestsEnabled', 'quietHoursOffsetMinutes'],
    'the ledger of what changed is the field list the caller actually sent');

  // And the dispatcher agrees: it records the row as skipped with the audit-only reason.
  const { rows } = await db.query(`SELECT id FROM outbox_events WHERE correlation_id = $1`, [correlationId]);
  const dispatcher = new NotificationDispatcher(recordingSender(), async () => ({
    query: (text, params) => db.query(text, params), release() {},
  }), { now: () => new Date('2026-10-26T12:00:00Z') });
  const result = await dispatcher.notify(rows[0].id, 'family.notification_preferences_updated');
  assert.equal(result.status, 'skipped');
  assert.equal(result.reason, 'audit_only');
  await db.close();
});
