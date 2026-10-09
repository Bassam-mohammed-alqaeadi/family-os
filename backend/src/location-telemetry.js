import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

/**
 * Where a child's device has been, and the boundaries it crossed.
 *
 * Three operations, one authority, and one rule that everything else follows from:
 * **the server decides what happened, and the log is the only memory of it.**
 *
 *   ingestFix        one reported position, evaluated against the zones it belongs to
 *   familyLocation   the live picture a family reads - children, devices, and where each
 *                    child stands relative to each zone
 *   geofenceEvents   the crossings themselves, newest first, for the arrival feed
 *
 * The evaluation rule, stated plainly because it is the part that would be easy to get
 * wrong in a way nobody notices:
 *
 *   * A fix is judged against the zones ASSIGNED TO THAT CHILD, as they stand now, and the
 *     geometry version is recorded with the crossing.
 *   * Whether the child was inside is derived from the LAST crossing of that (child, zone)
 *     pair - there is no `inside` column anywhere, because a stored copy of a derived fact
 *     is a second version of the truth waiting to disagree with the first.
 *   * The FIRST fix that places a child inside a zone records a BASELINE crossing and
 *     announces nothing. "We had never looked before" is not "she just arrived", and a
 *     family woken at 03:00 because a zone was drawn while the child slept would rightly
 *     stop trusting the alerts.
 *   * A fix OLDER than the newest fix already stored for that child is kept in the trail
 *     but is NOT evaluated. A late retry from a handset that was underground must not
 *     replay history in the wrong order and flip the world backwards.
 *   * A replayed fix - same Idempotency-Key, or the same fix id under a new key - produces
 *     no second row and no second crossing. That is what makes an arrival alert
 *     exactly-once, and it is enforced by the primary key, not by a check that races.
 *
 * Retention: a fix older than `LOCATION_RETENTION_DAYS` is deleted inside the same
 * transaction that stores a new one for the same family, through an index built for it.
 * The history is bounded by construction rather than by a job someone must remember to run.
 * Crossings are the safety record and are not pruned here, and neither is the one sample
 * that produced a crossing: an event whose measurement has been deleted is an event nobody
 * can check.
 */

/** How long a trail sample is kept. Enforced on every write, per family. */
export const LOCATION_RETENTION_DAYS = 30;

/**
 * How long ago a device may have reported and still count as live. Deliberately generous:
 * a child's phone in a pocket with the screen off reports less often than a driving app,
 * and calling that "offline" would teach a family to ignore the word.
 */
export const LOCATION_LIVENESS_WINDOW_MS = 30 * 60 * 1000;

const MAX_FEED_EVENTS = 100;

/// How much of a child's trail one read may return. The window is the retention window; the
/// bound is there so a busy week cannot turn one screen into an unbounded response.
const MAX_HISTORY_FIXES = 500;

