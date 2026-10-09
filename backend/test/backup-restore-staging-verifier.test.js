import assert from 'node:assert/strict';
import test from 'node:test';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../src/schema-manifest.js';
import { verifyBackupRestoreStaging } from '../src/backup-restore-staging-verifier.js';

function historyOutput() {
  return `${FOUNDATION_SCHEMA_MIGRATIONS
    .map((migration) => `${migration.name}\t${migration.sha256}`)
    .join('\n')}\n`;
}

function invariantOutput({ primaryViolation = 0 } = {}) {
  return [
    'completed_guardian_transfer_matches_primary\t0',
    'correlated_audit_outbox_one_to_one\t0',
    `family_primary_reference_valid\t${primaryViolation}`,
    'one_active_primary_per_family\t0',
  ].join('\n');
}

test('backup/restore verifier attests migration history and restored authorization invariants', async () => {
  const commands = [];
  const result = await verifyBackupRestoreStaging({
    containerName: 'family-os-restore-20261001',
    runCommand: async (args) => {
      commands.push(args);
      return {
        exitCode: 0,
        stdout: commands.length === 1 ? historyOutput() : invariantOutput(),
        stderr: '',
      };
    },
  });

  assert.deepEqual(result, {
    checks: [
      'manifest_attested_migration_history_restored',
      'primary_guardian_continuity_invariants_restored',
      'correlated_audit_outbox_invariant_restored',
    ],
    migrationCount: FOUNDATION_SCHEMA_MIGRATIONS.length,
  });
  assert.equal(commands.length, 2);
  assert.deepEqual(commands[0].slice(0, 2), ['exec', 'family-os-restore-20261001']);
  assert.equal(commands[0].includes('--dbname=family_os_restore'), true);
  assert.match(commands[0].at(-1), /schema_migrations/);
  assert.match(commands[1].at(-1), /guardian_continuity_cases/);
});

test('backup/restore verifier fails closed on manifest mismatch', async () => {
  await assert.rejects(
    verifyBackupRestoreStaging({
      containerName: 'family-os-restore-20261001',
      runCommand: async () => ({
        exitCode: 0,
        stdout: '001_foundation.sql\tnot-the-reviewed-checksum\n',
        stderr: '',
      }),
    }),
    /migration history does not exactly match/,
  );
});

test('backup/restore verifier fails closed when a restored authorization invariant has violations', async () => {
  let calls = 0;
  await assert.rejects(
    verifyBackupRestoreStaging({
      containerName: 'family-os-restore-20261001',
      runCommand: async () => {
        calls += 1;
        return {
          exitCode: 0,
          stdout: calls === 1 ? historyOutput() : invariantOutput({ primaryViolation: 1 }),
          stderr: '',
        };
      },
    }),
    /authorization invariants were not preserved/,
  );
});

test('backup/restore verifier rejects unsafe Docker container names before executing commands', async () => {
  let called = false;
  await assert.rejects(
    verifyBackupRestoreStaging({
      containerName: 'family-os-restore; echo unexpected',
      runCommand: async () => {
        called = true;
        return { exitCode: 0, stdout: '', stderr: '' };
      },
    }),
    /valid local restore Docker container name/,
  );
  assert.equal(called, false);
});
