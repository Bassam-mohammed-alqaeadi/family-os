// Safety slice 3 — minutes economy: the server-side ledger of a child's screen minutes.
//
// The truth is `family_minutes_ledger` (migration 130), an append-only list of rows. Every
// number this module reports is a SUM over rows at a named instant. Nothing here stores a
// balance that could drift from the rows that produced it; `family_app_wallets` (131) is a
// projection that `rebuildAppWalletProjection` can always reconstruct from the ledger.
//
// Four wallets: daily (valid until midnight in the family's timezone), temporary (an
// explicit expiry), app (one countable app) and free (spendable across allowed apps).
//
// The nine operations (`earn`, `attribute`, `credit`, `readBalance`, `allocate`, `consume`,
// `expire`, `adjust`, `readLedger`) plus `grant`, which the grants route will call, each:
//   * runs inside a transaction (the `withMinutesTransaction` wrapper; nesting is allowed,
//     so a later caller such as the device-revocation flow can embed them in its own),
//   * takes a transaction-level advisory lock per child, so two phones spending the same
//     minutes serialize instead of both reading the same balance (the race the card's
//     acceptance requires PostgreSQL to prove),
//   * reads the clock after taking the lock, so rows of one child are ordered by when they
//     were actually written rather than by when their transaction began,
//   * refuses an archived child with 404 (the same standing rule every child read follows).
//
// Pure functions (balance arithmetic, draw planning, validation, grant rules) are exported
// separately so the rules can be tested without a database; the operations use the same
// functions, so the tested arithmetic is the arithmetic that runs.
import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';
import { DEFAULT_POLICY, familyLocalParts, isCountable } from './screen-time.js';
import {
  GUARDIAN_ROLE_KEYS,
  collaborationRoleAllowed,
  readCollaborationPolicy,
} from './collaboration-policy.js';

// ---------------------------------------------------------------------------------------
// Vocabulary (closed sets — widening is a migration, narrowing is never allowed).
// ---------------------------------------------------------------------------------------

export const ENTRY_KINDS = Object.freeze(['credit', 'consumption', 'reversal', 'expiry']);
export const WALLET_SCOPES = Object.freeze(['daily', 'temporary', 'app', 'free']);
export const MINUTES_CHANNELS = Object.freeze([
  'quran_portion',
  'athkar',
  'learning_challenge',
  'family_task_child',
  'conditional_app_unlock',
  'guardian_grant',
  'time_request_grant',
  'usage_consumption',
  'guardian_reversal',
  'migration_from_points',
]);
/** Channels a child's own activity may earn through `earn`. Guardian channels are never earned. */
export const EARN_CHANNELS = Object.freeze([
  'quran_portion',
  'athkar',
  'learning_challenge',
  'family_task_child',
  'conditional_app_unlock',
]);
/** Sources that may spend minutes (S-1: only countable surfaces spend). */
export const CONSUME_SOURCE_TYPES = Object.freeze(['session', 'usage']);

/** A guardian who is not primary may grant at most this many minutes per request (ceiling). */
export const GUARDIAN_GRANT_CEILING = 30;
export const MAX_EARN_MINUTES = 1440;
export const MAX_CONSUME_MINUTES = 1440;
/** A technical bound against integer overflow, not a product ceiling: primary has no cap. */
/** D20: every ledger row, in every operation, is 1..1440 minutes. No other per-row ceiling exists. */
export const MAX_MINUTES_PER_ENTRY = 1440;
/** D22: a reversal's reason is mandatory, 1..500 characters. */
export const MAX_REASON_LENGTH = 500;
export const DEFAULT_LEDGER_LIMIT = 50;
export const MAX_LEDGER_LIMIT = 100;

const TRANSACTION = Symbol('minutesEconomyTransaction');

// ---------------------------------------------------------------------------------------
// Errors and small validators.
// ---------------------------------------------------------------------------------------

function fail(status, code, message) {
  return new HttpError(status, code, message);
}

export function assertInteger(value, { min, max, code, field }) {
  if (!Number.isInteger(value) || value < min || value > max) {
    throw fail(400, code, `${field} must be an integer between ${min} and ${max}.`);
  }
  return value;
}

export function assertUuid(value, field) {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
    throw fail(400, 'minutes_invalid_reference', `${field} must be a UUID.`);
  }
  return value;
}

export function assertSource(source) {
  if (source === null || typeof source !== 'object' || Array.isArray(source)) {
    throw fail(400, 'minutes_invalid_source', 'source must be an object with type and id.');
  }
  const { type, id } = source;
  if (typeof type !== 'string' || type.trim().length < 1 || type.length > 60) {
    throw fail(400, 'minutes_invalid_source', 'source.type must be 1-60 characters.');
  }
  if (typeof id !== 'string' || id.trim().length < 1 || id.length > 160) {
    throw fail(400, 'minutes_invalid_source', 'source.id must be 1-160 characters.');
  }
  return { type, id };
}

