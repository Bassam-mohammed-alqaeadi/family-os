// Programme «family character», slice 1 — migration 135 on a real PostgreSQL engine.
//
// CI applies every migration to PostgreSQL 16 in `migration-and-integration`; this file runs in the
// default `npm test` gate through PGlite (Postgres compiled to WASM), so a law that does not actually
// fire catches the author before push. What is proven here is the floor, not the vocabulary: the
// words a family chooses are its own, and the things that must not be stored — a week with no rest
// day, a day spelled wrong, a fifth key smuggled into a JSONB object, an editor from another family —
// are refused by the database rather than by a paragraph in a contract.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
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
  '130_family_minutes_ledger.sql','131_family_app_wallets.sql','132_point_ledger_to_minutes.sql',
  '133_screen_time_earned_minutes_switch.sql','134_usage_consumption_ledger_shape.sql',
  '135_family_customization_profile.sql',
];

async function freshDb() {
  const db = new PGlite();
  await db.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY, checksum TEXT NOT NULL, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`);
  for (const name of MIGRATIONS) {
    await db.exec(readFileSync(join(MIG_DIR, name), 'utf8'));
  }
  return db;
}

/** One family with its own primary and co-guardian, and a second family to collide with. */
async function seedFamilies(db) {
  const ids = {
    family: 'a1000000-0000-4000-8000-000000000001',
    otherFamily: 'a2000000-0000-4000-8000-000000000002',
    primary: 'b1000000-0000-4000-8000-000000000001',
    co: 'b2000000-0000-4000-8000-000000000002',
    otherPrimary: 'b3000000-0000-4000-8000-000000000003',
  };
  await db.exec(`
    INSERT INTO accounts (id, oidc_subject)
    VALUES ('aa000000-0000-4000-8000-000000000001', 'customization-primary'),
           ('ab000000-0000-4000-8000-000000000002', 'customization-co'),
           ('ac000000-0000-4000-8000-000000000003', 'customization-other')`);
  await db.exec(`
    INSERT INTO families (id, display_name, status)
    VALUES ('${ids.family}', 'عائلة الاختبار', 'active'),
           ('${ids.otherFamily}', 'Other family', 'active')`);
  await db.exec(`
    INSERT INTO family_memberships (id, family_id, account_id, target_subject, role, status, joined_at)
    VALUES ('${ids.primary}', '${ids.family}', 'aa000000-0000-4000-8000-000000000001',
            'customization-primary', 'primary_guardian', 'active', NOW()),
           ('${ids.co}', '${ids.family}', 'ab000000-0000-4000-8000-000000000002',
            'customization-co', 'co_guardian', 'active', NOW()),
           ('${ids.otherPrimary}', '${ids.otherFamily}', 'ac000000-0000-4000-8000-000000000003',
            'customization-other', 'primary_guardian', 'active', NOW())`);
  await db.exec(`UPDATE families SET primary_membership_id = '${ids.primary}' WHERE id = '${ids.family}'`);
  await db.exec(`UPDATE families SET primary_membership_id = '${ids.otherPrimary}' WHERE id = '${ids.otherFamily}'`);
  return ids;
}

test('migration 135 creates the profile table with the laws the programme claims', async () => {
  const db = await freshDb();
  const tables = await db.query(`SELECT tablename FROM pg_tables WHERE schemaname='public'`);
  assert.ok(tables.rows.some((r) => r.tablename === 'family_customization_profiles'),
    'family_customization_profiles must exist after 135');

  const columns = await db.query(`SELECT column_name, is_nullable, column_default
     FROM information_schema.columns WHERE table_name='family_customization_profiles'`);
  const byName = new Map(columns.rows.map((r) => [r.column_name, r]));
  for (const day of ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']) {
    const row = byName.get(`rest_${day}`);
    assert.ok(row, `rest_${day} must be a column, not an array element`);
    assert.equal(row.is_nullable, 'NO', `rest_${day} must not be null - a null would walk past the CHECK`);
  }
  assert.equal(byName.get('version').is_nullable, 'NO');
  assert.equal(byName.get('guardian_labels').column_default, "'{}'::jsonb");

  for (const name of [
    'family_customization_profiles_friday_rest_idx',
  ]) {
    const found = await db.query(`SELECT indexname FROM pg_indexes WHERE indexname=$1`, [name]);
    assert.equal(found.rowCount, 1, `${name} must exist`);
  }
  await db.close();
});

test('the defaults are the behaviour the app had before a family existed', async () => {
  const db = await freshDb();
  const ids = await seedFamilies(db);
  await db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id)
    VALUES ('${ids.family}', '${ids.primary}')`);
  const { rows } = await db.query(`SELECT * FROM family_customization_profiles WHERE family_id='${ids.family}'`);
  const row = rows[0];
  assert.equal(row.week_start_day, 'mon', 'a Monday-first grid is what every screen drew before this migration');
  assert.equal(row.rest_friday, true);
  assert.equal(row.rest_saturday, true);
  assert.equal(row.rest_sunday, false);
  assert.equal(row.rest_monday, false);
  assert.equal(row.version, 1);
  assert.deepEqual(row.guardian_labels, {});
  await db.close();
});

