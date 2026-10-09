import assert from 'node:assert/strict';
import test from 'node:test';

import { verifyDeviceTelemetryStaging } from '../src/device-telemetry-staging-verifier.js';

const jwtFor = (subject) => `header.${Buffer.from(JSON.stringify({ sub: subject })).toString('base64url')}.signature`;

test('device telemetry staging verifier rejects absent or duplicate synthetic identities before network activity', async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    throw new Error('network must not be called');
  };
  await assert.rejects(
    verifyDeviceTelemetryStaging({
      baseUrl: 'https://staging.example.test',
      primaryGuardianToken: '',
      coGuardianToken: jwtFor('co-guardian'),
      childToken: jwtFor('child'),
      unrelatedToken: jwtFor('unrelated'),
      fetchImpl,
    }),
    /Primary guardian token is required/,
  );
  await assert.rejects(
    verifyDeviceTelemetryStaging({
      baseUrl: 'https://staging.example.test',
      primaryGuardianToken: jwtFor('same-subject'),
      coGuardianToken: jwtFor('same-subject'),
      childToken: jwtFor('child'),
      unrelatedToken: jwtFor('unrelated'),
      fetchImpl,
    }),
    /four distinct synthetic principals/,
  );
  assert.equal(calls, 0);
});