/** A reference to a wallet that is being drawn from: its shape, but no expiry demanded. */
export function assertWalletRef({ scope, appId = null }) {
  if (!WALLET_SCOPES.includes(scope)) {
    throw fail(400, 'minutes_invalid_scope', 'scope must be one of daily, temporary, app, free.');
  }
  if (scope === 'app') {
    if (typeof appId !== 'string' || appId.trim().length < 1 || appId.length > 120) {
      throw fail(400, 'minutes_invalid_scope', 'An app wallet needs an appId.');
    }
    return { scope, appId };
  }
  if (appId !== null && appId !== undefined) {
    throw fail(400, 'minutes_invalid_scope', 'Only an app wallet may name an appId.');
  }
  return { scope, appId: null };
}

export function assertWalletShape({ scope, appId = null, expiresAt = null }, now) {
  if (!WALLET_SCOPES.includes(scope)) {
    throw fail(400, 'minutes_invalid_scope', 'scope must be one of daily, temporary, app, free.');
  }
  if (scope === 'app') {
    if (typeof appId !== 'string' || appId.trim().length < 1 || appId.length > 120) {
      throw fail(400, 'minutes_invalid_scope', 'An app wallet needs an appId.');
    }
  } else if (appId !== null && appId !== undefined) {
    throw fail(400, 'minutes_invalid_scope', 'Only an app wallet may name an appId.');
  }
  if (scope === 'temporary') {
    if (!(expiresAt instanceof Date) || Number.isNaN(expiresAt.getTime()) || expiresAt <= now) {
      throw fail(400, 'minutes_expiry_scope_mismatch',
        'A temporary wallet needs an expiry strictly in the future.');
    }
  } else if (expiresAt !== null && expiresAt !== undefined) {
    throw fail(400, 'minutes_expiry_scope_mismatch', 'Only a temporary wallet may carry an expiry.');
  }
  return {
    scope,
    appId: scope === 'app' ? appId : null,
    expiresAt: scope === 'temporary' ? expiresAt : null,
  };
}

// ---------------------------------------------------------------------------------------
// Pure arithmetic over ledger rows. A row is { entry_kind, minutes, wallet_scope, app_id,
// expires_at (Date|null), created_at (Date) }; these are the shapes the database returns.
// ---------------------------------------------------------------------------------------

/** +minutes for a credit, -minutes for anything that takes minutes away. */
export function signedMinutes(row) {
  return row.entry_kind === 'credit' ? row.minutes : -row.minutes;
}

/** The family's local calendar day (YYYY-MM-DD) of an instant, in the family's offset. */
export function dayKey(instant, offsetMinutes) {
  return familyLocalParts(instant, offsetMinutes).date;
}

/**
 * The child's wallets as they stand at `at`. Rows created after `at` are invisible, so the
 * same function answers "now" and "what did it look like at 21:00 yesterday".
 *
 * Daily: only rows whose local day equals the local day of `at` — yesterday's allowance is
 * gone at midnight without any job having to remove it. Temporary: only pools whose expiry
 * is still ahead of `at` — an expired pool is excluded by the clock, not by a row.
 */
export function balanceAt(rows, at, offsetMinutes) {
  const today = dayKey(at, offsetMinutes);
  let daily = 0;
  let temporary = 0;
  let free = 0;
  const apps = new Map();
  for (const row of rows) {
    if (row.created_at > at) continue;
    const amount = signedMinutes(row);
    switch (row.wallet_scope) {
      case 'daily':
        if (dayKey(row.created_at, offsetMinutes) === today) daily += amount;
        break;
      case 'temporary':
        if (row.expires_at > at) temporary += amount;
        break;
      case 'free':
        free += amount;
        break;
      case 'app':
        apps.set(row.app_id, (apps.get(row.app_id) ?? 0) + amount);
        break;
      default:
        break;
    }
  }
  const appList = [...apps.entries()]
    .filter(([, minutes]) => minutes > 0)
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([appId, minutes]) => ({ appId, minutes }));
  const total = daily + temporary + free + appList.reduce((sum, app) => sum + app.minutes, 0);
  return { daily, temporary, free, apps: appList, total, asOf: at };
}

/** Temporary pools alive at `at`, earliest expiry first: [{ expiresAt, minutes }]. */
export function temporaryPoolsAt(rows, at) {
  const pools = new Map();
  for (const row of rows) {
    if (row.wallet_scope !== 'temporary') continue;
    if (row.created_at > at || row.expires_at <= at) continue;
    const key = row.expires_at.toISOString();
    const current = pools.get(key) ?? { expiresAt: row.expires_at, minutes: 0 };
    current.minutes += signedMinutes(row);
    pools.set(key, current);
  }
  return [...pools.values()]
    .filter((pool) => pool.minutes > 0)
    .sort((a, b) => a.expiresAt - b.expiresAt);
}

/**
 * Minutes still held by one credit: the credit itself, less every row that names it through
 * `credit_ref` (consumption, reversal, expiry). The ledger alone answers "how much of this
 * grant is left", so an expiry can record exactly the unspent part of each credit.
 */
export function remainingOf(rows, creditId) {
  let remaining = 0;
  for (const row of rows) {
    if (row.id === creditId || row.credit_ref === creditId) remaining += signedMinutes(row);
  }
  return remaining;
}