test('a week with no rest day cannot be stored, and neither can a day spelled wrong', async () => {
  const db = await freshDb();
  const ids = await seedFamilies(db);
  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles
      (family_id, updated_by_membership_id, rest_sunday, rest_monday, rest_tuesday, rest_wednesday,
       rest_thursday, rest_friday, rest_saturday)
    VALUES ('${ids.family}', '${ids.primary}', FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)`),
    /family_customization_rest_day_exists/);

  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id, week_start_day)
    VALUES ('${ids.family}', '${ids.primary}', 'friday')`),
    /family_customization_profiles_week_start_day_check/);

  // Digits are a closed pair, not a free word: the app branches on exactly two renderers.
  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id, numerals)
    VALUES ('${ids.family}', '${ids.primary}', 'arabic-indic')`),
    /family_customization_profiles_numerals_check/);
  await db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id, numerals)
    VALUES ('${ids.family}', '${ids.primary}', 'eastern')`);
  const chosen = await db.query(`SELECT numerals FROM family_customization_profiles WHERE family_id='${ids.family}'`);
  assert.equal(chosen.rows[0].numerals, 'eastern');
  await db.close();
});

test('the addressing words are four keys of short text, and nothing else', async () => {
  const db = await freshDb();
  const ids = await seedFamilies(db);
  const insert = (labels) => db.exec(
    `INSERT INTO family_customization_profiles (family_id, updated_by_membership_id, guardian_labels)
     VALUES ('${ids.family}', '${ids.primary}', '${labels}'::jsonb)`,
  );

  await assert.rejects(() => insert('{"father":"بابا","uncle":"عمو"}'),
    /family_customization_labels_known_keys/);
  await assert.rejects(() => insert('{"father":"' + 'ط'.repeat(25) + '"}'),
    /family_customization_labels_are_short_words/);
  await assert.rejects(() => insert('{"father":"   "}'),
    /family_customization_labels_are_short_words/);
  await assert.rejects(() => insert('{"father":7}'),
    /family_customization_labels_are_short_words/);
  await assert.rejects(() => insert('"بابا"'),
    /family_customization_labels_are_object/);
  await assert.rejects(() => insert('{"father":"بابا","constructor":"x"}'),
    /family_customization_labels_known_keys/);

  // A word for every role the app speaks with is legal, and one rest day alone is legal too.
  await db.exec(`
    INSERT INTO family_customization_profiles
      (family_id, updated_by_membership_id, guardian_labels, rest_friday, rest_saturday, rest_sunday)
    VALUES ('${ids.family}', '${ids.primary}',
            '{"father":"بابا","mother":"ماما","guardian":"الوصي","child":"يا صغيري"}'::jsonb,
            TRUE, FALSE, FALSE)`);
  const { rows } = await db.query(`SELECT guardian_labels, rest_days FROM (
      SELECT guardian_labels,
             (rest_sunday OR rest_monday OR rest_tuesday OR rest_wednesday
              OR rest_thursday OR rest_friday OR rest_saturday) AS rest_days
        FROM family_customization_profiles WHERE family_id='${ids.family}') shaped`);
  assert.equal(rows[0].guardian_labels.father, 'بابا');
  assert.equal(rows[0].rest_days, true);
  await db.close();
});

test('an editor must be a membership of the same family, and the version cannot go backwards', async () => {
  const db = await freshDb();
  const ids = await seedFamilies(db);
  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id)
    VALUES ('${ids.family}', '${ids.otherPrimary}')`),
    /family_customization_editor_membership_fk/);

  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id, version)
    VALUES ('${ids.family}', '${ids.primary}', 0)`),
    /family_customization_profiles_version_check/);
  await db.close();
});

test('one profile per family, and the guarded upsert the server uses updates in place', async () => {
  const db = await freshDb();
  const ids = await seedFamilies(db);
  const upsert = (nextVersion, expectedCurrent) => db.query(`
    INSERT INTO family_customization_profiles
      (family_id, week_start_day, rest_thursday, rest_friday, rest_saturday, guardian_labels,
       version, updated_by_membership_id, updated_at)
    VALUES ($1, 'sat', $2, TRUE, FALSE, '{"father":"بابا"}'::jsonb, $3, $4, NOW())
    ON CONFLICT (family_id) DO UPDATE SET
      week_start_day = EXCLUDED.week_start_day,
      rest_thursday = EXCLUDED.rest_thursday,
      rest_friday = EXCLUDED.rest_friday,
      rest_saturday = EXCLUDED.rest_saturday,
      guardian_labels = EXCLUDED.guardian_labels,
      version = EXCLUDED.version,
      updated_by_membership_id = EXCLUDED.updated_by_membership_id,
      updated_at = NOW()
    WHERE family_customization_profiles.version = $5
    RETURNING version, week_start_day`,
    [ids.family, nextVersion === 2, nextVersion, ids.primary, expectedCurrent]);

  const inserted = await upsert(1, 0);
  assert.equal(inserted.rows.length, 1, 'a family with no row yet is created by the same statement');
  assert.equal(inserted.rows[0].version, 1);

  const updated = await upsert(2, 1);
  assert.equal(updated.rows.length, 1, 'a matching version updates in place');
  assert.equal(updated.rows[0].version, 2);
  assert.equal(updated.rows[0].week_start_day, 'sat');

  const stale = await upsert(3, 1);
  assert.equal(stale.rows.length, 0, 'a write that read an older version changes nothing and returns nothing');

  const rows = await db.query(`SELECT count(*)::int AS n FROM family_customization_profiles WHERE family_id=$1`,
    [ids.family]);
  assert.equal(rows.rows[0].n, 1, 'the primary key is what makes "one profile per family" a fact');
  await assert.rejects(() => db.exec(`
    INSERT INTO family_customization_profiles (family_id, updated_by_membership_id)
    VALUES ('${ids.family}', '${ids.primary}')`),
    /family_customization_profiles_pkey|duplicate key/);
  await db.close();
});
