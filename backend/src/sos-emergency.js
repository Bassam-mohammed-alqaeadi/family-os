import { randomUUID } from 'node:crypto';
import { HttpError } from './http-error.js';

/**
 * The family's emergency surface: the child's button, the ladder it climbs, and the
 * record of what each recipient was actually told.
 *
 * Why this exists at all, in one paragraph: the button has been on the child's screen for
 * a while and the thing behind it always succeeded. That is the worst shape a safety
 * feature can have - a parent who believes an alarm left the handset will stop checking,
 * and the day it mattered nobody was coming. This module replaces "it worked" with what
 * the server actually did, in states a screen can render without flattering anyone.
 *
 * Four rules live here, and nowhere else:
 *
 *   1. ONE INCIDENT PER CHILD. Pressing twice, or pressing while an alert is already in
 *      flight, does not open a second incident: the second press is answered with the
 *      incident that exists. Two open alerts for one child would split the family's
 *      attention across two screens at the moment attention is the whole product.
 *
 *   2. THE PICTURE IS HONEST. Whatever position the device had when the button was
 *      pressed is stored as it was stated - including "acquiring" and "unavailable",
 *      which carry no coordinates at all. The screen shows the difference between "we
 *      know where she is" and "we have not been able to look", which is the difference
 *      between a rescue and a search.
 *
 *   3. DELIVERY IS NEVER OVERSTATED. There is no push transport and no SMS transport in
 *      this repository, so a delivery row is either `recorded` (a durable payload was
 *      written for the in-app pipe to pick up) or `not_configured` (there is nothing to
 *      send it on, and the row carries the reason). `delivered` is not a value this
 *      server can write, and the database refuses it by CHECK. A guardian told "sent"
 *      when nobody sent anything has been actively misled.
 *
 *   4. EVERY ACTIVE MEMBER READS. The child whose incident it is sees what the family
 *      sees: the same alert, the same recipients, the same delivery states. Selective
 *      visibility is how a safety product quietly becomes a surveillance product, and
 *      this company's promise is that it never does that - starting with the person the
 *      button belongs to.
 *
 * Authorization, precisely:
 *
 *   read (list / one)     every active membership of the family, child role included
 *   raise for a child     guardians. A child membership may not open an incident for
 *                         another child, and the device credential path covers its own
 *                         child only - the handset is the proof, not a parameter.
 *   acknowledge / escalate / resolve   guardians. A child membership cannot act here
 *                         because this schema has no link from a membership to a child
 *                         row, so "is this your incident?" cannot be answered - and a
 *                         refusal is the only honest answer available. The child's own
 *                         device CAN close its own incident, and only as a false alarm.
 *   ladder management     guardians. Only a `verified` contact ever escalates, which is
 *                         the same hard-skip law the client's SosEscalationResolver
 *                         already enforces; holding it here too means a client bug cannot
 *                         ring a stranger.
 */

export const SOS_LOCATION_CLASSES = Object.freeze([
  'ready',
  'acquiring',
  'stale_last_known',
  'unavailable',
]);

export const SOS_CONNECTION_CLASSES = Object.freeze([
  'online',
  'degraded',
  'offline',
]);

export const SOS_TERMINAL_REASONS = Object.freeze([
  'helped',
  'false_alarm',
  'other',
]);

export const SOS_OPEN_STATUSES = Object.freeze([
  'active',
  'acknowledged',
  'escalating',
]);

export const SOS_BACKUP_VERIFICATIONS = Object.freeze([
  'unverified',
  'verified',
  'revoked',
]);

/** A ladder with more rungs than this is not a ladder anyone answers. */
export const MAX_BACKUP_CONTACTS = 8;

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);

function requireGuardian(actor, code, message) {
  if (!GUARDIAN_ROLES.has(actor.role)) {
    throw new HttpError(403, code, message);
  }
}

/**
 * Builds the raise operation over a data port.
 *
 * Port shape, all of it data access and none of it rules:
 *
 *   withTransaction(run)
 *   idempotent(scope, key, requestHash, work)
 *   authorize(tx, { familyId, subject })                -> { id, role } active membership
 *   readReportingDevice(tx, { deviceId })               -> device row or null
 *   credentialMatches(hash, credential)                 -> boolean
 *   readChild(tx, { familyId, childId })                -> child row or null
 *   readOpenAlertForChild(tx, { childId, forUpdate })   -> raw alert row or null
 *   readGuardians(tx, { familyId })                     -> active guardian memberships
 *   insertAlert(tx, { alert })                          -> raw alert row
 *   insertDeliveries(tx, { alertId, familyId, rows })
 *   readDeliveries(tx, { alertIds })                    -> delivery rows
 *   audit(tx, { familyId, actorMembershipId, correlationId, subjectId, eventType })
 */
