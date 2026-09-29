import assert from 'node:assert/strict';
import test from 'node:test';
import {
  applyMigrations,
  MIGRATION_LOCK_NAME,
  MigrationIntegrityError,
} from '../src/migration-runner.js';

const migration = Object.freeze({
  name: '999_test.sql',
  sha256: 'a'.repeat(64),
});

function createClient({ lockAcquired = true, existingChecksums = new Map(), failSql = undefined } = {}) {
  const queries = [];
  const checksums = new Map(existingChecksums);
  return {
    queries,
    checksums,
    async query(sql, values = []) {
      queries.push({ sql: sql.trim(), values });
      if (sql.includes('pg_try_advisory_lock')) {
        assert.deepEqual(values, [MIGRATION_LOCK_NAME]);
        return { rows: [{ acquired: lockAcquired }], rowCount: 1 };
      }
      if (sql.includes('pg_advisory_unlock')) {
        assert.deepEqual(values, [MIGRATION_LOCK_NAME]);
        return { rows: [{ pg_advisory_unlock: true }], rowCount: 1 };
      }
      if (sql.startsWith('SELECT checksum FROM schema_migrations')) {
        const checksum = checksums.get(values[0]);
        return checksum === undefined
          ? { rows: [], rowCount: 0 }
          : { rows: [{ checksum }], rowCount: 1 };
      }
      if (sql === failSql) {
        throw new Error('simulated migration SQL failure');
      }
      if (sql.startsWith('INSERT INTO schema_migrations')) {
        checksums.set(values[0], values[1]);
      }
      return { rows: [], rowCount: 0 };
    },
  };
}

test('migration runner refuses concurrent migration execution before schema work begins', async () => {
  const client = createClient({ lockAcquired: false });
  await assert.rejects(
    applyMigrations({
      client,
      migrations: [migration],
      readVerifiedMigration: async () => 'SELECT 1',
    }),
    MigrationIntegrityError,
  );
  assert.equal(client.queries.length, 1);
  assert.match(client.queries[0].sql, /pg_try_advisory_lock/);
});

test('migration runner applies and records a verified migration under one exclusive lock', async () => {
  const client = createClient();
  const events = [];
  await applyMigrations({
    client,
    migrations: [migration],
    readVerifiedMigration: async () => 'CREATE TABLE test_table (id INTEGER)',
    log: (event) => events.push(event),
  });

  assert.equal(client.checksums.get(migration.name), migration.sha256);
  assert.deepEqual(events, [{ severity: 'info', event: 'migration_applied', migration: migration.name }]);
  assert.ok(client.queries.some((query) => query.sql === 'BEGIN'));
  assert.ok(client.queries.some((query) => query.sql === 'COMMIT'));
  assert.ok(client.queries.some((query) => query.sql.includes('pg_advisory_unlock')));
});

test('migration runner rejects an altered recorded history and still releases its lock', async () => {
  const client = createClient({ existingChecksums: new Map([[migration.name, 'b'.repeat(64)]]) });
  await assert.rejects(
    applyMigrations({
      client,
      migrations: [migration],
      readVerifiedMigration: async () => 'SELECT 1',
    }),
    MigrationIntegrityError,
  );

  assert.equal(client.queries.some((query) => query.sql === 'BEGIN'), false);
  assert.ok(client.queries.some((query) => query.sql.includes('pg_advisory_unlock')));
});

test('migration runner rolls back a failed migration and releases the exclusive lock', async () => {
  const client = createClient({ failSql: 'BROKEN SQL' });
  await assert.rejects(
    applyMigrations({
      client,
      migrations: [migration],
      readVerifiedMigration: async () => 'BROKEN SQL',
    }),
    /simulated migration SQL failure/,
  );

  assert.ok(client.queries.some((query) => query.sql === 'ROLLBACK'));
  assert.ok(client.queries.some((query) => query.sql.includes('pg_advisory_unlock')));
  assert.equal(client.checksums.has(migration.name), false);
});
