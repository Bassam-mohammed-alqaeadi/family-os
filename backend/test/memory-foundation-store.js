// Test-only fixture. It is never imported by the runtime server and is not a development fallback.
import { randomUUID } from 'node:crypto';
import { HttpError } from '../src/http-error.js';

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

export class MemoryFoundationStore {
  configured = true;

  constructor() {
    this.families = new Map();
    this.memberships = new Map();
    this.audit = [];
    this.idempotency = new Map();
  }

  async health() {
    return { available: true };
  }

  idempotent(scope, key, hash, work) {
    const recordKey = `${scope}:${key}`;
    const existing = this.idempotency.get(recordKey);
    if (existing) {
      if (existing.hash !== hash) {
        throw new HttpError(409, 'idempotency_key_reused', 'Idempotency-Key cannot be reused with a different request.');
      }
      return clone(existing.response);
    }
    const response = work();
    this.idempotency.set(recordKey, { hash, response: clone(response) });
    return response;
  }

  activeMembership(familyId, subject, primaryOnly = false) {
    const found = [...this.memberships.values()].find(
      (membership) =>
        membership.familyId === familyId &&
        membership.targetSubject === subject &&
        membership.status === 'active' &&
        (!primaryOnly || membership.role === 'primary_guardian'),
    );
    if (!found) {
      throw new HttpError(403, 'family_access_denied', 'The authenticated account has no permitted family membership.');
    }
    return found;
  }

  memberView(membership) {
    return {
      id: membership.id,
      role: membership.role,
      status: membership.status,
      joinedAt: membership.joinedAt,
      createdAt: membership.createdAt,
    };
  }

  recordAudit(familyId, actorMembershipId, eventType, subjectType, subjectId) {
    this.audit.push({
      id: randomUUID(),
      familyId,
      actorMembershipId,
      eventType,
      subjectType,
      subjectId,
      occurredAt: new Date().toISOString(),
    });
  }

  async createFamily({ principal, displayName, idempotencyKey, requestHash }) {
    return this.idempotent(`family:create:${principal.subject}`, idempotencyKey, requestHash, () => {
      const now = new Date().toISOString();
      const family = { id: randomUUID(), displayName, status: 'active', createdAt: now };
      const membership = {
        id: randomUUID(),
        familyId: family.id,
        targetSubject: principal.subject,
        role: 'primary_guardian',
        status: 'active',
        joinedAt: now,
        createdAt: now,
      };
      this.families.set(family.id, family);
      this.memberships.set(membership.id, membership);
      this.recordAudit(family.id, membership.id, 'family.created', 'family', family.id);
      return { family: { ...family, members: [this.memberView(membership)] } };
    });
  }

  async getFamily({ principal, familyId }) {
    this.activeMembership(familyId, principal.subject);
    const family = this.families.get(familyId);
    if (!family) {
      throw new HttpError(404, 'family_not_found', 'Family was not found.');
    }
    return {
      family: {
        ...family,
        members: [...this.memberships.values()]
          .filter((membership) => membership.familyId === familyId)
          .map((membership) => this.memberView(membership)),
      },
    };
  }

  async createMembershipInvitation({ principal, familyId, role, targetSubject, idempotencyKey, requestHash }) {
    return this.idempotent(`membership:create:${familyId}`, idempotencyKey, requestHash, () => {
      const actor = this.activeMembership(familyId, principal.subject, true);
      if (targetSubject === principal.subject) {
        throw new HttpError(400, 'invalid_request', 'A guardian cannot invite the same account to its current family.');
      }
      const duplicate = [...this.memberships.values()].some(
        (membership) =>
          membership.familyId === familyId &&
          membership.targetSubject === targetSubject &&
          ['invited', 'active'].includes(membership.status),
      );
      if (duplicate) {
        throw new HttpError(409, 'membership_already_exists', 'This account already has an active or pending membership.');
      }
      const now = new Date().toISOString();
      const membership = {
        id: randomUUID(),
        familyId,
        targetSubject,
        role,
        status: 'invited',
        joinedAt: null,
        createdAt: now,
      };
      this.memberships.set(membership.id, membership);
      this.recordAudit(familyId, actor.id, 'family.membership_invited', 'membership', membership.id);
      return { membership: this.memberView(membership) };
    });
  }

  async acceptMembershipInvitation({ principal, familyId, membershipId, idempotencyKey, requestHash }) {
    return this.idempotent(`membership:accept:${membershipId}`, idempotencyKey, requestHash, () => {
      const membership = this.memberships.get(membershipId);
      if (!membership || membership.familyId !== familyId) {
        throw new HttpError(404, 'membership_not_found', 'Membership was not found.');
      }
      if (membership.targetSubject !== principal.subject) {
        throw new HttpError(403, 'membership_acceptance_denied', 'Only the invited account can accept this membership.');
      }
      if (membership.status !== 'invited') {
        throw new HttpError(409, 'membership_not_invitable', 'This membership is not awaiting acceptance.');
      }
      membership.status = 'active';
      membership.joinedAt = new Date().toISOString();
      this.recordAudit(familyId, membership.id, 'family.membership_accepted', 'membership', membership.id);
      return { membership: this.memberView(membership) };
    });
  }

  async listAuditEvents({ principal, familyId }) {
    const actor = this.activeMembership(familyId, principal.subject);
    if (actor.role === 'child') {
      throw new HttpError(403, 'audit_access_denied', 'Child memberships cannot view family audit events.');
    }
    return {
      events: this.audit
        .filter((event) => event.familyId === familyId)
        .sort((left, right) => right.occurredAt.localeCompare(left.occurredAt)),
    };
  }
}

export class TestAuthVerifier {
  configured = true;

  async verify(authorization) {
    const match = /^Bearer (test-[A-Za-z0-9_-]{1,64})$/.exec(authorization ?? '');
    if (!match) {
      throw new HttpError(401, 'authentication_required', 'A bearer access token is required.');
    }
    return { subject: match[1] };
  }
}