function creditOrder(a, b) {
  const byExpiry = (a.expiresAt ? a.expiresAt.getTime() : 0) - (b.expiresAt ? b.expiresAt.getTime() : 0);
  if (byExpiry !== 0) return byExpiry;
  const byCreated = a.createdAt.getTime() - b.createdAt.getTime();
  if (byCreated !== 0) return byCreated;
  return a.creditId < b.creditId ? -1 : a.creditId > b.creditId ? 1 : 0;
}

/**
 * Every credit that still holds minutes at `at`, in draw order: earliest expiry first, then the
 * earlier credit (FEFO, then FIFO). Daily credits count only on today's local day; temporary
 * credits only before their expiry. Rows created after `at` are invisible.
 */
export function creditSources(rows, at, offsetMinutes) {
  const today = dayKey(at, offsetMinutes);
  const live = rows.filter((row) => row.created_at <= at);
  const out = [];
  for (const row of live) {
    if (row.entry_kind !== 'credit') continue;
    if (row.wallet_scope === 'daily' && dayKey(row.created_at, offsetMinutes) !== today) continue;
    if (row.wallet_scope === 'temporary' && row.expires_at <= at) continue;
    const minutes = remainingOf(live, row.id);
    if (minutes <= 0) continue;
    out.push({
      creditId: row.id, scope: row.wallet_scope, appId: row.app_id ?? null,
      expiresAt: row.expires_at ?? null, createdAt: row.created_at, minutes,
    });
  }
  return out.sort(creditOrder);
}

/**
 * The order in which a spend draws minutes: today's allowance, then temporary credits (earliest
 * expiry first), then the app's own credits, then free credits. A draw is per credit, so every
 * consumption row names the credit it came from. Spending from the free wallet first would
 * strand the minutes a family granted for a purpose.
 */
export function consumptionSources(rows, at, offsetMinutes, appId) {
  const credits = creditSources(rows, at, offsetMinutes);
  const of = (scope, pick = () => true) => credits.filter((c) => c.scope === scope && pick(c));
  return [
    ...of('daily'),
    ...of('temporary'),
    ...of('app', (c) => c.appId === appId),
    ...of('free'),
  ];
}

/** Greedy draw over ordered sources. Never draws more than a source holds. */
export function planDraws(minutes, sources) {
  let remaining = minutes;
  const draws = [];
  for (const source of sources) {
    if (remaining === 0) break;
    const take = Math.min(remaining, Math.max(0, source.minutes));
    if (take > 0) {
      draws.push({
        creditId: source.creditId ?? null,
        scope: source.scope,
        appId: source.appId ?? null,
        expiresAt: source.expiresAt ?? null,
        minutes: take,
      });
      remaining -= take;
    }
  }
  return { draws, shortfall: remaining };
}

/**
 * The guardian-grant rule, as a pure function. Primary has no ceiling per request; any other
 * guardian is held to GUARDIAN_GRANT_CEILING, because a co-parent's ability to add minutes is
 * the thing a primary most needs to be able to bound.
 */
export function grantRuleViolation({ actorRole, minutes }) {
  if (actorRole === 'primary_guardian') return null;
  if (actorRole === 'co_guardian') {
    if (minutes <= GUARDIAN_GRANT_CEILING) return null;
    return { status: 403, code: 'minutes_grant_ceiling',
      message: `A co-guardian may grant at most ${GUARDIAN_GRANT_CEILING} minutes per request.` };
  }
  return { status: 403, code: 'minutes_forbidden', message: 'Only a guardian may grant minutes.' };
}

// ---------------------------------------------------------------------------------------
// Views: the shapes the contract publishes.
// ---------------------------------------------------------------------------------------

function iso(value) {
  if (value === null || value === undefined) return null;
  return value instanceof Date ? value.toISOString() : String(value);
}

export function entryView(row) {
  return {
    id: row.id,
    entryKind: row.entry_kind,
    channel: row.channel,
    minutes: row.minutes,
    walletScope: row.wallet_scope,
    appId: row.app_id ?? null,
    expiresAt: iso(row.expires_at),
    creditRef: row.credit_ref ?? null,
    sourceType: row.source_type,
    sourceId: row.source_id,
    actorMembershipId: row.actor_membership_id ?? null,
    awardedByDeviceId: row.awarded_by_device_id ?? null,
    balanceAfterMinutes: row.balance_after_minutes,
    createdAt: iso(row.created_at),
  };
}

export function balanceView(balance) {
  return {
    daily: balance.daily,
    temporary: balance.temporary,
    free: balance.free,
    apps: balance.apps.map((app) => ({ appId: app.appId, minutes: app.minutes })),
    total: balance.total,
    asOf: iso(balance.asOf),
  };
}

// ---------------------------------------------------------------------------------------
// Transactions, locks and the per-operation context.
// ---------------------------------------------------------------------------------------

/**
 * Run `fn` inside a transaction on `client`. Nested calls on the same client join the outer
 * transaction, so an operation can be embedded in a larger one without a savepoint dance.
 * The child lock is transaction-scoped, so it is held until the outermost COMMIT: releasing
 * it earlier would let a second writer read rows the first has not committed yet.
 */
