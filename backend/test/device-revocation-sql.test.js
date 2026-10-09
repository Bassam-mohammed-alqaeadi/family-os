// The production revocation adapter, against a recording pool.
//
// The other half of this operation is tested over the in-memory store, but an
// in-memory adapter cannot prove anything about the statements PostgreSQL actually
// receives. This file asserts on the SQL itself, because here the statement IS the
// behaviour: the guard against a second revocation lives in a WHERE clause, the
// revocation time comes from the database clock, and the audit record, the outbox
// event, the recorded fact and the idempotency slot have to share one transaction
// with the revocation they describe.
import assert from 'node:assert/strict';
import test from 'node:test';
import { deviceRevocationFor } from '../src/device-revocation.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';

const CORRELATION_ID = '11111111-2222-4333-8444-555555555555';
const FAMILY_ID = 'aaaaaaaa-1111-4111-8111-111111111111';
const CHILD_ID = 'bbbbbbbb-2222-4222-8222-222222222222';
const DEVICE_ID = 'cccccccc-3333-4333-8333-333333333333';

/**
 * A pool that answers queries by shape and remembers every one of them.
 *
 * `replay` stands in for an idempotency record already holding a response, which is
 * how a retried request looks to the real store.
 */
function recordingPool({ membership, device, updatedDevice, replay = null } = {}) {
  const transcript = [];

  const answer = (sql) => {
    if (sql.startsWith('BEGIN') || sql.startsWith('COMMIT') || sql.startsWith('ROLLBACK')) return { rows: [], rowCount: 0 };
    if (sql.startsWith('SELECT pg_advisory_xact_lock')) return { rows: [], rowCount: 0 };
    if (sql.includes('FROM idempotency_records')) {
      return replay === null
        ? { rows: [], rowCount: 0 }
        : { rows: [replay], rowCount: 1 };
    }
    if (sql.startsWith('INSERT INTO idempotency_records')) return { rows: [], rowCount: 1 };
    if (sql.includes('UPDATE idempotency_records')) return { rows: [], rowCount: 1 };
    if (sql.includes('FROM family_memberships AS membership')) {
      return membership === null
        ? { rows: [], rowCount: 0 }
        : { rows: [membership], rowCount: 1 };
    }
    if (sql.includes('FROM family_child_devices')) {
      return device === null ? { rows: [], rowCount: 0 } : { rows: [device], rowCount: 1 };
    }
    if (sql.includes('UPDATE family_child_devices')) {
      return updatedDevice === null
        ? { rows: [], rowCount: 0 }
        : { rows: [updatedDevice], rowCount: 1 };
    }
    return { rows: [], rowCount: 1 };
  };

  const client = {
    async query(sql, params) {
      transcript.push({ sql, params });
      return answer(sql);
    },
    release() {},
  };

  return {
    transcript,
    async connect() {
      return client;
    },
    async query(sql, params) {
      transcript.push({ sql, params });
      return answer(sql);
    },
    async end() {},
  };
}

function storeWith(pool) {
  return new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool,
  });
}

const PAIRED_DEVICE = {
  id: DEVICE_ID,
  family_id: FAMILY_ID,
  child_id: CHILD_ID,
  device_label: 'Amani Android',
  credential_hash: 'a'.repeat(64),
  credential_revoked_at: null,
  last_seen_at: '2026-10-06T11:00:00.000Z',
  location_lat: 15.35,
  location_lng: 44.2,
  location_label: 'GPS 15.35, 44.2',
  linked_at: '2026-10-01T00:00:00.000Z',
  version: 1,
};

const REVOKED_DEVICE = { ...PAIRED_DEVICE, credential_revoked_at: '2026-10-06T12:00:00.000Z', version: 2 };

function sqlOf(transcript, needle) {
  return transcript.filter((entry) => entry.sql.includes(needle));
}

