import { verifyOidcPrincipalLifecycle } from '../src/oidc-principal-lifecycle-verifier.js';

async function readHiddenLine(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== 'function') {
    throw new Error('Run this verifier from an interactive terminal so the synthetic ID token can be entered without echo.');
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

if (process.env.STAGING_EXECUTION_ACK !== 'synthetic-operational-verification') {
  throw new Error(
    'Set STAGING_EXECUTION_ACK=synthetic-operational-verification to acknowledge the synthetic OIDC lifecycle check.',
  );
}

const token = await readHiddenLine('Disposable synthetic principal Firebase ID token (hidden): ');
const checks = await verifyOidcPrincipalLifecycle({
  baseUrl: process.env.STAGING_API_BASE_URL,
  token,
  expectation: process.env.STAGING_OIDC_EXPECTATION,
});
console.log(JSON.stringify({
  severity: 'info',
  event: 'staging_oidc_principal_lifecycle_probe_passed',
  expectation: process.env.STAGING_OIDC_EXPECTATION,
  checks,
}));
