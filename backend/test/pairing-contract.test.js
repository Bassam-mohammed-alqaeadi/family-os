import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  generatePairingCode,
  PAIRING_CLAIM_MAX_FAILURES,
  PAIRING_CLAIM_WINDOW_MINUTES,
  PAIRING_CODE_LENGTH,
  PAIRING_CODE_PATTERN,
  PAIRING_CONTRACT,
} from '../src/pairing-code.js';
import { claimDevicePairingInput } from '../src/validation.js';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, '..', '..');
const { examples } = PAIRING_CONTRACT;
const LEGACY_ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEF0123456789_-';

test('the contract examples decide the backend claim rule: accept and reject exactly as listed', () => {
  for (const code of examples.accept) {
    assert.equal(claimDevicePairingInput({ pairingCode: code }).pairingCode, code, `accepted: ${code}`);
  }
  for (const code of examples.reject) {
    assert.throws(() => claimDevicePairingInput({ pairingCode: code }), undefined, `rejected: ${code}`);
  }
});

test('the pattern and length the backend enforces are the contract, not a copy of it', () => {
  assert.equal(PAIRING_CODE_LENGTH, PAIRING_CONTRACT.pairingCode.length);
  assert.equal(PAIRING_CODE_PATTERN.source, PAIRING_CONTRACT.pairingCode.pattern);
});

test('the claim-attempt policy is the agreed one, and the limiter reads it from the contract', () => {
  // A policy change must be deliberate: change the contract AND this assertion together.
  assert.equal(PAIRING_CONTRACT.claimAttempts.maxFailures, 5);
  assert.equal(PAIRING_CONTRACT.claimAttempts.windowMinutes, 10);
  assert.equal(PAIRING_CONTRACT.claimAttempts.countsSuccess, false);
  assert.equal(PAIRING_CLAIM_MAX_FAILURES, PAIRING_CONTRACT.claimAttempts.maxFailures);
  assert.equal(PAIRING_CLAIM_WINDOW_MINUTES, PAIRING_CONTRACT.claimAttempts.windowMinutes);
});

test('OpenAPI declares the same pattern and length as the contract', () => {
  const openapi = JSON.parse(readFileSync(join(repoRoot, 'backend', 'openapi', 'foundation.v1.json'), 'utf8'));
  for (const name of ['ClaimDevicePairingRequest', 'DevicePairing']) {
    const schema = openapi.components.schemas[name].properties.pairingCode;
    assert.equal(schema.pattern, PAIRING_CONTRACT.pairingCode.pattern, `${name} pattern`);
    assert.equal(schema.minLength, PAIRING_CODE_LENGTH, `${name} minLength`);
    assert.equal(schema.maxLength, PAIRING_CODE_LENGTH, `${name} maxLength`);
  }
});

test('every generated code is in the contract: right shape, inside the issue range', () => {
  const [min, max] = PAIRING_CONTRACT.pairingCode.issueRange;
  const seen = new Set();
  for (let i = 0; i < 2000; i += 1) {
    const code = generatePairingCode();
    assert.match(code, PAIRING_CODE_PATTERN);
    assert.ok(Number(code) >= min && Number(code) <= max, code);
    seen.add(code);
  }
  assert.ok(seen.size > 1900, 'codes are not repeating');
});

test('the generated Dart contract is up to date with the JSON contract', () => {
  // Throws (non-zero exit) when stale; the message says how to regenerate.
  const output = execFileSync(process.execPath, [join(repoRoot, 'tools', 'contracts', 'generate-dart.mjs'), '--check'], { encoding: 'utf8' });
  assert.match(output, /up to date/);
});

test('no test reintroduces the retired pairing alphabet', () => {
  const offenders = [];
  const scan = (dir, extensions) => {
    for (const name of readdirSync(dir)) {
      const path = join(dir, name);
      if (statSync(path).isDirectory()) {
        if (name !== 'node_modules') scan(path, extensions);
      } else if (extensions.some((ext) => name.endsWith(ext)) && !path.endsWith('pairing-contract.test.js')) {
        if (readFileSync(path, 'utf8').includes(LEGACY_ALPHABET)) offenders.push(relative(repoRoot, path));
      }
    }
  };
  scan(here, ['.js']);
  scan(join(repoRoot, 'app', 'test'), ['.dart']);
  assert.deepEqual(offenders, [], 'pairing tests must use the contract or the generator, not a literal');
});