export function createSosAlertFire({ port, now = () => new Date() }) {
  return async function fireFamilySosAlert({
    principal,
    deviceCredential,
    deviceId,
    familyId,
    childId,
    picture,
    fixId,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `sos:fire:${deviceId ?? childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        let resolvedFamilyId = familyId ?? null;
        let resolvedChildId = childId ?? null;
        let raiserMembershipId = null;
        let actorMembershipId = null;
        // Who raised it is derived from which door the press came through, never from a
        // parameter: a handset cannot claim a guardian raised it, and a guardian cannot
        // claim the child's device did.
        let kind;

        if (deviceId != null) {
          const device = await port.readReportingDevice(tx, { deviceId });
          if (device === null) {
            throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
          }
          if (deviceCredential != null) {
            // The child's handset proves itself with the credential it was issued once.
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
            // The transitional support path, identical to location ingestion: a primary
            // guardian may report on behalf of a device while native collection is still
            // being finished, and the audit record names the person who did it.
            if (!principal) {
              throw new HttpError(
                401,
                'authentication_required',
                'A device credential or bearer token is required.',
              );
            }
            const actor = await port.authorize(tx, {
              familyId: device.family_id,
              subject: principal.subject,
            });
            requireGuardian(
              actor,
              'sos_raise_forbidden',
              'Only a guardian may report an alarm on behalf of a device.',
            );
            actorMembershipId = actor.id;
          }
          resolvedFamilyId = device.family_id;
          resolvedChildId = device.child_id;
          kind = 'child_device';
        } else {
          const actor = await port.authorize(tx, { familyId, subject: principal.subject });
          requireGuardian(
            actor,
            'sos_raise_forbidden',
            'Only a guardian may open an incident for a child.',
          );
          actorMembershipId = actor.id;
          raiserMembershipId = actor.id;
          kind = 'guardian';
        }

        const child = await port.readChild(tx, {
          familyId: resolvedFamilyId,
          childId: resolvedChildId,
        });
        if (child === null) {
          throw new HttpError(
            404,
            'family_child_not_found',
            'The child was not found in this family.',
          );
        }

        if (fixId != null) {
          const fix = await port.readFixOwnership(tx, {
            familyId: resolvedFamilyId,
            childId: resolvedChildId,
            fixId,
          });
          if (fix === null) {
            throw new HttpError(
              404,
              'location_fix_not_found',
              'The position this alarm points at was not found for this child.',
            );
          }
        }

        const existing = await port.readOpenAlertForChild(tx, { childId: resolvedChildId });
        if (existing !== null) {
          // Not an error the child made: the incident they already have is the answer.
          throw new HttpError(
            409,
            'sos_alert_already_open',
            'This child already has an open incident.',
            { alertId: existing.id, status: existing.status },
          );
        }

        const pressedAt = picture.pressedAt ?? now();
        const alert = {
          id: randomUUID(),
          familyId: resolvedFamilyId,
          childId: resolvedChildId,
          raisedByKind: kind,
          raisedByMembershipId: raiserMembershipId,
          pressedAt,
          status: 'active',
          locationClass: picture.locationClass,
          latitude: picture.latitude,
          longitude: picture.longitude,
          accuracyMeters: picture.accuracyMeters,
          connectionClass: picture.connectionClass,
          batteryPercent: picture.batteryPercent,
          placeLabel: picture.placeLabel,
          panicQuiet: picture.panicQuiet,
          fixId,
        };
        const row = await port.insertAlert(tx, { alert });

        // Rung 1 of the ladder is the family's guardians, and they are derived from the
        // roster rather than from the request: an alarm that names its own recipients is
        // an alarm that can be pointed away from the people responsible for answering it.
        const guardians = await port.readGuardians(tx, { familyId: resolvedFamilyId });
        const deliveries = [
          ...guardians.map((guardian) => ({
            id: randomUUID(),
            recipientKind: 'guardian',
            recipientMembershipId: guardian.id,
            recipientContactId: null,
            channel: 'in_app',
            deliveryState: 'recorded',
            reasonCode: null,
          })),
          ...guardians.map((guardian) => ({
            id: randomUUID(),
            recipientKind: 'guardian',
            recipientMembershipId: guardian.id,
            recipientContactId: null,
            channel: 'push',
            deliveryState: 'not_configured',
            reasonCode: 'push_transport_absent',
          })),
        ];
        await port.insertDeliveries(tx, {
          alertId: row.id,
          familyId: resolvedFamilyId,
          rows: deliveries,
        });

        await port.audit(tx, {
          familyId: resolvedFamilyId,
          actorMembershipId,
          correlationId,
          subjectId: row.id,
          subjectType: 'sos_alert',
          eventType: 'family.sos_alert_raised',
        });

        // The answer reports the rows that were actually stored, not the ones this
        // function intended to store: a view built from intentions is how a delivery
        // state ends up on a screen that the database never held.
        const stored = await port.readDeliveries(tx, { alertIds: [row.id] });
        return {
          alert: sosAlertView(row, stored),
          replayed: false,
        };
      },
    );
  };
}

/**
 * Builds the family read: every incident this family has, newest first.
 *
 * Port shape adds `readAlerts(tx, { familyId, statuses })`.
 */
export function createSosAlertList({ port }) {
  return async function listFamilySosAlerts({ principal, familyId, status = 'open' }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const statuses =
        status === 'all'
          ? ['active', 'acknowledged', 'escalating', 'resolved']
          : status === 'resolved'
            ? ['resolved']
            : [...SOS_OPEN_STATUSES];
      const rows = await port.readAlerts(tx, { familyId, statuses });
      const deliveries = await port.readDeliveries(tx, {
        alertIds: rows.map((row) => row.id),
      });
      const byAlert = groupDeliveries(deliveries);
      return {
        alerts: rows.map((row) => sosAlertView(row, byAlert.get(row.id) ?? [])),
      };
    });
  };
}

/** Builds the one-incident read. Port shape adds `readAlert(tx, { familyId, alertId })`. */
export function createSosAlertRead({ port }) {
  return async function readFamilySosAlert({ principal, familyId, alertId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const row = await port.readAlert(tx, { familyId, alertId });
      if (row === null) {
        throw new HttpError(404, 'sos_alert_not_found', 'The incident was not found.');
      }
      const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
      return { alert: sosAlertView(row, deliveries) };
    });
  };
}

/**
 * Builds the acknowledgement — the guardian saying "I have seen this".
 *
 * A second acknowledgement is not a conflict, whether it arrives under the same key or a
 * fresh one: the state answers it (`replayed: true`), so a genuine retry and the other
 * parent's tap both land on the same incident without creating a second one.
 *
 * Acknowledging is not resolving, and this module keeps them apart: an incident that has
 * been seen by a parent is still open, still escalating, still visible. Treating "seen"
 * as "handled" is how an alarm gets closed by somebody who only opened the app.
 */
export function createSosAlertAcknowledge({ port }) {
  return async function acknowledgeFamilySosAlert({
    principal,
    familyId,
    alertId,
    idempotencyKey = null,
    requestHash,
    correlationId,
  }) {
    const work = async (tx) => {
      const actor = await port.authorize(tx, {
        familyId,
        subject: principal.subject,
      });
      requireGuardian(
        actor,
        'sos_acknowledge_forbidden',
        'Only a guardian may acknowledge an incident.',
      );
      const row = await port.readAlert(tx, { familyId, alertId, forUpdate: true });
      if (row === null) {
        throw new HttpError(404, 'sos_alert_not_found', 'The incident was not found.');
      }
      if (row.status === 'resolved') {
        throw new HttpError(
          409,
          'sos_alert_resolved',
          'This incident has already been closed.',
        );
      }
      if (row.acknowledged_at !== null) {
        // A second acknowledgement from the other parent is not a conflict: the first
        // one stands and the answer reports the incident as it is.
        const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
        return { alert: sosAlertView(row, deliveries), replayed: true };
      }
      const updated = await port.updateAlertAcknowledged(tx, {
        alertId: row.id,
        membershipId: actor.id,
      });
      await port.audit(tx, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        subjectId: row.id,
        subjectType: 'sos_alert',
        eventType: 'family.sos_alert_acknowledged',
      });
      const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
      return { alert: sosAlertView(updated, deliveries), replayed: false };
    };
    return idempotencyKey == null
      ? port.withTransaction(work)
      : port.idempotent(`sos:acknowledge:${alertId}`, idempotencyKey, requestHash, work);
  };
}

/**
 * Builds the escalation: the family's own ladder, climbed in the family's own order.
 *
 * Only verified contacts are used. The unverified ones are not silently dropped either -
 * the answer says how many were skipped and why, because a parent who added a number and
 * forgot to verify it must find that out now and not on the day it was needed.
 *
 * SMS is intent, not delivery. Nothing in this repository can send a text message, so an
 * escalated contact gets a `not_configured` row with the reason written into it. The
 * conversation this creates ("why does it say not configured?") is the honest one.
 */
export function createSosAlertEscalate({ port }) {
  return async function escalateFamilySosAlert({
    principal,
    familyId,
    alertId,
    idempotencyKey = null,
    requestHash,
    correlationId,
  }) {
    const work = async (tx) => {
      const actor = await port.authorize(tx, {
        familyId,
        subject: principal.subject,
      });
      requireGuardian(
        actor,
        'sos_escalate_forbidden',
        'Only a guardian may escalate an incident.',
      );
      const row = await port.readAlert(tx, { familyId, alertId, forUpdate: true });
      if (row === null) {
        throw new HttpError(404, 'sos_alert_not_found', 'The incident was not found.');
      }
      if (row.status === 'resolved') {
        throw new HttpError(
          409,
          'sos_alert_resolved',
          'This incident has already been closed.',
        );
      }

      const contacts = await port.readBackupContacts(tx, { familyId });
      const eligible = contacts.filter(
        (contact) => contact.enabled && contact.verification === 'verified',
      );
      const skippedUnverified = contacts.filter(
        (contact) => contact.verification !== 'verified',
      ).length;
      const summary = {
        eligibleContacts: eligible.length,
        skippedUnverified,
      };

      if (row.status === 'escalating') {
        // The ladder was already climbed for this incident. A second press of the same
        // button is not a second escalation, and recording one would make the trail read
        // as though the family had asked twice when it asked once.
        const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
        return { alert: sosAlertView(row, deliveries), escalation: summary, replayed: true };
      }

      const rows = eligible.map((contact) => ({
        id: randomUUID(),
        recipientKind: 'backup',
        recipientMembershipId: null,
        recipientContactId: contact.id,
        channel: 'sms',
        deliveryState: 'not_configured',
        reasonCode: 'sms_transport_absent',
      }));
      await port.insertDeliveries(tx, { alertId: row.id, familyId, rows });

      const updated = await port.updateAlertEscalated(tx, {
        alertId: row.id,
        membershipId: actor.id,
      });

      await port.audit(tx, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        subjectId: row.id,
        subjectType: 'sos_alert',
        eventType: 'family.sos_alert_escalated',
      });

      const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
      return {
        alert: sosAlertView(updated, deliveries),
        escalation: summary,
        replayed: false,
      };
    };
    return idempotencyKey == null
      ? port.withTransaction(work)
      : port.idempotent(`sos:escalate:${alertId}`, idempotencyKey, requestHash, work);
  };
}

/**
 * Builds the closure: how an incident ends, and who is allowed to end it.
 *
 * A guardian closes it with a reason. The child's own DEVICE closes it as a false alarm
 * and with nothing else - which is the client's `canCancelOwnSos` rule, held on the
 * server so that a client bug cannot turn "I pressed it by accident" into "my parent says
 * it is over". A child MEMBERSHIP is refused here, and the reason is a schema fact rather
 * than a policy taste: nothing links a membership row to a child row, so the server cannot
 * prove the incident is that account's, and an unprovable yes is not one this module
 * gives.
 */
export function createSosAlertResolve({ port }) {
  return async function resolveFamilySosAlert({
    principal,
    deviceCredential,
    deviceId,
    familyId,
    alertId,
    terminalReason,
    idempotencyKey = null,
    requestHash,
    correlationId,
  }) {
    const work = async (tx) => {
      let resolvedFamilyId = familyId ?? null;
      let actorMembershipId = null;

      let closerDevice = null;
      if (deviceId != null) {
        const device = await port.readReportingDevice(tx, { deviceId });
        if (device === null) {
          throw new HttpError(404, 'device_not_found', 'Linked device was not found.');
        }
        if (deviceCredential != null) {
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
          if (!principal) {
            throw new HttpError(
              401,
              'authentication_required',
              'A device credential or bearer token is required.',
            );
          }
          const actor = await port.authorize(tx, {
            familyId: device.family_id,
            subject: principal.subject,
          });
          requireGuardian(
            actor,
            'sos_resolve_forbidden',
            'Only a guardian may close an incident from another device.',
          );
          actorMembershipId = actor.id;
        }
        resolvedFamilyId = device.family_id;
        closerDevice = device;
      } else {
        const actor = await port.authorize(tx, {
          familyId,
          subject: principal.subject,
        });
        requireGuardian(
          actor,
          'sos_resolve_forbidden',
          'Only a guardian - or the child\'s own handset - may close an incident.',
        );
        actorMembershipId = actor.id;
      }

      const row = await port.readAlert(tx, {
        familyId: resolvedFamilyId,
        alertId,
        forUpdate: true,
      });
      if (row === null) {
        throw new HttpError(404, 'sos_alert_not_found', 'The incident was not found.');
      }

      if (closerDevice !== null) {
        // The handset closes only its own child's incident, and only as a false alarm.
        const device = closerDevice;
        if (device.child_id !== row.child_id) {
          throw new HttpError(
            403,
            'sos_resolve_forbidden',
            'This device may not close an incident about another child.',
          );
        }
        if (terminalReason !== 'false_alarm') {
          throw new HttpError(
            400,
            'invalid_request',
            'A device may only close its own incident as a false alarm.',
          );
        }
      }

      if (row.status === 'resolved') {
        const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
        return { alert: sosAlertView(row, deliveries), replayed: true };
      }

      const updated = await port.updateAlertResolved(tx, {
        alertId: row.id,
        membershipId: actorMembershipId,
        deviceId: closerDevice?.id ?? null,
        terminalReason,
      });
      await port.audit(tx, {
        familyId: resolvedFamilyId,
        actorMembershipId,
        correlationId,
        subjectId: row.id,
        subjectType: 'sos_alert',
        eventType: 'family.sos_alert_resolved',
      });
      const deliveries = await port.readDeliveries(tx, { alertIds: [row.id] });
      return { alert: sosAlertView(updated, deliveries), replayed: false };
    };
    // A handset that cannot hold a key still cannot close twice: the state check answers
    // the second call. An account states its key, and a retry returns the stored answer.
    return idempotencyKey == null
      ? port.withTransaction(work)
      : port.idempotent(`sos:resolve:${alertId}`, idempotencyKey, requestHash, work);
  };
}

/** Builds the ladder read: the family's own escalation contacts, in the family's order. */
export function createSosBackupContactList({ port }) {
  return async function listFamilySosBackupContacts({ principal, familyId }) {
    return port.withTransaction(async (tx) => {
      await port.authorize(tx, { familyId, subject: principal.subject });
      const rows = await port.readBackupContacts(tx, { familyId });
      return { contacts: rows.map(sosBackupContactView) };
    });
  };
}

/** Builds the ladder write. Port shape adds `readBackupContactCount`. */
export function createSosBackupContactCreate({ port }) {
  return async function createFamilySosBackupContact({
    principal,
    familyId,
    contact,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `sos:contact:${familyId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, {
          familyId,
          subject: principal.subject,
        });
        requireGuardian(
          actor,
          'sos_ladder_forbidden',
          'Only a guardian may change the escalation ladder.',
        );
        const count = await port.readBackupContactCount(tx, { familyId });
        if (count >= MAX_BACKUP_CONTACTS) {
          throw new HttpError(
            409,
            'sos_ladder_full',
            `A ladder carries at most ${MAX_BACKUP_CONTACTS} contacts.`,
          );
        }
        const row = await port.insertBackupContact(tx, {
          // `verification` is written after the spread on purpose: a new rung is
          // `unverified` whatever the caller sent, and verifying it is a separate act.
          // The column default says the same thing; this says it at the write, where a
          // reader of this operation will look.
          contact: { id: randomUUID(), familyId, ...contact, verification: 'unverified' },
          actorMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: row.id,
          subjectType: 'sos_backup_contact',
          eventType: 'family.sos_backup_contact_added',
        });
        return { contact: sosBackupContactView(row) };
      },
    );
  };
}

