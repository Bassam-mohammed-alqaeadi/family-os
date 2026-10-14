// Safety slice 3 — the minutes-economy journeys on real PostgreSQL. Gated by DATABASE_URL like
// every PostgreSQL test; CI runs it in backend_ci.yml.
//
// What it must prove (card §6, the D1 gate):
//   1. Two concurrent spends of the same minutes: exactly one succeeds, the balance never
//      goes negative (two real connections, a real lock — not a sequence of calls).
//   2. An earn racing a spend: whichever order the database picks, the record is consistent
//      and never negative.
//   3. One source, one row: a repeated earn or a repeated session is refused, not doubled.
//   4. Quran and education minutes are earned but never spent from an educational app (S-1).
//   5. An unknown app is refused, not guessed; an archived child answers 404 everywhere.
//   6. A live lock refuses a spend, and its release restores spending.
//   7. Guardian ceiling: a co-guardian at 30 succeeds and at 31 is refused; a temporary
//      grant disappears at its expiry and its expiry is recorded exactly once.
//   8. A reversal is a new row, only the primary may write it, and only once per credit.
//   9. An allocation moves minutes between wallets and creates none.
//  10. The app-wallet projection can be destroyed and rebuilt from the ledger, and matches it.
//  11. The ledger refuses UPDATE and DELETE in the database itself.
import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { applyMigrations } from '../src/migration-runner.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import {
  adjust,
  allocate,
  consume,
  earn,
  expire,
  grant,
  readAppWalletProjection,
  readBalance,
  readLedger,
  rebuildAppWalletProjection,
  withMinutesTransaction,
} from '../src/minutes-economy.js';

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

async function withFreshDatabase(run) {
  const admin = new Client({ connectionString: DATABASE_URL });
  await admin.connect();
  const name = `familyos_minutes_${process.pid}_${Math.random().toString(36).slice(2, 10)}`;
  const clients = [];
  try {
    await admin.query(`CREATE DATABASE ${name}`);
    const open = async () => {
      const client = new Client({ connectionString: withDatabase(DATABASE_URL, name) });
      await client.connect();
      clients.push(client);
      return client;
    };
    const client = await open();
    await migrate(client);
    await run({ client, open });
  } finally {
    for (const client of clients) await client.end().catch(() => {});
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

/** A family with a primary, a co-guardian, one child and three known apps. */
async function seedFamily(client, tag) {
  const account = await client.query(
    'INSERT INTO accounts (id, oidc_subject) VALUES (gen_random_uuid(), $1) RETURNING id',
    [`${tag}-primary`],
  );
  const family = await client.query(
    "INSERT INTO families (id, display_name, status) VALUES (gen_random_uuid(), 'Minutes family', 'active') RETURNING id",
  );
  const familyId = family.rows[0].id;
  const primary = await client.query(
    `INSERT INTO family_memberships (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES (gen_random_uuid(), $1, $2, $3, 'primary_guardian', 'active', NOW()) RETURNING id`,
    [familyId, account.rows[0].id, `${tag}-primary`],
  );
  await client.query('UPDATE families SET primary_membership_id = $1 WHERE id = $2',
    [primary.rows[0].id, familyId]);
  const coAccount = await client.query(
    'INSERT INTO accounts (id, oidc_subject) VALUES (gen_random_uuid(), $1) RETURNING id',
    [`${tag}-co`],
  );
  const co = await client.query(
    `INSERT INTO family_memberships (id, family_id, account_id, target_subject, role, status, joined_at)
     VALUES (gen_random_uuid(), $1, $2, $3, 'co_guardian', 'active', NOW()) RETURNING id`,
    [familyId, coAccount.rows[0].id, `${tag}-co`],
  );
  const child = await client.query(
    `INSERT INTO family_children (id, family_id, display_name, age_years)
     VALUES (gen_random_uuid(), $1, 'Amani', 9) RETURNING id`,
    [familyId],
  );
  const childId = child.rows[0].id;
  for (const [appId, category] of [['com.game', 'games'], ['com.learn', 'edu'], ['com.tools', 'tools']]) {
    await client.query(
      `INSERT INTO family_child_apps (id, family_id, child_id, app_id, display_name, category)
       VALUES (gen_random_uuid(), $1, $2, $3, $3, $4)`,
      [familyId, childId, appId, category],
    );
  }
  return {
    familyId,
    childId,
    primaryId: primary.rows[0].id,
    coId: co.rows[0].id,
  };
}

/** Run one operation in its own transaction on its own connection. */
function on(client, operation) {
  return withMinutesTransaction(client, operation);
}

function src(type, id) {
  return { type, id };
}

async function ledgerRows(client, childId) {
  const { rows } = await client.query(
    `SELECT entry_kind, channel, minutes, wallet_scope, app_id, source_type, source_id, balance_after_minutes
       FROM family_minutes_ledger WHERE child_id = $1 ORDER BY created_at, id`,
    [childId],
  );
  return rows;
}

function assertRejects(promise, code) {
  return promise.then(
    () => assert.fail(`expected ${code}`),
    (error) => assert.equal(error.code, code, `expected ${code}, got ${error.code}: ${error.message}`),
  );
}

test('two concurrent spends of the same minutes: exactly one succeeds, never negative',
  { skip }, () => withFreshDatabase(async ({ client, open }) => {
    const ids = await seedFamily(client, 'race-spend');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'quran_portion', minutes: 10, source: src('seed', 'race-spend-credit') }));

    const second = await open();
    const results = await Promise.allSettled([
      on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 10, source: src('session', 'race-a') })),
      on(second, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 10, source: src('session', 'race-b') })),
    ]);
    const fulfilled = results.filter((result) => result.status === 'fulfilled');
    const rejected = results.filter((result) => result.status === 'rejected');
    assert.equal(fulfilled.length, 1, 'exactly one spend may succeed');
    assert.equal(rejected.length, 1, 'the other must be refused');
    assert.equal(rejected[0].reason.code, 'minutes_insufficient');

    const balance = await readBalance(client, ids);
    assert.equal(balance.total, 0);
    const rows = await ledgerRows(client, ids.childId);
    assert.ok(rows.every((row) => row.balance_after_minutes >= 0), 'no stored balance may be negative');
    assert.equal(rows.filter((row) => row.entry_kind === 'consumption').length, 1);
  }));

