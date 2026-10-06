import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

/**
 * The safe zones a family draws around the places that matter, as one read and one write.
 *
 * Why this exists: the client has had a full geometry model (circle and polygon, both
 * first-class) and a zone screen for a while, and none of it reached a server. A zone
 * lived in one handset's local store, which means the mother could draw a boundary the
 * father never saw and no arrival could ever be detected, because detection needs a shared
 * truth about where the boundary is.
 *
 * Three rules live here and nowhere else:
 *
 *   1. READING a zone is open to every active member of the family, including a child. A
 *      boundary a person lives inside is not privileged information about them - it is the
 *      opposite: the transparency this surface promises starts with the shape being
 *      visible to everyone it applies to.
 *
 *   2. WRITING one is the guardians' act, and deliberately narrower than the read. The
 *      membership row answers "may you see this family"; this module answers "may you
 *      decide where its children are expected to be", and a child membership may not.
 *
 *   3. A zone is never assigned to nobody. The assignment is explicit and non-empty, and
 *      the children named must belong to this family. A zone that reads like protection
 *      and evaluates like nothing at all is the exact defect this rule prevents.
 *
 * Same isolation reasoning as the membership roster and device revocation: this reaches the
 * database through the Foundation store's published transaction, membership, idempotency
 * and audit helpers rather than adding methods to a file a parallel session edits, so the
 * whole surface costs route lines in `app.js` and nothing else.
 */

export const ZONE_GEOMETRY_KINDS = Object.freeze(['CIRCLE', 'POLYGON']);

/**
 * Builds the zone read over a data port.
 *
 * Port shape, all of it data access and none of it rules:
 *
 *   withTransaction(run)
 *   authorize(tx, { familyId, subject })                -> { id, role } active membership
 *   readZones(tx, { familyId })                         -> zone rows, oldest first
 *   readZoneChildren(tx, { zoneIds })                   -> { zone_id, child_id } rows
 */
export function createSafeZoneList({ port }) {
  return async function listFamilySafeZones({ principal, familyId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const [zones, assignments] = await Promise.all([
        port.readZones(tx, { familyId }),
        port.readZoneChildren(tx, { familyId }),
      ]);
      const byZone = new Map();
      for (const row of assignments) {
        const list = byZone.get(row.zone_id) ?? [];
        list.push(row.child_id);
        byZone.set(row.zone_id, list);
      }
      return {
        zones: zones.map((zone) => safeZoneView(zone, byZone.get(zone.id) ?? [])),
      };
    });
  };
}

/**
 * Builds the zone write over a data port.
 *
 * Port shape adds:
 *
 *   idempotent(scope, key, requestHash, work)           -> replays a stored result
 *   readFamilyChildren(tx, { familyId, childIds })      -> child rows that exist here
 *   insertZone(tx, { zone, actorMembershipId })         -> raw row
 *   assignChildren(tx, { zoneId, familyId, childIds })
 *   audit(tx, { familyId, actorMembershipId, correlationId, subjectId, eventType })
 */
