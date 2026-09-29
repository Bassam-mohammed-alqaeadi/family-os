import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { loadConfig } from './config.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from './schema-manifest.js';

const { Client } = pg;
const config = loadConfig();
if (!config.databaseUrl) {
  throw new Error('DATABASE_URL is required to run migrations.');
}

const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const filesystemMigrations = (await readdir(migrationDirectory)).filter((file) => file.endsWith('.sql')).sort();
const manifestMigrations = FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name);
if (JSON.stringify(filesystemMigrations) !== JSON.stringify(manifestMigrations)) {
  throw new Error('Migration manifest does not exactly match the migration directory.');
}

async function readVerifiedMigration(migration) {
  const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
  const checksum = createHash('sha256').update(sql).digest('hex');
  if (checksum !== migration.sha256) {
    throw new Error(`Migration checksum mismatch for ${migration.name}. Applied migrations are immutable.`);
  }
  return sql;
}

const client = new Client({ connectionString: config.databaseUrl });

try {
  await client.connect();
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY,
      checksum TEXT NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await client.query('ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS checksum TEXT');

  for (const migration of FOUNDATION_SCHEMA_MIGRATIONS) {
    const sql = await readVerifiedMigration(migration);
    const known = await client.query(
      'SELECT checksum FROM schema_migrations WHERE name = $1',
      [migration.name],
    );
    if (known.rowCount > 0) {
      if (known.rows[0].checksum !== migration.sha256) {
        throw new Error(`Recorded checksum mismatch for ${migration.name}; do not modify applied migrations.`);
      }
      continue;
    }

    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query(
        'INSERT INTO schema_migrations (name, checksum) VALUES ($1, $2)',
        [migration.name, migration.sha256],
      );
      await client.query('COMMIT');
      console.log(JSON.stringify({ severity: 'info', event: 'migration_applied', migration: migration.name }));
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  }
} finally {
  await client.end();
}