/// The same shape the store requires of an internal trace context.
const CORRELATION_ID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function createLocationSurface({ port, now = () => new Date() }) {
  /**
   * One reported fix: stored, evaluated, and answered with what the server concluded.
   *
   * The response is the server's own account of the fix - including whether it was
   * evaluated at all - so a device does not have to assume that its report was accepted.
   */
  async function ingestFix({
    principal,
    deviceCredential,
    deviceId,
    fix,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `location:fix:${deviceId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const device = await port.readReportingDevice(tx, { deviceId });
        if (device === null) {
          throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
        }

        if (deviceCredential != null) {
          // The child's handset proves itself with the credential it was issued once. It
          // does not need an account, and it may not speak for a device it does not hold.
          if (
            device.credential_revoked_at != null ||
            !port.credentialMatches(device.credential_hash, deviceCredential)
          ) {
            throw new HttpError(
              401,
              'invalid_device_credential',
              'The device credential is invalid or revoked.',
            );
          }
        } else {
          // The transitional support path, identical to the existing telemetry route: a
          // primary guardian may report on behalf of a device while native collection is
          // still being finished, and the audit record says a person did it.
          if (!principal) {
            throw new HttpError(
              401,
              'authentication_required',
              'A device credential or bearer token is required.',
            );
          }
          await port.authorize(tx, {
            familyId: device.family_id,
            subject: principal.subject,
            primaryGuardianOnly: true,
          });
        }

        const { row, replayed } = await port.insertFix(tx, {
          familyId: device.family_id,
          childId: device.child_id,
          deviceId,
          fix,
        });

        if (replayed) {
          // The same fix, sent twice. The crossings it produced are already facts; this
          // answer reports them rather than producing them again.
          const recorded = await port.readCrossingsForFix(tx, { fixId: row.id });
          return {
            fix: fixView(row),
            evaluated: false,
            reason: 'duplicate',
            crossings: recorded,
            replayed: true,
          };
        }

        const newest = await port.readNewestFixTime(tx, {
          familyId: device.family_id,
          childId: device.child_id,
          excludingFixId: row.id,
        });
        const outOfOrder =
          newest !== null && new Date(row.recorded_at).getTime() < newest.getTime();

        const crossings = [];
        let evaluation = 'evaluated';
        if (outOfOrder) {
          evaluation = 'stored_out_of_order';
        } else if (row.location_lat === null || row.location_lng === null) {
          // No usable position: there is nothing to place relative to a boundary. Saying
          // "evaluated" here would be the same lie as a fix that pretends to a location.
          evaluation = 'no_coordinates';
        } else {
          const zones = await port.readAssignedZones(tx, {
            familyId: device.family_id,
            childId: device.child_id,
          });
          for (const zone of zones) {
            const inside = port.containsPoint(zone, {
              latitude: row.location_lat,
              longitude: row.location_lng,
            });
            const previous = await port.readLastCrossing(tx, {
              zoneId: zone.id,
              childId: device.child_id,
            });
            const wasInside = previous !== null && previous.kind === 'ENTER';
            if (inside === wasInside) continue;

            const kind = inside ? 'ENTER' : 'EXIT';
            const baseline = previous === null;
            const alerts = kind === 'ENTER' ? zone.alert_enter : zone.alert_exit;
            const notified = alerts && !baseline;

            await port.insertCrossing(tx, {
              zoneId: zone.id,
              familyId: device.family_id,
              childId: device.child_id,
              deviceId,
              fixId: row.id,
              kind,
              baseline,
              zoneVersion: zone.version,
              occurredAt: row.recorded_at,
            });
            await port.audit(tx, {
              familyId: device.family_id,
              actorMembershipId: null,
              correlationId,
              subjectId: zone.id,
              subjectType: 'safe_zone',
              eventType: kind === 'ENTER' ? 'family.geofence_entered' : 'family.geofence_exited',
            });
            if (notified) {
              // The payload a delivery worker would hand to a notification is written here,
              // in the same transaction as the crossing, so a family is never told about a
              // crossing that was rolled back and never misses one that committed.
              await port.notify(tx, {
                familyId: device.family_id,
                zoneId: zone.id,
                zoneName: zone.name,
                childId: device.child_id,
                deviceId,
                fixId: row.id,
                kind,
                zoneVersion: zone.version,
                occurredAt: row.recorded_at,
                correlationId,
              });
            }
            crossings.push({
              zoneId: zone.id,
              kind,
              baseline,
              notified,
              zoneVersion: zone.version,
            });
          }
        }

        await port.audit(tx, {
          familyId: device.family_id,
          actorMembershipId: null,
          correlationId,
          subjectId: row.id,
          subjectType: 'location_fix',
          eventType: 'family.location_fix_recorded',
        });
        const pruned = await port.pruneFixes(tx, {
          familyId: device.family_id,
          before: new Date(now().getTime() - LOCATION_RETENTION_DAYS * 24 * 60 * 60 * 1000),
        });

        return {
          fix: fixView(row),
          evaluated: evaluation === 'evaluated',
          reason: evaluation,
          crossings,
          replayed: false,
          pruned,
        };
      },
    );
  }

  /**
   * The trail a family can actually read back.
   *
   * Same rule as the live picture, for the same reason: one read, one rule for every active
   * member. A history only the parents can open would be the covert half of the same
   * surface - the child could see where she is now and not what was kept about her, which
   * is precisely the asymmetry that turns "safety" into surveillance.
   *
   * The newest fix comes first, and a fix with no coordinates is returned with `null`
   * coordinates rather than a zero: an `acquiring` answer is a fact about the device, and
   * it must not be drawn as a position in the Gulf of Guinea.
   */
  async function locationHistory({ principal, familyId, childId, limit }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const child = await port.readChild(tx, { familyId, childId });
      if (child === null) {
        throw new HttpError(404, 'family_child_not_found', 'Child was not found in this family.');
      }
      const rows = await port.readTrail(tx, {
        familyId,
        childId,
        limit: limit ?? MAX_HISTORY_FIXES,
      });
      return {
        visibility: 'family_members',
        childId: child.child_id,
        displayName: child.display_name,
        retentionDays: LOCATION_RETENTION_DAYS,
        fixes: rows.map(fixView),
      };
    });
  }

  /**
   * The family's live picture.
   *
   * Readable by EVERY active member of the family, including a child - the same rows, in
   * the same shape. That is not a convenience: it is the promise. A surface where the
   * parent sees where the child is and the child cannot see that tracking is on is the
   * covert-tracking pattern this product refuses to absorb, and the cheapest way to
   * guarantee it never creeps in is to have one read with one rule.
   */
  async function familyLocation({ principal, familyId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const children = await port.readFamilyLocation(tx, { familyId });
      const at = now();
      return {
        visibility: 'family_members',
        observedAt: at.toISOString(),
        children: children.map((child) => ({
          childId: child.childId,
          displayName: child.displayName,
          devices: child.devices.map((device) => ({
            deviceId: device.deviceId,
            deviceLabel: device.deviceLabel,
            state: livenessOf(device.lastFixAt, at),
            lastFix: device.lastFix,
          })),
          zones: child.zones,
        })),
      };
    });
  }

  /** The arrival and departure feed, newest first. Same visibility rule as the live read. */
  async function geofenceEvents({ principal, familyId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const rows = await port.readRecentCrossings(tx, { familyId, limit: MAX_FEED_EVENTS });
      return {
        visibility: 'family_members',
        events: rows.map((row) => ({
          id: row.id,
          zoneId: row.zone_id,
          zoneName: row.zone_name,
          childId: row.child_id,
          kind: row.kind,
          baseline: row.baseline,
          zoneVersion: row.zone_version,
          occurredAt: row.occurred_at,
        })),
      };
    });
  }

  return { ingestFix, familyLocation, geofenceEvents, locationHistory };
}

/**
 * How a device's reporting reads to a family.
 *
 * `silent` and `never` are different answers and are kept different: a device that used to
 * report and stopped is a fact worth acting on, and a device that has never reported is a
 * device that may simply not be set up yet. Collapsing them into "no location" would hide
 * the one that matters.
 */
function livenessOf(lastFixAt, at) {
  if (lastFixAt === null) return 'never';
  const age = at.getTime() - new Date(lastFixAt).getTime();
  return age <= LOCATION_LIVENESS_WINDOW_MS ? 'live' : 'silent';
}

/** The wire form of a stored fix. Coordinates are absent, not zero, when none exist. */
function fixView(row) {
  return Object.freeze({
    id: row.id,
    acquisition: row.acquisition,
    latitude: row.location_lat,
    longitude: row.location_lng,
    accuracyMeters: row.accuracy_meters,
    integritySoftWarning: row.integrity_soft_warning,
    recordedAt: row.recorded_at,
    receivedAt: row.received_at,
  });
}

/**
 * The production port: real SQL through the Foundation store's own transaction, membership
 * and idempotency helpers.
 *
 * The geometry is evaluated HERE, in the server, and not in the database. That is a
 * deliberate choice: a point-in-circle test is a Haversine comparison and a point-in-polygon
 * test is ray casting, both of which are exact for the zone sizes a family draws, and
 * neither of which needs a spatial extension this deployment would then have to carry. The
 * authority is this module; the client has its own evaluator only so it can draw a preview
 * before a fix leaves the handset, and it never emits an event.
 */
export function postgresLocationPort(store, { credentialMatches }) {
  return {
    credentialMatches,

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

    async authorize(client, { familyId, subject, primaryGuardianOnly = false }) {
      return store.activeActorMembership(client, familyId, subject, { primaryGuardianOnly });
    },

    async readReportingDevice(client, { deviceId }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, device_label, credential_hash, credential_revoked_at
           FROM family_child_devices
          WHERE id = $1
          FOR UPDATE`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    async insertFix(client, { familyId, childId, deviceId, fix }) {
      const { rows } = await client.query(
        `INSERT INTO family_child_location_fixes
           (id, family_id, child_id, device_id, acquisition, location_lat, location_lng,
            accuracy_meters, integrity_soft_warning, recorded_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (id) DO NOTHING
         RETURNING id, acquisition, location_lat, location_lng, accuracy_meters,
                   integrity_soft_warning, recorded_at, received_at`,
        [
          fix.fixId,
          familyId,
          childId,
          deviceId,
          fix.acquisition,
          fix.latitude,
          fix.longitude,
          fix.accuracyMeters,
          fix.integritySoftWarning,
          fix.recordedAt,
        ],
      );
      if (rows.length > 0) return { row: rows[0], replayed: false };

      // The id is already taken. Either this device is repeating a report under a fresh
      // key, or another device is claiming an id that is not its own - and the second one
      // is a conflict worth refusing rather than answering with someone else's position.
      const existing = await client.query(
        `SELECT id, family_id, child_id, device_id, acquisition, location_lat, location_lng,
                accuracy_meters, integrity_soft_warning, recorded_at, received_at
           FROM family_child_location_fixes
          WHERE id = $1`,
        [fix.fixId],
      );
      const row = existing.rows[0];
      if (row.family_id !== familyId || row.child_id !== childId || row.device_id !== deviceId) {
        throw new HttpError(
          409,
          'location_fix_conflict',
          'This fix identifier already belongs to another report.',
        );
      }
      return { row, replayed: true };
    },

    async readNewestFixTime(client, { familyId, childId, excludingFixId }) {
      const { rows } = await client.query(
        `SELECT max(recorded_at) AS newest
           FROM family_child_location_fixes
          WHERE family_id = $1 AND child_id = $2 AND id <> $3`,
        [familyId, childId, excludingFixId],
      );
      return rows[0]?.newest ? new Date(rows[0].newest) : null;
    },

    async readAssignedZones(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT zone.id, zone.name, zone.geometry_kind, zone.center_lat, zone.center_lng,
                zone.radius_meters, zone.vertices, zone.alert_enter, zone.alert_exit,
                zone.version
           FROM family_safe_zones AS zone
           INNER JOIN family_safe_zone_children AS assignment
             ON assignment.zone_id = zone.id AND assignment.family_id = zone.family_id
          WHERE zone.family_id = $1
            AND assignment.child_id = $2
            AND zone.archived_at IS NULL
          ORDER BY zone.created_at ASC, zone.id ASC`,
        [familyId, childId],
      );
      return rows;
    },

    async readLastCrossing(client, { zoneId, childId }) {
      const { rows } = await client.query(
        `SELECT kind, baseline, occurred_at
           FROM family_geofence_events
          WHERE zone_id = $1 AND child_id = $2
          ORDER BY occurred_at DESC, created_at DESC, id DESC
          LIMIT 1`,
        [zoneId, childId],
      );
      return rows[0] ?? null;
    },

    async insertCrossing(client, {
      zoneId,
      familyId,
      childId,
      deviceId,
      fixId,
      kind,
      baseline,
      zoneVersion,
      occurredAt,
    }) {
      await client.query(
        `INSERT INTO family_geofence_events
           (id, family_id, zone_id, child_id, device_id, fix_id, kind, baseline, zone_version, occurred_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [randomUUID(), familyId, zoneId, childId, deviceId, fixId, kind, baseline, zoneVersion, occurredAt],
      );
    },

    async readCrossingsForFix(client, { fixId }) {
      const { rows } = await client.query(
        `SELECT zone_id, kind, baseline, zone_version
           FROM family_geofence_events
          WHERE fix_id = $1
          ORDER BY created_at ASC, id ASC`,
        [fixId],
      );
      return rows.map((row) => ({
        zoneId: row.zone_id,
        kind: row.kind,
        baseline: row.baseline,
        notified: false,
        zoneVersion: row.zone_version,
      }));
    },

    async pruneFixes(client, { familyId, before }) {
      // The trail is bounded; the safety record is not. A sample that produced a crossing
      // stays with it, because the crossing's provenance is the whole reason a family can
      // trust an arrival alert - and deleting the measurement an event points at would
      // leave the event asserting something nobody can check.
      //
      // The same rule covers the emergency surface (W4): a press may point at the sample
      // that was the child's last known position, and an alarm whose measurement has been
      // pruned is an alarm nobody can check afterwards. The reference is what makes the
      // fix evidence, so the fix outlives the retention window the moment an incident
      // names it.
      const { rowCount } = await client.query(
        `DELETE FROM family_child_location_fixes AS fix
          WHERE fix.family_id = $1
            AND fix.recorded_at < $2
            AND NOT EXISTS (
              SELECT 1 FROM family_geofence_events AS event WHERE event.fix_id = fix.id
            )
            AND NOT EXISTS (
              SELECT 1 FROM family_sos_alerts AS alert WHERE alert.fix_id = fix.id
            )`,
        [familyId, before],
      );
      return rowCount ?? 0;
    },

    /**
     * The audit row for a location fact, and deliberately NOT an outbox row.
     *
     * The store's shared helper writes both, because every change it was written for is
     * also something the family is told about. That is not true here: a position report is
     * a fact, and only a crossing the zone's own flags ask to announce is an announcement.
     * Routing a fix through the shared helper would put every reported position into the
     * delivery queue and make "we told them" mean nothing.
     *
     * The correlation id is checked against the same shape the store checks, because a
     * surface that writes its own audit rows must not become the one place a trace context
     * goes in unverified.
     */
    async audit(client, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      if (typeof correlationId !== 'string' || !CORRELATION_ID_PATTERN.test(correlationId)) {
        throw new HttpError(
          500,
          'correlation_context_missing',
          'A required internal trace context is unavailable.',
        );
      }
      await client.query(
        `INSERT INTO family_audit_events
           (id, family_id, actor_membership_id, correlation_id, event_type, subject_type, subject_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [randomUUID(), familyId, actorMembershipId, correlationId, eventType, subjectType, subjectId],
      );
    },

    async notify(client, {
      familyId,
      zoneId,
      zoneName,
      childId,
      deviceId,
      fixId,
      kind,
      zoneVersion,
      occurredAt,
      correlationId,
    }) {
      // The same outbox the rest of the Foundation writes to, with a payload that carries
      // everything a delivery worker needs to phrase the alert - so the alert is never a
      // second interpretation of the event.
      await client.query(
        `INSERT INTO outbox_events
           (id, aggregate_type, aggregate_id, correlation_id, event_type, payload)
         VALUES ($1, 'family', $2, $3, $4, $5::jsonb)`,
        [
          randomUUID(),
          familyId,
          correlationId,
          kind === 'ENTER' ? 'family.geofence_entered' : 'family.geofence_exited',
          JSON.stringify({
            zoneId,
            zoneName,
            childId,
            deviceId,
            fixId,
            kind,
            zoneVersion,
            occurredAt,
          }),
        ],
      );
    },

    async readFamilyLocation(client, { familyId }) {
      // One query for the children and their devices, one for the newest fix per device,
      // one for where each child stands relative to each zone. The zone state is derived
      // from the crossing log, never from a stored flag.
      const [children, devices, latest, zoneState, zoneNames] = await Promise.all([
        client.query(
          `SELECT id, display_name, avatar_emoji FROM family_children WHERE family_id = $1 ORDER BY created_at ASC, id ASC`,
          [familyId],
        ),
        client.query(
          `SELECT id, child_id, device_label FROM family_child_devices
            WHERE family_id = $1 AND credential_revoked_at IS NULL
            ORDER BY linked_at ASC, id ASC`,
          [familyId],
        ),
        client.query(
          `SELECT DISTINCT ON (device_id)
                  device_id, id, acquisition, location_lat, location_lng, accuracy_meters,
                  integrity_soft_warning, recorded_at, received_at
             FROM family_child_location_fixes
            WHERE family_id = $1
            ORDER BY device_id, recorded_at DESC, id DESC`,
          [familyId],
        ),
        client.query(
          `SELECT DISTINCT ON (event.child_id, event.zone_id)
                  event.child_id, event.zone_id, event.kind, event.baseline
             FROM family_geofence_events AS event
            WHERE event.family_id = $1
            ORDER BY event.child_id, event.zone_id, event.occurred_at DESC, event.created_at DESC`,
          [familyId],
        ),
        client.query(
          `SELECT id, name FROM family_safe_zones WHERE family_id = $1 AND archived_at IS NULL`,
          [familyId],
        ),
      ]);

      const fixByDevice = new Map(latest.rows.map((row) => [row.device_id, row]));
      const nameByZone = new Map(zoneNames.rows.map((row) => [row.id, row.name]));
      const stateByChildZone = new Map(
        zoneState.rows.map((row) => [`${row.child_id}:${row.zone_id}`, row]),
      );

      return children.rows.map((child) => {
        const childDevices = devices.rows.filter((device) => device.child_id === child.id);
        const zones = [];
        for (const [key, row] of stateByChildZone) {
          if (!key.startsWith(`${child.id}:`)) continue;
          zones.push({
            zoneId: row.zone_id,
            name: nameByZone.get(row.zone_id) ?? null,
            inside: row.kind === 'ENTER',
            // A baseline says the state is known but no crossing was ever observed.
            observedCrossing: !row.baseline,
          });
        }
        return {
          childId: child.id,
          displayName: child.display_name,
          devices: childDevices.map((device) => {
            const fix = fixByDevice.get(device.id) ?? null;
            return {
              deviceId: device.id,
              deviceLabel: device.device_label,
              lastFixAt: fix?.recorded_at ?? null,
              lastFix: fix === null ? null : fixView(fix),
            };
          }),
          zones: zones
            .filter((zone) => zone.name !== null)
            .sort((left, right) => String(left.name).localeCompare(String(right.name))),
        };
      });
    },

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id AS child_id, display_name
           FROM family_children
          WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readTrail(client, { familyId, childId, limit }) {
      const { rows } = await client.query(
        `SELECT id, acquisition, location_lat, location_lng, accuracy_meters,
                integrity_soft_warning, recorded_at, received_at
           FROM family_child_location_fixes
          WHERE family_id = $1 AND child_id = $2
          ORDER BY recorded_at DESC, received_at DESC, id DESC
          LIMIT $3`,
        [familyId, childId, limit],
      );
      return rows;
    },

    async readRecentCrossings(client, { familyId, limit }) {
      const { rows } = await client.query(
        `SELECT event.id, event.zone_id, zone.name AS zone_name, event.child_id, event.kind,
                event.baseline, event.zone_version, event.occurred_at
           FROM family_geofence_events AS event
           INNER JOIN family_safe_zones AS zone ON zone.id = event.zone_id
          WHERE event.family_id = $1
          ORDER BY event.occurred_at DESC, event.created_at DESC, event.id DESC
          LIMIT $2`,
        [familyId, limit],
      );
      return rows;
    },

    /**
     * Whether a point lies inside a zone, decided here and only here.
     *
     * Circle: the great-circle distance against the radius.
     * Polygon: ray casting on the ordered ring, which is exact for the simple shapes a
     * family draws and is the same algorithm the client uses for its preview.
     */
    containsPoint(zone, point) {
      if (zone.geometry_kind === 'CIRCLE') {
        return distanceMeters(zone.center_lat, zone.center_lng, point.latitude, point.longitude) <= Number(zone.radius_meters);
      }
      const vertices = Array.isArray(zone.vertices) ? zone.vertices : [];
      if (vertices.length < 3) return false;
      let inside = false;
      for (let index = 0, previous = vertices.length - 1; index < vertices.length; previous = index++) {
        const current = vertices[index];
        const before = vertices[previous];
        const intersects =
          (current.latitude > point.latitude) !== (before.latitude > point.latitude) &&
          point.longitude <
            ((before.longitude - current.longitude) * (point.latitude - current.latitude)) /
              (before.latitude - current.latitude || 1e-12) +
              current.longitude;
        if (intersects) inside = !inside;
      }
      return inside;
    },
  };
}

/** Great-circle distance in meters. */
export function distanceMeters(lat1, lng1, lat2, lng2) {
  const earthRadiusM = 6371000;
  const toRad = (degrees) => (degrees * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return earthRadiusM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Builds the surface for a server that was handed a Foundation store. */
export function locationSurfaceFor(store, { credentialMatches }) {
  return createLocationSurface({ port: postgresLocationPort(store, { credentialMatches }) });
}