export async function withMinutesTransaction(client, fn) {
  if (client[TRANSACTION]) return fn(client);
  await client.query('BEGIN');
  client[TRANSACTION] = true;
  try {
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    throw error;
  } finally {
    client[TRANSACTION] = false;
  }
}

function lockKey(childId) {
  return `minutes-economy:${childId}`;
}

async function assertActiveChild(client, { familyId, childId }) {
  const { rows } = await client.query(
    `SELECT id FROM family_children
      WHERE id = $1 AND family_id = $2 AND archived_at IS NULL`,
    [childId, familyId],
  );
  if (rows.length === 0) {
    throw fail(404, 'child_not_found', 'The child was not found in this family.');
  }
}

async function readOffset(client, childId) {
  const { rows } = await client.query(
    'SELECT timezone_offset_minutes FROM family_child_screen_time_policies WHERE child_id = $1',
    [childId],
  );
  return rows[0]?.timezone_offset_minutes ?? DEFAULT_POLICY.timezoneOffsetMinutes;
}

async function loadRows(client, { familyId, childId }) {
  const { rows } = await client.query(
    `SELECT id, family_id, child_id, entry_kind, channel, minutes, wallet_scope, app_id,
            expires_at, source_type, source_id, actor_membership_id, awarded_by_device_id,
            balance_after_minutes, created_at, credit_ref
       FROM family_minutes_ledger
      WHERE family_id = $1 AND child_id = $2
      ORDER BY created_at, id`,
    [familyId, childId],
  );
  return rows;
}

async function readActor(client, { familyId, membershipId }) {
  assertUuid(membershipId, 'actorMembershipId');
  const { rows } = await client.query(
    'SELECT id, role, status FROM family_memberships WHERE id = $1 AND family_id = $2',
    [membershipId, familyId],
  );
  const actor = rows[0];
  if (!actor || actor.status !== 'active') {
    throw fail(403, 'minutes_forbidden', 'The acting membership is not an active member of this family.');
  }
  return actor;
}

function assertGuardian(actor) {
  if (!GUARDIAN_ROLE_KEYS.includes(actor.role)) {
    throw fail(403, 'minutes_forbidden', 'Only a guardian may do this.');
  }
}

/**
 * Lock the child, prove it is active, read the clock and the ledger, then run `fn` with a
 * context whose `rows` and `total` track what this operation has already written.
 */
async function withChild(client, { familyId, childId }, fn) {
  return withMinutesTransaction(client, async (tx) => {
    await tx.query('SELECT pg_advisory_xact_lock(hashtext($1))', [lockKey(childId)]);
    await assertActiveChild(tx, { familyId, childId });
    const { rows: clockRows } = await tx.query('SELECT clock_timestamp() AS now');
    const now = clockRows[0].now;
    const offset = await readOffset(tx, childId);
    const ctxRows = await loadRows(tx, { familyId, childId });
    const ctx = {
      familyId,
      childId,
      now,
      offset,
      rows: ctxRows,
      total: balanceAt(ctxRows, now, offset).total,
    };
    return fn(tx, ctx);
  });
}

async function hasSource(client, { childId, sourceType, sourceId }) {
  const { rows } = await client.query(
    `SELECT 1 FROM family_minutes_ledger
      WHERE child_id = $1 AND source_type = $2 AND source_id = $3`,
    [childId, sourceType, sourceId],
  );
  return rows.length > 0;
}

async function assertNoDuplicateSource(client, args) {
  if (await hasSource(client, args)) {
    throw fail(409, 'minutes_duplicate_source',
      'These minutes were already recorded for this source.');
  }
}

/**
 * Append one row. The running total moves with it, so every row records the balance the
 * family saw immediately after it. An expiry changes nothing in the total: the pool it closes
 * was already excluded by the clock, and writing the row only makes that exclusion visible.
 */
async function appendRow(client, ctx, row) {
  const id = randomUUID();
  const createdAt = ctx.now;
  const signed = row.entry_kind === 'expiry' ? 0 : signedMinutes(row);
  const total = ctx.total + signed;
  try {
    await client.query(
      `INSERT INTO family_minutes_ledger
         (id, family_id, child_id, entry_kind, channel, minutes, wallet_scope, app_id,
          expires_at, source_type, source_id, actor_membership_id, awarded_by_device_id,
          balance_after_minutes, created_at, credit_ref)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`,
      [
        id, ctx.familyId, ctx.childId, row.entry_kind, row.channel, row.minutes,
        row.wallet_scope, row.app_id ?? null, row.expires_at ?? null,
        row.source_type, row.source_id, row.actor_membership_id ?? null,
        row.awarded_by_device_id ?? null, total, createdAt, row.credit_ref ?? null,
      ],
    );
  } catch (error) {
    if (error?.code === '23505') {
      throw fail(409, 'minutes_duplicate_source',
        'These minutes were already recorded for this source.');
    }
    throw error;
  }
  const stored = { ...row, id, family_id: ctx.familyId, child_id: ctx.childId,
    app_id: row.app_id ?? null, expires_at: row.expires_at ?? null, credit_ref: row.credit_ref ?? null,
    actor_membership_id: row.actor_membership_id ?? null,
    awarded_by_device_id: row.awarded_by_device_id ?? null,
    balance_after_minutes: total, created_at: createdAt };
  ctx.rows.push(stored);
  ctx.total = total;
  return stored;
}

