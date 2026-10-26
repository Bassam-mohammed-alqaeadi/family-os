// Invites by code against real PostgreSQL. Gated by DATABASE_URL like every PostgreSQL test; CI
// runs it in backend_ci.yml.
//
// What it must prove:
//   1. A primary guardian issues a code; the code is returned once, only its digest is stored,
//      and a retried issue never reveals it again.
//   2. A signed-in invitee redeems it and becomes an ACTIVE member with the code's role, bound
//      to the verified subject - no targetSubject was ever needed. The family is then
//      discoverable by the invitee and the roster shows the new member.
//   3. A code is single-use: a second account gets the same refusal as an unknown code.
//   4. Expired and revoked codes are refused with that same answer (no oracle).
//   5. Only the primary guardian issues or revokes; a co-guardian and an outsider cannot.
//   6. An account already in the family cannot spend a code; the code stays open.
//   7. A family cannot hold more than five open codes.
//   8. A redemption replayed with the same Idempotency-Key returns the same membership.
//   9. Two accounts racing for one code: exactly one wins.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { createApp } from '../src/app.js';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';
import { inviteCodeDigest } from '../src/family-invite-codes.js';
import { TestAuthVerifier } from './memory-foundation-store.js';

const { Client } = pg;
const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : 'DATABASE_URL is not set; the real-PostgreSQL gate runs in CI.';
const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');

