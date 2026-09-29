export const MIGRATION_LOCK_NAME = 'family-os-schema-migrations-v1';

export class MigrationIntegrityError extends Error {
  constructor(message) {
    super(message);
    this.name = 'MigrationIntegrityError';
  }
}

async function acquireMigrationLock(client) {
  const result = await client.query(
    'SELECT pg_try_advisory_lock(hashtext($1)) AS acquired',
    [MIGRATION_LOCK_NAME],
  );
  if (!result.rows[0]?.acquired) {
    throw new MigrationIntegrityError('Another migration process is already active for this database.');
  }
}

async function releaseMigrationLock(client) {
  await client.query('SELECT pg_advisory_unlock(hashtext($1))', [MIGRATION_LOCK_NAME]);
}

async function ensureMigrationTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY,
      checksum TEXT NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  // Existing pre-checksum schemas are intentionally not auto-adopted: recorded history must be provable.
  await client.query('ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS checksum TEXT');
}

export async function applyMigrations({ client, migrations, readVerifiedMigration, log = () => {} }) {
  let lockAcquired = false;
  try {
    await acquireMigrationLock(client);
    lockAcquired = true;
    await ensureMigrationTable(client);

    for (const migration of migrations) {
      const sql = await readVerifiedMigration(migration);
      const known = await client.query(
        'SELECT checksum FROM schema_migrations WHERE name = $1',
        [migration.name],
      );
      if (known.rowCount > 0) {
        if (known.rows[0].checksum !== migration.sha256) {
          throw new MigrationIntegrityError(
            `Recorded checksum mismatch for ${migration.name}; do not modify applied migrations.`,
          );
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
        log({ severity: 'info', event: 'migration_applied', migration: migration.name });
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    }
  } finally {
    if (lockAcquired) {
      await releaseMigrationLock(client);
    }
  }
}
