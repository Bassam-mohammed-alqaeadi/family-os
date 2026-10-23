#!/usr/bin/env node
// Generates the Dart side of the pairing contract from backend/contracts/pairing.v1.json.
//   node tools/contracts/generate-dart.mjs          -> writes the file
//   node tools/contracts/generate-dart.mjs --check  -> exits 1 if the committed file is stale
// Never hand-edit the generated file: change the contract, then regenerate.
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const contractPath = join(root, 'backend', 'contracts', 'pairing.v1.json');
const outPath = join(root, 'app', 'lib', 'foundation_gate', 'pairing_contract.generated.dart');

const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
const { length, pattern } = contract.pairingCode;
const { maxFailures, windowMinutes } = contract.claimAttempts;
if (!Number.isInteger(length) || typeof pattern !== 'string' || pattern.includes("'")) {
  throw new Error('pairing contract is malformed');
}
if (!Number.isInteger(maxFailures) || !Number.isInteger(windowMinutes)) {
  throw new Error('pairing contract claimAttempts is malformed');
}

const dart = `// GENERATED from backend/contracts/pairing.v1.json by tools/contracts/generate-dart.mjs.
// Do not edit by hand: change the contract and run the generator.

/// The one-time child pairing code contract, shared with the backend.
abstract final class PairingContract {
  static const String contractId = '${contract.contract}';
  static const int codeLength = ${length};
  static const String codePattern = r'${pattern}';
  /// Failed claims a source may make within one window. A claim that succeeds is not counted.
  static const int claimMaxFailures = ${maxFailures};
  static const int claimWindowMinutes = ${windowMinutes};
}
`;

if (process.argv.includes('--check')) {
  // A generated file that git ignores never reaches CI. Refuse that state explicitly.
  const ignored = spawnSync('git', ['check-ignore', '-q', outPath], { cwd: root });
  if (ignored.status === 0) {
    console.error(`stale: ${outPath} is ignored by git and would not reach CI. Rename it or fix .gitignore.`);
    process.exit(1);
  }
  let current = '';
  try { current = readFileSync(outPath, 'utf8'); } catch { /* missing counts as stale */ }
  if (current !== dart) {
    console.error(`stale: ${outPath} does not match the contract. Run: node tools/contracts/generate-dart.mjs`);
    process.exit(1);
  }
  console.log('pairing contract: Dart file is up to date');
} else {
  writeFileSync(outPath, dart);
  console.log(`wrote ${outPath}`);
}
