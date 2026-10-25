#!/usr/bin/env node
import { execSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function runCheckProtected({ baseRef = 'HEAD~1', repoRoot = process.cwd() } = {}) {
  const protectedPath = resolve(repoRoot, 'docs/safety_phase/PROTECTED_SYSTEMS.json');

  if (!existsSync(protectedPath)) {
    throw new Error(`PROTECTED_SYSTEMS.json not found at ${protectedPath}`);
  }

  const protectedSystems = JSON.parse(readFileSync(protectedPath, 'utf8'));

  // Get added lines in CONTRACT_CHANGES.md relative to baseRef
  let addedContractChangesLines = [];
  try {
    const diffDoc = execSync(`git diff ${baseRef} -- docs/safety_phase/CONTRACT_CHANGES.md`, {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    addedContractChangesLines = diffDoc
      .split(/\r?\n/)
      .filter(line => line.startsWith('+') && !line.startsWith('+++'))
      .map(line => line.slice(1));
  } catch (err) {
    addedContractChangesLines = [];
  }

  // Get changed files
  let diffOutput = '';
  try {
    diffOutput = execSync(`git diff --name-only ${baseRef}`, {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
  } catch (err) {
    // If baseRef comparison fails (e.g., initial commit or invalid ref), fallback to empty
    diffOutput = '';
  }

  const changedFiles = diffOutput
    .split(/\r?\n/)
    .map(f => f.trim().replace(/\\/g, '/'))
    .filter(Boolean);

  const affectedSystems = new Map();
  const testsToRun = new Set();

  for (const file of changedFiles) {
    for (const sys of protectedSystems) {
      const owned = (sys.owned_files || []).map(f => f.replace(/\\/g, '/'));
      if (owned.includes(file)) {
        if (!affectedSystems.has(sys.id)) {
          affectedSystems.set(sys.id, {
            system: sys,
            files: []
          });
        }
        affectedSystems.get(sys.id).files.push(file);
        for (const test of sys.tests || []) {
          testsToRun.add(test);
        }
      }
    }
  }

  console.log(`[check_protected] Changed files inspected: ${changedFiles.length}`);
  console.log(`[check_protected] Affected protected systems: ${affectedSystems.size}`);

  const unrecordedSystems = [];

  for (const [sysId, { system, files }] of affectedSystems.entries()) {
    console.log(`\n  -> System: ${sysId} (${system.name_en})`);
    console.log(`     Changed owned files: ${files.join(', ')}`);

    // A system counts as recorded only if one added line mentions its sysId, name_en, or name_ar
    const hasRecord = addedContractChangesLines.some(line =>
      line.includes(sysId) ||
      (system.name_en && line.includes(system.name_en)) ||
      (system.name_ar && line.includes(system.name_ar))
    );

    if (!hasRecord) {
      unrecordedSystems.push({ sysId, files });
    }
  }

  if (testsToRun.size > 0) {
    console.log('\n[check_protected] Recommended tests to run:');
    for (const test of testsToRun) {
      if (test.endsWith('.js')) {
        console.log(`  node --test backend/${test.replace(/^backend\//, '')}`);
      } else if (test.endsWith('.dart')) {
        console.log(`  flutter test app/${test.replace(/^app\//, '')}`);
      } else if (test.endsWith('.sh')) {
        console.log(`  bash ${test}`);
      } else {
        console.log(`  ${test}`);
      }
    }
  }

  if (unrecordedSystems.length > 0) {
    console.error('\n[ERROR] The following protected systems were changed without an entry in docs/safety_phase/CONTRACT_CHANGES.md:');
    for (const item of unrecordedSystems) {
      console.error(`  - ${item.sysId} (modified: ${item.files.join(', ')})`);
    }
    console.error('\nPlease document the change in docs/safety_phase/CONTRACT_CHANGES.md before pushing.');
    return { success: false, unrecordedSystems, testsToRun: Array.from(testsToRun) };
  }

  console.log('\n[check_protected] PASS: All protected system changes are properly documented.');
  return { success: true, unrecordedSystems: [], testsToRun: Array.from(testsToRun) };
}

const isMain = process.argv[1] && (
  resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url)) ||
  import.meta.url === `file://${process.argv[1]}`.replace(/\\/g, '/') ||
  import.meta.url === `file:///${process.argv[1]}`.replace(/\\/g, '/')
);

if (isMain) {
  const baseRef = process.argv[2] || 'HEAD~1';
  const result = runCheckProtected({ baseRef });
  if (!result.success) {
    process.exit(1);
  }
}