async function revoke({ pool, reasonCode = null, requestHash = 'hash-1' }) {
  const operation = deviceRevocationFor(storeWith(pool));
  return operation({
    principal: { subject: 'test-primary' },
    familyId: FAMILY_ID,
    childId: CHILD_ID,
    deviceId: DEVICE_ID,
    reasonCode,
    idempotencyKey: 'revoke-1',
    requestHash,
    correlationId: CORRELATION_ID,
  });
}

test('a successful revocation runs inside exactly one transaction', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
  });

  await revoke({ pool, reasonCode: 'stolen' });

  const control = pool.transcript
    .map((entry) => entry.sql)
    .filter((sql) => ['BEGIN', 'COMMIT', 'ROLLBACK'].includes(sql));
  // One transaction. The revocation, its audit record, its outbox event, its fact
  // and its idempotency slot either all commit or none of them do.
  assert.deepEqual(control, ['BEGIN', 'COMMIT']);
});

test('the guard against a second revocation lives in the statement, not before it', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
  });

  await revoke({ pool });

  const [update] = sqlOf(pool.transcript, 'UPDATE family_child_devices');
  assert.ok(update, 'the device row must be updated');
  // Both conditions are part of the WHERE clause. A read-then-write would let two
  // simultaneous revocations each pass their own check and both succeed.
  assert.match(update.sql, /credential_revoked_at IS NULL/);
  assert.match(update.sql, /credential_hash IS NOT NULL/);
  // The database's clock, not this process's. A server that invented the timestamp
  // could record a revocation before the telemetry it is meant to stop.
  assert.match(update.sql, /credential_revoked_at = NOW\(\)/);
  // Provenance travels with the revocation, which is what migration 101 requires.
  assert.match(update.sql, /revoked_by_membership_id = \$2/);
  assert.match(update.sql, /revocation_reason = \$3/);
  assert.equal(update.params[1], 'membership-primary');
});

test('the reason is optional and is stored as null rather than as an empty string', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
  });

  await revoke({ pool, reasonCode: null });

  const [update] = sqlOf(pool.transcript, 'UPDATE family_child_devices');
  assert.equal(update.params[2], null);
});

test('authorization is decided by the database, and the SQL asks only for a primary guardian', async () => {
  // A co-guardian is refused because the query returns no membership for them: the
  // role filter is part of the SQL, so the refusal comes from the same lookup that
  // resolves the actor rather than from a check this process performs afterwards.
  const pool = recordingPool({
    membership: null,
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
  });

  await assert.rejects(
    () => revoke({ pool }),
    (error) => error.status === 403 && error.code === 'family_access_denied',
  );

  const [membershipQuery] = sqlOf(pool.transcript, 'FROM family_memberships AS membership');
  assert.match(membershipQuery.sql, /membership\.role = 'primary_guardian'/);
  assert.equal(sqlOf(pool.transcript, 'UPDATE family_child_devices').length, 0);
});

test('nothing is written when the device is already revoked', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: { ...PAIRED_DEVICE, credential_revoked_at: '2026-10-05T08:00:00.000Z' },
    updatedDevice: REVOKED_DEVICE,
  });

  await assert.rejects(
    () => revoke({ pool }),
    (error) => error.status === 409 && error.code === 'device_already_revoked',
  );

  assert.equal(sqlOf(pool.transcript, 'UPDATE family_child_devices').length, 0);
  assert.equal(sqlOf(pool.transcript, 'INSERT INTO family_audit_events').length, 0);
  assert.equal(sqlOf(pool.transcript, 'INSERT INTO ai_events').length, 0);
  assert.deepEqual(
    pool.transcript.map((entry) => entry.sql).filter((sql) => sql === 'COMMIT'),
    [],
    'a refused revocation must not commit',
  );
});

