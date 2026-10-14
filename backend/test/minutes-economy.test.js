// Safety slice 3 — minutes economy: the pure rules, without a database.
//
// These tests pin the arithmetic that the operations in src/minutes-economy.js run: balances
// by local day and by expiry instant, the draw order, the guardian ceiling, the expiry and
// scope shapes, and the closed vocabularies. The same rules are then proven on real
// PostgreSQL in postgres-minutes-economy.test.js; this file is the cheap first line.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  EARN_CHANNELS,
  GUARDIAN_GRANT_CEILING,
  MINUTES_CHANNELS,
  WALLET_SCOPES,
  assertSource,
  assertWalletRef,
  assertWalletShape,
  balanceAt,
  consumptionSources,
  dayKey,
  grantRuleViolation,
  planDraws,
  temporaryPoolsAt,
} from '../src/minutes-economy.js';
import { isCountable } from '../src/screen-time.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';

const here = dirname(fileURLToPath(import.meta.url));
const migrationDirectory = join(here, '..', 'db', 'migrations');

// Sanaa is +180 minutes east of UTC; the family's own day starts at 21:00 UTC the day before.
const OFFSET = 180;
const at = (iso) => new Date(iso);

function row(overrides) {
  return {
    entry_kind: 'credit',
    channel: 'quran_portion',
    minutes: 10,
    wallet_scope: 'free',
    app_id: null,
    expires_at: null,
    created_at: at('2026-10-14T10:00:00Z'),
    ...overrides,
  };
}

test('daily allowance is valid only on the family day it was granted', () => {
  // 23:50 on 14 Oct in Sanaa is 20:50 UTC.
  const granted = row({ wallet_scope: 'daily', minutes: 30, created_at: at('2026-10-14T20:50:00Z') });
  assert.equal(balanceAt([granted], at('2026-10-14T20:55:00Z'), OFFSET).daily, 30);
  // 00:10 on 15 Oct in Sanaa: the allowance is gone without any job removing it.
  const later = balanceAt([granted], at('2026-10-14T21:10:00Z'), OFFSET);
  assert.equal(later.daily, 0);
  assert.equal(dayKey(at('2026-10-14T21:10:00Z'), OFFSET), '2026-10-15');
});

test('a temporary pool disappears at its expiry by the clock alone', () => {
  const expiresAt = at('2026-10-14T12:00:00Z');
  const grant = row({ wallet_scope: 'temporary', minutes: 20, expires_at: expiresAt,
    channel: 'guardian_grant', created_at: at('2026-10-14T10:00:00Z') });
  assert.equal(balanceAt([grant], at('2026-10-14T11:59:59Z'), OFFSET).temporary, 20);
  assert.equal(balanceAt([grant], at('2026-10-14T12:00:00Z'), OFFSET).temporary, 0);
});

test('a draw from a temporary pool is subtracted from that pool only', () => {
  const soon = at('2026-10-14T12:00:00Z');
  const later = at('2026-10-15T12:00:00Z');
  const rows = [
    row({ wallet_scope: 'temporary', minutes: 30, expires_at: later, channel: 'guardian_grant' }),
    row({ wallet_scope: 'temporary', minutes: 10, expires_at: soon, channel: 'guardian_grant' }),
    row({ entry_kind: 'consumption', channel: 'usage_consumption', wallet_scope: 'temporary',
      minutes: 10, expires_at: soon, created_at: at('2026-10-14T10:30:00Z') }),
  ];
  const pools = temporaryPoolsAt(rows, at('2026-10-14T11:00:00Z'));
  assert.deepEqual(pools.map((pool) => pool.minutes), [30], 'the soon pool is spent out');
  assert.equal(balanceAt(rows, at('2026-10-14T11:00:00Z'), OFFSET).temporary, 30);
});

