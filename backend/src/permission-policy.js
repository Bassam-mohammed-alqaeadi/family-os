// Permission policy v1 — the server-owned projection of what a family role may
// be told it can do.
//
// This module never authorizes anything. Every protected route re-checks the
// membership and role inside the store before it acts, so a stale, cached or
// tampered snapshot can never grant authority. The snapshot exists for one
// reason: the client must be able to *explain* permission instead of deciding
// it, and the explanation must be provably identical to the enforcement.
//
// `permission-policy.test.js` binds every capability declared here to the real
// endpoint and asserts the observed authorization outcome per role, so drift
// between this explanation and the server's enforcement fails CI.

export const PERMISSION_POLICY_VERSION = 'permission.v1';

// A snapshot is a short-lived explanation, never a durable grant. The value is
// deliberately short so revocation, role change or family suspension is
// re-elected from the server rather than trusted from a cached document.
export const PERMISSION_SNAPSHOT_TTL_SECONDS = 300;

export const FAMILY_ROLES = Object.freeze(['primary_guardian', 'co_guardian', 'child']);

const GUARDIAN_ROLES = Object.freeze(['primary_guardian', 'co_guardian']);

// Ordered so a rendered scope list reads from broadest to most privileged.
const CAPABILITY_RULES = Object.freeze([
  Object.freeze({
    capability: 'family.read',
    roles: FAMILY_ROLES,
    reason: 'active_membership',
  }),
  Object.freeze({
    capability: 'family.permission_snapshot.read',
    roles: FAMILY_ROLES,
    reason: 'active_membership',
  }),
  Object.freeze({
    capability: 'family.roster.read',
    roles: GUARDIAN_ROLES,
    reason: 'guardian_scope',
  }),
  Object.freeze({
    capability: 'family.device.read',
    roles: GUARDIAN_ROLES,
    reason: 'guardian_scope',
  }),
  Object.freeze({
    capability: 'family.audit.read',
    roles: GUARDIAN_ROLES,
    reason: 'guardian_scope',
  }),
  Object.freeze({
    capability: 'family.ai_events.read',
    roles: GUARDIAN_ROLES,
    reason: 'guardian_scope',
  }),
  Object.freeze({
    capability: 'family.child.create',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
  Object.freeze({
    capability: 'family.device.register',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
  Object.freeze({
    capability: 'family.device_pairing.create',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
  Object.freeze({
    capability: 'family.membership.invite',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
  Object.freeze({
    capability: 'family.membership.revoke',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
  Object.freeze({
    capability: 'family.guardian_transfer.create',
    roles: Object.freeze(['primary_guardian']),
    reason: 'primary_guardian_scope',
  }),
]);

export const PERMISSION_CAPABILITIES = Object.freeze(
  CAPABILITY_RULES.map((rule) => rule.capability),
);

export function isFamilyRole(role) {
  return typeof role === 'string' && FAMILY_ROLES.includes(role);
}

/**
 * Builds one versioned, expiring explanation of the role's capabilities.
 *
 * Every declared capability is present exactly once with an explicit `allowed`
 * flag, so a client renders denial from the same document it renders permission
 * from and never infers an absence from a missing entry.
 */
export function buildPermissionSnapshot({ familyId, role, issuedAt = new Date() }) {
  if (typeof familyId !== 'string' || familyId.length === 0) {
    throw new TypeError('familyId is required to build a permission snapshot.');
  }
  if (!isFamilyRole(role)) {
    throw new TypeError('role must be a known family role.');
  }
  if (!(issuedAt instanceof Date) || Number.isNaN(issuedAt.getTime())) {
    throw new TypeError('issuedAt must be a valid date.');
  }

  const expiresAt = new Date(
    issuedAt.getTime() + PERMISSION_SNAPSHOT_TTL_SECONDS * 1000,
  );

  return {
    policyVersion: PERMISSION_POLICY_VERSION,
    familyId,
    role,
    freshness: 'live',
    issuedAt: issuedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
    scopes: CAPABILITY_RULES.map((rule) => {
      const allowed = rule.roles.includes(role);
      return {
        capability: rule.capability,
        allowed,
        reason: allowed ? rule.reason : 'role_not_permitted',
      };
    }),
  };
}
