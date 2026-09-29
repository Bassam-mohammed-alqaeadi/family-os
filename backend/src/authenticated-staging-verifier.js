import { randomUUID } from 'node:crypto';
import { stagingBaseUrl } from './staging-foundation-verifier.js';

function requiredToken(value, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} is required.`);
  }
  return value.trim();
}

async function jsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}

function requireResponse({ response, body }, { status, errorCode }) {
  if (response.status !== status) {
    throw new Error(`Expected HTTP ${status}, received ${response.status}.`);
  }
  if (errorCode && body?.error?.code !== errorCode) {
    throw new Error(`Expected API error code ${errorCode}.`);
  }
}

function correlationId(response) {
  const value = response.headers.get('x-correlation-id');
  return value ?? undefined;
}

export async function verifyAuthenticatedStaging({
  baseUrl,
  guardianAToken,
  principalXToken,
  fetchImpl = fetch,
  idFactory = randomUUID,
}) {
  const origin = stagingBaseUrl(baseUrl);
  const guardianToken = requiredToken(guardianAToken, 'Guardian A token');
  const unrelatedToken = requiredToken(principalXToken, 'Principal X token');
  const request = async (path, { token, method = 'GET', idempotencyKey, body } = {}) => {
    const headers = { Accept: 'application/json' };
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }
    if (idempotencyKey) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    if (body) {
      headers['Content-Type'] = 'application/json';
    }
    const response = await fetchImpl(new URL(path, origin), {
      method,
      redirect: 'error',
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    return { response, body: await jsonResponse(response) };
  };

  const idempotencyKey = idFactory();
  const displayName = `Synthetic staging verification ${idFactory()}`;
  const createInput = { displayName };
  const created = await request('/v1/families', {
    method: 'POST',
    token: guardianToken,
    idempotencyKey,
    body: createInput,
  });
  requireResponse(created, { status: 201 });

  const family = created.body?.family;
  const familyId = family?.id;
  const primaryMembership = family?.members?.find(
    (membership) => membership.role === 'primary_guardian' && membership.status === 'active',
  );
  if (typeof familyId !== 'string' || !primaryMembership) {
    throw new Error('Family creation response did not contain one active primary guardian.');
  }

  const primaryRead = await request(`/v1/families/${familyId}`, { token: guardianToken });
  requireResponse(primaryRead, { status: 200 });

  const unrelatedRead = await request(`/v1/families/${familyId}`, { token: unrelatedToken });
  requireResponse(unrelatedRead, { status: 403, errorCode: 'family_access_denied' });

  const replay = await request('/v1/families', {
    method: 'POST',
    token: guardianToken,
    idempotencyKey,
    body: createInput,
  });
  requireResponse(replay, { status: 201 });
  if (replay.body?.family?.id !== familyId) {
    throw new Error('Idempotent replay did not return the original family result.');
  }

  const conflictingReplay = await request('/v1/families', {
    method: 'POST',
    token: guardianToken,
    idempotencyKey,
    body: { displayName: `${displayName} conflict` },
  });
  requireResponse(conflictingReplay, { status: 409, errorCode: 'idempotency_key_reused' });

  return {
    checks: [
      'guardian_a_authenticated',
      'family_created_with_one_primary_guardian',
      'primary_guardian_read_allowed',
      'unrelated_principal_denied',
      'idempotent_replay_preserved',
      'conflicting_idempotency_key_denied',
    ],
    familyId,
    correlationIds: [
      correlationId(created.response),
      correlationId(primaryRead.response),
      correlationId(unrelatedRead.response),
      correlationId(replay.response),
      correlationId(conflictingReplay.response),
    ].filter(Boolean),
  };
}
