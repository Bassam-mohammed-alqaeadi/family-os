// Test-only fixture. It is never imported by the runtime server and is not a development fallback.
import { createHash, randomUUID } from 'node:crypto';
import { AI_EVENT_SCHEMA_VERSION, aiEventDefinition } from '../src/ai-events.js';
import { HttpError } from '../src/http-error.js';
import { PERMISSION_POLICY_VERSION, buildPermissionSnapshot } from '../src/permission-policy.js';

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_DISCOVERABLE_FAMILIES = 20;

function requireServerCorrelationId(correlationId) {
  if (typeof correlationId !== 'string' || !UUID_PATTERN.test(correlationId)) {
    throw new HttpError(500, 'correlation_context_missing', 'A required internal trace context is unavailable.');
  }
}

export class MemoryFoundationStore {
  configured = true;

  constructor({ guardianTransferTtlHours = 72, now = () => new Date() } = {}) {
    this.families = new Map();
    this.memberships = new Map();
    this.guardianTransfers = new Map();
    this.children = new Map();
    this.devices = new Map();
    this.devicePairings = new Map();
    this.audit = [];
    this.outbox = [];
    this.aiEvents = [];
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
    const family = this.families.get(familyId);
    if (!family || family.status !== 'active') {
      throw new HttpError(403, 'family_access_denied', 'The authenticated account has no permitted family membership.');
    }
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

  familyChildView(child) {
    return {
      id: child.id,
      displayName: child.displayName,
      ageYears: child.ageYears,
      avatarEmoji: child.avatarEmoji,
      themeColor: child.themeColor,
      version: child.version,
      createdAt: child.createdAt,
      updatedAt: child.updatedAt,
    };
  }

  capabilityHash(value) {
    return createHash('sha256').update(value).digest('hex');
  }

  newCapability() {
    return `${randomUUID().replaceAll('-', '')}${randomUUID().replaceAll('-', '')}`;
  }

  familyDeviceView(device) {
    return {
      id: device.id,
      childId: device.childId,
      deviceLabel: device.deviceLabel,
      batteryLevel: device.batteryLevel,
      batteryStatus: device.batteryStatus,
      locationLat: device.locationLat,
      locationLng: device.locationLng,
      locationLabel: device.locationLabel,
      lastSeenAt: device.lastSeenAt,
      linkedAt: device.linkedAt,
      version: device.version,
    };
  }

  recordAudit(familyId, actorMembershipId, correlationId, eventType, subjectType, subjectId) {
    requireServerCorrelationId(correlationId);
    const auditEvent = {
      id: randomUUID(),
      familyId,
      actorMembershipId,
      correlationId,
      eventType,
      subjectType,
      subjectId,
      occurredAt: new Date().toISOString(),
    };
    this.audit.push(auditEvent);
    this.outbox.push({
      id: randomUUID(),
      aggregateType: 'family',
      aggregateId: familyId,
      correlationId,
      eventType,
      payload: { auditEventId: auditEvent.id, subjectType, subjectId },
    });
  }

  async createFamily({ principal, displayName, idempotencyKey, requestHash, correlationId }) {
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
      this.recordAudit(family.id, membership.id, correlationId, 'family.created', 'family', family.id);
      return { family: { ...family, members: [this.memberView(membership)] } };
    });
  }

  async listMyFamilies({ principal }) {
    const families = [...this.memberships.values()]
      .filter((membership) => membership.targetSubject === principal.subject && membership.status === 'active')
      .map((membership) => ({ membership, family: this.families.get(membership.familyId) }))
      .filter(({ family }) => family?.status === 'active')
      .sort(({ family: left }, { family: right }) => {
        const createdAtOrder = left.createdAt.localeCompare(right.createdAt);
        return createdAtOrder || left.id.localeCompare(right.id);
      });
    if (families.length > MAX_DISCOVERABLE_FAMILIES) {
      throw new HttpError(
        409,
        'family_discovery_limit_exceeded',
        'The family discovery result exceeds the supported limit.',
      );
    }
    return {
      families: families.map(({ membership, family }) => ({
        id: family.id,
        displayName: family.displayName,
        role: membership.role,
      })),
    };
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

  async listFamilyChildren({ principal, familyId }) {
    const actor = this.activeMembership(familyId, principal.subject);
    if (!['primary_guardian', 'co_guardian'].includes(actor.role)) {
      throw new HttpError(
        403,
        'children_control_centre_access_denied',
        'Only guardian memberships can access the parent children control centre.',
      );
    }
    return {
      children: [...this.children.values()]
        .filter((child) => child.familyId === familyId)
        .sort((left, right) => left.createdAt.localeCompare(right.createdAt) || left.id.localeCompare(right.id))
        .map((child) => this.familyChildView(child)),
    };
  }

  async createFamilyChild({
    principal,
    familyId,
    displayName,
    ageYears,
    avatarEmoji,
    themeColor,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    // Authorize before accepting a replay so a removed guardian cannot use an
    // old idempotency key as a roster-read side channel.
    const actor = this.activeMembership(familyId, principal.subject, true);
    return this.idempotent(`family-child:create:${familyId}`, idempotencyKey, requestHash, () => {
      const now = this.now().toISOString();
      const child = {
        id: randomUUID(),
        familyId,
        displayName,
        ageYears,
        avatarEmoji,
        themeColor,
        version: 1,
        createdAt: now,
        updatedAt: now,
      };
      this.children.set(child.id, child);
      this.recordAudit(familyId, actor.id, correlationId, 'family.child_created', 'family_child', child.id);
      this.recordAiEvent({
        familyId,
        childId: child.id,
        eventType: 'family.child.created',
        correlationId,
      });
      return { child: this.familyChildView(child) };
    });
  }

  async listFamilyDevices({ principal, familyId }) {
    const actor = this.activeMembership(familyId, principal.subject);
    if (!['primary_guardian', 'co_guardian'].includes(actor.role)) {
      throw new HttpError(
        403,
        'device_telemetry_access_denied',
        'Only guardian memberships can access family device telemetry.',
      );
    }
    return {
      devices: [...this.devices.values()]
        .filter((device) => device.familyId === familyId)
        .sort((left, right) => {
          const childOrder = left.childId.localeCompare(right.childId);
          if (childOrder) return childOrder;
          const seenOrder = (right.lastSeenAt ?? '').localeCompare(left.lastSeenAt ?? '');
          return seenOrder || left.linkedAt.localeCompare(right.linkedAt) || left.id.localeCompare(right.id);
        })
        .map((device) => this.familyDeviceView(device)),
    };
  }

  async registerFamilyChildDevice({
    principal,
    familyId,
    childId,
    deviceLabel,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    const actor = this.activeMembership(familyId, principal.subject, true);
    return this.idempotent(`family-child-device:register:${familyId}:${childId}`, idempotencyKey, requestHash, () => {
      const child = this.children.get(childId);
      if (!child || child.familyId !== familyId) {
        throw new HttpError(404, 'family_child_not_found', 'Child profile was not found in this family.');
      }
      const now = this.now().toISOString();
      const device = {
        id: randomUUID(),
        familyId,
        childId,
        deviceLabel,
        batteryLevel: null,
        batteryStatus: null,
        locationLat: null,
        locationLng: null,
        locationLabel: null,
        lastSeenAt: null,
        linkedAt: now,
        version: 1,
      };
      this.devices.set(device.id, device);
      this.recordAudit(familyId, actor.id, correlationId, 'family.child_device_linked', 'family_child_device', device.id);
      return { device: this.familyDeviceView(device) };
    });
  }

  async createDevicePairing({
    principal,
    familyId,
    childId,
    deviceLabel,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    const actor = this.activeMembership(familyId, principal.subject, true);
    const child = this.children.get(childId);
    if (!child || child.familyId !== familyId) {
      throw new HttpError(404, 'family_child_not_found', 'Child profile was not found in this family.');
    }
    const idempotencyRecordKey = `family-device-pairing:create:${familyId}:${childId}:${idempotencyKey}`;
    const existing = this.idempotency.get(idempotencyRecordKey);
    if (existing) {
      if (existing.hash !== requestHash) {
        throw new HttpError(409, 'idempotency_key_reused', 'Idempotency-Key cannot be reused with a different request.');
      }
      throw new HttpError(409, 'pairing_code_not_replayable', 'A pairing code was already issued. Create a new pairing code.');
    }
    const pairingCode = this.newCapability();
    const pairing = {
      id: randomUUID(), familyId, childId, deviceLabel,
      pairingCodeHash: this.capabilityHash(pairingCode),
      expiresAt: new Date(this.now().getTime() + 10 * 60 * 1000).toISOString(),
      claimedAt: null, claimedDeviceId: null, createdByMembershipId: actor.id,
    };
    this.devicePairings.set(pairing.id, pairing);
    this.recordAudit(familyId, actor.id, correlationId, 'family.device_pairing_created', 'family_device_pairing', pairing.id);
    // Deliberately retain no raw pairing capability in test-only idempotency
    // storage either; this matches the production persistence invariant.
    this.idempotency.set(idempotencyRecordKey, { hash: requestHash, response: { pairingIssued: true } });
    return { pairing: {
      id: pairing.id, childId, deviceLabel, pairingCode, expiresAt: pairing.expiresAt,
    } };
  }

  async claimDevicePairing({ pairingCode, correlationId }) {
    const now = this.now().toISOString();
    const pairing = [...this.devicePairings.values()].find((item) =>
      item.pairingCodeHash === this.capabilityHash(pairingCode) &&
      item.claimedAt == null && item.expiresAt > now,
    );
    if (!pairing) {
      throw new HttpError(400, 'pairing_not_claimable', 'This pairing code is invalid, expired, or already used.');
    }
    const deviceCredential = this.newCapability();
    const device = {
      id: randomUUID(), familyId: pairing.familyId, childId: pairing.childId,
      deviceLabel: pairing.deviceLabel, batteryLevel: null, batteryStatus: null,
      locationLat: null, locationLng: null, locationLabel: null, lastSeenAt: null,
      linkedAt: now, version: 1, credentialHash: this.capabilityHash(deviceCredential), credentialRevokedAt: null,
    };
    this.devices.set(device.id, device);
    pairing.claimedAt = now;
    pairing.claimedDeviceId = device.id;
    this.recordAudit(pairing.familyId, null, correlationId, 'family.device_paired', 'family_child_device', device.id);
    return { device: this.familyDeviceView(device), deviceCredential };
  }

  async ingestDeviceTelemetry({
    principal,
    deviceCredential,
    deviceId,
    batteryLevel,
    batteryStatus,
    locationLat,
    locationLng,
    locationLabel,
    correlationId,
  }) {
    const device = this.devices.get(deviceId);
    if (!device) {
      throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
    }
    let actorMembershipId = null;
    if (deviceCredential != null) {
      if (device.credentialRevokedAt != null || this.capabilityHash(deviceCredential) !== device.credentialHash) {
        throw new HttpError(401, 'invalid_device_credential', 'The device credential is invalid or revoked.');
      }
    } else {
      if (!principal) {
        throw new HttpError(401, 'authentication_required', 'A device credential or bearer token is required.');
      }
      actorMembershipId = this.activeMembership(device.familyId, principal.subject, true).id;
    }
    device.batteryLevel = batteryLevel;
    device.batteryStatus = batteryStatus;
    device.locationLat = locationLat;
    device.locationLng = locationLng;
    device.locationLabel = locationLabel;
    device.lastSeenAt = this.now().toISOString();
    device.version += 1;
    this.recordAudit(device.familyId, actorMembershipId, correlationId, 'family.device_telemetry_received', 'family_child_device', device.id);
    return { device: this.familyDeviceView(device) };
  }

  async createMembershipInvitation({ principal, familyId, role, targetSubject, idempotencyKey, requestHash, correlationId }) {
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
      this.recordAudit(familyId, actor.id, correlationId, 'family.membership_invited', 'membership', membership.id);
      return { membership: this.memberView(membership) };
    });
  }

  async acceptMembershipInvitation({ principal, familyId, membershipId, idempotencyKey, requestHash, correlationId }) {
    return this.idempotent(`membership:accept:${membershipId}`, idempotencyKey, requestHash, () => {
      const membership = this.memberships.get(membershipId);
      if (!membership || membership.familyId !== familyId) {
        throw new HttpError(404, 'membership_not_found', 'Membership was not found.');
      }
      if (membership.targetSubject !== principal.subject) {
        throw new HttpError(403, 'membership_acceptance_denied', 'Only the invited account can accept this membership.');
      }
      const family = this.families.get(familyId);
      if (!family || family.status !== 'active') {
        throw new HttpError(409, 'family_not_active', 'This family is not active for membership acceptance.');
      }
      if (membership.status !== 'invited') {
        throw new HttpError(409, 'membership_not_invitable', 'This membership is not awaiting acceptance.');
      }
      membership.status = 'active';
      membership.statusReasonCode = null;
      membership.statusChangedAt = new Date().toISOString();
      membership.version += 1;
      membership.joinedAt = membership.statusChangedAt;
      this.recordAudit(familyId, membership.id, correlationId, 'family.membership_accepted', 'membership', membership.id);
      return { membership: this.memberView(membership) };
    });
  }

  async revokeMembership({ principal, familyId, membershipId, reasonCode, idempotencyKey, requestHash, correlationId }) {
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
        correlationId,
        nextStatus === 'revoked' ? 'family.membership_invitation_revoked' : 'family.membership_removed',
        'membership',
        membershipId,
      );
      return { membership: this.memberView(membership) };
    });
  }

  async createGuardianTransfer({ principal, familyId, candidateMembershipId, idempotencyKey, requestHash, correlationId }) {
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
      this.recordAudit(familyId, actor.id, correlationId, 'guardian_transfer.requested', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
    });
  }

  async acceptGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash, correlationId }) {
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
      const family = this.families.get(familyId);
      if (!family || family.status !== 'active') {
        throw new HttpError(409, 'guardian_continuity_required', 'This family is not active for guardian continuity.');
      }
      const now = this.now();
      if (new Date(transfer.expiresAt) <= now) {
        transfer.status = 'expired';
        transfer.version += 1;
        this.recordAudit(familyId, candidate.id, correlationId, 'guardian_transfer.expired', 'guardian_continuity_case', transfer.id);
        return { transfer: this.guardianTransferView(transfer), expired: true };
      }
      if (candidate.status !== 'active' || candidate.role !== 'co_guardian') {
        throw new HttpError(
          409,
          'guardian_transfer_candidate_invalid',
          'The nominated guardian is no longer eligible to become primary guardian.',
        );
      }
      const primary = this.memberships.get(family.primaryMembershipId);
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
      this.recordAudit(familyId, candidate.id, correlationId, 'guardian_transfer.completed', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
    });
  }

  async cancelGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash, correlationId }) {
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
      this.recordAudit(familyId, actor.id, correlationId, 'guardian_transfer.cancelled', 'guardian_continuity_case', transfer.id);
      return { transfer: this.guardianTransferView(transfer) };
    });
  }

  recordAiEvent({ familyId, childId = null, deviceId = null, eventType, correlationId }) {
    requireServerCorrelationId(correlationId);
    const definition = aiEventDefinition(eventType);
    const event = {
      id: randomUUID(),
      schemaVersion: AI_EVENT_SCHEMA_VERSION,
      eventType,
      familyId,
      childId,
      deviceId,
      policyVersion: PERMISSION_POLICY_VERSION,
      source: definition.source,
      confidence: definition.confidence,
      explanation: definition.explanation,
      rejectPath: definition.rejectPath,
      correlationId,
      occurredAt: new Date().toISOString(),
    };
    this.aiEvents.push(event);
    return event;
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

  async getFamilyPermissionSnapshot({ principal, familyId }) {
    const actor = this.activeMembership(familyId, principal.subject);
    return {
      permissionSnapshot: buildPermissionSnapshot({ familyId, role: actor.role }),
    };
  }

  async listFamilyAiEvents({ principal, familyId }) {
    const actor = this.activeMembership(familyId, principal.subject);
    if (actor.role === 'child') {
      throw new HttpError(403, 'ai_events_access_denied', 'Child memberships cannot view family intelligence events.');
    }
    return {
      events: this.aiEvents
        .filter((event) => event.familyId === familyId)
        .sort((left, right) => right.occurredAt.localeCompare(left.occurredAt))
        .map((event) => {
          const { correlationId: _correlationId, ...view } = event;
          return view;
        }),
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
