import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import test from 'node:test';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { PostgresFoundationStore } from '../src/store/postgres-foundation-store.js';

function healthStore(query) {
  return new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: {
      query,
      async end() {},
    },
  });
}

test('PostgreSQL readiness requires every Foundation migration', async () => {
  const store = healthStore(async (sql) => {
    if (sql === 'SELECT 1') {
      return { rows: [{ '?column?': 1 }] };
    }
    return { rows: [{ name: '001_foundation.sql' }] };
  });

  assert.deepEqual(await store.health(), {
    available: false,
    reason: 'database_schema_not_ready',
  });
});

test('PostgreSQL readiness is available only with the complete expected migration set', async () => {
  const store = healthStore(async (sql) => {
    if (sql === 'SELECT 1') {
      return { rows: [{ '?column?': 1 }] };
    }
    return {
      rows: FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => ({
        name: migration.name,
        checksum: migration.sha256,
      })),
    };
  });

  assert.deepEqual(await store.health(), { available: true });
});

test('recorded migration checksum mismatch fails readiness', async () => {
  const store = healthStore(async (sql) => {
    if (sql === 'SELECT 1') {
      return { rows: [{ '?column?': 1 }] };
    }
    return {
      rows: FOUNDATION_SCHEMA_MIGRATIONS.map((migration, index) => ({
        name: migration.name,
        checksum: index === 0 ? '0'.repeat(64) : migration.sha256,
      })),
    };
  });

  assert.deepEqual(await store.health(), {
    available: false,
    reason: 'database_schema_not_ready',
  });
});

test('missing schema metadata fails readiness without pretending the database is available', async () => {
  const store = healthStore(async (sql) => {
    if (sql === 'SELECT 1') {
      return { rows: [{ '?column?': 1 }] };
    }
    const error = new Error('relation schema_migrations does not exist');
    error.code = '42P01';
    throw error;
  });

  assert.deepEqual(await store.health(), {
    available: false,
    reason: 'database_schema_not_ready',
  });
});

test('PostgreSQL family discovery derives a bounded minimal view from the verified subject without writes', async () => {
  const statements = [];
  const store = healthStore(async (sql, values) => {
    statements.push({ sql, values });
    return {
      rows: [{
        id: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
        display_name: 'Synthetic family',
        role: 'primary_guardian',
      }],
    };
  });

  const result = await store.listMyFamilies({ principal: { subject: 'verified-subject-only' } });

  assert.deepEqual(result, {
    families: [{
      id: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
      displayName: 'Synthetic family',
      role: 'primary_guardian',
    }],
  });
  assert.equal(statements.length, 1);
  assert.match(statements[0].sql, /FROM accounts AS account/);
  assert.match(statements[0].sql, /membership\.status = 'active'/);
  assert.match(statements[0].sql, /family\.status = 'active'/);
  assert.equal(/INSERT|UPDATE|DELETE/i.test(statements[0].sql), false);
  assert.deepEqual(statements[0].values, ['verified-subject-only', 21]);
});

test('PostgreSQL family discovery fails closed rather than returning a partial over-limit result', async () => {
  const store = healthStore(async () => ({
    rows: Array.from({ length: 21 }, (_, index) => ({
      id: `family-${index}`,
      display_name: `Family ${index}`,
      role: 'primary_guardian',
    })),
  }));

  await assert.rejects(
    store.listMyFamilies({ principal: { subject: 'verified-subject-only' } }),
    { status: 409, code: 'family_discovery_limit_exceeded' },
  );
});

