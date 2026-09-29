import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { loadConfig } from './config.js';
import { applyMigrations } from './migration-runner.js';
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
  await applyMigrations({
    client,
    migrations: FOUNDATION_SCHEMA_MIGRATIONS,
    readVerifiedMigration,
    log: (event) => console.log(JSON.stringify(event)),
  });
} finally {
  await client.end();
}
