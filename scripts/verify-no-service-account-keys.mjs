import { readFile, stat } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';

const root = process.cwd();
const trackedFiles = execFileSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'buffer' })
  .toString('utf8')
  .split('\0')
  .filter(Boolean);

const prohibitedFilename = [
  /firebase-adminsdk/i,
  /service[-_]?account.*\.json$/i,
  /(?:^|\/)google-services\.json$/i,
  /(?:^|\/)GoogleService-Info\.plist$/i,
  /(?:^|\/)firebase_options\.dart$/i,
  /(?:^|\/)foundation_gate_local_configuration\.dart$/i,
];
const credentialMarkers = [
  new RegExp(`"type"\\s*:\\s*"service${'_'}account"`),
  new RegExp(`"private${'_'}key"\\s*:`),
  /-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/,
];

const failures = [];
for (const relativePath of trackedFiles) {
  if (prohibitedFilename.some((pattern) => pattern.test(relativePath))) {
    failures.push(`${relativePath} (prohibited credential filename)`);
    continue;
  }

  const absolutePath = resolve(root, relativePath);
  const fileStat = await stat(absolutePath);
  // Private service-account JSON is small. Avoid processing large binary assets in CI.
  if (!fileStat.isFile() || fileStat.size > 5 * 1024 * 1024) {
    continue;
  }

  const contents = await readFile(absolutePath, 'utf8');
  if (credentialMarkers.some((pattern) => pattern.test(contents))) {
    failures.push(`${relativePath} (service-account credential marker)`);
  }
}

if (failures.length > 0) {
  console.error('Prohibited Firebase credential or controlled client-configuration material must not be committed. Affected paths:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log('Credential guard passed: no tracked Firebase private credential or controlled client configuration detected.');