test('concurrent PostgreSQL membership uniqueness conflicts become an explicit lifecycle conflict', async () => {
  const client = {
    async query(sql) {
      if (sql === 'BEGIN' || sql === 'ROLLBACK') {
        return { rows: [], rowCount: 0 };
      }
      if (sql.startsWith('SELECT pg_advisory_xact_lock')) {
        return { rows: [], rowCount: 1 };
      }
      if (sql.includes('FROM idempotency_records')) {
        return { rows: [], rowCount: 0 };
      }
      if (sql.includes('INSERT INTO idempotency_records')) {
        return { rows: [], rowCount: 1 };
      }
      if (sql.includes('FROM family_memberships AS membership')) {
        return { rows: [{ id: 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b', role: 'primary_guardian' }], rowCount: 1 };
      }
      if (sql.includes('WHERE family_id = $1 AND target_subject')) {
        return { rows: [], rowCount: 0 };
      }
      if (sql.includes('INSERT INTO family_memberships')) {
        const error = new Error('duplicate active or pending membership');
        error.code = '23505';
        throw error;
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  await assert.rejects(
    store.createMembershipInvitation({
      principal: { subject: 'guardian-a' },
      familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
      role: 'child',
      targetSubject: 'child-c',
      idempotencyKey: 'concurrent-membership-test',
      requestHash: 'a'.repeat(64),
      correlationId: '1f7f43e1-ea4f-4d8a-9a0a-8dc1d6421fe1',
    }),
    { status: 409, code: 'membership_already_exists' },
  );
});

test('PostgreSQL audit and outbox inserts share only the supplied server correlation ID', async () => {
  const store = healthStore(async () => ({ rows: [] }));
  const statements = [];
  const client = {
    async query(sql, values) {
      statements.push({ sql, values });
      return { rows: [] };
    },
  };
  const correlationId = '1f7f43e1-ea4f-4d8a-9a0a-8dc1d6421fe1';

  await store.appendAuditAndOutbox(client, {
    familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
    actorMembershipId: 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b',
    correlationId,
    eventType: 'family.created',
    subjectType: 'family',
    subjectId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
  });

  assert.equal(statements.length, 2);
  assert.match(statements[0].sql, /family_audit_events[\s\S]*correlation_id/);
  assert.match(statements[1].sql, /outbox_events[\s\S]*correlation_id/);
  assert.equal(statements[0].values[3], correlationId);
  assert.equal(statements[1].values[2], correlationId);
  assert.equal(JSON.parse(statements[1].values[4]).auditEventId, statements[0].values[0]);
});

test('PostgreSQL evidence writes fail closed when internal correlation context is absent', async () => {
  const store = healthStore(async () => ({ rows: [] }));
  const client = { async query() { throw new Error('query should not execute'); } };

  await assert.rejects(
    store.appendAuditAndOutbox(client, {
      familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
      actorMembershipId: 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b',
      eventType: 'family.created',
      subjectType: 'family',
      subjectId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
    }),
    { code: 'correlation_context_missing', status: 500 },
  );
});

test('PostgreSQL children roster read is guardian-scoped and performs no evidence writes', async () => {
  const statements = [];
  const client = {
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [], rowCount: 0 };
      }
      if (sql.includes('FROM family_memberships AS membership')) {
        return {
          rows: [{ id: 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b', role: 'co_guardian' }],
          rowCount: 1,
        };
      }
      if (sql.includes('FROM family_children')) {
        return {
          rows: [{
            id: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
            display_name: 'Amani',
            age_years: 0,
            avatar_emoji: '🦁',
            theme_color: 'purple',
            version: 1,
            created_at: '2026-10-02T00:00:00.000Z',
            updated_at: '2026-10-02T00:00:00.000Z',
          }],
          rowCount: 1,
        };
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  const result = await store.listFamilyChildren({
    principal: { subject: 'guardian-b' },
    familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
  });

  assert.deepEqual(result.children, [{
    id: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
    displayName: 'Amani',
    ageYears: 0,
    avatarEmoji: '🦁',
    themeColor: 'purple',
    version: 1,
    createdAt: '2026-10-02T00:00:00.000Z',
    updatedAt: '2026-10-02T00:00:00.000Z',
  }]);
  const childRead = statements.find((statement) => statement.sql.includes('FROM family_children'));
  assert.deepEqual(childRead.values, ['6dbb6760-f609-4f3e-a29f-4c209dc1d53b']);
  assert.equal(statements.some((statement) => /^\s*(?:INSERT|UPDATE|DELETE)\b/i.test(statement.sql)), false);
});

test('PostgreSQL child context is tenant-bound, fresh, narrow and read-only', async () => {
  const statements = [];
  const client = {
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [], rowCount: 0 };
      }
      if (sql.includes('FROM family_memberships AS membership')) {
        return {
          rows: [{
            id: 'b7fe4b27-2df2-4cf7-8071-9792b4ef665b',
            role: 'primary_guardian',
            version: 7,
          }],
          rowCount: 1,
        };
      }
      if (sql.includes('FROM family_children AS child')) {
        return {
          rows: [{
            id: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
            display_name: 'Amani',
            age_years: 8,
            avatar_emoji: '🦁',
            theme_color: 'purple',
            version: 2,
            created_at: '2026-10-02T00:00:00.000Z',
            updated_at: '2026-10-06T00:00:00.000Z',
            device_count: 1,
            latest_device_seen_at: '2026-10-07T08:00:00.000Z',
            observed_at: new Date('2026-10-07T09:00:00.000Z'),
            permissions_expires_at: new Date('2026-10-07T09:05:00.000Z'),
          }],
          rowCount: 1,
        };
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  const result = await store.getFamilyChildContext({
    principal: { subject: 'guardian-a' },
    familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
    childId: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
  });

  assert.deepEqual(result.setup, {
    deviceState: 'linked',
    deviceCount: 1,
    observedAt: '2026-10-07T09:00:00.000Z',
  });
  assert.deepEqual(result.permissionSnapshot, {
    policyVersion: 7,
    role: 'primary_guardian',
    scopes: ['child.context.read', 'child.device_pairing.create'],
    observedAt: '2026-10-07T09:00:00.000Z',
    expiresAt: '2026-10-07T09:05:00.000Z',
  });
  assert.deepEqual(Object.keys(result.child).sort(), [
    'ageYears', 'avatarEmoji', 'createdAt', 'displayName', 'id',
    'themeColor', 'updatedAt', 'version',
  ]);
  const contextRead = statements.find((statement) => statement.sql.includes('FROM family_children AS child'));
  assert.deepEqual(contextRead.values, [
    '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
    '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
  ]);
  assert.match(contextRead.sql, /WHERE child\.family_id = \$1 AND child\.id = \$2/);
  assert.match(contextRead.sql, /SELECT COUNT\(\*\)::integer/);
  assert.equal(/LEFT JOIN|GROUP BY/i.test(contextRead.sql), false);
  assert.equal(/battery_level|location_|policy/i.test(contextRead.sql), false);
  assert.equal(statements.some((statement) => /^\s*(?:INSERT|UPDATE|DELETE)\b/i.test(statement.sql)), false);
});

test('PostgreSQL context returns a newly-created child even when no optional device row exists', async () => {
  const client = {
    async query(sql) {
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [] };
      }
      if (sql.includes('FROM family_memberships AS membership')) {
        return {
          rows: [{ id: 'member', role: 'primary_guardian', version: 1 }],
        };
      }
      if (sql.includes('FROM family_children AS child')) {
        return {
          // Deliberately omit rowCount: child existence is a property of the
          // returned rows, not optional driver command metadata.
          rows: [{
            id: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
            display_name: 'New child',
            age_years: 7,
            avatar_emoji: '🦁',
            theme_color: 'purple',
            version: 1,
            created_at: '2026-10-07T09:00:00.000Z',
            updated_at: '2026-10-07T09:00:00.000Z',
            device_count: 0,
            latest_device_seen_at: null,
            observed_at: new Date('2026-10-07T09:01:00.000Z'),
            permissions_expires_at: new Date('2026-10-07T09:06:00.000Z'),
          }],
        };
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  const result = await store.getFamilyChildContext({
    principal: { subject: 'guardian-a' },
    familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
    childId: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
  });

  assert.equal(result.child.displayName, 'New child');
  assert.deepEqual(result.setup, {
    deviceState: 'not_linked',
    deviceCount: 0,
    observedAt: '2026-10-07T09:01:00.000Z',
  });
});

test('PostgreSQL child context returns tenant-safe not-found when the scoped child query has no row', async () => {
  const client = {
    async query(sql) {
      if (sql === 'BEGIN' || sql === 'ROLLBACK') return { rows: [], rowCount: 0 };
      if (sql.includes('FROM family_memberships AS membership')) {
        return { rows: [{ id: 'member', role: 'co_guardian', version: 1 }], rowCount: 1 };
      }
      if (sql.includes('FROM family_children AS child')) return { rows: [], rowCount: 0 };
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  await assert.rejects(
    store.getFamilyChildContext({
      principal: { subject: 'guardian-b' },
      familyId: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
      childId: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
    }),
    { status: 404, code: 'family_child_not_found' },
  );
});

test('PostgreSQL device self-read verifies its capability and performs no evidence writes', async () => {
  const credential = 'c'.repeat(64);
  const statements = [];
  const client = {
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [], rowCount: 0 };
      }
      if (sql.includes('FROM family_child_devices')) {
        return {
          rows: [{
            id: '76331550-5bab-4bc4-9f56-d98c9d80ef25',
            child_id: '4a3846da-8f5f-4f2b-b7ea-8a0afcd989fb',
            device_label: 'Amani Android',
            battery_level: 62,
            battery_status: 'charging',
            location_lat: null,
            location_lng: null,
            location_label: null,
            last_seen_at: '2026-10-06T12:00:00.000Z',
            linked_at: '2026-10-06T11:00:00.000Z',
            version: 2,
            credential_hash: createHash('sha256').update(credential).digest('hex'),
            credential_revoked_at: null,
          }],
          rowCount: 1,
        };
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
    release() {},
  };
  const store = new PostgresFoundationStore({
    connectionString: 'postgresql://unused-in-test',
    pool: { async connect() { return client; }, async end() {} },
  });

  const result = await store.getDeviceForCapability({
    deviceCredential: credential,
    deviceId: '76331550-5bab-4bc4-9f56-d98c9d80ef25',
  });

  assert.deepEqual(Object.keys(result.device).sort(), [
    'batteryLevel',
    'batteryStatus',
    'deviceLabel',
    'id',
    'lastSeenAt',
  ]);
  assert.equal(result.device.deviceLabel, 'Amani Android');
  assert.equal(result.device.batteryLevel, 62);
  assert.equal(result.device.lastSeenAt, '2026-10-06T12:00:00.000Z');
  assert.equal(
    statements.some((statement) => /^\s*(?:INSERT|UPDATE|DELETE)\b/i.test(statement.sql)),
    false,
  );
});