test('an earn racing a spend keeps the record consistent in either order',
  { skip }, () => withFreshDatabase(async ({ client, open }) => {
    const ids = await seedFamily(client, 'race-earn');
    const second = await open();
    for (let round = 0; round < 4; round += 1) {
      const [earned, spent] = await Promise.allSettled([
        on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
          channel: 'athkar', minutes: 10, source: src('athkar', `earn-${round}`) })),
        on(second, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 10,
          source: src('session', `spend-${round}`) })),
      ]);
      assert.equal(earned.status, 'fulfilled', 'the earn must succeed');
      const balance = await readBalance(client, ids);
      assert.ok(balance.total >= 0, 'the balance is never negative');
      if (spent.status === 'rejected') {
        assert.equal(spent.reason.code, 'minutes_insufficient');
      }
      const rows = await ledgerRows(client, ids.childId);
      assert.equal(rows.at(-1).balance_after_minutes, balance.total,
        'the last stored balance is the derived balance');
      // Drain what is left so the next round starts from zero again.
      if (balance.total > 0) {
        await on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: balance.total,
          source: src('session', `drain-${round}`) }));
      }
    }
  }));

test('one source produces one row: repeated earns and repeated sessions are refused',
  { skip }, () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'idem');
    const earnOnce = () => on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'quran_portion', minutes: 5, source: src('quran', 'portion-1') }));
    await earnOnce();
    await assertRejects(earnOnce(), 'minutes_duplicate_source');

    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'quran_portion', minutes: 20, source: src('quran', 'seed-2') }));
    const spend = () => on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 3,
      source: src('session', 'same-session') }));
    await spend();
    await assertRejects(spend(), 'minutes_duplicate_source');

    const balance = await readBalance(client, ids);
    assert.equal(balance.total, 5 + 20 - 3);
  }));

test('Quran minutes are earned but never spent from an educational app', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'edu');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'quran_portion', minutes: 10, source: src('quran', 'edu-1') }));
    await assertRejects(on(client, (tx) => consume(tx, { ...ids, appId: 'com.learn', minutes: 5,
      source: src('session', 'edu-spend') })), 'minutes_non_countable');
    assert.equal((await readBalance(client, ids)).total, 10);
    await on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 5,
      source: src('session', 'game-spend') }));
    assert.equal((await readBalance(client, ids)).total, 5);
  }));

