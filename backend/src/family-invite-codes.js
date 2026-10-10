import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';
import { INVITE_CODE_ALPHABET, INVITE_CODE_LENGTH } from './validation.js';

/**
 * Family invites by code (owner decision 2026-10-10).
 *
 * The membership invitation that already exists asks the guardian for the invitee's OIDC
 * subject, and nothing in the product can tell a guardian that identifier - so no screen
 * could ever issue a real invitation. A code turns the flow around:
 *
 *   1. A primary guardian issues a code for one role. The server draws it from a
 *      cryptographic source, returns it once, and keeps only its SHA-256 digest.
 *   2. The guardian shares it however the family talks (read aloud, a message).
 *   3. The invitee, signed in with their own account, redeems it. The membership is bound
 *      to the subject of the verified token at that moment - never to an identifier a
 *      client typed - and becomes active in the same transaction that spends the code.
 *
 * The rules live here and only here:
 *   - only an active primary guardian issues or revokes a code;
 *   - a code is single-use, expires (24 hours by default), and a family holds at most
 *     a handful of open codes at once;
 *   - a redemption refusal never says whether the code existed, expired or was spent: one
 *     answer for all three, so the endpoint is not an oracle for guessing;
 *   - an account that already belongs to the family cannot spend a code on it, and the
 *     code stays open for the person it was meant for;
 *   - an issued code is never replayed: a retried issue answers 409 instead of revealing
 *     the code a second time (the same law device pairing codes follow).
 *
 * Data access goes through the Foundation store's published transaction, idempotency,
 * account and audit helpers - the same arrangement every surface since device revocation
 * uses - so this costs route lines in `app.js` and nothing inside the shared store file.
 */

export const INVITE_CODE_TTL_MS = 24 * 60 * 60 * 1000;
export const MAX_OPEN_INVITE_CODES_PER_FAMILY = 5;

/** The digest the database stores. The raw code never leaves this module except once, to the issuer. */
export function inviteCodeDigest(normalizedCode) {
  return createHash('sha256').update(`family-invite-code:v1:${normalizedCode}`).digest('hex');
}

/**
 * A uniformly random code over the 31-letter alphabet (~49.5 bits for ten letters).
 * Rejection sampling keeps every letter equally likely: bytes at or above the largest
 * multiple of the alphabet size are discarded rather than folded with a modulo bias.
 */
export function newInviteCode(random = randomBytes) {
  const size = INVITE_CODE_ALPHABET.length;
  const ceiling = Math.floor(256 / size) * size;
  let code = '';
  while (code.length < INVITE_CODE_LENGTH) {
    for (const byte of random(INVITE_CODE_LENGTH * 2)) {
      if (byte >= ceiling) continue;
      code += INVITE_CODE_ALPHABET[byte % size];
      if (code.length === INVITE_CODE_LENGTH) break;
    }
  }
  return code;
}

/** `ABCDEFGHJK` -> `ABCDE-FGHJK`: the shape a person reads aloud and the shape the screen shows. */
export function displayInviteCode(code) {
  return `${code.slice(0, 5)}-${code.slice(5)}`;
}

