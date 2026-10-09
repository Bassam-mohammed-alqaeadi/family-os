import { verifyDeviceTelemetryStaging } from '../src/device-telemetry-staging-verifier.js';

const result = await verifyDeviceTelemetryStaging({
  baseUrl: process.env.STAGING_BASE_URL,
  primaryGuardianToken: process.env.STAGING_PRIMARY_GUARDIAN_TOKEN,
  coGuardianToken: process.env.STAGING_CO_GUARDIAN_TOKEN,
  childToken: process.env.STAGING_CHILD_TOKEN,
  unrelatedToken: process.env.STAGING_UNRELATED_TOKEN,
});

// This intentionally reports only test names and opaque server correlation
// evidence, never supplied bearer tokens or decoded subject identifiers.
console.log(JSON.stringify(result, null, 2));
