// Push registrations: which guardian handset can be nudged, and how to reach it.
//
// A registration is a device token that Firebase issued to the app, tied to one guardian's
// membership in one family. Only guardians register (a child's handset is a paired device with
// no membership and receives no nudges). The room is still the permission: a nudge goes only to
// active guardian members of the thread that received a message, never to anyone else.
//
// A nudge is content-free (see fcm-sender.js). When it cannot be delivered, the failure is logged
// by class only, and the message itself is never affected: sending is not allowed to fail
// because a notification did not go out.

import { ChatError, postgresFamilyChatPort } from './family-chat.js';

const TOKEN_PATTERN = /^[A-Za-z0-9:_-]{32,4096}$/;
const PLATFORMS = new Set(['android', 'ios']);
const LOCALES = new Set(['ar', 'en']);

function requireObject(body, allowed, message) {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    throw new ChatError(400, 'invalid_request', message);
  }
  for (const key of Object.keys(body)) {
    if (!allowed.has(key)) throw new ChatError(400, 'invalid_request', `Unknown field: ${key}.`);
  }
}

function requirePushToken(value) {
  if (typeof value !== 'string' || !TOKEN_PATTERN.test(value)) {
    throw new ChatError(400, 'invalid_push_token', 'The device token is not in the expected format.');
  }
  return value;
}

function requireRegistrationBody(body) {
  requireObject(body, new Set(['token', 'platform', 'locale']), 'The registration must be a JSON object.');
  const token = requirePushToken(body.token);
  if (!PLATFORMS.has(body.platform)) {
    throw new ChatError(400, 'invalid_request', 'platform must be android or ios.');
  }
  if (!LOCALES.has(body.locale)) {
    throw new ChatError(400, 'invalid_request', 'locale must be ar or en.');
  }
  return { token, platform: body.platform, locale: body.locale };
}

function requireCurrentTokenBody(body) {
  requireObject(body, new Set(['token']), 'The current-device revocation must be a JSON object.');
  return { token: requirePushToken(body.token) };
}

/**
 * @param {object} options
 * @param {object} options.store            the Postgres foundation store
 * @param {Function} options.credentialMatches
 * @param {{ send: Function }} options.sender  an FcmSender (or any object with the same send)
 */
