import { verifyStagingFoundation } from '../src/staging-foundation-verifier.js';

if (process.env.STAGING_EXECUTION_ACK !== 'synthetic-only') {
  throw new Error('Set STAGING_EXECUTION_ACK=synthetic-only before running the non-mutating staging verifier.');
}

const checks = await verifyStagingFoundation({ baseUrl: process.env.STAGING_API_BASE_URL });
console.log(JSON.stringify({
  severity: 'info',
  event: 'staging_foundation_smoke_verification_passed',
  checks,
}));
