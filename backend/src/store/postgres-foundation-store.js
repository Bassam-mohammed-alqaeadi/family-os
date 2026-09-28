import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { HttpError } from '../http-error.js';

const { Pool } = pg;

function memberView(row) {
  return {
    id: row.id,
    role: row.role,
    status: row.status,
    joinedAt: row.joined_at,
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

function auditView(row) {
  return {
    id: row.id,
    eventType: row.event_type,
    actorMembershipId: row.actor_membership_id,
    subjectType: row.subject_type,
    subjectId: row.subject_id,
    occurredAt: row.occurred_at,
  };
}

export class PostgresFoundationStore {
  configured = true;

  constructor({ connectionString }) {
    this.pool = new Pool({ connectionString, max: 10, idleTimeoutMillis: 10_000 });
  }

  async close() {
    await this.pool.end();
  }

  async health() {
    try {
      await this.pool.query('SELECT 1');
      return { available: true };
    } catch {
      return { available: false, reason: 'database_unavailable' };
    }
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

  async appendAuditAndOutbox(client, { familyId, actorMembershipId, eventType, subjectType, subjectId }) {
    const auditId = randomUUID();
    await client.query(
      `INSERT INTO family_audit_events
       (id, family_id, actor_membership_id, event_type, subject_type, subject_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [auditId, familyId, actorMembershipId, eventType, subjectType, subjectId],
    );
    await client.query(
      `INSERT INTO outbox_events
       (id, aggregate_type, aggregate_id, event_type, payload)
       VALUES ($1, 'family', $2, $3, $4::jsonb)`,
      [randomUUID(), familyId, eventType, JSON.stringify({ auditEventId: auditId, subjectType, subjectId })],
    );
  }

  async activeActorMembership(client, familyId, subject, { primaryGuardianOnly = false } = {}) {
    const roleClause = primaryGuardianOnly ? `AND membership.role = 'primary_guardian'` : '';
    const { rows } = await client.query(
      `SELECT membership.id, membership.role
       FROM family_memberships AS membership
       INNER JOIN accounts AS account ON account.id = membership.account_id
       WHERE membership.family_id = $1
         AND account.oidc_subject = $2
         AND membership.status = 'active'
         ${roleClause}`,
      [familyId, subject],
    );
    if (rows.length === 0) {
      throw new HttpError(403, 'family_access_denied', 'The authenticated account has no permitted family membership.');
    }
    return rows[0];
  }

  async createFamily({ principal, displayName, idempotencyKey, requestHash }) {
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
         RETURNING id, role, status, joined_at, created_at`,
        [membershipId, familyId, account.id, principal.subject],
      );
      await client.query('UPDATE families SET primary_membership_id = $2 WHERE id = $1', [familyId, membershipId]);
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: membershipId,
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
        `SELECT id, role, status, joined_at, created_at
         FROM family_memberships
         WHERE family_id = $1
         ORDER BY created_at ASC`,
        [familyId],
      );
      return { family: familyView(family.rows[0], memberships.rows.map(memberView)) };
    });
  }

  async createMembershipInvitation({ principal, familyId, role, targetSubject, idempotencyKey, requestHash }) {
    return this.withTransaction(async (client) => {
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
         RETURNING id, role, status, joined_at, created_at`,
        [membershipId, familyId, targetSubject, role, actor.id],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        eventType: 'family.membership_invited',
        subjectType: 'membership',
        subjectId: membershipId,
      });
      const result = { membership: memberView(membership.rows[0]) };
      await this.completeIdempotencySlot(client, `membership:create:${familyId}`, idempotencyKey, result);
      return result;
    });
  }

  async acceptMembershipInvitation({ principal, familyId, membershipId, idempotencyKey, requestHash }) {
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
      if (membership.rows[0].status !== 'invited') {
        throw new HttpError(409, 'membership_not_invitable', 'This membership is not awaiting acceptance.');
      }

      const account = await this.ensureAccount(client, principal.subject);
      const accepted = await client.query(
        `UPDATE family_memberships
         SET account_id = $3, status = 'active', joined_at = NOW()
         WHERE id = $1 AND family_id = $2
         RETURNING id, role, status, joined_at, created_at`,
        [membershipId, familyId, account.id],
      );
      await this.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: membershipId,
        eventType: 'family.membership_accepted',
        subjectType: 'membership',
        subjectId: membershipId,
      });
      const result = { membership: memberView(accepted.rows[0]) };
      await this.completeIdempotencySlot(client, `membership:accept:${membershipId}`, idempotencyKey, result);
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
        `SELECT id, event_type, actor_membership_id, subject_type, subject_id, occurred_at
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
