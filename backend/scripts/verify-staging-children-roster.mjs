import { verifyAuditOutboxCorrelation } from '../src/audit-outbox-correlation-verifier.js';
import { verifyChildrenRosterStaging } from '../src/children-roster-staging-verifier.js';

async function readHiddenLine(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== 'function') {
    throw new Error('Run this verifier from an interactive terminal so credentials are entered without echo.');
  }

  const input = process.stdin;
  const previousRawMode = input.isRaw;
  let value = '';
  process.stdout.write(prompt);
  input.setEncoding('utf8');
  input.setRawMode(true);
  input.resume();

  return new Promise((resolve, reject) => {
    const cleanup = () => {
      input.removeListener('data', onData);
      input.setRawMode(previousRawMode ?? false);
      input.pause();
    };
    const onData = (chunk) => {
      for (const character of chunk) {
        if (character === '\u0003') {
          cleanup();
          process.stdout.write('\n');
          reject(new Error('Verification cancelled.'));
          return;
        }
        if (character === '\r' || character === '\n') {
          cleanup();
          process.stdout.write('\n');
          resolve(value);
          return;
        }
        if (character === '\u007F' || character === '\b') {
          value = value.slice(0, -1);
          continue;
        }
        value += character;
      }
    };
    input.on('data', onData);
  });
}

if (process.env.STAGING_EXECUTION_ACK !== 'synthetic-authorized-roster-mutations') {
  throw new Error(
    'Set STAGING_EXECUTION_ACK=synthetic-authorized-roster-mutations to acknowledge this verifier creates two synthetic families, memberships and child profiles.',
  );
}

const guardianAToken = await readHiddenLine('Guardian A Firebase ID token (hidden): ');
const guardianBToken = await readHiddenLine('Guardian B Firebase ID token (hidden): ');
const childCToken = await readHiddenLine('Child C Firebase ID token (hidden): ');
const principalXToken = await readHiddenLine('Principal X Firebase ID token (hidden): ');

const result = await verifyChildrenRosterStaging({
  baseUrl: process.env.STAGING_API_BASE_URL,
  guardianAToken,
  guardianBToken,
  childCToken,
  principalXToken,
});

let auditOutboxChecks = [];
if (process.env.STAGING_AUDIT_OUTBOX_ACK === 'synthetic-read-only-database-evidence') {
  const connectionString = await readHiddenLine('External staging database URL (hidden): ');
  const evidence = await verifyAuditOutboxCorrelation({
    connectionString,
    ...result.auditEvidence,
  });
  auditOutboxChecks = evidence.checks;
}

// Keep family IDs, correlation IDs, tokens and response bodies in process memory
// only. The terminal result is safe for an approved evidence record.
console.log(JSON.stringify({
  severity: 'info',
  event: 'staging_children_roster_verification_passed',
  checks: [...result.checks, ...auditOutboxChecks],
  auditOutboxEvidence: auditOutboxChecks.length > 0 ? 'verified' : 'not_run',
}));
