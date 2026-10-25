import { randomInt } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// The pairing contract is data, not code: the backend, OpenAPI tests and the Flutter app all read
// the same file (backend/contracts/pairing.v1.json). Keeping it inside backend/ means it ships with
// the backend deploy and is covered by backend CI.
export const PAIRING_CONTRACT = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', 'contracts', 'pairing.v1.json'), 'utf8'),
);

export const PAIRING_CODE_LENGTH = PAIRING_CONTRACT.pairingCode.length;
export const PAIRING_CODE_PATTERN = new RegExp(PAIRING_CONTRACT.pairingCode.pattern);

export const PAIRING_CLAIM_MAX_FAILURES = PAIRING_CONTRACT.claimAttempts.maxFailures;
export const PAIRING_CLAIM_WINDOW_MINUTES = PAIRING_CONTRACT.claimAttempts.windowMinutes;

const [ISSUE_MIN, ISSUE_MAX] = PAIRING_CONTRACT.pairingCode.issueRange;

/**
 * A human-typeable code from the contract's issue range. crypto.randomInt is uniform (no modulo
 * bias). Pairing codes are short-lived and typed by a person; device credentials are machine-held
 * and stay long (newCapability in the store).
 */
export function generatePairingCode() {
  return String(randomInt(ISSUE_MIN, ISSUE_MAX + 1));
}
