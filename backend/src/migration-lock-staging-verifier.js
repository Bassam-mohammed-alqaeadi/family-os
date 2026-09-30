import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import pg from 'pg';
import { FOUNDATION_SCHEMA_MIGRATIONS } from './schema-manifest.js';
import { MIGRATION_LOCK_NAME } from './migration-runner.js';

const { Client } = pg;
const backendDirectory = join(dirname(fileURLToPath(import.meta.url)), '..');

function requiredConnectionString(value) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('A database connection string is required.');
  }
  return value.trim();
}

function runMigrationProcess(connectionString) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, ['src/migrate.js'], {
      cwd: backendDirectory,
      env: { ...process.env, DATABASE_URL: connectionString },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let output = '';
    child.stdout.on('data', (chunk) => { output += chunk; });
    child.stderr.on('data', (chunk) => { output += chunk; });
    child.once('error', reject);
    child.once('close', (exitCode) => resolve({ exitCode, output }));
  });
}

export async function verifyMigrationLockStaging({
  connectionString,
  clientFactory = (options) => new Client(options),
  runMigration = runMigrationProcess,
}) {
  const verifiedConnectionString = requiredConnectionString(connectionString);
  const client = clientFactory({ connectionString: verifiedConnectionString });
  let locked = false;

  try {
    await client.connect();
    await client.query('SELECT pg_advisory_lock(hashtext($1))', [MIGRATION_LOCK_NAME]);
    locked = true;

    const history = await client.query('SELECT name, checksum FROM schema_migrations ORDER BY name ASC');
    const expected = FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => ({
      name: migration.name,
      checksum: migration.sha256,
    }));
    if (JSON.stringify(history.rows) !== JSON.stringify(expected)) {
      throw new Error('Recorded migration history does not exactly match the reviewed manifest.');
    }

    const blockedRun = await runMigration(verifiedConnectionString);
    if (blockedRun.exitCode === 0 || !blockedRun.output.includes('Another migration process is already active for this database.')) {
      throw new Error('A concurrent migration run was not rejected by the advisory lock.');
    }

    return {
      checks: [
        'manifest_attested_migration_history_present',
        'migration_advisory_lock_acquired',
        'concurrent_migration_rejected_before_schema_work',
      ],
      migrationCount: expected.length,
    };
  } finally {
    if (locked) {
      await client.query('SELECT pg_advisory_unlock(hashtext($1))', [MIGRATION_LOCK_NAME]);
    }
    await client.end();
  }
}