/** Builds the ladder update: rename, renumber, verify, disable, archive. */
export function createSosBackupContactUpdate({ port }) {
  return async function updateFamilySosBackupContact({
    principal,
    familyId,
    contactId,
    patch,
    correlationId,
  }) {
    return port.withTransaction(async (tx) => {
      const actor = await port.authorize(tx, {
        familyId,
        subject: principal.subject,
      });
      requireGuardian(
        actor,
        'sos_ladder_forbidden',
        'Only a guardian may change the escalation ladder.',
      );
      const existing = await port.readBackupContact(tx, {
        familyId,
        contactId,
        forUpdate: true,
      });
      if (existing === null) {
        throw new HttpError(404, 'sos_backup_contact_not_found', 'Contact was not found.');
      }
      const row = await port.updateBackupContact(tx, { contactId, patch });
      const eventType =
        patch.verification !== undefined
          ? 'family.sos_backup_contact_verified'
          : 'family.sos_backup_contact_changed';
      await port.audit(tx, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        subjectId: row.id,
        subjectType: 'sos_backup_contact',
        eventType,
      });
      return { contact: sosBackupContactView(row) };
    });
  };
}

/** One incident, in the shape the client's own SosAlert model expects. */
export function sosAlertView(row, deliveries) {
  return Object.freeze({
    id: row.id,
    familyId: row.family_id,
    childId: row.child_id,
    raisedByKind: row.raised_by_kind,
    raisedByMembershipId: row.raised_by_membership_id ?? null,
    status: row.status,
    open: row.status !== 'resolved',
    pressedAt: row.pressed_at,
    receivedAt: row.received_at,
    acknowledgedAt: row.acknowledged_at ?? null,
    escalatedAt: row.escalated_at ?? null,
    resolvedAt: row.resolved_at ?? null,
    terminalReason: row.terminal_reason ?? null,
    resolvedByKind: row.resolved_at == null
      ? null
      : row.resolved_by_device_id != null
        ? 'child_device'
        : 'guardian',
    picture: Object.freeze({
      locationClass: row.location_class,
      latitude: row.latitude ?? null,
      longitude: row.longitude ?? null,
      accuracyMeters: row.accuracy_meters ?? null,
      connectionClass: row.connection_class,
      batteryPercent: row.battery_percent ?? null,
      placeLabel: row.place_label ?? null,
      panicQuiet: row.panic_quiet,
      fixId: row.fix_id ?? null,
    }),
    deliveries: Object.freeze(
      deliveries.map((delivery) => sosDeliveryView(delivery)),
    ),
    version: row.version,
  });
}