/** The app-wallet and free-wallet projection, rebuilt from the ledger. Idempotent. */
export async function rebuildAppWalletProjection(client, { familyId, childId }) {
  await withMinutesTransaction(client, async (tx) => {
    await tx.query('DELETE FROM family_app_wallets WHERE child_id = $1', [childId]);
    await tx.query(
      `INSERT INTO family_app_wallets
         (id, family_id, child_id, wallet_scope, app_id, earned_minutes, updated_at)
       SELECT gen_random_uuid(), family_id, child_id, wallet_scope, app_id,
              SUM(CASE WHEN entry_kind = 'credit' THEN minutes ELSE -minutes END)::INTEGER,
              NOW()
         FROM family_minutes_ledger
        WHERE family_id = $1 AND child_id = $2 AND wallet_scope IN ('app', 'free')
        GROUP BY family_id, child_id, wallet_scope, app_id
       HAVING SUM(CASE WHEN entry_kind = 'credit' THEN minutes ELSE -minutes END) > 0`,
      [familyId, childId],
    );
  });
}

// ---------------------------------------------------------------------------------------
// Operations.
// ---------------------------------------------------------------------------------------

/** Read the balance at `at` (default: now). A child with no rows reads zeros, never 404. */
export async function readBalance(client, { familyId, childId, at = null }) {
  return withMinutesTransaction(client, async (tx) => {
    await assertActiveChild(tx, { familyId, childId });
    const { rows: clockRows } = await tx.query('SELECT clock_timestamp() AS now');
    const now = clockRows[0].now;
    const instant = at === null ? now : new Date(at);
    if (Number.isNaN(instant.getTime()) || instant > now) {
      throw fail(400, 'minutes_invalid_time', 'at must be a valid instant not later than now.');
    }
    const offset = await readOffset(tx, childId);
    const rows = await loadRows(tx, { familyId, childId });
    return balanceView(balanceAt(rows, instant, offset));
  });
}

/** Page the ledger newest first. A child with no rows reads an empty page, never 404. */
export async function readLedger(client, { familyId, childId, limit = DEFAULT_LEDGER_LIMIT, cursor = null }) {
  assertInteger(limit, { min: 1, max: MAX_LEDGER_LIMIT, code: 'minutes_invalid_limit', field: 'limit' });
  const position = cursor === null ? null : decodeCursor(cursor);
  return withMinutesTransaction(client, async (tx) => {
    await assertActiveChild(tx, { familyId, childId });
    const params = [familyId, childId, limit + 1];
    let where = '';
    if (position !== null) {
      params.push(position.createdAt, position.id);
      where = 'AND (created_at, id) < ($4, $5)';
    }
    const { rows } = await tx.query(
      `SELECT id, entry_kind, channel, minutes, wallet_scope, app_id, expires_at, source_type,
              source_id, actor_membership_id, awarded_by_device_id, balance_after_minutes, created_at
         FROM family_minutes_ledger
        WHERE family_id = $1 AND child_id = $2 ${where}
        ORDER BY created_at DESC, id DESC
        LIMIT $3`,
      params,
    );
    const page = rows.slice(0, limit);
    const last = page[page.length - 1];
    return {
      entries: page.map(entryView),
      nextCursor: rows.length > limit && last ? encodeCursor(last) : null,
    };
  });
}

function encodeCursor(row) {
  return Buffer.from(JSON.stringify({ c: row.created_at.toISOString(), i: row.id })).toString('base64url');
}

function decodeCursor(cursor) {
  try {
    const parsed = JSON.parse(Buffer.from(String(cursor), 'base64url').toString('utf8'));
    const createdAt = new Date(parsed.c);
    assertUuid(parsed.i, 'cursor');
    if (Number.isNaN(createdAt.getTime())) throw new Error('bad cursor');
    return { createdAt, id: parsed.i };
  } catch {
    throw fail(400, 'minutes_invalid_cursor', 'The ledger cursor is not valid.');
  }
}

/** The one door minutes enter through, for a guardian or a verified activity. */
export async function earn(client, {
  familyId, childId, actorMembershipId, channel, minutes, appId = null, source,
}) {
  if (!EARN_CHANNELS.includes(channel)) {
    throw fail(400, 'minutes_invalid_channel', 'This channel cannot earn minutes.');
  }
  assertInteger(minutes, { min: 1, max: MAX_EARN_MINUTES, code: 'minutes_invalid_amount', field: 'minutes' });
  const src = assertSource(source);
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    const actor = await readActor(tx, { familyId, membershipId: actorMembershipId });
    assertGuardian(actor);
    if (channel === 'family_task_child') {
      const policy = await readCollaborationPolicy(tx, { familyId });
      if (!collaborationRoleAllowed(actor, policy, 'task')) {
        throw fail(403, 'minutes_forbidden', 'Your role may not confirm family tasks.');
      }
    }
    await assertNoDuplicateSource(tx, { childId, sourceType: src.type, sourceId: src.id });
    const wallet = await attribute(tx, ctx, { appId });
    const entry = await credit(tx, ctx, {
      channel, minutes, wallet, source: src, actorMembershipId: actor.id,
    });
    await rebuildAppWalletProjection(tx, { familyId, childId });
    return { entry: entryView(entry), balance: balanceView(balanceAt(ctx.rows, ctx.now, ctx.offset)) };
  });
}

