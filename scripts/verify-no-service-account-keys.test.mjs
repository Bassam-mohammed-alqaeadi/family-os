// Negative and positive proof for the credential guard (RESCUE-002 closing criterion):
// a throwaway repository with a fake keystore must be rejected, the same repository
// without it must pass. Run: node --test scripts/verify-no-service-account-keys.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const guard = resolve(fileURLToPath(new URL('.', import.meta.url)), 'verify-no-service-account-keys.mjs');

function repoWith(files) {
  const dir = mkdtempSync(join(tmpdir(), 'credential-guard-'));
  execFileSync('git', ['init', '-q'], { cwd: dir });
  for (const [path, contents] of Object.entries(files)) {
    mkdirSync(join(dir, path, '..'), { recursive: true });
    writeFileSync(join(dir, path), contents);
  }
  execFileSync('git', ['add', '-A'], { cwd: dir });
  return dir;
}

function runGuard(dir) {
  return spawnSync(process.execPath, [guard], { cwd: dir, encoding: 'utf8' });
}

test('a clean repository passes', () => {
  const dir = repoWith({ 'README.md': 'hello\n' });
  try {
    assert.equal(runGuard(dir).status, 0);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

for (const path of [
  'app/android/upload-keystore.jks',
  'app/android/app/release.keystore',
  'app/android/key.properties',
  'signing/release.p12',
  'app/android/app/google-services.json',
]) {
  test(`a tracked ${path} is rejected without printing its contents`, () => {
    const marker = 'NOT-A-REAL-SECRET-MARKER';
    const dir = repoWith({ 'README.md': 'hello\n', [path]: marker });
    try {
      const result = runGuard(dir);
      assert.equal(result.status, 1);
      assert.ok(result.stderr.includes(path), `guard output names ${path}`);
      assert.ok(!(result.stdout + result.stderr).includes(marker), 'contents never printed');
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
