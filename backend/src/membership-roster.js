import { HttpError } from './http-error.js';

/**
 * The guardian-facing roster of a family's memberships, as one read operation.
 *
 * Why this exists: the family write path - invite, accept, revoke - has been live for a
 * while, and no read returned who the members ARE from the caller's point of view. The
 * family envelope (`GET /v1/families/{familyId}`) lists roles and statuses, but it cannot
 * say which row is the caller: `memberView` has no principal to compare against, and the
 * subject that would identify the caller is deliberately absent from that response.
 *
 * So the Family Members screen had to invent membership from a local projection, which is
 * the defect this module closes. `isSelf` is decided HERE, on the server, against the
 * authenticated principal - never by the client guessing from an account id that the
 * server never promised to use as a subject.
 *
 * The rules live in this module and nowhere else:
 *
 *   1. Only an active member of the family may read its roster. The store's own membership
 *      lookup enforces it; a denied caller reads the envelope rule from the same place
 *      every other read does.
 *   2. A membership is the caller's own when its subject matches the caller's subject, in
 *      any status. An invitation that is still pending and belongs to the caller is the
 *      one row the caller must be able to recognise - it is the offer waiting for them.
 *   3. The response carries no subject. The guardian does not need the invitee's OIDC
 *      subject to run a family, and returning it would put a durable identifier for a
 *      person on a screen with no use for it.
 *
 * Same isolation reasoning as device revocation: this reaches the database through the
 * Foundation store's published transaction and membership helpers rather than adding a
 * method to a file a parallel session edits, so the read surface costs one route line in
 * `app.js` and nothing else.
 */

/** Machine reason codes for an invitation that is no longer waiting. */
export const MEMBERSHIP_STATUSES = Object.freeze(['invited', 'active', 'revoked', 'removed']);

const ROSTER_ORDER = Object.freeze([
  'active',
  'invited',
  'revoked',
  'removed',
]);

/**
 * Builds the roster read over a data port.
 *
 * Port shape, all of it data access and none of it rules:
 *
 *   authorize(tx, { familyId, subject })                 -> { id } membership
 *   readMemberships(tx, { familyId, subject })           -> raw rows, oldest first
 *
 * `tx` is whatever the adapter passes; this operation never inspects it.
 */
export function createMembershipRoster({ port }) {
  return async function listFamilyMemberships({ principal, familyId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const rows = await port.readMemberships(tx, { familyId, subject: principal.subject });
      return {
        memberships: rows
          .map((row) => membershipView(row, principal.subject))
          .sort(compareMemberships),
      };
    });
  };
}

/** A row, narrowed to what a guardian can act on, with self decided server-side. */
function membershipView(row, subject) {
  const status = row.status;
  if (!MEMBERSHIP_STATUSES.includes(status)) {
    // A status this server does not know is not a status the client may interpret. The
    // roster drops it rather than rendering a guessed label for a real person.
    throw new HttpError(500, 'membership_status_unknown', 'A membership carries an unknown status.');
  }
  return Object.freeze({
    id: row.id,
    role: row.role,
    status,
    statusReasonCode: row.status_reason_code ?? null,
    version: row.version,
    joinedAt: row.joined_at ?? null,
    statusChangedAt: row.status_changed_at ?? null,
    createdAt: row.created_at,
    isSelf: row.target_subject === subject,
  });
}

/**
 * Active first, then invitations waiting, then what was cut off. Within a group the oldest
 * membership leads, so a roster that has not changed never reorders itself between reads.
 */
function compareMemberships(left, right) {
  const rank = ROSTER_ORDER.indexOf(left.status) - ROSTER_ORDER.indexOf(right.status);
  if (rank !== 0) return rank;
  const leftTime = Date.parse(left.createdAt ?? '') || 0;
  const rightTime = Date.parse(right.createdAt ?? '') || 0;
  if (leftTime !== rightTime) return leftTime - rightTime;
  return String(left.id).localeCompare(String(right.id));
}

/**
 * The production port: real SQL through the Foundation store's own transaction and
 * membership helpers. Nothing here decides anything - the visibility rule is the store's,
 * and the meaning of `isSelf` is the operation's above.
 */
export function postgresMembershipRosterPort(store) {
  return {
    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async authorize(client, { familyId, subject }) {
      // Any active membership may read the roster - the same rule the family envelope
      // applies. Reading who is in your family is not a privileged act; changing it is.
      return store.activeActorMembership(client, familyId, subject);
    },

    async readMemberships(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, role, status, status_reason_code, version,
                joined_at, status_changed_at, created_at, target_subject
           FROM family_memberships
          WHERE family_id = $1
          ORDER BY created_at ASC, id ASC`,
        [familyId],
      );
      return rows;
    },
  };
}

/** Builds the read operation for a server that was handed a Foundation store. */
export function membershipRosterFor(store) {
  return createMembershipRoster({ port: postgresMembershipRosterPort(store) });
}
