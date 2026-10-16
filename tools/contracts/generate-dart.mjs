#!/usr/bin/env node
// Generates the Dart side of the pairing contract from backend/contracts/pairing.v1.json.
//   node tools/contracts/generate-dart.mjs          -> writes the file
//   node tools/contracts/generate-dart.mjs --check  -> exits 1 if the committed file is stale
// Never hand-edit the generated file: change the contract, then regenerate.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const contractPath = join(root, 'backend', 'contracts', 'pairing.v1.json');
const outPath = join(root, 'app', 'lib', 'foundation_gate', 'pairing_contract.g.dart');

const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
const { length, pattern } = contract.pairingCode;
if (!Number.isInteger(length) || typeof pattern !== 'string' || pattern.includes("'")) {
  throw new Error('pairing contract is malformed');
}

const dart = `// GENERATED from backend/contracts/pairing.v1.json by tools/contracts/generate-dart.mjs.
// Do not edit by hand: change the contract and run the generator.

/// The one-time child pairing code contract, shared with the backend.
abstract final class PairingContract {
  static const String contractId = '${contract.contract}';
  static const int codeLength = ${length};
  static const String codePattern = r'${pattern}';
}
`;

if (process.argv.includes('--check')) {
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
