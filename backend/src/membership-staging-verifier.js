import { randomUUID } from 'node:crypto';
import { stagingBaseUrl } from './staging-foundation-verifier.js';

function requiredToken(value, label) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} token is required.`);
  }
  return value.trim();
}

function subjectFromToken(token, label) {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error(`${label} token is not a JWT.`);
  }
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (typeof payload.sub !== 'string' || !payload.sub || payload.sub.length > 255 || /[\u0000-\u001F\u007F]/.test(payload.sub)) {
      throw new Error('invalid subject');
    }
    return payload.sub;
  } catch {
    throw new Error(`${label} token does not contain a valid subject.`);
  }
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

function requireMembership(body, { role, status }) {
  const membership = body?.membership;
  if (typeof membership?.id !== 'string' || membership.role !== role || membership.status !== status) {
    throw new Error(`Expected ${status} ${role} membership response.`);
  }
  return membership;
}

function correlationId(response) {
  return response.headers.get('x-correlation-id') ?? undefined;
}

export async function verifyMembershipLifecycleStaging({
  baseUrl,
  guardianAToken,
  guardianBToken,
  childCToken,
  principalXToken,
  fetchImpl = fetch,
  idFactory = randomUUID,
}) {
  const origin = stagingBaseUrl(baseUrl);
  const tokens = {
    guardianA: requiredToken(guardianAToken, 'Guardian A'),
    guardianB: requiredToken(guardianBToken, 'Guardian B'),
    childC: requiredToken(childCToken, 'Child C'),
    principalX: requiredToken(principalXToken, 'Principal X'),
  };
  // The API performs the authoritative signature/issuer/audience verification. This local shape check
  // prevents malformed input from causing any synthetic mutation before the first network request.
  subjectFromToken(tokens.guardianA, 'Guardian A');
  const guardianBSubject = subjectFromToken(tokens.guardianB, 'Guardian B');
  const childCSubject = subjectFromToken(tokens.childC, 'Child C');
  subjectFromToken(tokens.principalX, 'Principal X');
  const correlations = [];

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
    const result = { response, body: await jsonResponse(response) };
    const correlation = correlationId(response);
    if (correlation) {
      correlations.push(correlation);
    }
    return result;
  };

  const createFamily = await request('/v1/families', {
    method: 'POST',
    token: tokens.guardianA,
    idempotencyKey: idFactory(),
    body: { displayName: `Synthetic membership verification ${idFactory()}` },
  });
  requireResponse(createFamily, { status: 201 });
  const familyId = createFamily.body?.family?.id;
  const primaryMembershipId = createFamily.body?.family?.members?.find(
    (membership) => membership.role === 'primary_guardian' && membership.status === 'active',
  )?.id;
  if (typeof familyId !== 'string' || typeof primaryMembershipId !== 'string') {
    throw new Error('Family creation did not return an active primary guardian.');
  }

  const invite = async ({ role, subject, token = tokens.guardianA }) => {
    const result = await request(`/v1/families/${familyId}/memberships`, {
      method: 'POST',
      token,
      idempotencyKey: idFactory(),
      body: { role, targetSubject: subject },
    });
    return result;
  };
  const accept = async (membershipId, token) => request(
    `/v1/families/${familyId}/memberships/${membershipId}/accept`,
    { method: 'POST', token, idempotencyKey: idFactory(), body: {} },
  );
  const revoke = async (membershipId, token = tokens.guardianA) => request(
    `/v1/families/${familyId}/memberships/${membershipId}/revoke`,
    {
      method: 'POST',
      token,
      idempotencyKey: idFactory(),
      body: { reasonCode: 'synthetic_lifecycle_test' },
    },
  );

  const invitedGuardian = await invite({ role: 'co_guardian', subject: guardianBSubject });
  requireResponse(invitedGuardian, { status: 201 });
  const guardianMembership = requireMembership(invitedGuardian.body, { role: 'co_guardian', status: 'invited' });

  const strangerAcceptsGuardian = await accept(guardianMembership.id, tokens.principalX);
  requireResponse(strangerAcceptsGuardian, { status: 403, errorCode: 'membership_acceptance_denied' });

  const acceptedGuardian = await accept(guardianMembership.id, tokens.guardianB);
  requireResponse(acceptedGuardian, { status: 200 });
  requireMembership(acceptedGuardian.body, { role: 'co_guardian', status: 'active' });

  const pendingChild = await invite({ role: 'child', subject: childCSubject });
  requireResponse(pendingChild, { status: 201 });
  const pendingChildMembership = requireMembership(pendingChild.body, { role: 'child', status: 'invited' });

  const coGuardianRevoke = await revoke(pendingChildMembership.id, tokens.guardianB);
  requireResponse(coGuardianRevoke, { status: 403, errorCode: 'family_access_denied' });

  const revokedChild = await revoke(pendingChildMembership.id);
  requireResponse(revokedChild, { status: 200 });
  requireMembership(revokedChild.body, { role: 'child', status: 'revoked' });

  const revokedChildAccept = await accept(pendingChildMembership.id, tokens.childC);
  requireResponse(revokedChildAccept, { status: 409, errorCode: 'membership_not_invitable' });

  const reinvitedChild = await invite({ role: 'child', subject: childCSubject });
  requireResponse(reinvitedChild, { status: 201 });
  const reinvitedChildMembership = requireMembership(reinvitedChild.body, { role: 'child', status: 'invited' });

  const acceptedChild = await accept(reinvitedChildMembership.id, tokens.childC);
  requireResponse(acceptedChild, { status: 200 });
  requireMembership(acceptedChild.body, { role: 'child', status: 'active' });

  const removedChild = await revoke(reinvitedChildMembership.id);
  requireResponse(removedChild, { status: 200 });
  requireMembership(removedChild.body, { role: 'child', status: 'removed' });

  const removedChildRead = await request(`/v1/families/${familyId}`, { token: tokens.childC });
  requireResponse(removedChildRead, { status: 403, errorCode: 'family_access_denied' });

  const primaryRemoval = await revoke(primaryMembershipId);
  requireResponse(primaryRemoval, { status: 409, errorCode: 'primary_guardian_continuity_required' });

  const concurrentInvites = await Promise.all([
    invite({ role: 'child', subject: childCSubject }),
    invite({ role: 'child', subject: childCSubject }),
  ]);
  const successfulInvite = concurrentInvites.find((result) => result.response.status === 201);
  const rejectedInvite = concurrentInvites.find((result) => result.response.status === 409);
  if (!successfulInvite || !rejectedInvite) {
    throw new Error('Concurrent conflicting invitations did not produce exactly one success and one conflict.');
  }
  requireResponse(rejectedInvite, { status: 409, errorCode: 'membership_already_exists' });
  const racedMembership = requireMembership(successfulInvite.body, { role: 'child', status: 'invited' });

  const cleanupRacedInvite = await revoke(racedMembership.id);
  requireResponse(cleanupRacedInvite, { status: 200 });
  requireMembership(cleanupRacedInvite.body, { role: 'child', status: 'revoked' });

  return {
    checks: [
      'co_guardian_invited_pending',
      'unrelated_principal_membership_acceptance_denied',
      'co_guardian_accepted_active',
      'co_guardian_privileged_membership_mutation_denied',
      'pending_child_invitation_revoked',
      'revoked_child_acceptance_denied',
      'child_accepted_active',
      'active_child_removed_and_access_denied',
      'primary_guardian_ordinary_removal_denied',
      'concurrent_conflicting_invitation_controlled',
    ],
    familyId,
    correlationIds: correlations,
  };
}