export function createSafeZoneCreate({ port }) {
  return async function createFamilySafeZone({
    principal,
    familyId,
    name,
    emoji,
    geometry,
    childIds,
    alertEnter,
    alertExit,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `safe-zone:create:${familyId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        if (actor.role === 'child') {
          throw new HttpError(
            403,
            'safe_zone_guardian_required',
            'A safe zone is defined by a guardian of the family.',
          );
        }

        const children = await port.readFamilyChildren(tx, { familyId, childIds });
        if (children.length !== childIds.length) {
          // Named, not silently dropped: assigning a zone to a child who is not here would
          // either fail on a foreign key or, worse, succeed against another family.
          throw new HttpError(404, 'child_not_found', 'A child named for this zone was not found in the family.');
        }

        const zone = await port.insertZone(tx, {
          zone: {
            id: randomUUID(),
            familyId,
            name,
            emoji,
            geometry,
            alertEnter,
            alertExit,
          },
          actorMembershipId: actor.id,
        });
        await port.assignChildren(tx, { zoneId: zone.id, familyId, childIds });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: zone.id,
          eventType: 'family.safe_zone_created',
        });

        return { zone: safeZoneView(zone, childIds) };
      },
    );
  };
}

/**
 * The wire form of a zone.
 *
 * `version` travels with the geometry because a crossing is a fact about the shape as it
 * stood at that moment. A family that widens a zone tomorrow must not re-describe an
 * arrival that already happened yesterday.
 */
export function safeZoneView(row, childIds) {
  return Object.freeze({
    id: row.id,
    name: row.name,
    emoji: row.emoji,
    geometry: geometryView(row),
    childIds: Object.freeze([...childIds]),
    alertEnter: row.alert_enter,
    alertExit: row.alert_exit,
    version: row.version,
    archivedAt: row.archived_at ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  });
}

function geometryView(row) {
  const version = row.version;
  if (row.geometry_kind === 'CIRCLE') {
    return Object.freeze({
      kind: 'CIRCLE',
      version,
      center: Object.freeze({ latitude: row.center_lat, longitude: row.center_lng }),
      radiusMeters: row.radius_meters,
    });
  }
  return Object.freeze({
    kind: 'POLYGON',
    version,
    vertices: Object.freeze(
      (row.vertices ?? []).map((vertex) =>
        Object.freeze({ latitude: vertex.latitude, longitude: vertex.longitude }),
      ),
    ),
  });
}

/**
 * The production port: real SQL through the Foundation store's own transaction, membership,
 * idempotency and audit helpers. Nothing here decides anything.
 */
export function postgresSafeZonePort(store) {
  return {
    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async idempotent(scope, key, requestHash, work) {
      return store.withTransaction(async (client) => {
        const replay = await store.acquireIdempotencySlot(client, scope, key, requestHash);
        if (replay) return replay;
        const result = await work(client);
        await store.completeIdempotencySlot(client, scope, key, result);
        return result;
      });
    },

    async authorize(client, { familyId, subject }) {
      return store.activeActorMembership(client, familyId, subject);
    },

    async readZones(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, name, emoji, geometry_kind, center_lat, center_lng, radius_meters,
                vertices, alert_enter, alert_exit, version, created_at, updated_at, archived_at
           FROM family_safe_zones
          WHERE family_id = $1 AND archived_at IS NULL
          ORDER BY created_at ASC, id ASC`,
        [familyId],
      );
      return rows;
    },

    async readZoneChildren(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT zone_id, child_id
           FROM family_safe_zone_children
          WHERE family_id = $1
          ORDER BY assigned_at ASC, child_id ASC`,
        [familyId],
      );
      return rows;
    },

    async readFamilyChildren(client, { familyId, childIds }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = ANY($2::uuid[])`,
        [familyId, childIds],
      );
      return rows;
    },

    async insertZone(client, { zone, actorMembershipId }) {
      const circle = zone.geometry.kind === 'CIRCLE';
      const { rows } = await client.query(
        `INSERT INTO family_safe_zones
           (id, family_id, name, emoji, geometry_kind, center_lat, center_lng, radius_meters,
            vertices, alert_enter, alert_exit, created_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11, $12)
         RETURNING id, name, emoji, geometry_kind, center_lat, center_lng, radius_meters,
                   vertices, alert_enter, alert_exit, version, created_at, updated_at, archived_at`,
        [
          zone.id,
          zone.familyId,
          zone.name,
          zone.emoji,
          zone.geometry.kind,
          circle ? zone.geometry.center.latitude : null,
          circle ? zone.geometry.center.longitude : null,
          circle ? zone.geometry.radiusMeters : null,
          circle ? null : JSON.stringify(zone.geometry.vertices),
          zone.alertEnter,
          zone.alertExit,
          actorMembershipId,
        ],
      );
      return rows[0];
    },

    async assignChildren(client, { zoneId, familyId, childIds }) {
      await client.query(
        `INSERT INTO family_safe_zone_children (zone_id, family_id, child_id)
         SELECT $1, $2, unnest($3::uuid[])`,
        [zoneId, familyId, childIds],
      );
    },

    async audit(client, { familyId, actorMembershipId, correlationId, subjectId, eventType }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        eventType,
        subjectType: 'safe_zone',
        subjectId,
      });
    },
  };
}

/** Builds both operations for a server that was handed a Foundation store. */
export function safeZonesFor(store) {
  const port = postgresSafeZonePort(store);
  return {
    list: createSafeZoneList({ port }),
    create: createSafeZoneCreate({ port }),
  };
}