function sha256Hex(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function withDatabase(url, name) {
  const parsed = new URL(url);
  parsed.pathname = `/${name}`;
  return parsed.toString();
}

async function withFreshHousehold(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_invite_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
  let store;
  try {
    await admin.query(`CREATE DATABASE ${name}`);
    const client = new Client({ connectionString: withDatabase(DATABASE_URL, name) });
    await client.connect();
    try {
      await applyMigrations({
        client,
        migrations: FOUNDATION_SCHEMA_MIGRATIONS,
        readVerifiedMigration: async (migration) => {
          const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
          assert.equal(sha256Hex(sql), migration.sha256, `${migration.name} must match its recorded checksum`);
          return sql;
        },
      });
      store = new PostgresFoundationStore({ connectionString: withDatabase(DATABASE_URL, name) });
      const app = createApp({
        store,
        authVerifier: new TestAuthVerifier(),
        readiness: () => ({ ready: true, missing: [] }),
        // The journeys below make more attempts than a person would; the limits themselves are
        // proven without a database in family-invite-codes.test.js.
        inviteRedeemRateLimit: { subjectLimit: 1000, peerLimit: 1000 },
      });
      const server = app.listen(0, '127.0.0.1');
      await new Promise((resolve) => server.once('listening', resolve));
      try {
        const baseUrl = `http://127.0.0.1:${server.address().port}`;
        const created = await call(baseUrl, '/v1/families', {
          method: 'POST',
          subject: 'test-primary',
          key: 'family-1',
          body: { displayName: 'عائلة الدعوة' },
        });
        assert.equal(created.status, 201, JSON.stringify(created.body));
        await run({ baseUrl, client, familyId: created.body.family.id });
      } finally {
        await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
      }
    } finally {
      if (store) await store.close();
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

let keyCounter = 0;
async function call(baseUrl, path, { method = 'GET', subject, key, body } = {}) {
  const headers = { accept: 'application/json' };
  if (subject) headers.authorization = `Bearer ${subject}`;
  if (method !== 'GET') headers['idempotency-key'] = key ?? `auto-${process.pid}-${(keyCounter += 1)}`;
  if (body !== undefined) headers['content-type'] = 'application/json';
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}

const issue = (baseUrl, familyId, { subject = 'test-primary', role = 'co_guardian', key } = {}) =>
  call(baseUrl, `/v1/families/${familyId}/invite-codes`, { method: 'POST', subject, key, body: { role } });
const redeem = (baseUrl, subject, code, key) =>
  call(baseUrl, '/v1/invite-codes/redeem', { method: 'POST', subject, key, body: { code } });

test('a guardian issues a code once, and the invitee joins with it - no account id needed', { skip }, async () => {
  await withFreshHousehold(async ({ baseUrl, client, familyId }) => {
    const issued = await issue(baseUrl, familyId, { key: 'issue-1' });
    assert.equal(issued.status, 201, JSON.stringify(issued.body));
    const { invite } = issued.body;
    assert.match(invite.code, /^[A-HJKMNP-Z2-9]{5}-[A-HJKMNP-Z2-9]{5}$/);
    assert.equal(invite.role, 'co_guardian');
    assert.equal(invite.status, 'open');
    const lifetimeMs = Date.parse(invite.expiresAt) - Date.parse(invite.createdAt);
    assert.ok(Math.abs(lifetimeMs - 24 * 3600 * 1000) < 5000, 'a code lives for one day');

    // Only the digest is stored - in the code table and in the idempotency record.
    const raw = invite.code.replace('-', '');
    const stored = await client.query('SELECT code_hash FROM family_invite_codes WHERE id = $1', [invite.id]);
    assert.equal(stored.rows[0].code_hash, inviteCodeDigest(raw));
    const leaked = await client.query(
      `SELECT count(*)::int AS n FROM idempotency_records
        WHERE response_body::text LIKE $1 OR response_body::text LIKE $2`,
      [`%${raw}%`, `%${invite.code}%`],
    );
    assert.equal(leaked.rows[0].n, 0, 'the raw code is never written anywhere');

    // A retried issue never reveals the code a second time.
    const retried = await issue(baseUrl, familyId, { key: 'issue-1' });
    assert.equal(retried.status, 409);
    assert.equal(retried.body.error.code, 'invite_code_not_replayable');

    // Before redemption the invitee sees no family.
    const before = await call(baseUrl, '/v1/me/families', { subject: 'test-mother' });
    assert.equal(before.status, 200);
    assert.deepEqual(before.body.families, []);

    const joined = await redeem(baseUrl, 'test-mother', invite.code.toLowerCase(), 'redeem-1');
    assert.equal(joined.status, 200, JSON.stringify(joined.body));
    assert.equal(joined.body.family.id, familyId);
    assert.equal(joined.body.family.displayName, 'عائلة الدعوة');
    assert.equal(joined.body.membership.role, 'co_guardian');
    assert.equal(joined.body.membership.status, 'active');
    assert.ok(joined.body.membership.joinedAt);

    // The same request replayed returns the same membership and creates nothing new.
    const replayed = await redeem(baseUrl, 'test-mother', invite.code.toLowerCase(), 'redeem-1');
    assert.equal(replayed.status, 200);
    assert.equal(replayed.body.membership.id, joined.body.membership.id);

    // The invitee now discovers the family, and the guardian's roster shows the new member.
    const after = await call(baseUrl, '/v1/me/families', { subject: 'test-mother' });
    assert.deepEqual(after.body.families.map((family) => [family.id, family.role]), [[familyId, 'co_guardian']]);
    const roster = await call(baseUrl, `/v1/families/${familyId}/memberships`, { subject: 'test-primary' });
    assert.equal(roster.status, 200);
    const mother = roster.body.memberships.find((row) => row.id === joined.body.membership.id);
    assert.equal(mother.status, 'active');
    assert.equal(mother.isSelf, false);

    // The membership is bound to the verified subject, attributed to the issuer, and audited.
    const row = await client.query(
      `SELECT membership.target_subject, membership.invited_by_membership_id, family.primary_membership_id
         FROM family_memberships AS membership
         JOIN families AS family ON family.id = membership.family_id
        WHERE membership.id = $1`,
      [joined.body.membership.id],
    );
    assert.equal(row.rows[0].target_subject, 'test-mother');
    assert.equal(row.rows[0].invited_by_membership_id, row.rows[0].primary_membership_id);
    const code = await client.query(
      'SELECT status, redeemed_membership_id FROM family_invite_codes WHERE id = $1',
      [invite.id],
    );
    assert.deepEqual(code.rows[0], { status: 'redeemed', redeemed_membership_id: joined.body.membership.id });
    const audit = await client.query(
      `SELECT event_type FROM family_audit_events WHERE family_id = $1 ORDER BY occurred_at, event_type`,
      [familyId],
    );
    const events = audit.rows.map((entry) => entry.event_type);
    assert.ok(events.includes('family.invite_code_issued'));
    assert.ok(events.includes('family.invite_code_redeemed'));

    // Single use: another account is told exactly what it would be told for a made-up code.
    const second = await redeem(baseUrl, 'test-stranger', invite.code, 'redeem-2');
    assert.equal(second.status, 404);
    assert.equal(second.body.error.code, 'invite_code_not_redeemable');
    const unknown = await redeem(baseUrl, 'test-stranger', 'ABCDE-FGHJK', 'redeem-3');
    assert.equal(unknown.status, 404);
    assert.equal(unknown.body.error.code, 'invite_code_not_redeemable');
    assert.equal(unknown.body.error.message, second.body.error.message);
  });
});

test('expired and revoked codes are refused with the same answer as an unknown one', { skip }, async () => {
  await withFreshHousehold(async ({ baseUrl, client, familyId }) => {
    const expiring = await issue(baseUrl, familyId);
    assert.equal(expiring.status, 201);
    await client.query(
      `UPDATE family_invite_codes SET created_at = NOW() - INTERVAL '2 days', expires_at = NOW() - INTERVAL '1 second'
        WHERE id = $1`,
      [expiring.body.invite.id],
    );
    const expired = await redeem(baseUrl, 'test-late', expiring.body.invite.code);
    assert.equal(expired.status, 404);
    assert.equal(expired.body.error.code, 'invite_code_not_redeemable');

    const revocable = await issue(baseUrl, familyId, { role: 'child' });
    assert.equal(revocable.status, 201);
    const revokePath = `/v1/families/${familyId}/invite-codes/${revocable.body.invite.id}/revoke`;

    // Only the primary guardian may revoke: an outsider is denied before anything is read.
    const outsider = await call(baseUrl, revokePath, { method: 'POST', subject: 'test-outsider' });
    assert.equal(outsider.status, 403);

    const revoked = await call(baseUrl, revokePath, { method: 'POST', subject: 'test-primary', key: 'revoke-1' });
    assert.equal(revoked.status, 200, JSON.stringify(revoked.body));
    assert.equal(revoked.body.invite.status, 'revoked');
    assert.equal(revoked.body.invite.code, undefined, 'a revoke never echoes the code');
    const replay = await call(baseUrl, revokePath, { method: 'POST', subject: 'test-primary', key: 'revoke-1' });
    assert.equal(replay.status, 200);
    const again = await call(baseUrl, revokePath, { method: 'POST', subject: 'test-primary', key: 'revoke-2' });
    assert.equal(again.status, 409);
    assert.equal(again.body.error.code, 'invite_code_not_revocable');

    const refused = await redeem(baseUrl, 'test-late', revocable.body.invite.code);
    assert.equal(refused.status, 404);
    assert.equal(refused.body.error.code, 'invite_code_not_redeemable');

    const members = await client.query(
      `SELECT count(*)::int AS n FROM family_memberships WHERE family_id = $1`,
      [familyId],
    );
    assert.equal(members.rows[0].n, 1, 'no refused redemption produced a membership');

    const missing = await call(
      baseUrl,
      `/v1/families/${familyId}/invite-codes/00000000-0000-4000-8000-000000000000/revoke`,
      { method: 'POST', subject: 'test-primary' },
    );
    assert.equal(missing.status, 404);
    assert.equal(missing.body.error.code, 'invite_code_not_found');
  });
});

test('only the primary guardian issues; members cannot spend a code twice; five open codes at most', { skip }, async () => {
  await withFreshHousehold(async ({ baseUrl, client, familyId }) => {
    const outsider = await issue(baseUrl, familyId, { subject: 'test-outsider' });
    assert.equal(outsider.status, 403);
    assert.equal(outsider.body.error.code, 'family_access_denied');

    const first = await issue(baseUrl, familyId);
    const joined = await redeem(baseUrl, 'test-mother', first.body.invite.code);
    assert.equal(joined.status, 200);

    // A co-guardian is a member but not the primary guardian: no codes from them.
    const fromCo = await issue(baseUrl, familyId, { subject: 'test-mother' });
    assert.equal(fromCo.status, 403);

    // The primary guardian and the new member cannot spend another code on their own family,
    // and the code stays open for the person it was meant for.
    const second = await issue(baseUrl, familyId);
    for (const subject of ['test-primary', 'test-mother']) {
      const refused = await redeem(baseUrl, subject, second.body.invite.code);
      assert.equal(refused.status, 409);
      assert.equal(refused.body.error.code, 'membership_already_exists');
    }
    const stillOpen = await client.query('SELECT status FROM family_invite_codes WHERE id = $1', [second.body.invite.id]);
    assert.equal(stillOpen.rows[0].status, 'open');

    // Second code is open; four more reach the ceiling of five, and the sixth is refused.
    for (let index = 0; index < 4; index += 1) {
      const more = await issue(baseUrl, familyId);
      assert.equal(more.status, 201);
    }
    const sixth = await issue(baseUrl, familyId);
    assert.equal(sixth.status, 409);
    assert.equal(sixth.body.error.code, 'invite_code_limit_reached');

    // The database refuses a code row that claims to be redeemed without naming a membership.
    await assert.rejects(
      client.query(
        `UPDATE family_invite_codes SET status = 'redeemed', redeemed_at = NOW() WHERE id = $1`,
        [second.body.invite.id],
      ),
      /family_invite_codes_lifecycle_valid/,
    );
  });
});

test('two accounts racing for one code: exactly one joins', { skip }, async () => {
  await withFreshHousehold(async ({ baseUrl, client, familyId }) => {
    const issued = await issue(baseUrl, familyId);
    const results = await Promise.all(
      ['test-racer-a', 'test-racer-b', 'test-racer-c'].map((subject) => redeem(baseUrl, subject, issued.body.invite.code)),
    );
    const statuses = results.map((result) => result.status).sort();
    assert.deepEqual(statuses, [200, 404, 404]);
    const members = await client.query(
      `SELECT count(*)::int AS n FROM family_memberships WHERE family_id = $1 AND status = 'active'`,
      [familyId],
    );
    assert.equal(members.rows[0].n, 2);
  });
});
