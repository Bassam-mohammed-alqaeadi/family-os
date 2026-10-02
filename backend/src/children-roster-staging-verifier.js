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

function requireDistinctSubjects(subjects) {
  if (new Set(Object.values(subjects)).size !== Object.keys(subjects).length) {
    throw new Error('Roster staging verification requires four distinct synthetic principals.');
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

function requireFamilyId(body) {
  const familyId = body?.family?.id;
  if (typeof familyId !== 'string' || !familyId) {
    throw new Error('Family creation response did not contain a family ID.');
  }
  return familyId;
}

function requireMembership(body, { role, status }) {
  const membership = body?.membership;
  if (typeof membership?.id !== 'string' || membership.role !== role || membership.status !== status) {
    throw new Error(`Expected ${status} ${role} membership response.`);
  }
  return membership;
}

function requireChild(body, input) {
  const child = body?.child;
  if (
    typeof child?.id !== 'string'
    || child.displayName !== input.displayName
    || child.ageYears !== input.ageYears
    || child.version !== 1
    || typeof child.createdAt !== 'string'
    || typeof child.updatedAt !== 'string'
  ) {
    throw new Error('Child creation response did not contain the expected durable roster profile.');
  }
  return child;
}

function requireExactlyOneChild(body, childId) {
  const children = body?.children;
  if (!Array.isArray(children) || children.length !== 1 || children[0]?.id !== childId) {
    throw new Error('Roster read did not return exactly the expected family-scoped child profile.');
  }
}

function responseCorrelation(response) {
  const correlationId = response.headers.get('x-correlation-id');
  if (!correlationId) {
    throw new Error('Expected a server-generated correlation ID.');
  }
  return correlationId;
}

/// Runs the synthetic, mutating HTTP portion of the Children Roster release
/// check. The returned audit evidence is intentionally for immediate in-memory
/// handoff to the optional read-only database check; callers must not log it.
export async function verifyChildrenRosterStaging({
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
  const subjects = {
    guardianA: subjectFromToken(tokens.guardianA, 'Guardian A'),
    guardianB: subjectFromToken(tokens.guardianB, 'Guardian B'),
    childC: subjectFromToken(tokens.childC, 'Child C'),
    principalX: subjectFromToken(tokens.principalX, 'Principal X'),
  };
  requireDistinctSubjects(subjects);

  const request = async (path, { token, method = 'GET', idempotencyKey, body } = {}) => {
    const headers = { Accept: 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey;
    if (body) headers['Content-Type'] = 'application/json';
    const response = await fetchImpl(new URL(path, origin), {
      method,
      redirect: 'error',
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    return { response, body: await jsonResponse(response) };
  };

  const createFamily = async (token) => {
    const result = await request('/v1/families', {
      method: 'POST',
      token,
      idempotencyKey: idFactory(),
      body: { displayName: `Synthetic roster verification ${idFactory()}` },
    });
    requireResponse(result, { status: 201 });
    return requireFamilyId(result.body);
  };

  const familyId = await createFamily(tokens.guardianA);
  const invite = async (role, subject) => {
    const result = await request(`/v1/families/${familyId}/memberships`, {
      method: 'POST',
      token: tokens.guardianA,
      idempotencyKey: idFactory(),
      body: { role, targetSubject: subject },
    });
    requireResponse(result, { status: 201 });
    return requireMembership(result.body, { role, status: 'invited' });
  };
  const guardianMembership = await invite('co_guardian', subjects.guardianB);
  const guardianAcceptance = await request(`/v1/families/${familyId}/memberships/${guardianMembership.id}/accept`, {
    method: 'POST',
    token: tokens.guardianB,
    idempotencyKey: idFactory(),
    body: {},
  });
  requireResponse(guardianAcceptance, { status: 200 });
  requireMembership(guardianAcceptance.body, { role: 'co_guardian', status: 'active' });

  const childMembership = await invite('child', subjects.childC);
  const childAcceptance = await request(`/v1/families/${familyId}/memberships/${childMembership.id}/accept`, {
    method: 'POST',
    token: tokens.childC,
    idempotencyKey: idFactory(),
    body: {},
  });
  requireResponse(childAcceptance, { status: 200 });
  requireMembership(childAcceptance.body, { role: 'child', status: 'active' });

  const childInput = { displayName: `Synthetic child ${idFactory()}`, ageYears: 0 };
  const childKey = idFactory();
  const created = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.guardianA,
    idempotencyKey: childKey,
    body: childInput,
  });
  requireResponse(created, { status: 201 });
  const child = requireChild(created.body, childInput);
  const childCreateCorrelationId = responseCorrelation(created.response);

  const replay = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.guardianA,
    idempotencyKey: childKey,
    body: childInput,
  });
  requireResponse(replay, { status: 201 });
  if (requireChild(replay.body, childInput).id !== child.id) {
    throw new Error('Idempotent roster replay did not return the original child profile.');
  }

  const changedReplay = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.guardianA,
    idempotencyKey: childKey,
    body: { ...childInput, ageYears: 1 },
  });
  requireResponse(changedReplay, { status: 409, errorCode: 'idempotency_key_reused' });

  const primaryRoster = await request(`/v1/families/${familyId}/children`, { token: tokens.guardianA });
  requireResponse(primaryRoster, { status: 200 });
  requireExactlyOneChild(primaryRoster.body, child.id);

  const coGuardianRoster = await request(`/v1/families/${familyId}/children`, { token: tokens.guardianB });
  requireResponse(coGuardianRoster, { status: 200 });
  requireExactlyOneChild(coGuardianRoster.body, child.id);

  const coGuardianWrite = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.guardianB,
    idempotencyKey: idFactory(),
    body: childInput,
  });
  requireResponse(coGuardianWrite, { status: 403, errorCode: 'family_access_denied' });

  const childRead = await request(`/v1/families/${familyId}/children`, { token: tokens.childC });
  requireResponse(childRead, { status: 403, errorCode: 'children_control_centre_access_denied' });

  const childWrite = await request(`/v1/families/${familyId}/children`, {
    method: 'POST',
    token: tokens.childC,
    idempotencyKey: idFactory(),
    body: childInput,
  });
  requireResponse(childWrite, { status: 403, errorCode: 'family_access_denied' });

  const unrelatedRead = await request(`/v1/families/${familyId}/children`, { token: tokens.principalX });
  requireResponse(unrelatedRead, { status: 403, errorCode: 'family_access_denied' });

  const unrelatedFamilyId = await createFamily(tokens.principalX);
  const unrelatedChildInput = {
    displayName: `Synthetic isolated child ${idFactory()}`,
    ageYears: 1,
  };
  const unrelatedChild = await request(`/v1/families/${unrelatedFamilyId}/children`, {
    method: 'POST',
    token: tokens.principalX,
    idempotencyKey: idFactory(),
    body: unrelatedChildInput,
  });
  requireResponse(unrelatedChild, { status: 201 });
  const unrelatedChildId = requireChild(unrelatedChild.body, unrelatedChildInput).id;
  // Do not trust a successful write alone: prove the second family reads only its own row.
  const unrelatedRoster = await request(`/v1/families/${unrelatedFamilyId}/children`, { token: tokens.principalX });
  requireResponse(unrelatedRoster, { status: 200 });
  requireExactlyOneChild(unrelatedRoster.body, unrelatedChildId);

  const crossFamilyRead = await request(`/v1/families/${unrelatedFamilyId}/children`, { token: tokens.guardianA });
  requireResponse(crossFamilyRead, { status: 403, errorCode: 'family_access_denied' });

  const audit = await request(`/v1/families/${familyId}/audit-events`, { token: tokens.guardianA });
  requireResponse(audit, { status: 200 });
  const creationEvents = audit.body?.events?.filter(
    (event) => event?.eventType === 'family.child_created' && event.subjectId === child.id,
  );
  if (!Array.isArray(creationEvents) || creationEvents.length !== 1 || creationEvents[0].correlationId !== childCreateCorrelationId) {
    throw new Error('Roster idempotency did not leave exactly one correlated child-created audit event.');
  }

  return {
    checks: [
      'primary_guardian_child_create_allowed',
      'idempotent_child_create_replayed_without_duplicate_audit',
      'conflicting_child_idempotency_key_denied',
      'primary_and_co_guardian_roster_read_allowed',
      'co_guardian_roster_write_denied',
      'child_parent_control_centre_denied',
      'unrelated_principal_denied',
      'family_scoped_roster_isolation_verified',
      'child_created_audit_event_correlated_once',
    ],
    auditEvidence: { familyId, correlationId: childCreateCorrelationId },
  };
}
