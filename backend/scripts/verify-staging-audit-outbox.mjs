import { verifyAuditOutboxCorrelation } from '../src/audit-outbox-correlation-verifier.js';

async function readHiddenLine(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== 'function') {
    throw new Error('Run this verifier from an interactive terminal so database evidence can be entered without echo.');
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

if (process.env.STAGING_EXECUTION_ACK !== 'synthetic-read-only-database-evidence') {
  throw new Error(
    'Set STAGING_EXECUTION_ACK=synthetic-read-only-database-evidence to acknowledge this verifier uses read-only database evidence.',
  );
}

const connectionString = await readHiddenLine('External staging database URL (hidden): ');
const familyId = await readHiddenLine('Synthetic family ID (hidden): ');
const correlationId = await readHiddenLine('Server correlation ID from a synthetic mutation (hidden): ');

const result = await verifyAuditOutboxCorrelation({ connectionString, familyId, correlationId });
console.log(JSON.stringify({
  severity: 'info',
  event: 'staging_audit_outbox_correlation_verification_passed',
  ...result,
}));
