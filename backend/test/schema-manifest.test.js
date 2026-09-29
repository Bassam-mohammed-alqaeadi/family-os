import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';

const migrationDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'db', 'migrations');

test('schema manifest lists every migration in deterministic order', async () => {
  const filesystemMigrations = (await readdir(migrationDirectory))
    .filter((file) => file.endsWith('.sql'))
    .sort();
  assert.deepEqual(
    FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name),
    filesystemMigrations,
  );
});

test('schema manifest SHA-256 values match immutable migration contents', async () => {
  for (const migration of FOUNDATION_SCHEMA_MIGRATIONS) {
    const sql = await readFile(join(migrationDirectory, migration.name), 'utf8');
    const checksum = createHash('sha256').update(sql).digest('hex');
    assert.equal(checksum, migration.sha256, migration.name);
  }
});
