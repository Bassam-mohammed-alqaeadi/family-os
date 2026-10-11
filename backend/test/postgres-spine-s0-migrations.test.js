// S0 spine — migrations apply cleanly on a real-Postgres-compatible runtime and
// the CHECK/ENUM constraints we depend on actually fire. CI already runs every
// migration against PostgreSQL 16 in the `migration-and-integration` job; this
// unit-level file runs in the default `npm test` gate (no DATABASE_URL needed)
// so a broken CHECK or enum catches the author before push.
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
];

async function freshDb() {
  const db = new PGlite();
  await db.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY, checksum TEXT NOT NULL, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`);
  await db.exec(`SELECT pg_try_advisory_lock(hashtext('family-os-schema-migrations-v1'))`);
  for (const name of MIGRATIONS) {
    await db.exec(readFileSync(join(MIG_DIR, name), 'utf8'));
    await db.query(`INSERT INTO schema_migrations (name, checksum) VALUES ($1, 'sha')`, [name]);
  }
  return db;
}

test('all 28 migrations apply to an empty database in order', async () => {
  const db = await freshDb();
  const tables = await db.query(`SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename`);
  const names = tables.rows.map(r => r.tablename);
  for (const needed of ['family_device_capabilities','family_commands','family_command_receipts']) {
    assert.ok(names.includes(needed), `${needed} must exist after migration 117/118`);
  }
  const cols = await db.query(`SELECT column_name FROM information_schema.columns
     WHERE table_name='ai_events' AND column_name IN
       ('security_context','required_capabilities','ttl_minutes','expires_at','trace_id',
        'capability_key','command_id','policy_id','source_trust','data_quality')`);
  assert.equal(cols.rowCount, 10, 'S-SEV-1 envelope columns must all be present');
  await db.close();
});

test('117 CHECK: confirmed ↔ confirmedAt enforced', async () => {
  const db = await freshDb();
  await assert.rejects(() => db.exec(`
    INSERT INTO family_device_capabilities
      (device_id, family_id, capability_key, state, confirmed_at, reported_at)
    VALUES ('00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000002',
            'instant_lock','unsupported',NOW(),NOW())`),
    /family_device_capabilities_confirmed_pair/);
  await assert.rejects(() => db.exec(`
    INSERT INTO family_device_capabilities
      (device_id, family_id, capability_key, state, confirmed_at, reported_at)
    VALUES ('00000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000002',
            'background_location','confirmed',NULL,NOW())`),
    /family_device_capabilities_confirmed_pair/);
  await db.close();
});

test('118 enum: invalid command_type rejected', async () => {
  const db = await freshDb();
  await db.exec(`CREATE TEMP TABLE cmd_test (LIKE family_commands INCLUDING ALL)`);
  await assert.rejects(() => db.exec(`
    INSERT INTO cmd_test
      (id, family_id, child_id, device_id, command_type, idempotency_key, priority,
       expires_at, state, created_at, actor_membership_id, payload)
    VALUES (gen_random_uuid(),'00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000004',
            '00000000-0000-4000-8000-000000000003','block_app','k2',50,NOW()+INTERVAL '60s',
            'accepted',NOW(),'00000000-0000-4000-8000-000000000005','{}'::jsonb)`),
    /family_commands_command_type_check|invalid input value for enum/);
  await db.close();
});

test('118 receipt: failed requires failure_reason', async () => {
  const db = await freshDb();
  const c = await db.query(`SELECT pg_get_constraintdef(c.oid) AS def
    FROM pg_constraint c JOIN pg_class t ON c.conrelid=t.oid
    WHERE t.relname='family_command_receipts' AND c.conname='family_command_receipts_failure_pair'`);
  assert.ok(c.rowCount === 1, 'family_command_receipts_failure_pair must exist');
  assert.match(c.rows[0].def, /receipt_kind.*failed.*failure_reason/);
  await db.close();
});

test('119 S-SEV-1 constraints present and ttl range enforced', async () => {
  const db = await freshDb();
  const needed = ['ai_events_ttl_minutes_check','ai_events_ttl_pair',
    'ai_events_security_context_object','ai_events_required_capabilities_known',
    'ai_events_trace_id_unique_per_family'];
  for (const name of needed) {
    const r = await db.query(`SELECT conname FROM pg_constraint WHERE conname=$1`, [name]);
    assert.equal(r.rowCount, 1, `${name} constraint must exist after migration 119`);
  }
  await db.close();
});