/** Where a credit lands: a named app (must be a known app of this child) or the free wallet. */
export async function attribute(client, ctx, { appId }) {
  if (appId === null || appId === undefined) {
    return { scope: 'free', appId: null, expiresAt: null };
  }
  if (typeof appId !== 'string' || appId.trim().length < 1 || appId.length > 120) {
    throw fail(400, 'minutes_invalid_scope', 'appId must be 1-120 characters.');
  }
  const { rows } = await client.query(
    'SELECT app_id FROM family_child_apps WHERE child_id = $1 AND app_id = $2',
    [ctx.childId, appId],
  );
  if (rows.length === 0) {
    throw fail(409, 'minutes_unknown_app', 'The server does not know this app for this child yet.');
  }
  return { scope: 'app', appId, expiresAt: null };
}

/** Append a credit into a resolved wallet. Callers have already decided who may credit. */
export async function credit(client, ctx, {
  channel, minutes, wallet, source, actorMembershipId = null, awardedByDeviceId = null,
}) {
  return appendRow(client, ctx, {
    entry_kind: 'credit',
    channel,
    minutes,
    wallet_scope: wallet.scope,
    app_id: wallet.appId,
    expires_at: wallet.expiresAt,
    source_type: source.type,
    source_id: source.id,
    actor_membership_id: actorMembershipId,
    awarded_by_device_id: awardedByDeviceId,
  });
}

/**
 * A guardian grant: daily, temporary (with an expiry), app or free. The grant rule is the
 * pure `grantRuleViolation`; the expiry and scope rules are `assertWalletShape`.
 */
export async function grant(client, {
  familyId, childId, actorMembershipId, minutes, scope, appId = null, expiresAt = null,
  source, reason = '',
}) {
  assertInteger(minutes, { min: 1, max: MAX_MINUTES_PER_ENTRY, code: 'minutes_invalid_amount', field: 'minutes' });
  if (typeof reason !== 'string' || reason.length > MAX_REASON_LENGTH) {
    throw fail(400, 'minutes_invalid_reason', `reason must be at most ${MAX_REASON_LENGTH} characters.`);
  }
  const src = assertSource(source);
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    const wallet = assertWalletShape({ scope, appId, expiresAt }, ctx.now);
    if (wallet.scope === 'app') {
      const { rows } = await tx.query(
        'SELECT app_id FROM family_child_apps WHERE child_id = $1 AND app_id = $2',
        [childId, wallet.appId],
      );
      if (rows.length === 0) {
        throw fail(409, 'minutes_unknown_app', 'The server does not know this app for this child yet.');
      }
    }
    const actor = await readActor(tx, { familyId, membershipId: actorMembershipId });
    const violation = grantRuleViolation({ actorRole: actor.role, minutes });
    if (violation !== null) {
      throw fail(violation.status, violation.code, violation.message);
    }
    await assertNoDuplicateSource(tx, { childId, sourceType: src.type, sourceId: src.id });
    const entry = await credit(tx, ctx, {
      channel: 'guardian_grant', minutes, wallet, source: src, actorMembershipId: actor.id,
    });
    await rebuildAppWalletProjection(tx, { familyId, childId });
    return { entry: entryView(entry), balance: balanceView(balanceAt(ctx.rows, ctx.now, ctx.offset)) };
  });
}

/**
 * Spend minutes for a session or a usage record. The draw order is pinned by
 * `consumptionSources`; each draw is its own row, so a temporary pool that spans two expiries
 * leaves two honest rows rather than one that names the wrong expiry.
 */
