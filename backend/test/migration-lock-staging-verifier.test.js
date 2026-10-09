import assert from 'node:assert/strict';
import test from 'node:test';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { MIGRATION_LOCK_NAME } from '../src/migration-runner.js';
import { verifyMigrationLockStaging } from '../src/migration-lock-staging-verifier.js';

function expectedHistory() {
  return FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => ({ name: migration.name, checksum: migration.sha256 }));
}

test('migration-lock verifier validates recorded history and rejects a concurrent runner before schema work', async () => {
  const statements = [];
  let ended = false;
  const client = {
    async connect() {},
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql === 'SELECT name, checksum FROM schema_migrations ORDER BY name ASC') {
        return { rows: expectedHistory() };
      }
      return { rows: [] };
    },
    async end() { ended = true; },
  };
  let receivedConnectionString;
  const result = await verifyMigrationLockStaging({
    connectionString: 'postgresql://unused-in-test',
    clientFactory: () => client,
    runMigration: async (connectionString) => {
      receivedConnectionString = connectionString;
      return {
        exitCode: 1,
        output: 'MigrationIntegrityError: Another migration process is already active for this database.',
      };
    },
  });

  assert.deepEqual(result, {
    checks: [
      'manifest_attested_migration_history_present',
      'migration_advisory_lock_acquired',
      'concurrent_migration_rejected_before_schema_work',
    ],
    migrationCount: FOUNDATION_SCHEMA_MIGRATIONS.length,
  });
  assert.equal(receivedConnectionString, 'postgresql://unused-in-test');
  assert.deepEqual(statements[0], {
    sql: 'SELECT pg_advisory_lock(hashtext($1))',
    values: [MIGRATION_LOCK_NAME],
  });
  assert.deepEqual(statements.at(-1), {
    sql: 'SELECT pg_advisory_unlock(hashtext($1))',
    values: [MIGRATION_LOCK_NAME],
  });
  assert.equal(ended, true);
});

test('migration-lock verifier fails closed when a concurrent runner unexpectedly succeeds', async () => {
  const statements = [];
  const client = {
    async connect() {},
    async query(sql, values) {
      statements.push({ sql, values });
      if (sql === 'SELECT name, checksum FROM schema_migrations ORDER BY name ASC') {
        return { rows: expectedHistory() };
      }
      return { rows: [] };
    },
    async end() {},
  };

  await assert.rejects(
    verifyMigrationLockStaging({
      connectionString: 'postgresql://unused-in-test',
      clientFactory: () => client,
      runMigration: async () => ({ exitCode: 0, output: '' }),
    }),
    /concurrent migration run was not rejected/,
  );
  assert.equal(statements.at(-1).sql, 'SELECT pg_advisory_unlock(hashtext($1))');
});