test('losing the race to another revocation is a conflict, never a silent overwrite', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    // The row was still un-revoked when it was read, and the guarded update matched
    // nothing: another request revoked it in between. The first record stands.
    updatedDevice: null,
  });

  await assert.rejects(
    () => revoke({ pool }),
    (error) => error.status === 409 && error.code === 'device_already_revoked',
  );

  assert.equal(sqlOf(pool.transcript, 'INSERT INTO ai_events').length, 0);
});

test('a device no handset claimed is refused instead of being marked revoked', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: { ...PAIRED_DEVICE, credential_hash: null },
    updatedDevice: REVOKED_DEVICE,
  });

  await assert.rejects(
    () => revoke({ pool }),
    (error) => error.status === 409 && error.code === 'device_not_claimed',
  );

  assert.equal(sqlOf(pool.transcript, 'UPDATE family_child_devices').length, 0);
});

test('a device from another family is not found, and the lookup is scoped to say so', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: null,
    updatedDevice: null,
  });

  await assert.rejects(
    () => revoke({ pool }),
    (error) => error.status === 404 && error.code === 'device_not_found',
  );

  const [read] = sqlOf(pool.transcript, 'FROM family_child_devices');
  assert.match(read.sql, /family_id = \$1 AND child_id = \$2 AND id = \$3/);
  assert.deepEqual(read.params, [FAMILY_ID, CHILD_ID, DEVICE_ID]);
});

test('the audit record, the outbox event and the fact are all written for a revocation', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
  });

  await revoke({ pool });

  const [audit] = sqlOf(pool.transcript, 'INSERT INTO family_audit_events');
  assert.ok(audit.params.includes('family.child_device_revoked'), 'the audit event type is named');
  assert.ok(audit.params.includes(DEVICE_ID), 'the audit record names the device as its subject');
  assert.ok(audit.params.includes(CORRELATION_ID), 'the audit record carries the request trace');
  const [outbox] = sqlOf(pool.transcript, 'INSERT INTO outbox_events');
  assert.ok(outbox.params.includes('family.child_device_revoked'), 'the outbox carries the same event type');

  const [fact] = sqlOf(pool.transcript, 'INSERT INTO ai_events');
  assert.ok(fact.params.includes('device.revoked'), 'the recorded fact is the registered type');
  assert.ok(fact.params.includes(DEVICE_ID), 'the fact names the device');
  assert.ok(fact.params.includes(CHILD_ID), 'the fact names the child');
});

test('a retry replays the stored answer without touching the device again', async () => {
  const storedResponse = { device: { id: DEVICE_ID, health: { state: 'revoked' } } };
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
    replay: { request_hash: 'hash-1', response_body: storedResponse },
  });

  const result = await revoke({ pool, requestHash: 'hash-1' });

  assert.deepEqual(result, storedResponse);
  assert.equal(sqlOf(pool.transcript, 'UPDATE family_child_devices').length, 0);
  assert.equal(sqlOf(pool.transcript, 'INSERT INTO family_audit_events').length, 0);
  assert.equal(sqlOf(pool.transcript, 'UPDATE idempotency_records').length, 0);
});

test('reusing a key for a different request is refused rather than replayed', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
    replay: { request_hash: 'hash-1', response_body: { device: {} } },
  });

  await assert.rejects(
    () => revoke({ pool, requestHash: 'a-different-hash' }),
    (error) => error.status === 409 && error.code === 'idempotency_key_reused',
  );

  assert.equal(sqlOf(pool.transcript, 'UPDATE family_child_devices').length, 0);
});

test('a request still in progress is not answered with an empty success', async () => {
  const pool = recordingPool({
    membership: { id: 'membership-primary', role: 'primary_guardian' },
    device: PAIRED_DEVICE,
    updatedDevice: REVOKED_DEVICE,
    replay: { request_hash: 'hash-1', response_body: null },
  });

  await assert.rejects(
    () => revoke({ pool, requestHash: 'hash-1' }),
    (error) => error.status === 409 && error.code === 'request_in_progress',
  );
});
