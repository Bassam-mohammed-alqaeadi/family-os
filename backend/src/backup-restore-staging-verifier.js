import { spawn } from 'node:child_process';
import { FOUNDATION_SCHEMA_MIGRATIONS } from './schema-manifest.js';

const CONTAINER_NAME = /^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}$/;
const RESTORE_DATABASE = 'family_os_restore';

const invariantQuery = `
  WITH invariant_counts AS (
    SELECT
      'family_primary_reference_valid' AS check_name,
      COUNT(*)::text AS violations
    FROM families AS family
    LEFT JOIN family_memberships AS membership
      ON membership.family_id = family.id
      AND membership.id = family.primary_membership_id
    WHERE membership.id IS NULL
      OR membership.role <> 'primary_guardian'
      OR membership.status <> 'active'

    UNION ALL

    SELECT
      'one_active_primary_per_family' AS check_name,
      COUNT(*)::text AS violations
    FROM families AS family
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS active_primary_count
      FROM family_memberships AS membership
      WHERE membership.family_id = family.id
        AND membership.role = 'primary_guardian'
        AND membership.status = 'active'
    ) AS primary_count ON TRUE
    WHERE primary_count.active_primary_count <> 1

    UNION ALL

    SELECT
      'completed_guardian_transfer_matches_primary' AS check_name,
      COUNT(*)::text AS violations
    FROM guardian_continuity_cases AS continuity_case
    JOIN families AS family ON family.id = continuity_case.family_id
    LEFT JOIN family_memberships AS candidate
      ON candidate.family_id = continuity_case.family_id
      AND candidate.id = continuity_case.candidate_membership_id
    WHERE continuity_case.status = 'completed'
      AND (
        family.primary_membership_id <> continuity_case.candidate_membership_id
        OR candidate.id IS NULL
        OR candidate.role <> 'primary_guardian'
        OR candidate.status <> 'active'
      )

    UNION ALL

    SELECT
      'correlated_audit_outbox_one_to_one' AS check_name,
      COUNT(*)::text AS violations
    FROM (
      SELECT correlation_id, COUNT(*) AS audit_count
      FROM family_audit_events
      WHERE correlation_id IS NOT NULL
      GROUP BY correlation_id
    ) AS audit
    FULL OUTER JOIN (
      SELECT correlation_id, COUNT(*) AS outbox_count
      FROM outbox_events
      WHERE correlation_id IS NOT NULL
      GROUP BY correlation_id
    ) AS outbox USING (correlation_id)
    WHERE COALESCE(audit.audit_count, 0) <> 1
      OR COALESCE(outbox.outbox_count, 0) <> 1
  )
  SELECT check_name || E'\\t' || violations
  FROM invariant_counts
  ORDER BY check_name ASC
`;

function requiredContainerName(value) {
  if (typeof value !== 'string' || !CONTAINER_NAME.test(value)) {
    throw new Error('A valid local restore Docker container name is required.');
  }
  return value;
}

function parseRows(output, expectedColumnCount) {
  const trimmed = output.trim();
  if (!trimmed) {
    return [];
  }

  return trimmed.split(/\r?\n/).map((line) => {
    const columns = line.split('\t');
    if (columns.length !== expectedColumnCount || columns.some((column) => !column)) {
      throw new Error('Local restore verifier received an unexpected database result.');
    }
    return columns;
  });
}

export function runDocker(args) {
  return new Promise((resolve, reject) => {
    const child = spawn('docker', args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (chunk) => { stdout += chunk; });
    child.stderr.on('data', (chunk) => { stderr += chunk; });
    child.once('error', reject);
    child.once('close', (exitCode) => resolve({ exitCode, stdout, stderr }));
  });
}

async function runLocalQuery({ containerName, sql, runCommand }) {
  const result = await runCommand([
    'exec',
    containerName,
    'psql',
    '--no-psqlrc',
    '--quiet',
    '--tuples-only',
    '--no-align',
    '--set=ON_ERROR_STOP=1',
    '--username=postgres',
    `--dbname=${RESTORE_DATABASE}`,
    '--command',
    sql,
  ]);

  if (result.exitCode !== 0) {
    throw new Error('Local restored database query failed.');
  }
  return result.stdout;
}

export async function verifyBackupRestoreStaging({
  containerName,
  runCommand = runDocker,
}) {
  const verifiedContainerName = requiredContainerName(containerName);

  const historyOutput = await runLocalQuery({
    containerName: verifiedContainerName,
    runCommand,
    sql: "SELECT name || E'\\t' || checksum FROM schema_migrations ORDER BY name ASC",
  });
  const history = parseRows(historyOutput, 2).map(([name, checksum]) => ({ name, checksum }));
  const expectedHistory = FOUNDATION_SCHEMA_MIGRATIONS.map(({ name, sha256 }) => ({
    name,
    checksum: sha256,
  }));
  if (JSON.stringify(history) !== JSON.stringify(expectedHistory)) {
    throw new Error('Restored migration history does not exactly match the reviewed manifest.');
  }

  const invariantOutput = await runLocalQuery({
    containerName: verifiedContainerName,
    runCommand,
    sql: invariantQuery,
  });
  const invariantRows = parseRows(invariantOutput, 2);
  const expectedChecks = [
    'completed_guardian_transfer_matches_primary',
    'correlated_audit_outbox_one_to_one',
    'family_primary_reference_valid',
    'one_active_primary_per_family',
  ];
  const observedChecks = invariantRows.map(([checkName]) => checkName);
  if (JSON.stringify(observedChecks) !== JSON.stringify(expectedChecks)
    || invariantRows.some(([, violations]) => violations !== '0')) {
    throw new Error('Restored authorization invariants were not preserved.');
  }

  return {
    checks: [
      'manifest_attested_migration_history_restored',
      'primary_guardian_continuity_invariants_restored',
      'correlated_audit_outbox_invariant_restored',
    ],
    migrationCount: expectedHistory.length,
  };
}
