#!/usr/bin/env node
// One command for a stage gate: the generated Dart contract is current, and the backend suite
// (which includes every contract test) passes at or above the recorded baseline.
// Flutter analyze/test run in CI (flutter_ci.yml) and need the Flutter SDK, which this script does not require.
//   node tools/contracts/verify-stage.mjs
import { execFileSync, spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const backend = join(root, 'backend');
const baseline = JSON.parse(readFileSync(join(backend, 'contracts', 'baseline.json'), 'utf8'));

function step(name, fn) {
  process.stdout.write(`\n== ${name}\n`);
  fn();
}

step('generated Dart contract is up to date', () => {
  execFileSync(process.execPath, [join(root, 'tools', 'contracts', 'generate-dart.mjs'), '--check'], { stdio: 'inherit' });
});

let passed = 0;
step('backend suite (contracts included)', () => {
  const run = spawnSync('npm', ['test', '--silent'], { cwd: backend, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const output = `${run.stdout}${run.stderr}`;
  passed = Number(output.match(/^# pass (\d+)/m)?.[1] ?? NaN);
  const failed = Number(output.match(/^# fail (\d+)/m)?.[1] ?? NaN);
  console.log(`pass ${passed}, fail ${failed}, floor ${baseline.backendPassMinimum}`);
  if (run.status !== 0 || failed !== 0) {
    process.stdout.write(output.split('\n').filter((line) => /^not ok/.test(line)).join('\n') + '\n');
    throw new Error('backend suite is red');
  }
  if (!(passed >= baseline.backendPassMinimum)) {
    throw new Error(`pass count ${passed} is below the floor ${baseline.backendPassMinimum}: a regression removed tests or cases`);
  }
});

console.log(`\nSTAGE GREEN: backend ${passed} passing, Dart contract current.`);