test('an unknown app is refused rather than guessed', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'unknown-app');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 10, source: src('athkar', 'u-1') }));
    await assertRejects(on(client, (tx) => consume(tx, { ...ids, appId: 'com.never.seen', minutes: 2,
      source: src('session', 'u-spend') })), 'minutes_unknown_app');
    assert.equal((await readBalance(client, ids)).total, 10);
  }));

test('a spend draws daily, then temporary, then the app, then free — in that order', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'order');
    await on(client, (tx) => grant(tx, { ...ids, actorMembershipId: ids.primaryId, minutes: 5,
      scope: 'daily', source: src('guardian_grant', 'order-daily') }));
    await on(client, (tx) => grant(tx, { ...ids, actorMembershipId: ids.primaryId, minutes: 4,
      scope: 'temporary', expiresAt: new Date(Date.now() + 60 * 60 * 1000),
      source: src('guardian_grant', 'order-temp') }));
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 6, appId: 'com.game', source: src('athkar', 'order-app') }));
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 7, source: src('athkar', 'order-free') }));

    const spent = await on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 18,
      source: src('session', 'order-spend') }));
    assert.deepEqual(spent.entries.map((entry) => [entry.walletScope, entry.minutes]), [
      ['daily', 5],
      ['temporary', 4],
      ['app', 6],
      ['free', 3],
    ]);
    const balance = await readBalance(client, ids);
    assert.equal(balance.total, 7 - 3);
    assert.equal(balance.daily, 0);
    assert.equal(balance.temporary, 0);
  }));

test('a child may neither earn nor grant minutes; only a guardian may', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'child-actor');
    const childAccount = await client.query(
      'INSERT INTO accounts (id, oidc_subject) VALUES (gen_random_uuid(), $1) RETURNING id',
      ['child-actor-child'],
    );
    const childMembership = await client.query(
      `INSERT INTO family_memberships (id, family_id, account_id, target_subject, role, status, joined_at)
       VALUES (gen_random_uuid(), $1, $2, $3, 'child', 'active', NOW()) RETURNING id`,
      [ids.familyId, childAccount.rows[0].id, 'child-actor-child'],
    );
    await assertRejects(on(client, (tx) => earn(tx, { ...ids, actorMembershipId: childMembership.rows[0].id,
      channel: 'athkar', minutes: 5, source: src('athkar', 'by-child') })), 'minutes_forbidden');
    await assertRejects(on(client, (tx) => grant(tx, { ...ids, actorMembershipId: childMembership.rows[0].id,
      minutes: 5, scope: 'free', source: src('guardian_grant', 'by-child') })), 'minutes_forbidden');
    assert.equal((await readBalance(client, ids)).total, 0);
  }));

test('an archived child answers 404 on every operation, and a new child reads zeros', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'archived');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 4, source: src('athkar', 'a-1') }));
    const fresh = await client.query(
      `INSERT INTO family_children (id, family_id, display_name, age_years)
       VALUES (gen_random_uuid(), $1, 'Newborn', 3) RETURNING id`,
      [ids.familyId],
    );
    const zero = await readBalance(client, { familyId: ids.familyId, childId: fresh.rows[0].id });
    assert.deepEqual([zero.daily, zero.temporary, zero.free, zero.total], [0, 0, 0, 0]);
    assert.ok(zero.asOf);

    await client.query(
      'UPDATE family_children SET archived_at = NOW(), archived_by_membership_id = $1 WHERE id = $2',
      [ids.primaryId, ids.childId],
    );
    await assertRejects(readBalance(client, ids), 'child_not_found');
    await assertRejects(readLedger(client, ids), 'child_not_found');
    await assertRejects(on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 1, source: src('athkar', 'a-2') })), 'child_not_found');
    await assertRejects(on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 1,
      source: src('session', 'a-3') })), 'child_not_found');
    await assertRejects(on(client, (tx) => expire(tx, ids)), 'child_not_found');
  }));