export function pushRegistrationsFor(store, { credentialMatches, sender }) {
  const port = postgresFamilyChatPort(store, { credentialMatches });

  async function guardianMembership(client, { principal, familyId }) {
    // Guardians only. The device path is refused before any row is written.
    const { participant } = await port.resolveParticipant(client, {
      principal,
      deviceId: null,
      deviceCredential: null,
      familyId,
    });
    if (participant?.kind !== 'membership') {
      throw new ChatError(403, 'push_guardian_only', 'Only a guardian can register this device for notifications.');
    }
    return participant.id;
  }

  async function requireGuardianIdentity(client, principal) {
    const subject = principal?.subject;
    if (typeof subject !== 'string' || subject.trim().length === 0) {
      throw new ChatError(403, 'push_guardian_only', 'Only a guardian can remove device notifications.');
    }
    // Permit a former guardian to clean up their device after family access has been revoked.
    // Invited-only memberships do not prove prior guardian access.
    const { rowCount } = await client.query(
      `SELECT 1 FROM family_memberships
        WHERE target_subject = $1
          AND role IN ('primary_guardian', 'co_guardian')
          AND status IN ('active', 'removed', 'revoked')
        LIMIT 1`,
      [subject],
    );
    if (rowCount === 0) {
      throw new ChatError(403, 'push_guardian_only', 'Only a guardian can remove device notifications.');
    }
    return subject;
  }

  return {
    /**
     * An explicit registration is authorized by the caller's guardian membership in this family,
     * not by token possession alone. The authenticated guardian can bind this shared handset to
     * their family; legacy DELETE remains owner-scoped and cannot be used to remove a foreign row.
     */
    async register({ principal, familyId, body }) {
      const input = requireRegistrationBody(body);
      return port.transact(async (client) => {
        const membershipId = await guardianMembership(client, { principal, familyId });
        // A token names one handset. If it was registered before, it moves to the latest guardian
        // who signed in on it, so an old owner never receives this handset's nudges.
        const { rows } = await client.query(
          `INSERT INTO family_push_registrations (family_id, membership_id, token, platform, locale)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (token) DO UPDATE
             SET family_id = EXCLUDED.family_id,
                 membership_id = EXCLUDED.membership_id,
                 device_id = NULL,
                 platform = EXCLUDED.platform,
                 locale = EXCLUDED.locale,
                 updated_at = now()
           RETURNING id, platform, locale, (xmax = 0) AS created`,
          [familyId, membershipId, input.token, input.platform, input.locale],
        );
        const row = rows[0];
        return {
          created: row.created === true,
          registration: { id: row.id, platform: row.platform, locale: row.locale },
        };
      });
    },

    /** Removes one of the caller's own registrations. Another guardian's id reads as not found. */
    async unregister({ principal, familyId, registrationId }) {
      return port.transact(async (client) => {
        const membershipId = await guardianMembership(client, { principal, familyId });
        const { rowCount } = await client.query(
          `DELETE FROM family_push_registrations
            WHERE id = $1 AND family_id = $2 AND membership_id = $3`,
          [registrationId, familyId, membershipId],
        );
        // This is deliberately idempotent for both absent and foreign-owned UUIDs. Returning
        // the same response prevents this endpoint from becoming a registration-existence oracle.
        return { deleted: true };
      });
    },

    /**
     * Legacy cleanup lacks the registration UUID, so the exact FCM token selects a candidate row;
     * it is not authorization. Delete only when the authenticated current/former guardian owns
     * the row through its recorded membership. A guardian from another account/family is a
     * uniform no-op, indistinguishable from an absent token. If FCM rotated the token, this
     * request also cannot identify the older row. An explicit registration POST is the separate,
     * authorized path that may move a shared handset to the newly signed-in guardian.
     */
    async unregisterCurrentToken({ principal, body }) {
      const { token } = requireCurrentTokenBody(body);
      return port.transact(async (client) => {
        const subject = await requireGuardianIdentity(client, principal);
        await client.query(
          `DELETE FROM family_push_registrations AS registration
            USING family_memberships AS membership
            WHERE registration.token = $1
              AND membership.id = registration.membership_id
              AND membership.family_id = registration.family_id
              AND membership.target_subject = $2
              AND membership.role IN ('primary_guardian', 'co_guardian')
              AND membership.status IN ('active', 'removed', 'revoked')`,
          [token, subject],
        );
        return { deleted: true };
      });
    },

    /**
     * Nudges the other active guardians in a thread after a message was sent. The family comes
     * from the thread, so a child's message is covered too. The author is never nudged.
     */
    async notifyNewMessage({ messageId, threadId, authorKind, authorId }) {
      const targets = await store.withTransaction(async (client) => {
        // Claim the message before anything is sent. A message already claimed is not nudged again.
        const claimed = await client.query(
          'INSERT INTO family_push_nudges (message_id) VALUES ($1) ON CONFLICT (message_id) DO NOTHING RETURNING message_id',
          [messageId],
        );
        if (claimed.rowCount === 0) return null;
        const { rows } = await client.query(
          `SELECT r.id, r.token, r.locale
             FROM family_chat_threads t
             JOIN family_chat_thread_members m
               ON m.thread_id = t.id AND m.participant_kind = 'membership'
             JOIN family_memberships fm
               ON fm.id = m.participant_id AND fm.family_id = t.family_id AND fm.status = 'active'
             JOIN family_push_registrations r
               ON r.membership_id = fm.id AND r.family_id = t.family_id
            WHERE t.id = $1
              AND NOT (m.participant_kind = $2::text AND m.participant_id = $3::uuid)`,
          [threadId, authorKind, authorId],
        );
        return rows;
      });
      const outcome = { sent: 0, removed: 0, failed: 0, alreadyNudged: targets === null };
      if (targets === null) return outcome;
      for (const target of targets) {
        try {
          const result = await sender.send({
            token: target.token,
            locale: target.locale,
            data: { type: 'chat.message', threadId },
          });
          if (result === 'unregistered') {
            await store.withTransaction((client) =>
              client.query('DELETE FROM family_push_registrations WHERE id = $1', [target.id]),
            );
            outcome.removed += 1;
          } else {
            outcome.sent += 1;
          }
        } catch (error) {
          outcome.failed += 1;
          // Class only: the message can carry provider detail, and never content.
          console.error(JSON.stringify({ severity: 'error', event: 'push_nudge_failed', errorName: error?.name ?? 'Error' }));
        }
      }
      return outcome;
    },
  };
}