test('app and free wallets are sums of their rows and never negative in the snapshot', () => {
  const rows = [
    row({ wallet_scope: 'app', app_id: 'com.game', minutes: 25 }),
    row({ wallet_scope: 'app', app_id: 'com.game', minutes: 5, entry_kind: 'consumption',
      channel: 'usage_consumption' }),
    row({ wallet_scope: 'free', minutes: 7 }),
  ];
  const snapshot = balanceAt(rows, at('2026-10-14T11:00:00Z'), OFFSET);
  assert.deepEqual(snapshot.apps, [{ appId: 'com.game', minutes: 20 }]);
  assert.equal(snapshot.free, 7);
  assert.equal(snapshot.total, 27);
});

test('a row created after the requested instant is invisible to it', () => {
  const rows = [row({ wallet_scope: 'free', minutes: 50, created_at: at('2026-10-14T11:00:00Z') })];
  assert.equal(balanceAt(rows, at('2026-10-14T10:59:59Z'), OFFSET).total, 0);
  assert.equal(balanceAt(rows, at('2026-10-14T11:00:00Z'), OFFSET).total, 50);
});

test('the draw order is daily, then temporary earliest-expiry first, then the app, then free', () => {
  const rows = [
    row({ wallet_scope: 'daily', minutes: 5, created_at: at('2026-10-14T10:00:00Z') }),
    row({ wallet_scope: 'temporary', minutes: 4, expires_at: at('2026-10-14T20:00:00Z'),
      channel: 'guardian_grant' }),
    row({ wallet_scope: 'temporary', minutes: 6, expires_at: at('2026-10-14T15:00:00Z'),
      channel: 'guardian_grant' }),
    row({ wallet_scope: 'app', app_id: 'com.game', minutes: 8 }),
    row({ wallet_scope: 'free', minutes: 9 }),
  ];
  const now = at('2026-10-14T11:00:00Z');
  const snapshot = balanceAt(rows, now, OFFSET);
  const sources = consumptionSources(snapshot, rows, now, 'com.game');
  const { draws, shortfall } = planDraws(20, sources);
  assert.equal(shortfall, 0);
  assert.deepEqual(draws.map((draw) => [draw.scope, draw.minutes]), [
    ['daily', 5],
    ['temporary', 6],
    ['temporary', 4],
    ['app', 5],
  ]);
  assert.equal(draws[1].expiresAt.toISOString(), '2026-10-14T15:00:00.000Z');
});

test('planDraws reports a shortfall rather than overdrawing', () => {
  const { draws, shortfall } = planDraws(12, [
    { scope: 'free', minutes: 5 },
    { scope: 'app', appId: 'com.game', minutes: 3 },
  ]);
  assert.equal(shortfall, 4);
  assert.equal(draws.reduce((sum, draw) => sum + draw.minutes, 0), 8);
});

test('primary has no ceiling; a co-guardian is held to the ceiling per request', () => {
  assert.equal(grantRuleViolation({ actorRole: 'primary_guardian', minutes: 5000 }), null);
  assert.equal(grantRuleViolation({ actorRole: 'co_guardian', minutes: GUARDIAN_GRANT_CEILING }), null);
  const over = grantRuleViolation({ actorRole: 'co_guardian', minutes: GUARDIAN_GRANT_CEILING + 1 });
  assert.equal(over.code, 'minutes_grant_ceiling');
  assert.equal(over.status, 403);
});

test('a child and any unknown role may never grant minutes', () => {
  assert.equal(grantRuleViolation({ actorRole: 'child', minutes: 1 }).code, 'minutes_forbidden');
  assert.equal(grantRuleViolation({ actorRole: 'observer', minutes: 1 }).code, 'minutes_forbidden');
});