test('a live lock refuses a spend, and its release restores spending', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'lock');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 8, source: src('athkar', 'l-1') }));
    const lock = await client.query(
      `INSERT INTO family_child_lock_state (id, family_id, child_id, reason_code, locked_by_membership_id)
       VALUES (gen_random_uuid(), $1, $2, 'parent_lock', $3) RETURNING id`,
      [ids.familyId, ids.childId, ids.primaryId],
    );
    await assertRejects(on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 2,
      source: src('session', 'l-spend') })), 'minutes_locked');
    assert.equal((await readBalance(client, ids)).total, 8, 'a refused spend takes nothing');

    await client.query(
      `UPDATE family_child_lock_state SET released_at = NOW(), released_by_membership_id = $1 WHERE id = $2`,
      [ids.primaryId, lock.rows[0].id],
    );
    await on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 2,
      source: src('session', 'l-spend-2') }));
    assert.equal((await readBalance(client, ids)).total, 6);
  }));

test('guardian ceiling: a co-guardian at 30 succeeds and at 31 is refused; expiry is recorded once',
  { skip }, () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'ceiling');
    const coGrant = (minutes, id) => on(client, (tx) => grant(tx, { ...ids, actorMembershipId: ids.coId,
      minutes, scope: 'free', source: src('guardian_grant', id) }));
    await coGrant(30, 'co-30');
    await assertRejects(coGrant(31, 'co-31'), 'minutes_grant_ceiling');
    await on(client, (tx) => grant(tx, { ...ids, actorMembershipId: ids.primaryId, minutes: 200,
      scope: 'free', source: src('guardian_grant', 'primary-200') }));
    assert.equal((await readBalance(client, ids)).total, 230, 'primary has no per-request ceiling');

    await on(client, (tx) => grant(tx, { ...ids, actorMembershipId: ids.primaryId, minutes: 15,
      scope: 'temporary', expiresAt: new Date(Date.now() + 2000), source: src('guardian_grant', 'ttl-15') }));
    assert.equal((await readBalance(client, ids)).temporary, 15);
    await new Promise((resolve) => setTimeout(resolve, 2500));
    const after = await readBalance(client, ids);
    assert.equal(after.temporary, 0, 'the temporary pool is gone by the clock');
    assert.equal(after.total, 230, 'the total excludes it without any write');

    const first = await on(client, (tx) => expire(tx, ids));
    assert.equal(first.expired, 1);
    assert.equal(first.minutes, 15);
    const second = await on(client, (tx) => expire(tx, ids));
    assert.equal(second.expired, 0, 'a second expiry records nothing');
    const expiries = (await ledgerRows(client, ids.childId)).filter((row) => row.entry_kind === 'expiry');
    assert.equal(expiries.length, 1);
    assert.equal((await readBalance(client, ids)).total, 230, 'materializing the expiry changes no balance');
  }));

test('a reversal is a new row, once per credit, by the primary only, and never above the credit',
  { skip }, () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'reversal');
    const credited = await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 20, source: src('athkar', 'rev-1') }));
    const targetId = credited.entry.id;

    await assertRejects(on(client, (tx) => adjust(tx, { ...ids, actorMembershipId: ids.coId,
      targetEntryId: targetId, minutes: 5 })), 'minutes_forbidden');
    await assertRejects(on(client, (tx) => adjust(tx, { ...ids, actorMembershipId: ids.primaryId,
      targetEntryId: targetId, minutes: 21 })), 'minutes_reversal_exceeds_balance');

    const reversed = await on(client, (tx) => adjust(tx, { ...ids, actorMembershipId: ids.primaryId,
      targetEntryId: targetId, minutes: 5, reason: 'typo' }));
    assert.equal(reversed.reversalEntry.entryKind, 'reversal');
    assert.equal(reversed.balance.total, 15);
    await assertRejects(on(client, (tx) => adjust(tx, { ...ids, actorMembershipId: ids.primaryId,
      targetEntryId: targetId, minutes: 5 })), 'minutes_duplicate_source');

    const rows = await ledgerRows(client, ids.childId);
    assert.ok(rows.some((row) => row.entry_kind === 'credit' && row.minutes === 20),
      'the original credit is still there');
  }));

