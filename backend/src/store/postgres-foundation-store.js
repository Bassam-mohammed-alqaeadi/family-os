import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { HttpError } from '../http-error.js';
import { FOUNDATION_SCHEMA_MIGRATIONS } from '../schema-manifest.js';

const { Pool } = pg;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_DISCOVERABLE_FAMILIES = 20;

function requireServerCorrelationId(correlationId) {
  if (typeof correlationId !== 'string' || !UUID_PATTERN.test(correlationId)) {
    throw new HttpError(500, 'correlation_context_missing', 'A required internal trace context is unavailable.');
  }
  return correlationId;
}

function memberView(row) {
  return {
    id: row.id,
    role: row.role,
    status: row.status,
    statusReasonCode: row.status_reason_code,
    version: row.version,
    joinedAt: row.joined_at,
    statusChangedAt: row.status_changed_at,
    createdAt: row.created_at,
  };
}

function familyView(row, members) {
  return {
    id: row.id,
    displayName: row.display_name,
    status: row.status,
    createdAt: row.created_at,
    members,
  };
}

function discoveredFamilyView(row) {
  return {
    id: row.id,
    displayName: row.display_name,
    role: row.role,
  };
}

function familyChildView(row) {
  return {
    id: row.id,
    displayName: row.display_name,
    ageYears: row.age_years,
    avatarEmoji: row.avatar_emoji,
    themeColor: row.theme_color,
    version: row.version,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function familyDeviceView(row) {
  return {
    id: row.id,
    childId: row.child_id,
    deviceLabel: row.device_label,
    batteryLevel: row.battery_level,
    batteryStatus: row.battery_status,
    locationLat: row.location_lat,
    locationLng: row.location_lng,
    locationLabel: row.location_label,
    lastSeenAt: row.last_seen_at,
    linkedAt: row.linked_at,
    version: row.version,
  };
}

function guardianTransferView(row) {
  return {
    id: row.id,
    status: row.status,
    candidateMembershipId: row.candidate_membership_id,
    expiresAt: row.expires_at,
    completedAt: row.completed_at,
    cancelledAt: row.cancelled_at,
    version: row.version,
    createdAt: row.created_at,
  };
}

function auditView(row) {
  return {
    id: row.id,
    eventType: row.event_type,
    actorMembershipId: row.actor_membership_id,
    correlationId: row.correlation_id,
    subjectType: row.subject_type,
    subjectId: row.subject_id,
    occurredAt: row.occurred_at,
  };
}

export class PostgresFoundationStore {
  configured = true;

  constructor({ connectionString, guardianTransferTtlHours, pool = undefined }) {
    this.pool = pool ?? new Pool({ connectionString, max: 10, idleTimeoutMillis: 10_000 });
    this.guardianTransferTtlHours = guardianTransferTtlHours;
  }

  async close() {
    await this.pool.end();
  }

  async health() {
    try {
      await this.pool.query('SELECT 1');
      const expectedMigrationNames = FOUNDATION_SCHEMA_MIGRATIONS.map((migration) => migration.name);
      const applied = await this.pool.query(
        'SELECT name, checksum FROM schema_migrations WHERE name = ANY($1::text[])',
        [expectedMigrationNames],
      );
      const appliedByName = new Map(applied.rows.map((row) => [row.name, row.checksum]));
      const migrationMismatch = FOUNDATION_SCHEMA_MIGRATIONS.some(
        (migration) => appliedByName.get(migration.name) !== migration.sha256,
      );
      if (migrationMismatch) {
        return { available: false, reason: 'database_schema_not_ready' };
      }
      return { available: true };
    } catch (error) {
      return {
        available: false,
        reason: error?.code === '42P01' ? 'database_schema_not_ready' : 'database_unavailable',
      };
    }
  }

  async listMyFamilies({ principal }) {
    const { rows } = await this.pool.query(
      `SELECT family.id, family.display_name, membership.role
       FROM accounts AS account
       INNER JOIN family_memberships AS membership ON membership.account_id = account.id
       INNER JOIN families AS family ON family.id = membership.family_id
       WHERE account.oidc_subject = $1
         AND membership.status = 'active'
         AND family.status = 'active'
       ORDER BY family.created_at ASC, family.id ASC
       LIMIT $2`,
      [principal.subject, MAX_DISCOVERABLE_FAMILIES + 1],
    );
    if (rows.length > MAX_DISCOVERABLE_FAMILIES) {
      throw new HttpError(
        409,
        'family_discovery_limit_exceeded',
        'The family discovery result exceeds the supported limit.',
      );
    }
    return { families: rows.map(discoveredFamilyView) };
  }

  async withTransaction(run) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await run(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async ensureAccount(client, subject) {
    const accountId = randomUUID();
    const { rows } = await client.query(
      `INSERT INTO accounts (id, oidc_subject)
       VALUES ($1, $2)
       ON CONFLICT (oidc_subject) DO UPDATE SET oidc_subject = EXCLUDED.oidc_subject
       RETURNING id, oidc_subject`,
      [accountId, subject],
    );
    return rows[0];
  }

  async acquireIdempotencySlot(client, scope, key, requestHash) {
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1), hashtext($2))', [scope, key]);
    const existing = await client.query(
      `SELECT request_hash, response_body
       FROM idempotency_records
       WHERE operation_scope = $1 AND idempotency_key = $2`,
      [scope, key],
    );

    if (existing.rowCount === 0) {
      await client.query(
        `INSERT INTO idempotency_records (operation_scope, idempotency_key, request_hash)
         VALUES ($1, $2, $3)`,
        [scope, key, requestHash],
      );
      return undefined;
    }

    const saved = existing.rows[0];
    if (saved.request_hash !== requestHash) {
      throw new HttpError(
        409,
        'idempotency_key_reused',
        'Idempotency-Key cannot be reused with a different request.',
      );
    }
    if (!saved.response_body) {
      throw new HttpError(409, 'request_in_progress', 'A matching request is already in progress.');
    }
    return saved.response_body;
  }

  async completeIdempotencySlot(client, scope, key, response) {
    await client.query(
      `UPDATE idempotency_records
       SET response_body = $3::jsonb, completed_at = NOW()
       WHERE operation_scope = $1 AND idempotency_key = $2`,
      [scope, key, JSON.stringify(response)],
    );
  }

  async appendAuditAndOutbox(client, {
    familyId,
    actorMembershipId,
    correlationId,
    eventType,
    subjectType,
    subjectId,
  }) {
    requireServerCorrelationId(correlationId);
    const auditId = randomUUID();
    await client.query(
      `INSERT INTO family_audit_events
       (id, family_id, actor_membership_id, correlation_id, event_type, subject_type, subject_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [auditId, familyId, actorMembershipId, correlationId, eventType, subjectType, subjectId],
    );
    await client.query(
      `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, correlation_id, event_type, payload)
       VALUES ($1, 'family', $2, $3, $4, $5::jsonb)`,
      [
        randomUUID(),
        familyId,
        correlationId,
        eventType,
        JSON.stringify({ auditEventId: auditId, subjectType, subjectId }),
      ],
    );
  }

  async activeActorMembership(client, familyId, subject, { primaryGuardianOnly = false } = {}) {
    const roleClause = primaryGuardianOnly ? `AND membership.role = 'primary_guardian'` : '';
    const { rows } = await client.query(
      `SELECT membership.id, membership.role
       FROM family_memberships AS membership
       INNER JOIN accounts AS account ON account.id = membership.account_id
       INNER JOIN families AS family ON family.id = membership.family_id
       WHERE membership.family_id = $1
         AND account.oidc_subject = $2
         AND membership.status = 'active'
         AND family.status = 'active'
         ${roleClause}`,
      [familyId, subject],
    );
    if (rows.length === 0) {
      throw new HttpError(403, 'family_access_denied', 'The authenticated account has no permitted family membership.');
    }
    return rows[0];
  }

  async lockedFamilyPrimary(client, familyId) {
    const { rows } = await client.query(
      `SELECT family.id AS family_id,
              family.status AS family_status,
              family.primary_membership_id,
              membership.id AS membership_id,
              membership.role,
              membership.status
       FROM families AS family
       INNER JOIN family_memberships AS membership ON membership.id = family.primary_membership_id
       WHERE family.id = $1
       FOR UPDATE OF family, membership`,
      [familyId],
    );
    if (rows.length === 0) {
      throw new HttpError(404, 'family_not_found', 'Family was not found.');
    }
    const family = rows[0];
    if (
      family.family_status !== 'active'
      || family.role !== 'primary_guardian'
      || family.status !== 'active'
    ) {
      throw new HttpError(
        409,
        'guardian_continuity_required',
        'This family has no active primary guardian for the requested continuity action.',
      );
    }
    return family;
  }

  async createFamily({ principal, displayName, idempotencyKey, requestHash, correlationId }) {
    return this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `family:create:${principal.subject}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const account = await this.ensureAccount(client, principal.subject);
      const familyId = randomUUID();
      const membershipId = randomUUID();
      const family = await client.query(
        `INSERT INTO families (id, display_name, status)
         VALUES ($1, $2, 'active')
         RETURNING id, display_name, status, created_at`,
        [familyId, displayName],
      );
      const membership = await client.query(
        `INSERT INTO family_memberships
         (id, family_id, account_id, target_subject, role, status, joined_at)
         VALUES ($1, $2, $3, $4, 'primary_guardian', 'active', NOW())
         RETURNING id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at`,
        [membershipId, familyId, account.id, principal.subject],
      );
      await client.query('UPDATE families SET primary_membership_id = $2 WHERE id = $1', [familyId, membershipId]);
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: membershipId,
        correlationId,
        eventType: 'family.created',
        subjectType: 'family',
        subjectId: familyId,
      });

      const result = { family: familyView(family.rows[0], [memberView(membership.rows[0])]) };
      await this.completeIdempotencySlot(client, `family:create:${principal.subject}`, idempotencyKey, result);
      return result;
    });
  }

  async getFamily({ principal, familyId }) {
    return this.withTransaction(async (client) => {
      await this.activeActorMembership(client, familyId, principal.subject);
      const family = await client.query(
        'SELECT id, display_name, status, created_at FROM families WHERE id = $1',
        [familyId],
      );
      if (family.rowCount === 0) {
        throw new HttpError(404, 'family_not_found', 'Family was not found.');
      }
      const memberships = await client.query(
        `SELECT id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at
         FROM family_memberships
         WHERE family_id = $1
         ORDER BY created_at ASC`,
        [familyId],
      );
      return { family: familyView(family.rows[0], memberships.rows.map(memberView)) };
    });
  }

  async listFamilyChildren({ principal, familyId }) {
    return this.withTransaction(async (client) => {
      const actor = await this.activeActorMembership(client, familyId, principal.subject);
      if (!['primary_guardian', 'co_guardian'].includes(actor.role)) {
        throw new HttpError(
          403,
          'children_control_centre_access_denied',
          'Only guardian memberships can access the parent children control centre.',
        );
      }
      const children = await client.query(
        `SELECT id, display_name, age_years, avatar_emoji, theme_color, version, created_at, updated_at
         FROM family_children
         WHERE family_id = $1
         ORDER BY created_at ASC, id ASC`,
        [familyId],
      );
      return { children: children.rows.map(familyChildView) };
    });
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
    return this.withTransaction(async (client) => {
      // Authorize before accepting a replay so a removed guardian cannot use an
      // old idempotency key as a roster-read side channel.
      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const response = await this.acquireIdempotencySlot(
        client,
        `family-child:create:${familyId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const child = await client.query(
        `INSERT INTO family_children (id, family_id, display_name, age_years, avatar_emoji, theme_color)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, display_name, age_years, avatar_emoji, theme_color, version, created_at, updated_at`,
        [randomUUID(), familyId, displayName, ageYears, avatarEmoji, themeColor],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.child_created',
        subjectType: 'family_child',
        subjectId: child.rows[0].id,
      });
      const result = { child: familyChildView(child.rows[0]) };
      await this.completeIdempotencySlot(
        client,
        `family-child:create:${familyId}`,
        idempotencyKey,
        result,
      );
      return result;
    });
  }

  async listFamilyDevices({ principal, familyId }) {
    return this.withTransaction(async (client) => {
      const actor = await this.activeActorMembership(client, familyId, principal.subject);
      if (!['primary_guardian', 'co_guardian'].includes(actor.role)) {
        throw new HttpError(
          403,
          'device_telemetry_access_denied',
          'Only guardian memberships can access family device telemetry.',
        );
      }
      const devices = await client.query(
        `SELECT id, child_id, device_label, battery_level, battery_status,
                location_lat, location_lng, location_label, last_seen_at,
                linked_at, version
         FROM family_child_devices
         WHERE family_id = $1
         ORDER BY child_id ASC, last_seen_at DESC NULLS LAST, linked_at ASC, id ASC`,
        [familyId],
      );
      return { devices: devices.rows.map(familyDeviceView) };
    });
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
    return this.withTransaction(async (client) => {
      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const response = await this.acquireIdempotencySlot(
        client,
        `family-child-device:register:${familyId}:${childId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) return response;

      // The scoped foreign key also enforces this at write time. This explicit
      // check yields an intentional API result instead of a driver error.
      const child = await client.query(
        'SELECT id FROM family_children WHERE family_id = $1 AND id = $2',
        [familyId, childId],
      );
      if (child.rowCount === 0) {
        throw new HttpError(404, 'family_child_not_found', 'Child profile was not found in this family.');
      }

      const device = await client.query(
        `INSERT INTO family_child_devices (id, family_id, child_id, device_label)
         VALUES ($1, $2, $3, $4)
         RETURNING id, child_id, device_label, battery_level, battery_status,
                   location_lat, location_lng, location_label, last_seen_at,
                   linked_at, version`,
        [randomUUID(), familyId, childId, deviceLabel],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.child_device_linked',
        subjectType: 'family_child_device',
        subjectId: device.rows[0].id,
      });
      const result = { device: familyDeviceView(device.rows[0]) };
      await this.completeIdempotencySlot(
        client,
        `family-child-device:register:${familyId}:${childId}`,
        idempotencyKey,
        result,
      );
      return result;
    });
  }

  async ingestDeviceTelemetry({
    principal,
    deviceId,
    batteryLevel,
    batteryStatus,
    locationLat,
    locationLng,
    locationLabel,
    correlationId,
  }) {
    return this.withTransaction(async (client) => {
      // A device UUID is opaque, but it is still never enough to write telemetry:
      // Phase 1 accepts only an active primary guardian until child-device
      // credentials and attestation have a separately reviewed capability.
      const located = await client.query(
        'SELECT id, family_id FROM family_child_devices WHERE id = $1 FOR UPDATE',
        [deviceId],
      );
      if (located.rowCount === 0) {
        throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
      }
      const familyId = located.rows[0].family_id;
      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const device = await client.query(
        `UPDATE family_child_devices
         SET battery_level = $2,
             battery_status = $3,
             location_lat = $4,
             location_lng = $5,
             location_label = $6,
             last_seen_at = NOW(),
             version = version + 1
         WHERE id = $1
         RETURNING id, child_id, device_label, battery_level, battery_status,
                   location_lat, location_lng, location_label, last_seen_at,
                   linked_at, version`,
        [deviceId, batteryLevel, batteryStatus, locationLat, locationLng, locationLabel],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.device_telemetry_received',
        subjectType: 'family_child_device',
        subjectId: deviceId,
      });
      return { device: familyDeviceView(device.rows[0]) };
    });
  }

  async createMembershipInvitation({ principal, familyId, role, targetSubject, idempotencyKey, requestHash, correlationId }) {
    try {
      return await this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `membership:create:${familyId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      if (targetSubject === principal.subject) {
        throw new HttpError(400, 'invalid_request', 'A guardian cannot invite the same account to its current family.');
      }
      const duplicate = await client.query(
        `SELECT id FROM family_memberships
         WHERE family_id = $1 AND target_subject = $2 AND status IN ('invited', 'active')`,
        [familyId, targetSubject],
      );
      if (duplicate.rowCount > 0) {
        throw new HttpError(409, 'membership_already_exists', 'This account already has an active or pending membership.');
      }

      const membershipId = randomUUID();
      const membership = await client.query(
        `INSERT INTO family_memberships
         (id, family_id, target_subject, role, status, invited_by_membership_id)
         VALUES ($1, $2, $3, $4, 'invited', $5)
         RETURNING id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at`,
        [membershipId, familyId, targetSubject, role, actor.id],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.membership_invited',
        subjectType: 'membership',
        subjectId: membershipId,
      });
      const result = { membership: memberView(membership.rows[0]) };
      await this.completeIdempotencySlot(client, `membership:create:${familyId}`, idempotencyKey, result);
      return result;
      });
    } catch (error) {
      // The partial unique index is the final authority under concurrent invitation requests.
      if (error?.code === '23505') {
        throw new HttpError(409, 'membership_already_exists', 'This account already has an active or pending membership.');
      }
      throw error;
    }
  }

  async acceptMembershipInvitation({ principal, familyId, membershipId, idempotencyKey, requestHash, correlationId }) {
    return this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `membership:accept:${membershipId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const membership = await client.query(
        `SELECT id, status, target_subject
         FROM family_memberships
         WHERE id = $1 AND family_id = $2
         FOR UPDATE`,
        [membershipId, familyId],
      );
      if (membership.rowCount === 0) {
        throw new HttpError(404, 'membership_not_found', 'Membership was not found.');
      }
      if (membership.rows[0].target_subject !== principal.subject) {
        throw new HttpError(403, 'membership_acceptance_denied', 'Only the invited account can accept this membership.');
      }
      const family = await client.query(
        'SELECT status FROM families WHERE id = $1 FOR UPDATE',
        [familyId],
      );
      if (family.rowCount === 0) {
        throw new HttpError(404, 'family_not_found', 'Family was not found.');
      }
      if (family.rows[0].status !== 'active') {
        throw new HttpError(409, 'family_not_active', 'This family is not active for membership acceptance.');
      }
      if (membership.rows[0].status !== 'invited') {
        throw new HttpError(409, 'membership_not_invitable', 'This membership is not awaiting acceptance.');
      }

      const account = await this.ensureAccount(client, principal.subject);
      const accepted = await client.query(
        `UPDATE family_memberships
         SET account_id = $3,
             status = 'active',
             status_reason_code = NULL,
             status_changed_at = NOW(),
             version = version + 1,
             joined_at = NOW()
         WHERE id = $1 AND family_id = $2
         RETURNING id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at`,
        [membershipId, familyId, account.id],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: membershipId,
        correlationId,
        eventType: 'family.membership_accepted',
        subjectType: 'membership',
        subjectId: membershipId,
      });
      const result = { membership: memberView(accepted.rows[0]) };
      await this.completeIdempotencySlot(client, `membership:accept:${membershipId}`, idempotencyKey, result);
      return result;
    });
  }

  async revokeMembership({ principal, familyId, membershipId, reasonCode, idempotencyKey, requestHash, correlationId }) {
    return this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `membership:revoke:${membershipId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const membership = await client.query(
        `SELECT id, role, status
         FROM family_memberships
         WHERE id = $1 AND family_id = $2
         FOR UPDATE`,
        [membershipId, familyId],
      );
      if (membership.rowCount === 0) {
        throw new HttpError(404, 'membership_not_found', 'Membership was not found.');
      }
      if (membership.rows[0].role === 'primary_guardian') {
        throw new HttpError(
          409,
          'primary_guardian_continuity_required',
          'Primary guardian removal requires the separate guardian continuity process.',
        );
      }
      if (!['invited', 'active'].includes(membership.rows[0].status)) {
        throw new HttpError(409, 'membership_not_revocable', 'This membership is not pending or active.');
      }

      const nextStatus = membership.rows[0].status === 'invited' ? 'revoked' : 'removed';
      const eventType = nextStatus === 'revoked'
        ? 'family.membership_invitation_revoked'
        : 'family.membership_removed';
      const revoked = await client.query(
        `UPDATE family_memberships
         SET status = $3,
             status_reason_code = $4,
             status_changed_at = NOW(),
             version = version + 1
         WHERE id = $1 AND family_id = $2
         RETURNING id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at`,
        [membershipId, familyId, nextStatus, reasonCode],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType,
        subjectType: 'membership',
        subjectId: membershipId,
      });
      const result = { membership: memberView(revoked.rows[0]) };
      await this.completeIdempotencySlot(client, `membership:revoke:${membershipId}`, idempotencyKey, result);
      return result;
    });
  }

  async createGuardianTransfer({ principal, familyId, candidateMembershipId, idempotencyKey, requestHash, correlationId }) {
    try {
      return await this.withTransaction(async (client) => {
        const response = await this.acquireIdempotencySlot(
          client,
          `guardian-transfer:create:${familyId}`,
          idempotencyKey,
          requestHash,
        );
        if (response) {
          return response;
        }

      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const primary = await this.lockedFamilyPrimary(client, familyId);
      if (primary.membership_id !== actor.id) {
        throw new HttpError(409, 'guardian_continuity_required', 'The active primary guardian has changed.');
      }
      const candidate = await client.query(
        `SELECT id, role, status
         FROM family_memberships
         WHERE id = $1 AND family_id = $2
         FOR UPDATE`,
        [candidateMembershipId, familyId],
      );
      if (candidate.rowCount === 0) {
        throw new HttpError(404, 'membership_not_found', 'Candidate membership was not found.');
      }
      if (candidate.rows[0].role !== 'co_guardian' || candidate.rows[0].status !== 'active') {
        throw new HttpError(
          409,
          'guardian_transfer_candidate_invalid',
          'Guardian transfer requires an active co-guardian membership.',
        );
      }

      const transfer = await client.query(
        `INSERT INTO guardian_continuity_cases
         (id, family_id, initiator_membership_id, candidate_membership_id, status, expires_at)
         VALUES ($1, $2, $3, $4, 'pending_acceptance', NOW() + ($5 * INTERVAL '1 hour'))
         RETURNING id, status, candidate_membership_id, expires_at, completed_at, cancelled_at, version, created_at`,
        [randomUUID(), familyId, actor.id, candidateMembershipId, this.guardianTransferTtlHours],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'guardian_transfer.requested',
        subjectType: 'guardian_continuity_case',
        subjectId: transfer.rows[0].id,
      });
      const result = { transfer: guardianTransferView(transfer.rows[0]) };
      await this.completeIdempotencySlot(client, `guardian-transfer:create:${familyId}`, idempotencyKey, result);
      return result;
      });
    } catch (error) {
      if (error?.code === '23505') {
        throw new HttpError(409, 'guardian_transfer_already_pending', 'A guardian transfer is already awaiting acceptance.');
      }
      throw error;
    }
  }

  async acceptGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash, correlationId }) {
    return this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `guardian-transfer:accept:${transferId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const transfer = await client.query(
        `SELECT id, family_id, initiator_membership_id, candidate_membership_id, status, expires_at,
                completed_at, cancelled_at, version, created_at
         FROM guardian_continuity_cases
         WHERE id = $1 AND family_id = $2
         FOR UPDATE`,
        [transferId, familyId],
      );
      if (transfer.rowCount === 0) {
        throw new HttpError(404, 'guardian_transfer_not_found', 'Guardian transfer was not found.');
      }
      const current = transfer.rows[0];
      if (current.status !== 'pending_acceptance') {
        throw new HttpError(409, 'guardian_transfer_not_actionable', 'Guardian transfer is no longer awaiting acceptance.');
      }
      // Lock family/primary before candidate to match create-transfer lock ordering and avoid a role-swap deadlock.
      const primary = await this.lockedFamilyPrimary(client, familyId);
      if (primary.membership_id !== current.initiator_membership_id) {
        throw new HttpError(409, 'guardian_continuity_required', 'The family primary guardian has changed.');
      }

      const candidate = await client.query(
        `SELECT membership.id, membership.role, membership.status
         FROM family_memberships AS membership
         INNER JOIN accounts AS account ON account.id = membership.account_id
         WHERE membership.id = $1
           AND membership.family_id = $2
           AND account.oidc_subject = $3
         FOR UPDATE OF membership, account`,
        [current.candidate_membership_id, familyId, principal.subject],
      );
      if (candidate.rowCount === 0) {
        throw new HttpError(
          403,
          'guardian_transfer_acceptance_denied',
          'Only the active nominated co-guardian can accept this transfer.',
        );
      }
      if (current.expires_at <= new Date()) {
        const expired = await client.query(
          `UPDATE guardian_continuity_cases
           SET status = 'expired', version = version + 1
           WHERE id = $1
           RETURNING id, status, candidate_membership_id, expires_at, completed_at, cancelled_at, version, created_at`,
          [transferId],
        );
        await this.appendAuditAndOutbox(client, {
          familyId,
          actorMembershipId: candidate.rows[0].id,
          correlationId,
          eventType: 'guardian_transfer.expired',
          subjectType: 'guardian_continuity_case',
          subjectId: transferId,
        });
        const result = { transfer: guardianTransferView(expired.rows[0]), expired: true };
        await this.completeIdempotencySlot(client, `guardian-transfer:accept:${transferId}`, idempotencyKey, result);
        return result;
      }
      if (candidate.rows[0].role !== 'co_guardian' || candidate.rows[0].status !== 'active') {
        throw new HttpError(
          409,
          'guardian_transfer_candidate_invalid',
          'The nominated guardian is no longer eligible to become primary guardian.',
        );
      }

      await client.query(
        `UPDATE family_memberships
         SET role = 'co_guardian', version = version + 1
         WHERE id = $1 AND family_id = $2`,
        [current.initiator_membership_id, familyId],
      );
      await client.query(
        `UPDATE family_memberships
         SET role = 'primary_guardian', version = version + 1
         WHERE id = $1 AND family_id = $2`,
        [current.candidate_membership_id, familyId],
      );
      await client.query(
        'UPDATE families SET primary_membership_id = $2 WHERE id = $1',
        [familyId, current.candidate_membership_id],
      );
      const completed = await client.query(
        `UPDATE guardian_continuity_cases
         SET status = 'completed', completed_at = NOW(), version = version + 1
         WHERE id = $1
         RETURNING id, status, candidate_membership_id, expires_at, completed_at, cancelled_at, version, created_at`,
        [transferId],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: current.candidate_membership_id,
        correlationId,
        eventType: 'guardian_transfer.completed',
        subjectType: 'guardian_continuity_case',
        subjectId: transferId,
      });
      const result = { transfer: guardianTransferView(completed.rows[0]) };
      await this.completeIdempotencySlot(client, `guardian-transfer:accept:${transferId}`, idempotencyKey, result);
      return result;
    });
  }

  async cancelGuardianTransfer({ principal, familyId, transferId, idempotencyKey, requestHash, correlationId }) {
    return this.withTransaction(async (client) => {
      const response = await this.acquireIdempotencySlot(
        client,
        `guardian-transfer:cancel:${transferId}`,
        idempotencyKey,
        requestHash,
      );
      if (response) {
        return response;
      }

      const actor = await this.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const transfer = await client.query(
        `SELECT id, initiator_membership_id, status, expires_at
         FROM guardian_continuity_cases
         WHERE id = $1 AND family_id = $2
         FOR UPDATE`,
        [transferId, familyId],
      );
      if (transfer.rowCount === 0) {
        throw new HttpError(404, 'guardian_transfer_not_found', 'Guardian transfer was not found.');
      }
      if (transfer.rows[0].initiator_membership_id !== actor.id) {
        throw new HttpError(403, 'guardian_transfer_cancellation_denied', 'Only the initiating primary guardian can cancel this transfer.');
      }
      if (transfer.rows[0].status !== 'pending_acceptance') {
        throw new HttpError(409, 'guardian_transfer_not_actionable', 'Guardian transfer is no longer awaiting acceptance.');
      }

      const cancelled = await client.query(
        `UPDATE guardian_continuity_cases
         SET status = 'cancelled', cancelled_at = NOW(), version = version + 1
         WHERE id = $1
         RETURNING id, status, candidate_membership_id, expires_at, completed_at, cancelled_at, version, created_at`,
        [transferId],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'guardian_transfer.cancelled',
        subjectType: 'guardian_continuity_case',
        subjectId: transferId,
      });
      const result = { transfer: guardianTransferView(cancelled.rows[0]) };
      await this.completeIdempotencySlot(client, `guardian-transfer:cancel:${transferId}`, idempotencyKey, result);
      return result;
    });
  }

  async listAuditEvents({ principal, familyId }) {
    return this.withTransaction(async (client) => {
      const actor = await this.activeActorMembership(client, familyId, principal.subject);
      if (actor.role === 'child') {
        throw new HttpError(403, 'audit_access_denied', 'Child memberships cannot view family audit events.');
      }
      const events = await client.query(
        `SELECT id, event_type, actor_membership_id, correlation_id, subject_type, subject_id, occurred_at
         FROM family_audit_events
         WHERE family_id = $1
         ORDER BY occurred_at DESC
         LIMIT 100`,
        [familyId],
      );
      return { events: events.rows.map(auditView) };
    });
  }
}