export async function consume(client, {
  familyId, childId, appId, minutes, source, deviceId = null,
}) {
  if (typeof appId !== 'string' || appId.trim().length < 1 || appId.length > 120) {
    throw fail(400, 'minutes_invalid_scope', 'appId must be 1-120 characters.');
  }
  assertInteger(minutes, { min: 1, max: MAX_CONSUME_MINUTES, code: 'minutes_invalid_amount', field: 'minutes' });
  if (source === null || typeof source !== 'object' || !CONSUME_SOURCE_TYPES.includes(source.type)) {
    throw fail(400, 'minutes_invalid_source', 'consume source.type must be session or usage.');
  }
  const src = assertSource(source);
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    if (deviceId !== null) {
      assertUuid(deviceId, 'deviceId');
      const { rows } = await tx.query(
        `SELECT id FROM family_child_devices
          WHERE id = $1 AND child_id = $2 AND family_id = $3 AND credential_revoked_at IS NULL`,
        [deviceId, childId, familyId],
      );
      if (rows.length === 0) {
        throw fail(403, 'minutes_forbidden', 'This device is not an active handset of this child.');
      }
    }
    const { rows: lockRows } = await tx.query(
      `SELECT id FROM family_child_lock_state
        WHERE child_id = $1 AND family_id = $2 AND released_at IS NULL`,
      [childId, familyId],
    );
    if (lockRows.length > 0) {
      throw fail(409, 'minutes_locked', 'The phone is locked right now; nothing was spent.');
    }
    const { rows: appRows } = await tx.query(
      'SELECT category FROM family_child_apps WHERE child_id = $1 AND app_id = $2',
      [childId, appId],
    );
    if (appRows.length === 0) {
      throw fail(409, 'minutes_unknown_app', 'The server does not know this app for this child yet.');
    }
    if (!isCountable(appRows[0].category)) {
      throw fail(409, 'minutes_non_countable', 'This app does not spend minutes.');
    }
    const firstSourceId = `${src.id}#1`;
    await assertNoDuplicateSource(tx, { childId, sourceType: src.type, sourceId: firstSourceId });

    const sources = consumptionSources(ctx.rows, ctx.now, ctx.offset, appId);
    const { draws, shortfall } = planDraws(minutes, sources);
    if (shortfall > 0) {
      throw fail(409, 'minutes_insufficient', 'Not enough minutes for this spend.');
    }
    const entries = [];
    for (let index = 0; index < draws.length; index += 1) {
      const draw = draws[index];
      const row = await appendRow(tx, ctx, {
        entry_kind: 'consumption',
        channel: 'usage_consumption',
        minutes: draw.minutes,
        wallet_scope: draw.scope,
        app_id: draw.scope === 'app' ? appId : null,
        expires_at: draw.expiresAt,
        credit_ref: draw.creditId,
        source_type: src.type,
        source_id: `${src.id}#${index + 1}`,
      });
      entries.push(entryView(row));
    }
    await rebuildAppWalletProjection(tx, { familyId, childId });
    return { entries, balance: balanceView(balanceAt(ctx.rows, ctx.now, ctx.offset)) };
  });
}

/**
 * Move minutes between wallets without creating any: a reversal out of the source wallet and
 * a credit into the target, both carrying one transfer id. Temporary is only a source, never
 * a target, because a transfer into it would need an expiry the family never chose.
 */
export async function allocate(client, {
  familyId, childId, actorMembershipId, from, to, minutes, transferId, reason = '',
}) {
  assertInteger(minutes, { min: 1, max: MAX_MINUTES_PER_ENTRY, code: 'minutes_invalid_amount', field: 'minutes' });
  assertUuid(transferId, 'transferId');
  if (typeof reason !== 'string' || reason.length > MAX_REASON_LENGTH) {
    throw fail(400, 'minutes_invalid_reason', `reason must be at most ${MAX_REASON_LENGTH} characters.`);
  }
  // D21: an allocation moves minutes only between app and free wallets. A daily or temporary
  // wallet on either end would let a parent dodge expiry, so both are refused.
  if (!['app', 'free'].includes(from?.scope) || !['app', 'free'].includes(to?.scope)) {
    throw fail(400, 'minutes_invalid_scope', 'An allocation moves minutes only between app and free wallets.');
  }
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    const actor = await readActor(tx, { familyId, membershipId: actorMembershipId });
    assertGuardian(actor);
    const source = assertWalletRef({ scope: from?.scope, appId: from?.appId ?? null });
    const target = assertWalletRef({ scope: to?.scope, appId: to?.appId ?? null });
    if (target.scope === 'app') {
      const { rows: known } = await tx.query(
        'SELECT app_id FROM family_child_apps WHERE child_id = $1 AND app_id = $2',
        [childId, target.appId],
      );
      if (known.length === 0) {
        throw fail(409, 'minutes_unknown_app', 'The server does not know this app for this child yet.');
      }
    }
    if (source.scope === target.scope && source.appId === target.appId) {
      throw fail(400, 'minutes_invalid_scope', 'An allocation must move minutes between two different wallets.');
    }
    await assertNoDuplicateSource(tx, { childId, sourceType: 'scope_transfer', sourceId: `${transferId}:out#1` });
    const sources = consumptionSources(ctx.rows, ctx.now, ctx.offset, source.appId).filter(
      (candidate) => candidate.scope === source.scope
        && (source.scope !== 'app' || candidate.appId === source.appId),
    );
    const { draws, shortfall } = planDraws(minutes, sources);
    if (shortfall > 0) {
      throw fail(409, 'minutes_insufficient', 'Not enough minutes in the source wallet.');
    }
    const outEntries = [];
    for (let index = 0; index < draws.length; index += 1) {
      const draw = draws[index];
      const row = await appendRow(tx, ctx, {
        entry_kind: 'reversal',
        channel: 'guardian_reversal',
        minutes: draw.minutes,
        wallet_scope: draw.scope,
        app_id: draw.scope === 'app' ? source.appId : null,
        expires_at: draw.expiresAt,
        source_type: 'scope_transfer',
        credit_ref: draw.creditId,
        source_id: `${transferId}:out#${index + 1}`,
        actor_membership_id: actor.id,
      });
      outEntries.push(entryView(row));
    }
    const inRow = await appendRow(tx, ctx, {
      entry_kind: 'credit',
      channel: 'guardian_grant',
      minutes,
      wallet_scope: target.scope,
      app_id: target.scope === 'app' ? target.appId : null,
      expires_at: null,
      source_type: 'scope_transfer',
      source_id: `${transferId}:in`,
      actor_membership_id: actor.id,
    });
    await rebuildAppWalletProjection(tx, { familyId, childId });
    return {
      outEntry: outEntries[0],
      outEntries,
      inEntry: entryView(inRow),
      balance: balanceView(balanceAt(ctx.rows, ctx.now, ctx.offset)),
    };
  });
}

