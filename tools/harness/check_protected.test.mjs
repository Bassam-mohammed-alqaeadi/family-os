import assert from 'node:assert/strict';
import { execSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { runCheckProtected } from './check_protected.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const scriptPath = resolve(__dirname, 'check_protected.mjs');

function setupTestGitRepo() {
  const tmpDir = mkdtempSync(join(tmpdir(), 'check-protected-test-'));
  const run = (cmd) => execSync(cmd, { cwd: tmpDir, stdio: 'pipe' });

  run('git init -b main');
  run('git config user.name "Test"');
  run('git config user.email "test@example.com"');

  const docsDir = join(tmpDir, 'docs', 'safety_phase');
  mkdirSync(docsDir, { recursive: true });

  const protectedSystems = [
    {
      id: 'test_system',
      name_en: 'Test System',
      name_ar: 'نظام الاختبار',
      owned_files: ['lib/test_file.dart'],
      tests: ['test/test_file_test.dart']
    }
  ];

  writeFileSync(
    join(docsDir, 'PROTECTED_SYSTEMS.json'),
    JSON.stringify(protectedSystems, null, 2)
  );

  const initialContractChanges = `# Contract Changes Log\n\n- 2026-01-01 | test_system: Initial baseline record\n`;
  writeFileSync(join(docsDir, 'CONTRACT_CHANGES.md'), initialContractChanges);

  const libDir = join(tmpDir, 'lib');
  mkdirSync(libDir, { recursive: true });
  writeFileSync(join(libDir, 'test_file.dart'), '// initial\n');

  run('git add .');
  run('git commit -m "initial commit"');

  return {
    tmpDir,
    cleanup: () => rmSync(tmpDir, { recursive: true, force: true }),
    docsDir,
    libDir
  };
}

test('check_protected function is exported and returns verification object', () => {
  const result = runCheckProtected({ baseRef: 'HEAD' });
  assert.equal(typeof result, 'object');
  assert.equal(typeof result.success, 'boolean');
  assert.ok(Array.isArray(result.unrecordedSystems));
  assert.ok(Array.isArray(result.testsToRun));
});

test('a. Protected file changed, old record exists in base, no added record line -> must FAIL (exit 1)', () => {
  const env = setupTestGitRepo();
  try {
    // Modify protected file without adding a record in CONTRACT_CHANGES.md
    writeFileSync(join(env.libDir, 'test_file.dart'), '// modified protected file\n');

    const result = runCheckProtected({ baseRef: 'HEAD', repoRoot: env.tmpDir });
    assert.equal(result.success, false, 'Should fail when no new record is added in this change');
    assert.equal(result.unrecordedSystems.length, 1);
    assert.equal(result.unrecordedSystems[0].sysId, 'test_system');

    // Verify CLI exits with code 1
    const cli = spawnSync(process.execPath, [scriptPath, 'HEAD'], {
      cwd: env.tmpDir,
      encoding: 'utf8'
    });
    assert.equal(cli.status, 1, 'CLI should exit 1 on failure');
  } finally {
    env.cleanup();
  }
});

test('b. Protected file changed, one added record line naming the system -> must PASS', () => {
  const env = setupTestGitRepo();
  try {
    // Modify protected file
    writeFileSync(join(env.libDir, 'test_file.dart'), '// modified protected file\n');

    // Add a record line to CONTRACT_CHANGES.md naming the system
    const currentContract = `# Contract Changes Log\n\n- 2026-01-01 | test_system: Initial baseline record\n- 2026-10-21 | test_system: New change documented\n`;
    writeFileSync(join(env.docsDir, 'CONTRACT_CHANGES.md'), currentContract);

    const result = runCheckProtected({ baseRef: 'HEAD', repoRoot: env.tmpDir });
    assert.equal(result.success, true, 'Should pass when change has an added record line');
    assert.equal(result.unrecordedSystems.length, 0);

    // Verify CLI exits with code 0
    const cli = spawnSync(process.execPath, [scriptPath, 'HEAD'], {
      cwd: env.tmpDir,
      encoding: 'utf8'
    });
    assert.equal(cli.status, 0, 'CLI should exit 0 on success');
  } finally {
    env.cleanup();
  }
});

test('c. No protected file changed -> PASS', () => {
  const env = setupTestGitRepo();
  try {
    // Modify a non-protected file only
    writeFileSync(join(env.tmpDir, 'unrelated.txt'), 'hello\n');

    const result = runCheckProtected({ baseRef: 'HEAD', repoRoot: env.tmpDir });
    assert.equal(result.success, true, 'Should pass when no protected files are changed');
    assert.equal(result.unrecordedSystems.length, 0);

    // Verify CLI exits with code 0
    const cli = spawnSync(process.execPath, [scriptPath, 'HEAD'], {
      cwd: env.tmpDir,
      encoding: 'utf8'
    });
    assert.equal(cli.status, 0, 'CLI should exit 0 on success');
  } finally {
    env.cleanup();
  }
});
