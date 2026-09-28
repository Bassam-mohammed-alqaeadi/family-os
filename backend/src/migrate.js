import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { loadConfig } from './config.js';

const { Client } = pg;
const config = loadConfig();
if (!config.databaseUrl) {
  throw new Error('DATABASE_URL is required to run migrations.');
}

const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');
const migrations = (await readdir(migrationDirectory)).filter((file) => file.endsWith('.sql')).sort();
const client = new Client({ connectionString: config.databaseUrl });

try {
  await client.connect();
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  for (const migration of migrations) {
    const known = await client.query('SELECT 1 FROM schema_migrations WHERE name = $1', [migration]);
    if (known.rowCount > 0) {
      continue;
    }

    const sql = await readFile(join(migrationDirectory, migration), 'utf8');
    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [migration]);
      await client.query('COMMIT');
      console.log(JSON.stringify({ severity: 'info', event: 'migration_applied', migration }));
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  }
} finally {
  await client.end();
}
