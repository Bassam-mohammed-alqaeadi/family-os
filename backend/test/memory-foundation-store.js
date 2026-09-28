// Test-only fixture. It is never imported by the runtime server and is not a development fallback.
import { randomUUID } from 'node:crypto';
import { HttpError } from '../src/http-error.js';

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

export class MemoryFoundationStore {
  configured = true;

  constructor({ guardianTransferTtlHours = 72, now = () => new Date() } = {}) {
    this.families = new Map();
    this.memberships = new Map();
    this.guardianTransfers = new Map();
    this.audit = [];
    this.idempotency = new Map();
    this.guardianTransferTtlHours = guardianTransferTtlHours;
    this.now = now;
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
      statusReasonCode: membership.statusReasonCode,
      version: membership.version,
      joinedAt: membership.joinedAt,
      statusChangedAt: membership.statusChangedAt,
      createdAt: membership.createdAt,
    };
  }

  guardianTransferView(transfer) {
    return {
      id: transfer.id,
      status: transfer.status,
      candidateMembershipId: transfer.candidateMembershipId,
      expiresAt: transfer.expiresAt,
      completedAt: transfer.completedAt,
      cancelledAt: transfer.cancelledAt,
      version: transfer.version,
      createdAt: transfer.createdAt,
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
        statusReasonCode: null,
        version: 1,
        joinedAt: now,
        statusChangedAt: now,
        createdAt: now,
      };
      family.primaryMembershipId = membership.id;
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
        statusReasonCode: null,
        version: 1,
        joinedAt: null,
        statusChangedAt: now,
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
      membership.statusReasonCode = null;
      membership.statusChangedAt = new Date().toISOString();
      membership.version += 1;
      membership.joinedAt = membership.statusChangedAt;
      this.recordAudit(familyId, membership.id, 'family.membership_accepted', 'membership', membership.id);
      return { membership: this.memberView(membership) };
    });
  }

  async revokeMembership({ principal, familyId, membershipId, reasonCode, idempotencyKey, requestHash }) {
    return this.idempotent(`membership:revoke:${membershipId}`, idempotencyKey, requestHash, () => {
      const actor = this.activeMembership(familyId, principal.subject, true);
      const membership = this.memberships.get(membershipId);
      if (!membership || membership.familyId !== familyId) {
        throw new HttpError(404, 'membership_not_found', 'Membership was not found.');
      }
      if (membership.role === 'primary_guardian') {
        throw new HttpError(
          409,
          'primary_guardian_continuity_required',
          'Primary guardian removal requires the separate guardian continuity process.',
        );
      }
      if (!['invited', 'active'].includes(membership.status)) {
        throw new HttpError(409, 'membership_not_revocable', 'This membership is not pending or active.');
      }

      const nextStatus = membership.status === 'invited' ? 'revoked' : 'removed';
      membership.status = nextStatus;
      membership.statusReasonCode = reasonCode;
      membership.statusChangedAt = new Date().toISOString();
      membership.version += 1;
      this.recordAudit(
        familyId,
        actor.id,
        nextStatus === 'revoked' ? 'family.membership_invitation_revoked' : 'family.membership_removed',
        'membership',
        membershipId,
      );
      return { membership: this.memberView(membership) };
    });
  }

  async createGuardianTransfer({ principal, familyId, candidateMembershipId, idempotencyKey, requestHash }) {
    return this.idempotent(`guardian-transfer:create:${familyId}`, idempotencyKey, requestHash, () => {
      const actor = this.activeMembership(familyId, principal.subject, true);
      const family = this.families.get(familyId);
      if (!family || family.primaryMembershipId !== actor.id) {
        throw new HttpError(409, 'guardian_continuity_required', 'The active primary guardian has changed.');
      }
      const candidate = this.memberships.get(candidateMembershipId);
      if (!candidate || candidate.familyId !== familyId) {
        throw new HttpError(404, 'membership_not_found', 'Candidate membership was not found.');
      }
      if (candidate.role !== 'co_guardian' || candidate.status !== 'active') {
        throw new HttpError(
          409,
          'guardian_transfer_candidate_invalid',
          'Guardian transfer requires an active co-guardian membership.',
        );
      }
      if ([...this.guardianTransfers.values()].some(
        (transfer) => transfer.familyId === familyId && transfer.status === 'pending_acceptance',
      )) {
        throw new HttpError(409, 'guardian_transfer_already_pending', 'A guardian transfer is already awaiting acceptance.');
      }
      const now = this.now();
      const transfer = {
        id: randomUUID(),
        familyId,
        initiatorMembershipId: actor.id,
        candidateMembershipId,
        status: 'pending_acceptance',
        expiresAt: new Date(now.getTime() + this.guardianTransferTtlHours * 60 * 60 * 1000).toISOString(),
        completedAt: null,
        cancelledAt: null,
        version: 1,
        createdAt: now.toISOString(),
      };
      this.guardianTransfers.set(transfer.id, transfer);
      this.recordAudit(familyId, actor.id, 'guardian_transfer.requested', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
    });
  }

  async acceptGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash }) {
    return this.idempotent(`guardian-transfer:accept:${transferId}`, idempotencyKey, requestHash, () => {
      const transfer = this.guardianTransfers.get(transferId);
      if (!transfer || transfer.familyId !== familyId) {
        throw new HttpError(404, 'guardian_transfer_not_found', 'Guardian transfer was not found.');
      }
      if (transfer.status !== 'pending_acceptance') {
        throw new HttpError(409, 'guardian_transfer_not_actionable', 'Guardian transfer is no longer awaiting acceptance.');
      }
      const candidate = this.memberships.get(transfer.candidateMembershipId);
      if (!candidate || candidate.targetSubject !== principal.subject) {
        throw new HttpError(
          403,
          'guardian_transfer_acceptance_denied',
          'Only the active nominated co-guardian can accept this transfer.',
        );
      }
      const now = this.now();
      if (new Date(transfer.expiresAt) <= now) {
        transfer.status = 'expired';
        transfer.version += 1;
        this.recordAudit(familyId, candidate.id, 'guardian_transfer.expired', 'guardian_continuity_case', transfer.id);
        return { transfer: this.guardianTransferView(transfer), expired: true };
      }
      if (candidate.status !== 'active' || candidate.role !== 'co_guardian') {
        throw new HttpError(
          409,
          'guardian_transfer_candidate_invalid',
          'The nominated guardian is no longer eligible to become primary guardian.',
        );
      }
      const family = this.families.get(familyId);
      const primary = this.memberships.get(family?.primaryMembershipId);
      if (!primary || primary.id !== transfer.initiatorMembershipId || primary.role !== 'primary_guardian' || primary.status !== 'active') {
        throw new HttpError(409, 'guardian_continuity_required', 'The family primary guardian has changed.');
      }
      primary.role = 'co_guardian';
      primary.version += 1;
      candidate.role = 'primary_guardian';
      candidate.version += 1;
      family.primaryMembershipId = candidate.id;
      transfer.status = 'completed';
      transfer.completedAt = now.toISOString();
      transfer.version += 1;
      this.recordAudit(familyId, candidate.id, 'guardian_transfer.completed', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
    });
  }

  async cancelGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash }) {
    return this.idempotent(`guardian-transfer:cancel:${transferId}`, idempotencyKey, requestHash, () => {
      const actor = this.activeMembership(familyId, principal.subject, true);
      const transfer = this.guardianTransfers.get(transferId);
      if (!transfer || transfer.familyId !== familyId) {
        throw new HttpError(404, 'guardian_transfer_not_found', 'Guardian transfer was not found.');
      }
      if (transfer.initiatorMembershipId !== actor.id) {
        throw new HttpError(403, 'guardian_transfer_cancellation_denied', 'Only the initiating primary guardian can cancel this transfer.');
      }
      if (transfer.status !== 'pending_acceptance') {
        throw new HttpError(409, 'guardian_transfer_not_actionable', 'Guardian transfer is no longer awaiting acceptance.');
      }
      transfer.status = 'cancelled';
      transfer.cancelledAt = this.now().toISOString();
      transfer.version += 1;
      this.recordAudit(familyId, actor.id, 'guardian_transfer.cancelled', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
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