test('an app wallet names its app; no other wallet may', () => {
  assert.deepEqual(assertWalletShape({ scope: 'app', appId: 'com.game' }, at('2026-10-14T10:00:00Z')),
    { scope: 'app', appId: 'com.game', expiresAt: null });
  assert.throws(() => assertWalletShape({ scope: 'app' }, at('2026-10-14T10:00:00Z')),
    (error) => error.code === 'minutes_invalid_scope');
  assert.throws(() => assertWalletShape({ scope: 'free', appId: 'com.game' }, at('2026-10-14T10:00:00Z')),
    (error) => error.code === 'minutes_invalid_scope');
});

test('a temporary wallet needs a future expiry; no other wallet may carry one', () => {
  const now = at('2026-10-14T10:00:00Z');
  assert.throws(() => assertWalletShape({ scope: 'temporary' }, now),
    (error) => error.code === 'minutes_expiry_scope_mismatch');
  assert.throws(() => assertWalletShape({ scope: 'temporary', expiresAt: at('2026-10-14T09:00:00Z') }, now),
    (error) => error.code === 'minutes_expiry_scope_mismatch');
  assert.throws(() => assertWalletShape({ scope: 'daily', expiresAt: at('2026-10-15T00:00:00Z') }, now),
    (error) => error.code === 'minutes_expiry_scope_mismatch');
});

test('a source wallet may be temporary without naming an expiry it is drawn from', () => {
  assert.deepEqual(assertWalletRef({ scope: 'temporary' }), { scope: 'temporary', appId: null });
  assert.throws(() => assertWalletRef({ scope: 'bogus' }), (error) => error.code === 'minutes_invalid_scope');
});

test('the source reference is a typed pair with bounded text', () => {
  assert.deepEqual(assertSource({ type: 'session', id: 's-1' }), { type: 'session', id: 's-1' });
  assert.throws(() => assertSource({ type: '', id: 'x' }), (error) => error.code === 'minutes_invalid_source');
  assert.throws(() => assertSource({ type: 'session', id: 'x'.repeat(161) }),
    (error) => error.code === 'minutes_invalid_source');
  assert.throws(() => assertSource(['session', 'x']), (error) => error.code === 'minutes_invalid_source');
});

test('Quran and education surfaces are never countable (S-1)', () => {
  assert.equal(isCountable('edu'), false);
  assert.equal(isCountable('games'), true);
  assert.equal(isCountable('social'), true);
  assert.equal(isCountable('tools'), true);
});

test('guardian channels can never be earned by a child, and earn channels are a subset', () => {
  for (const channel of ['guardian_grant', 'guardian_reversal', 'usage_consumption', 'time_request_grant']) {
    assert.equal(EARN_CHANNELS.includes(channel), false, `${channel} must not be earnable`);
  }
  for (const channel of EARN_CHANNELS) assert.ok(MINUTES_CHANNELS.includes(channel));
});

test('the JS vocabularies match the CHECK lists in migration 130 exactly', async () => {
  const sql = await readFile(join(migrationDirectory, '130_family_minutes_ledger.sql'), 'utf8');
  const listAfter = (marker) => {
    const start = sql.indexOf(marker);
    assert.notEqual(start, -1, `${marker} must exist in the migration`);
    const open = sql.indexOf('(', start + marker.length);
    const close = sql.indexOf(')', open);
    return sql.slice(open + 1, close).split(',').map((item) => item.replace(/'/g, '').trim())
      .filter(Boolean).filter((item) => !item.startsWith('--')).map((item) => item.split(/\s/)[0]);
  };
  assert.deepEqual([...MINUTES_CHANNELS].sort(), listAfter('channel TEXT NOT NULL CHECK (channel IN').sort());
  assert.deepEqual([...WALLET_SCOPES].sort(), listAfter('wallet_scope TEXT NOT NULL CHECK (wallet_scope IN').sort());
});

test('migrations 130 and 131 are recorded in the manifest in order', () => {
  const names = FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name);
  assert.equal(names.at(-2), '130_family_minutes_ledger.sql');
  assert.equal(names.at(-1), '131_family_app_wallets.sql');
  assert.equal(names.includes('125_'), false, 'the reserved gap 125 is never used');
});