test('an allocation moves minutes between wallets and creates none', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'alloc');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'quran_portion', minutes: 20, source: src('quran', 'alloc-1') }));
    const moved = await on(client, (tx) => allocate(tx, { ...ids, actorMembershipId: ids.primaryId,
      from: { scope: 'free' }, to: { scope: 'app', appId: 'com.game' }, minutes: 8,
      transferId: randomUUID() }));
    assert.equal(moved.outEntry.entryKind, 'reversal');
    assert.equal(moved.inEntry.entryKind, 'credit');
    assert.equal(moved.balance.total, 20, 'an allocation creates no minutes');
    assert.equal(moved.balance.free, 12);
    assert.deepEqual(moved.balance.apps, [{ appId: 'com.game', minutes: 8 }]);

    await assertRejects(on(client, (tx) => allocate(tx, { ...ids, actorMembershipId: ids.primaryId,
      from: { scope: 'free' }, to: { scope: 'temporary' }, minutes: 1, transferId: randomUUID() })),
    'minutes_expiry_scope_mismatch');
  }));

test('the app projection is rebuilt from the ledger, never trusted', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'projection');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 30, source: src('athkar', 'p-1') }));
    await on(client, (tx) => allocate(tx, { ...ids, actorMembershipId: ids.primaryId,
      from: { scope: 'free' }, to: { scope: 'app', appId: 'com.game' }, minutes: 10,
      transferId: randomUUID() }));
    await on(client, (tx) => consume(tx, { ...ids, appId: 'com.game', minutes: 4,
      source: src('session', 'p-spend') }));

    const before = await readAppWalletProjection(client, { childId: ids.childId });
    const balance = await readBalance(client, ids);
    // 30 earned; 10 moved free -> app; 4 spent from the app (the app is drawn before free).
    assert.deepEqual(before.map((item) => [item.scope, item.appId, item.minutes]), [
      ['app', 'com.game', 6],
      ['free', null, 20],
    ]);
    assert.equal(balance.apps[0].minutes, 6);
    assert.equal(balance.free, 20);

    await client.query('UPDATE family_app_wallets SET earned_minutes = 999 WHERE child_id = $1', [ids.childId]);
    await client.query('DELETE FROM family_app_wallets WHERE child_id = $1 AND wallet_scope = $2',
      [ids.childId, 'free']);
    await on(client, (tx) => rebuildAppWalletProjection(tx, ids));
    const rebuilt = await readAppWalletProjection(client, { childId: ids.childId });
    assert.deepEqual(rebuilt, before, 'the rebuild restores exactly what the ledger says');
    assert.equal(rebuilt.find((item) => item.scope === 'app').minutes, balance.apps[0].minutes);
    assert.equal(rebuilt.find((item) => item.scope === 'free').minutes, balance.free);
    assert.equal(rebuilt.find((item) => item.scope === 'free').minutes, 20);
  }));

test('the ledger refuses to be edited or deleted, in the database itself', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'append-only');
    await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
      channel: 'athkar', minutes: 3, source: src('athkar', 'ao-1') }));
    await assert.rejects(
      client.query('UPDATE family_minutes_ledger SET minutes = 1 WHERE child_id = $1', [ids.childId]),
      (error) => /append-only/.test(error.message),
    );
    await assert.rejects(
      client.query('DELETE FROM family_minutes_ledger WHERE child_id = $1', [ids.childId]),
      (error) => /append-only/.test(error.message),
    );
    assert.equal((await readBalance(client, ids)).total, 3);
  }));

test('the ledger reads newest first, page by page, with no row twice', { skip },
  () => withFreshDatabase(async ({ client }) => {
    const ids = await seedFamily(client, 'pages');
    for (let index = 0; index < 5; index += 1) {
      await on(client, (tx) => earn(tx, { ...ids, actorMembershipId: ids.primaryId,
        channel: 'athkar', minutes: 1 + index, source: src('athkar', `page-${index}`) }));
    }
    const first = await readLedger(client, { ...ids, limit: 2 });
    const second = await readLedger(client, { ...ids, limit: 2, cursor: first.nextCursor });
    const third = await readLedger(client, { ...ids, limit: 2, cursor: second.nextCursor });
    const seen = [...first.entries, ...second.entries, ...third.entries].map((entry) => entry.id);
    assert.equal(new Set(seen).size, 5, 'every row appears exactly once');
    assert.equal(third.nextCursor, null);
    assert.equal(first.entries[0].minutes, 5, 'newest first');
  }));
