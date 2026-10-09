import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyFamilyDiscoveryStaging } from '../src/family-discovery-staging-verifier.js';

function response(status, body) {
  return {
    status,
    async json() { return body; },
  };
}

test('family discovery staging verifier accepts minimal active discovery, rejects query input and prevents unrelated enumeration', async () => {
  const requests = [];
  const checks = await verifyFamilyDiscoveryStaging({
    baseUrl: 'https://staging.example.test',
    guardianToken: 'guardian-token',
    unrelatedToken: 'unrelated-token',
    fetchImpl: async (url, options) => {
      requests.push({ url: url.toString(), options });
      if (url.search) {
        return response(400, { error: { code: 'invalid_request' } });
      }
      if (options.headers.Authorization === 'Bearer guardian-token') {
        return response(200, {
          families: [{
            id: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
            displayName: 'Synthetic family',
            role: 'primary_guardian',
          }],
        });
      }
      return response(200, { families: [] });
    },
  });

  assert.deepEqual(checks, [
    'active_guardian_minimal_family_discovery',
    'caller_query_input_rejected_before_discovery',
    'unrelated_principal_receives_empty_non_enumerating_result',
  ]);
  assert.equal(requests.length, 3);
  assert.equal(requests.every(({ options }) => options.redirect === 'error'), true);
  assert.equal(requests.every(({ options }) => options.headers.Accept === 'application/json'), true);
  assert.equal(requests.some(({ url }) => url.includes('guardian-token') || url.includes('unrelated-token')), false);
});

test('family discovery staging verifier fails closed if unrelated discovery is not empty', async () => {
  await assert.rejects(
    verifyFamilyDiscoveryStaging({
      baseUrl: 'https://staging.example.test',
      guardianToken: 'guardian-token',
      unrelatedToken: 'unrelated-token',
      fetchImpl: async (url, options) => {
        if (url.search) {
          return response(400, { error: { code: 'invalid_request' } });
        }
        if (options.headers.Authorization === 'Bearer guardian-token') {
          return response(200, {
            families: [{
              id: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
              displayName: 'Synthetic family',
              role: 'primary_guardian',
            }],
          });
        }
        return response(200, {
          families: [{
            id: '6dbb6760-f609-4f3e-a29f-4c209dc1d53b',
            displayName: 'Leaked family',
            role: 'primary_guardian',
          }],
        });
      },
    }),
    /Unrelated principal discovery was not an empty non-enumerating result/,
  );
});

test('family discovery staging verifier rejects blank token input before network activity', async () => {
  let requested = false;
  await assert.rejects(
    verifyFamilyDiscoveryStaging({
      baseUrl: 'https://staging.example.test',
      guardianToken: '',
      unrelatedToken: 'unrelated-token',
      fetchImpl: async () => {
        requested = true;
        return response(500, {});
      },
    }),
    /active guardian synthetic ID token is required/,
  );
  assert.equal(requested, false);
});