/**
 * A primary guardian reverses a credit. One reversal per credit (the source is the credit
 * itself), never more than the credit granted, and never more than the wallet holds now.
 * The original stays in the ledger: the parent sees the mistake and its correction together.
 */
export async function adjust(client, {
  familyId, childId, actorMembershipId, targetEntryId, minutes, reason,
}) {
  assertUuid(targetEntryId, 'targetEntryId');
  assertInteger(minutes, { min: 1, max: MAX_MINUTES_PER_ENTRY, code: 'minutes_invalid_amount', field: 'minutes' });
  // D22: a reversal always says why. Mandatory, 1..500 characters, at the operation level.
  if (typeof reason !== 'string' || reason.trim().length < 1 || reason.length > MAX_REASON_LENGTH) {
    throw fail(400, 'minutes_invalid_reason', `reason is required: 1-${MAX_REASON_LENGTH} characters.`);
  }
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    const actor = await readActor(tx, { familyId, membershipId: actorMembershipId });
    if (actor.role !== 'primary_guardian') {
      throw fail(403, 'minutes_forbidden', 'Only the primary guardian may reverse minutes.');
    }
    const target = ctx.rows.find((row) => row.id === targetEntryId);
    if (!target) {
      throw fail(404, 'minutes_entry_not_found', 'No ledger entry with this id belongs to this child.');
    }
    if (target.entry_kind !== 'credit') {
      throw fail(409, 'minutes_not_reversible', 'Only a credit can be reversed.');
    }
    if (target.wallet_scope === 'temporary' && target.expires_at <= ctx.now) {
      throw fail(409, 'minutes_not_reversible', 'An expired credit cannot be reversed; it has already expired.');
    }
    await assertNoDuplicateSource(tx, { childId, sourceType: 'minutes_reversal', sourceId: targetEntryId });
    // What this credit still holds, after spends and expiry: a reversal never takes more than that.
    const available = remainingOf(ctx.rows, target.id);
    if (minutes > available) {
      throw fail(409, 'minutes_reversal_exceeds_balance', 'The credit holds fewer minutes than this reversal.');
    }
    const row = await appendRow(tx, ctx, {
      entry_kind: 'reversal',
      channel: 'guardian_reversal',
      minutes,
      wallet_scope: target.wallet_scope,
      app_id: target.app_id ?? null,
      expires_at: target.expires_at ?? null,
      credit_ref: target.id,
      source_type: 'minutes_reversal',
      source_id: targetEntryId,
      actor_membership_id: actor.id,
    });
    await rebuildAppWalletProjection(tx, { familyId, childId });
    return { reversalEntry: entryView(row), balance: balanceView(balanceAt(ctx.rows, ctx.now, ctx.offset)) };
  });
}

/**
 * Materialize the expiry of temporary credits whose time has passed (D25). One expiry row per
 * credit, carrying the part of that credit still unspent at expiry (`credit_ref` names it).
 * Idempotent: the source is the credit itself, so a second run records nothing. Reads never
 * depend on this having run: `balanceAt` already excludes an expired credit by the clock.
 */
export async function expire(client, { familyId, childId }) {
  return withChild(client, { familyId, childId }, async (tx, ctx) => {
    const due = ctx.rows
      .filter((row) => row.entry_kind === 'credit' && row.wallet_scope === 'temporary' && row.expires_at <= ctx.now)
      .sort((a, b) => a.expires_at - b.expires_at || a.created_at - b.created_at
        || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
    const written = [];
    for (const credit of due) {
      const minutes = remainingOf(ctx.rows, credit.id);
      if (minutes <= 0) continue;
      if (await hasSource(tx, { childId, sourceType: 'minutes_expiry', sourceId: credit.id })) continue;
      const row = await appendRow(tx, ctx, {
        entry_kind: 'expiry',
        channel: 'guardian_grant',
        minutes,
        wallet_scope: 'temporary',
        app_id: null,
        expires_at: credit.expires_at,
        credit_ref: credit.id,
        source_type: 'minutes_expiry',
        source_id: credit.id,
      });
      written.push(entryView(row));
    }
    return {
      expired: written.length,
      minutes: written.reduce((sum, entry) => sum + entry.minutes, 0),
      entries: written,
    };
  });
}

/** Read the projection rows (for the rebuild check and the card's evidence). */
export async function readAppWalletProjection(client, { childId }) {
  const { rows } = await client.query(
    `SELECT wallet_scope, app_id, earned_minutes FROM family_app_wallets
      WHERE child_id = $1 ORDER BY wallet_scope, app_id NULLS FIRST`,
    [childId],
  );
  return rows.map((row) => ({
    scope: row.wallet_scope,
    appId: row.app_id,
    minutes: row.earned_minutes,
  }));
}
