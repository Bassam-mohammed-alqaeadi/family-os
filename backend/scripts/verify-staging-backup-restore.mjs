import { verifyBackupRestoreStaging } from '../src/backup-restore-staging-verifier.js';

if (process.env.STAGING_EXECUTION_ACK !== 'synthetic-operational-verification') {
  throw new Error(
    'Set STAGING_EXECUTION_ACK=synthetic-operational-verification to acknowledge the local synthetic backup/restore verification.',
  );
}

const result = await verifyBackupRestoreStaging({
  containerName: process.env.STAGING_RESTORE_CONTAINER,
});

console.log(JSON.stringify({
  severity: 'info',
  event: 'staging_backup_restore_verification_passed',
  ...result,
}));
