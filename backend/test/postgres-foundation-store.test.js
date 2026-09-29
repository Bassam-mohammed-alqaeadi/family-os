import assert from 'node:assert/strict';
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