function sosDeliveryView(row) {
  return Object.freeze({
    recipientKind: row.recipient_kind,
    recipientMembershipId: row.recipient_membership_id ?? null,
    recipientContactId: row.recipient_contact_id ?? null,
    channel: row.channel,
    deliveryState: row.delivery_state,
    reasonCode: row.reason_code ?? null,
    createdAt: row.created_at,
  });
}

export function sosBackupContactView(row) {
  return Object.freeze({
    id: row.id,
    name: row.name,
    relation: row.relation,
    phoneE164: row.phone_e164,
    verification: row.verification,
    enabled: row.enabled,
    priority: row.priority,
    archivedAt: row.archived_at ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  });
}

function groupDeliveries(rows) {
  const byAlert = new Map();
  for (const row of rows) {
    const list = byAlert.get(row.alert_id) ?? [];
    list.push(row);
    byAlert.set(row.alert_id, list);
  }
  return byAlert;
}

/**
 * The production port: real SQL through the Foundation store's own transaction,
 * membership, idempotency and audit helpers, so the whole emergency surface costs route
 * lines in `app.js` and nothing else.
 */
export function postgresSosPort(store, { credentialMatches }) {
  const alertColumns = `id, family_id, child_id, raised_by_kind, raised_by_membership_id,
                        pressed_at, received_at, status, location_class, latitude, longitude,
                        accuracy_meters, connection_class, battery_percent, place_label,
                        panic_quiet, fix_id, acknowledged_at, acknowledged_by_membership_id,
                        escalated_at, escalated_by_membership_id, resolved_at,
                        resolved_by_membership_id, resolved_by_device_id, terminal_reason,
                        version, created_at, updated_at`;

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

    async readReportingDevice(client, { deviceId }) {
      // The same read the telemetry and location surfaces use, and the same lock: a device
      // whose credential is being revoked mid-press must not be able to raise an incident
      // on its way out.
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices
          WHERE id = $1
          FOR UPDATE`,
        [deviceId],
      );
      return rows[0] ?? null;
    },

    // Injected rather than imported: the credential check is the same capability the
    // device telemetry and location surfaces already use, and re-deriving it here would
    // have been a second answer to a question that must have exactly one.
    credentialMatches,

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async readFixOwnership(client, { familyId, childId, fixId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_child_location_fixes
          WHERE family_id = $1 AND child_id = $2 AND id = $3`,
        [familyId, childId, fixId],
      );
      return rows[0] ?? null;
    },

    async readOpenAlertForChild(client, { childId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT ${alertColumns}
           FROM family_sos_alerts
          WHERE child_id = $1 AND status <> 'resolved'
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [childId],
      );
      return rows[0] ?? null;
    },

    async readAlert(client, { familyId, alertId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT ${alertColumns}
           FROM family_sos_alerts
          WHERE family_id = $1 AND id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [familyId, alertId],
      );
      return rows[0] ?? null;
    },

    async readAlerts(client, { familyId, statuses }) {
      const { rows } = await client.query(
        `SELECT ${alertColumns}
           FROM family_sos_alerts
          WHERE family_id = $1 AND status = ANY($2::text[])
          ORDER BY pressed_at DESC, id DESC`,
        [familyId, statuses],
      );
      return rows;
    },

    async readGuardians(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, role
           FROM family_memberships
          WHERE family_id = $1
            AND status = 'active'
            AND role IN ('primary_guardian', 'co_guardian')
          ORDER BY joined_at ASC, id ASC`,
        [familyId],
      );
      return rows;
    },

    async insertAlert(client, { alert }) {
      const { rows } = await client.query(
        `INSERT INTO family_sos_alerts
           (id, family_id, child_id, raised_by_kind, raised_by_membership_id, pressed_at,
            status, location_class, latitude, longitude, accuracy_meters, connection_class,
            battery_percent, place_label, panic_quiet, fix_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
         RETURNING ${alertColumns}`,
        [
          alert.id,
          alert.familyId,
          alert.childId,
          alert.raisedByKind,
          alert.raisedByMembershipId,
          alert.pressedAt,
          alert.status,
          alert.locationClass,
          alert.latitude,
          alert.longitude,
          alert.accuracyMeters,
          alert.connectionClass,
          alert.batteryPercent,
          alert.placeLabel,
          alert.panicQuiet,
          alert.fixId,
        ],
      );
      return rows[0];
    },

    async updateAlertAcknowledged(client, { alertId, membershipId }) {
      const { rows } = await client.query(
        `UPDATE family_sos_alerts
            SET status = CASE WHEN status = 'active' THEN 'acknowledged' ELSE status END,
                acknowledged_at = NOW(),
                acknowledged_by_membership_id = $2,
                version = version + 1,
                updated_at = NOW()
          WHERE id = $1
          RETURNING ${alertColumns}`,
        [alertId, membershipId],
      );
      return rows[0];
    },

    async updateAlertEscalated(client, { alertId, membershipId }) {
      const { rows } = await client.query(
        `UPDATE family_sos_alerts
            SET status = CASE WHEN status = 'resolved' THEN status ELSE 'escalating' END,
                escalated_at = NOW(),
                escalated_by_membership_id = $2,
                version = version + 1,
                updated_at = NOW()
          WHERE id = $1
          RETURNING ${alertColumns}`,
        [alertId, membershipId],
      );
      return rows[0];
    },

    async updateAlertResolved(client, { alertId, membershipId, deviceId, terminalReason }) {
      const { rows } = await client.query(
        `UPDATE family_sos_alerts
            SET status = 'resolved',
                resolved_at = NOW(),
                resolved_by_membership_id = $2,
                resolved_by_device_id = $3,
                terminal_reason = $4,
                version = version + 1,
                updated_at = NOW()
          WHERE id = $1
          RETURNING ${alertColumns}`,
        [alertId, membershipId, deviceId, terminalReason],
      );
      return rows[0];
    },

    async insertDeliveries(client, { alertId, familyId, rows }) {
      if (rows.length === 0) return;
      await client.query(
        `INSERT INTO family_sos_alert_deliveries
           (id, alert_id, family_id, recipient_kind, recipient_membership_id,
            recipient_contact_id, channel, delivery_state, reason_code)
         SELECT unnest($1::uuid[]), $2, $3, unnest($4::text[]), unnest($5::uuid[]),
                unnest($6::uuid[]), unnest($7::text[]), unnest($8::text[]),
                unnest($9::text[])
         ON CONFLICT DO NOTHING`,
        [
          rows.map((row) => row.id),
          alertId,
          familyId,
          rows.map((row) => row.recipientKind),
          rows.map((row) => row.recipientMembershipId),
          rows.map((row) => row.recipientContactId),
          rows.map((row) => row.channel),
          rows.map((row) => row.deliveryState),
          rows.map((row) => row.reasonCode),
        ],
      );
    },

    async readDeliveries(client, { alertIds }) {
      const { rows } = await client.query(
        `SELECT id, alert_id, recipient_kind, recipient_membership_id, recipient_contact_id,
                channel, delivery_state, reason_code, created_at
           FROM family_sos_alert_deliveries
          WHERE alert_id = ANY($1::uuid[])
          ORDER BY created_at ASC, id ASC`,
        [alertIds],
      );
      return rows;
    },

    async readBackupContacts(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT id, name, relation, phone_e164, verification, enabled, priority,
                created_at, updated_at, archived_at
           FROM family_sos_backup_contacts
          WHERE family_id = $1 AND archived_at IS NULL
          ORDER BY priority ASC, created_at ASC, id ASC`,
        [familyId],
      );
      return rows;
    },

    async readBackupContact(client, { familyId, contactId, forUpdate = false }) {
      const { rows } = await client.query(
        `SELECT id, name, relation, phone_e164, verification, enabled, priority,
                created_at, updated_at, archived_at
           FROM family_sos_backup_contacts
          WHERE family_id = $1 AND id = $2 AND archived_at IS NULL
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [familyId, contactId],
      );
      return rows[0] ?? null;
    },

    async readBackupContactCount(client, { familyId }) {
      const { rows } = await client.query(
        `SELECT COUNT(*)::int AS count
           FROM family_sos_backup_contacts
          WHERE family_id = $1 AND archived_at IS NULL`,
        [familyId],
      );
      return rows[0]?.count ?? 0;
    },

    async insertBackupContact(client, { contact, actorMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_sos_backup_contacts
           (id, family_id, name, relation, phone_e164, verification, enabled, priority,
            created_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING id, name, relation, phone_e164, verification, enabled, priority,
                   created_at, updated_at, archived_at`,
        [
          contact.id,
          contact.familyId,
          contact.name,
          contact.relation,
          contact.phoneE164,
          contact.verification,
          contact.enabled,
          contact.priority,
          actorMembershipId,
        ],
      );
      return rows[0];
    },

    async updateBackupContact(client, { contactId, patch }) {
      const { rows } = await client.query(
        `UPDATE family_sos_backup_contacts
            SET name = COALESCE($2, name),
                relation = COALESCE($3, relation),
                phone_e164 = COALESCE($4, phone_e164),
                verification = COALESCE($5, verification),
                enabled = COALESCE($6, enabled),
                priority = COALESCE($7, priority),
                archived_at = CASE WHEN $8::boolean THEN NOW() ELSE archived_at END,
                updated_at = NOW()
          WHERE id = $1 AND archived_at IS NULL
          RETURNING id, name, relation, phone_e164, verification, enabled, priority,
                    created_at, updated_at, archived_at`,
        [
          contactId,
          patch.name ?? null,
          patch.relation ?? null,
          patch.phoneE164 ?? null,
          patch.verification ?? null,
          patch.enabled ?? null,
          patch.priority ?? null,
          patch.archived === true,
        ],
      );
      return rows[0];
    },

    async audit(client, { familyId, actorMembershipId, correlationId, subjectId, subjectType, eventType }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        eventType,
        subjectType,
        subjectId,
      });
    },
  };
}

/** Builds every operation for a server that was handed a Foundation store. */
export function sosEmergencyFor(store, { credentialMatches }) {
  const port = postgresSosPort(store, { credentialMatches });
  return {
    fire: createSosAlertFire({ port }),
    list: createSosAlertList({ port }),
    read: createSosAlertRead({ port }),
    acknowledge: createSosAlertAcknowledge({ port }),
    escalate: createSosAlertEscalate({ port }),
    resolve: createSosAlertResolve({ port }),
    listBackupContacts: createSosBackupContactList({ port }),
    createBackupContact: createSosBackupContactCreate({ port }),
    updateBackupContact: createSosBackupContactUpdate({ port }),
  };
}