function inviteView(row) {
  return {
    id: row.id,
    role: row.role,
    status: row.status,
    expiresAt: row.expires_at,
    createdAt: row.created_at,
  };
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

const NOT_REDEEMABLE = () => new HttpError(
  404,
  'invite_code_not_redeemable',
  'This invite code is invalid, expired, or already used.',
);

export function createFamilyInviteCodes(store, {
  ttlMs = INVITE_CODE_TTL_MS,
  maxOpenPerFamily = MAX_OPEN_INVITE_CODES_PER_FAMILY,
  generateCode = newInviteCode,
} = {}) {
  async function issue({ principal, familyId, role, idempotencyKey, requestHash, correlationId }) {
    return store.withTransaction(async (client) => {
      const actor = await store.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const scope = `family-invite-code:issue:${familyId}`;
      const replay = await store.acquireIdempotencySlot(client, scope, idempotencyKey, requestHash);
      if (replay) {
        // The raw code is intentionally never stored in idempotency_records, so a network
        // retry cannot reveal it a second time.
        throw new HttpError(409, 'invite_code_not_replayable', 'An invite code was already issued. Issue a new code.');
      }

      // One issuer at a time per family, so the open-code ceiling cannot be raced past.
      await client.query('SELECT id FROM families WHERE id = $1 FOR UPDATE', [familyId]);
      const open = await client.query(
        `SELECT COUNT(*)::int AS open_count
           FROM family_invite_codes
          WHERE family_id = $1 AND status = 'open' AND expires_at > NOW()`,
        [familyId],
      );
      if (open.rows[0].open_count >= maxOpenPerFamily) {
        throw new HttpError(
          409,
          'invite_code_limit_reached',
          'This family already has the maximum number of open invite codes. Revoke one first.',
        );
      }

      const code = generateCode();
      const inserted = await client.query(
        `INSERT INTO family_invite_codes
           (id, family_id, role, code_hash, status, created_by_membership_id, expires_at)
         VALUES ($1, $2, $3, $4, 'open', $5, NOW() + ($6::bigint * INTERVAL '1 millisecond'))
         RETURNING id, role, status, expires_at, created_at`,
        [randomUUID(), familyId, role, inviteCodeDigest(code), actor.id, ttlMs],
      );
      const invite = inserted.rows[0];
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.invite_code_issued',
        subjectType: 'family_invite_code',
        subjectId: invite.id,
      });
      await store.completeIdempotencySlot(client, scope, idempotencyKey, {
        invite: { id: invite.id, issued: true },
      });
      return { invite: { ...inviteView(invite), code: displayInviteCode(code) } };
    });
  }

  async function revoke({ principal, familyId, inviteId, idempotencyKey, requestHash, correlationId }) {
    return store.withTransaction(async (client) => {
      const scope = `family-invite-code:revoke:${inviteId}`;
      const replay = await store.acquireIdempotencySlot(client, scope, idempotencyKey, requestHash);
      if (replay) return replay;

      const actor = await store.activeActorMembership(client, familyId, principal.subject, { primaryGuardianOnly: true });
      const found = await client.query(
        `SELECT id, status, expires_at <= NOW() AS expired
           FROM family_invite_codes
          WHERE id = $1 AND family_id = $2
          FOR UPDATE`,
        [inviteId, familyId],
      );
      if (found.rowCount === 0) {
        throw new HttpError(404, 'invite_code_not_found', 'Invite code was not found in this family.');
      }
      if (found.rows[0].status !== 'open') {
        throw new HttpError(409, 'invite_code_not_revocable', 'This invite code was already used or revoked.');
      }
      // An expired code is revoked all the same: the guardian asked for it to be dead, and
      // a dead code that says so is more honest than a refusal about a code nobody can use.
      const revoked = await client.query(
        `UPDATE family_invite_codes
            SET status = 'revoked', revoked_at = NOW(), revoked_by_membership_id = $3
          WHERE id = $1 AND family_id = $2
          RETURNING id, role, status, expires_at, created_at`,
        [inviteId, familyId, actor.id],
      );
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        eventType: 'family.invite_code_revoked',
        subjectType: 'family_invite_code',
        subjectId: inviteId,
      });
      const result = { invite: inviteView(revoked.rows[0]) };
      await store.completeIdempotencySlot(client, scope, idempotencyKey, result);
      return result;
    });
  }

  async function redeem({ principal, code, idempotencyKey, requestHash, correlationId }) {
    try {
      return await store.withTransaction(async (client) => {
        const scope = `family-invite-code:redeem:${principal.subject}`;
        const replay = await store.acquireIdempotencySlot(client, scope, idempotencyKey, requestHash);
        if (replay) return replay;

        const found = await client.query(
          `SELECT invite.id, invite.family_id, invite.role, invite.created_by_membership_id,
                  family.display_name, family.status AS family_status
             FROM family_invite_codes AS invite
             INNER JOIN families AS family ON family.id = invite.family_id
            WHERE invite.code_hash = $1
              AND invite.status = 'open'
              AND invite.expires_at > NOW()
            FOR UPDATE OF invite, family`,
          [inviteCodeDigest(code)],
        );
        if (found.rowCount === 0 || found.rows[0].family_status !== 'active') {
          throw NOT_REDEEMABLE();
        }
        const invite = found.rows[0];

        const existing = await client.query(
          `SELECT id FROM family_memberships
            WHERE family_id = $1 AND target_subject = $2 AND status IN ('invited', 'active')`,
          [invite.family_id, principal.subject],
        );
        if (existing.rowCount > 0) {
          // The code stays open: it was meant for someone who is not in the family yet.
          throw new HttpError(409, 'membership_already_exists', 'This account already belongs to this family.');
        }

        const account = await store.ensureAccount(client, principal.subject);
        const membershipId = randomUUID();
        const membership = await client.query(
          `INSERT INTO family_memberships
             (id, family_id, account_id, target_subject, role, status, invited_by_membership_id, joined_at)
           VALUES ($1, $2, $3, $4, $5, 'active', $6, NOW())
           RETURNING id, role, status, status_reason_code, version, joined_at, status_changed_at, created_at`,
          [membershipId, invite.family_id, account.id, principal.subject, invite.role, invite.created_by_membership_id],
        );
        await client.query(
          `UPDATE family_invite_codes
              SET status = 'redeemed', redeemed_at = NOW(), redeemed_membership_id = $2
            WHERE id = $1`,
          [invite.id, membershipId],
        );
        await store.appendAuditAndOutbox(client, {
          familyId: invite.family_id,
          actorMembershipId: membershipId,
          correlationId,
          eventType: 'family.invite_code_redeemed',
          subjectType: 'membership',
          subjectId: membershipId,
        });
        const result = {
          family: { id: invite.family_id, displayName: invite.display_name },
          membership: memberView(membership.rows[0]),
        };
        await store.completeIdempotencySlot(client, scope, idempotencyKey, result);
        return result;
      });
    } catch (error) {
      // The partial unique indexes are the final authority when two redemptions race.
      if (error?.code === '23505') {
        throw new HttpError(409, 'membership_already_exists', 'This account already belongs to this family.');
      }
      throw error;
    }
  }

  return Object.freeze({ issue, revoke, redeem });
}

export function familyInviteCodesFor(store, options) {
  return createFamilyInviteCodes(store, options);
}
