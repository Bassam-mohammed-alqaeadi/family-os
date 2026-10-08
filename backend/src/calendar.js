// W8 — the family calendar: what the family agreed to do together.
//
// Every wave before this one was about protection - what a phone may do, where a child may go,
// what a filter allows. This wave is about attendance, and that difference decides its laws,
// because a family product starts inventing facts at exactly the point where it starts
// recording people rather than devices:
//
//   * AN EVENT IS NEVER DELETED, IT IS CANCELLED. A cancellation carries an author, a reason
//     and a moment; a row that disappeared would teach a family that the plan was never real.
//   * TWO GUARDIANS DO NOT SILENTLY OVERWRITE EACH OTHER. Every edit states the version it
//     read, and a mismatch is a 409 that names the conflict - never last-write-wins on a
//     family's evening.
//   * AN ANSWER HAS AN AUTHOR. A child's yes or no arrives from their own paired handset, or
//     the guardian who recorded what the child said - exactly one of the two, enforced by the
//     database, so no device can answer as a person and no person can hide behind a device.
//     And a "no" is a first-class answer: a calendar that only counts yes is a scoreboard.
//   * ONLY AN INVITED CHILD ANSWERS. The audience table is the invitation, and the response
//     table's foreign key points at it, so a response to an event a child was never invited to
//     is refused by storage rather than by a code path someone might reorder.
//   * ATTENDANCE IS A FACT RECORDED AFTER THE FACT. It cannot be recorded before the event has
//     started (`event_not_started`) and cannot be recorded on a cancelled event
//     (`event_cancelled`) - and it is stated by a person, because presence inferred from a
//     phone's location is exactly the surveillance this product refuses to be.
//   * A REMINDER IS A PREFERENCE, NOT A DELIVERY. `reminder_minutes` records what a family
//     asked for, and nothing in this file pretends a notification arrived.
//
// Everything below is either a pure function (testable without a socket) or a thin translation
// of one into SQL. No decision is duplicated in the route layer, and no fact is stored twice.

import { randomUUID } from 'node:crypto';

import { HttpError } from './http-error.js';

export const EVENT_STATUSES = Object.freeze(['scheduled', 'cancelled']);
export const EVENT_RESPONSES = Object.freeze(['accepted', 'declined']);

export const EVENT_TITLE_MAX = 120;
export const EVENT_NOTE_MAX = 300;
export const EVENT_LOCATION_MAX = 160;
export const EVENT_CANCEL_REASON_MAX = 200;
export const EVENT_AUDIENCE_MAX = 24;
/// A generous bound, not a target: a family scheduling something three years out is far more
/// likely to be a clock or a typo than a plan, and the bound is what turns that into a refusal
/// with a field name instead of a row nobody will look at again.
export const EVENT_HORIZON_DAYS = 1095;
export const EVENT_LENGTH_MAX_HOURS = 24 * 30;
export const EVENT_REMINDER_MAX_MINUTES = 10080;

const GUARDIAN_ROLES = new Set(['primary_guardian', 'co_guardian']);

export class CalendarError extends HttpError {
  constructor(status, code, message) {
    super(status, code, message);
    this.name = 'CalendarError';
  }
}

function requireGuardian(actor, code, message) {
  if (!GUARDIAN_ROLES.has(actor?.role)) {
    throw new CalendarError(403, code, message);
  }
  return actor;
}

function instant(value) {
  const parsed = value instanceof Date ? value : new Date(value);
  return parsed.toISOString();
}

// ── pure shapes ───────────────────────────────────────────────────────────────────────────

/// One instant, stated by the server, never by a screen: `now` is passed in so the law about
/// attendance can be tested without waiting for a clock.
export function eventWindow(row) {
  return {
    startsAt: instant(row.starts_at),
    endsAt: instant(row.ends_at),
  };
}

export function eventView(row, { audience = [], responses = [], attendance = [] } = {}) {
  const responsesByChild = new Map(responses.map((r) => [r.child_id, r]));
  const attendanceByChild = new Map(attendance.map((a) => [a.child_id, a]));
  return {
    id: row.id,
    title: row.title,
    note: row.note,
    location: row.location,
    startsAt: instant(row.starts_at),
    endsAt: instant(row.ends_at),
    allDay: row.all_day === true,
    reminderMinutes: row.reminder_minutes ?? null,
    status: row.status,
    version: row.version,
    createdByMembershipId: row.created_by_membership_id,
    cancelReason: row.cancel_reason,
    cancelledAt: row.cancelled_at == null ? null : instant(row.cancelled_at),
    cancelledByMembershipId: row.cancelled_by_membership_id ?? null,
    createdAt: instant(row.created_at),
    updatedAt: instant(row.updated_at),
    // The audience is part of the event, not a separate call: a family asks "what is on
    // Saturday and who is going", which is one question.
    audience: audience.map((row_) => audienceView(row_, responsesByChild.get(row_.child_id), attendanceByChild.get(row_.child_id))),
  };
}

function audienceView(row, response, attendance) {
  return {
    childId: row.child_id,
    response: response == null ? null : responseView(response),
    attendance: attendance == null ? null : attendanceView(attendance),
  };
}

export function responseView(row) {
  return {
    childId: row.child_id,
    response: row.response,
    note: row.note,
    respondedByDeviceId: row.responded_by_device_id ?? null,
    respondedByMembershipId: row.responded_by_membership_id ?? null,
    respondedAt: instant(row.updated_at),
  };
}

export function attendanceView(row) {
  return {
    childId: row.child_id,
    attended: row.attended === true,
    note: row.note,
    recordedByMembershipId: row.recorded_by_membership_id,
    recordedAt: instant(row.recorded_at),
  };
}

/// What one child sees: the events they are invited to, with their own answer and what has
/// been recorded about their attendance. Deliberately NOT the other children's answers - a
/// child's phone has no business knowing whether their brother said no.
export function childEventView(row, response, attendance) {
  return {
    id: row.id,
    title: row.title,
    note: row.note,
    location: row.location,
    startsAt: instant(row.starts_at),
    endsAt: instant(row.ends_at),
    allDay: row.all_day === true,
    status: row.status,
    cancelReason: row.cancel_reason,
    response: response == null ? null : responseView(response),
    attendance: attendance == null ? null : attendanceView(attendance),
  };
}

/// The version an edit must state. A missing or nonsensical one is refused here rather than
/// compared as `undefined === undefined`, which would let a client skip the whole mechanism.
export function expectedVersion(value) {
  if (!Number.isInteger(value) || value < 1) {
    throw new CalendarError(
      400,
      'event_version_required',
      'An edit must state the version it read, as a whole number starting at 1.',
    );
  }
  return value;
}

/// The window a range read asks for. Bounded on purpose: a screen that asked for "everything"
/// would be asking the server to send a family's whole history to answer "what is this week".
export function normalizeRange({ from, to }) {
  const startsAt = from instanceof Date ? from : new Date(from);
  if (Number.isNaN(startsAt.getTime())) {
    throw new CalendarError(400, 'event_range_invalid', 'from must be an ISO-8601 instant.');
  }
  const endsAt = to instanceof Date ? to : new Date(to);
  if (Number.isNaN(endsAt.getTime())) {
    throw new CalendarError(400, 'event_range_invalid', 'to must be an ISO-8601 instant.');
  }
  if (endsAt <= startsAt) {
    throw new CalendarError(400, 'event_range_invalid', 'to must be after from.');
  }
  return { from: instant(startsAt), to: instant(endsAt) };
}

/// The instant an attendance record may exist: an event that has started and still stands.
export function requireRecordableAt(row, now) {
  if (row.status !== 'scheduled') {
    throw new CalendarError(
      409,
      'event_cancelled',
      'This event was cancelled, so there is nothing to record about it.',
    );
  }
  if (new Date(row.starts_at).getTime() > now.getTime()) {
    throw new CalendarError(
      409,
      'event_not_started',
      'Attendance is a fact: it cannot be recorded before the event starts.',
    );
  }
  return row;
}

// ── operations ────────────────────────────────────────────────────────────────────────────

/// A guardian states an event, and names who it is for. The audience is part of the same
/// transaction as the event: an event that exists for a moment with nobody invited is not
/// something any reader should ever be able to observe.
export function createEventCreate({ port }) {
  return async function createFamilyEvent({
    principal,
    familyId,
    title,
    note = '',
    location = '',
    startsAt,
    endsAt,
    allDay = false,
    reminderMinutes = null,
    childIds,
    idempotencyKey,
    requestHash,
    correlationId,
    now = () => new Date(),
  }) {
    return port.idempotent(
      `calendar:create:${familyId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'event_forbidden', 'Only a guardian may state a family event.');
        const start = new Date(startsAt);
        const end = new Date(endsAt);
        // The clock rule: an event is a plan about a time that still exists. Five minutes of
        // tolerance covers a family typing as the hour turns; anything more is a typo.
        if (start.getTime() < now().getTime() - 5 * 60 * 1000) {
          throw new CalendarError(422, 'event_in_past', 'An event cannot be stated in the past.');
        }
        if (end.getTime() - start.getTime() > EVENT_LENGTH_MAX_HOURS * 3600 * 1000) {
          throw new CalendarError(422, 'event_too_long', 'That is longer than a month - check the dates.');
        }
        const children = [];
        for (const childId of childIds) {
          const child = await port.readChild(tx, { familyId, childId });
          if (child == null) {
            throw new CalendarError(404, 'child_not_found', 'One of these children is not part of the family.');
          }
          children.push(childId);
        }
        const row = await port.insertEvent(tx, {
          familyId,
          title,
          note,
          location,
          startsAt: start,
          endsAt: end,
          allDay,
          reminderMinutes,
          createdByMembershipId: actor.id,
        });
        const audience = await port.insertAudience(tx, { familyId, eventId: row.id, childIds: children });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: row.id,
          subjectType: 'family_event',
          eventType: 'family.event_created',
        });
        return { event: eventView(row, { audience }) };
      },
    );
  };
}

/// What the family has agreed to do together, inside a window. Cancelled events are included,
/// with their reason: a family needs to know that the trip was called off, and a calendar that
/// hid it would leave a child waiting.
export function createEventList({ port }) {
  return async function listFamilyEvents({ principal, familyId, from, to }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'event_forbidden', 'Only a guardian may read the family calendar.');
      const rows = await port.listEvents(tx, { familyId, from, to });
      const audience = await port.listAudience(tx, { familyId, eventIds: rows.map((row) => row.id) });
      const responses = await port.listResponses(tx, { familyId, eventIds: rows.map((row) => row.id) });
      const attendance = await port.listAttendance(tx, { familyId, eventIds: rows.map((row) => row.id) });
      return {
        events: rows.map((row) =>
          eventView(row, {
            audience: audience.filter((entry) => entry.event_id === row.id),
            responses: responses.filter((entry) => entry.event_id === row.id),
            attendance: attendance.filter((entry) => entry.event_id === row.id),
          }),
        ),
      };
    });
  };
}

/// The child's own handset: what this child is invited to. No child id in the query, because
/// the device credential is what proves which child is asking.
export function createDeviceEventRead({ port }) {
  return async function readEventsForDevice({ deviceId, deviceCredential, from, to }) {
    return port.read(async (tx) => {
      const device = await port.requireDevice(tx, { deviceId, deviceCredential });
      const rows = await port.listEventsForChild(tx, {
        familyId: device.family_id,
        childId: device.child_id,
        from,
        to,
      });
      const responses = await port.listResponsesForChild(tx, {
        familyId: device.family_id,
        childId: device.child_id,
      });
      const attendance = await port.listAttendanceForChild(tx, {
        familyId: device.family_id,
        childId: device.child_id,
      });
      const byEvent = new Map(responses.map((entry) => [entry.event_id, entry]));
      const attendanceByEvent = new Map(attendance.map((entry) => [entry.event_id, entry]));
      return {
        events: rows.map((row) =>
          childEventView(row, byEvent.get(row.id) ?? null, attendanceByEvent.get(row.id) ?? null),
        ),
      };
    });
  };
}

/// The child answers - from their own handset, or through a guardian recording what they said.
/// One row per child per event: a second answer is a change of mind, and the row keeps the
/// author who is answering now.
export function createEventResponseRecord({ port }) {
  return async function recordEventResponse({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    childId,
    eventId,
    response,
    note = '',
    idempotencyKey,
    requestHash,
    correlationId,
    now = () => new Date(),
  }) {
    return port.idempotent(
      `calendar:response:${familyId ?? deviceId}:${eventId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        // The author is decided by HOW the request arrived, never by a field in the body: a
        // handset answers for its own child, a guardian answers for a child they name.
        let effectiveFamilyId = familyId;
        let effectiveChildId = childId;
        let authorDeviceId = null;
        let authorMembershipId = null;
        if (deviceId != null) {
          const device = await port.requireDevice(tx, { deviceId, deviceCredential });
          effectiveFamilyId = device.family_id;
          effectiveChildId = device.child_id;
          authorDeviceId = device.id;
        } else {
          const actor = await port.authorize(tx, { familyId: effectiveFamilyId, subject: principal.subject });
          requireGuardian(actor, 'event_forbidden', 'Only a guardian may answer for a child.');
          authorMembershipId = actor.id;
        }
        const event = await port.readEvent(tx, { familyId: effectiveFamilyId, eventId }, { forUpdate: true });
        if (event == null) {
          throw new CalendarError(404, 'event_not_found', 'This event is not part of the family.');
        }
        if (event.status !== 'scheduled') {
          throw new CalendarError(409, 'event_cancelled', 'This event was cancelled; there is nothing to answer.');
        }
        const invited = await port.readAudience(tx, {
          familyId: effectiveFamilyId,
          eventId,
          childId: effectiveChildId,
        });
        if (invited == null) {
          throw new CalendarError(403, 'event_not_invited', 'This child is not invited to that event.');
        }
        // Answering after the fact is not answering. The window closes when the event starts,
        // because "will you come" and "did you come" are different questions - and the second
        // one is asked with the attendance record.
        if (new Date(event.starts_at).getTime() <= now().getTime()) {
          throw new CalendarError(409, 'event_already_started', 'This event has already started.');
        }
        const row = await port.upsertResponse(tx, {
          familyId: effectiveFamilyId,
          eventId,
          childId: effectiveChildId,
          response,
          note,
          respondedByDeviceId: authorDeviceId,
          respondedByMembershipId: authorMembershipId,
        });
        await port.audit(tx, {
          familyId: effectiveFamilyId,
          actorMembershipId: authorMembershipId,
          correlationId,
          subjectId: eventId,
          subjectType: 'family_event',
          eventType: 'family.event_responded',
        });
        return { response: responseView(row) };
      },
    );
  };
}

/// A guardian records what actually happened. Two refusals carry the weight here: nothing can
/// be recorded before the event starts, and nothing can be recorded for a cancelled event.
export function createAttendanceRecord({ port }) {
  return async function recordEventAttendance({
    principal,
    familyId,
    eventId,
    childId,
    attended,
    note = '',
    idempotencyKey,
    requestHash,
    correlationId,
    now = () => new Date(),
  }) {
    // Idempotent for the same reason every write in this contract is: on a flaky connection a
    // guardian taps "he was there" twice, and the second attempt must be the same request -
    // not a second moment recorded, because `recorded_at` is part of the fact.
    return port.idempotent(
      `calendar:attendance:${familyId}:${eventId}:${childId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'event_forbidden', 'Only a guardian may record attendance.');
        const event = await port.readEvent(tx, { familyId, eventId }, { forUpdate: true });
        if (event == null) {
          throw new CalendarError(404, 'event_not_found', 'This event is not part of the family.');
        }
        requireRecordableAt(event, now());
        const invited = await port.readAudience(tx, { familyId, eventId, childId });
        if (invited == null) {
          throw new CalendarError(403, 'event_not_invited', 'This child is not invited to that event.');
        }
        const row = await port.upsertAttendance(tx, {
          familyId,
          eventId,
          childId,
          attended,
          note,
          recordedByMembershipId: actor.id,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: eventId,
          subjectType: 'family_event',
          eventType: 'family.event_attendance_recorded',
        });
        return { attendance: attendanceView(row) };
      },
    );
  };
}

/// A guardian changes an event. The version they read must still be the version stored: a
/// mismatch means somebody else's plan is not being overwritten, it is being preserved.
export function createEventUpdate({ port }) {
  return async function updateFamilyEvent({
    principal,
    familyId,
    eventId,
    version,
    changes,
    correlationId,
  }) {
    return port.read(async (tx) => {
      const actor = await port.authorize(tx, { familyId, subject: principal.subject });
      requireGuardian(actor, 'event_forbidden', 'Only a guardian may change a family event.');
      const current = await port.readEvent(tx, { familyId, eventId }, { forUpdate: true });
      if (current == null) {
        throw new CalendarError(404, 'event_not_found', 'This event is not part of the family.');
      }
      if (current.status !== 'scheduled') {
        throw new CalendarError(409, 'event_cancelled', 'This event was cancelled and is not edited.');
      }
      if (current.version !== version) {
        throw new CalendarError(
          409,
          'event_stale_version',
          'Somebody else changed this event since you read it.',
        );
      }
      const startsAt = changes.startsAt ?? instant(current.starts_at);
      const endsAt = changes.endsAt ?? instant(current.ends_at);
      if (new Date(endsAt) <= new Date(startsAt)) {
        throw new CalendarError(422, 'event_instant_ordered', 'The end must be after the start.');
      }
      const row = await port.updateEvent(tx, {
        familyId,
        eventId,
        title: changes.title ?? current.title,
        note: changes.note ?? current.note,
        location: changes.location ?? current.location,
        startsAt,
        endsAt,
        allDay: changes.allDay ?? current.all_day,
        reminderMinutes: changes.reminderMinutes === undefined ? current.reminder_minutes : changes.reminderMinutes,
      });
      if (changes.childIds != null) {
        // The audience is replaced rather than merged, because a guardian who unticks a name
        // means it: merged audiences are how a child stays invited to something they were
        // removed from. But an answer and an attendance record are facts with authors, and
        // this path may not delete them - so a child who already answered cannot be removed
        // silently; the guardian is told why, and the history keeps its author.
        const current_ = await port.listAudience(tx, { familyId, eventIds: [eventId] });
        const kept = new Set(changes.childIds);
        for (const entry of current_) {
          if (kept.has(entry.child_id)) continue;
          const answers = await port.audienceAnswerCount(tx, {
            familyId,
            eventId,
            childId: entry.child_id,
          });
          if (answers > 0) {
            throw new CalendarError(
              409,
              'event_audience_answered',
              'A child who already answered or attended cannot be removed from the plan.',
            );
          }
        }
        await port.deleteAudience(tx, { familyId, eventId });
        await port.insertAudience(tx, { familyId, eventId, childIds: changes.childIds });
      }
      const audience = await port.listAudience(tx, { familyId, eventIds: [eventId] });
      const responses = await port.listResponses(tx, { familyId, eventIds: [eventId] });
      const attendance = await port.listAttendance(tx, { familyId, eventIds: [eventId] });
      await port.audit(tx, {
        familyId,
        actorMembershipId: actor.id,
        correlationId,
        subjectId: eventId,
        subjectType: 'family_event',
        eventType: 'family.event_updated',
      });
      return { event: eventView(row, { audience, responses, attendance }) };
    });
  };
}

/// A guardian calls an event off. This is not a delete: the row keeps its times, its audience
/// and its answers, gains an author, a reason and a moment, and every reader can tell a child
/// why the plan changed. Cancelling twice is refused rather than ignored, because silence
/// would let two guardians each believe they were the one who called it off.
export function createEventCancel({ port }) {
  return async function cancelFamilyEvent({
    principal,
    familyId,
    eventId,
    reason,
    idempotencyKey,
    requestHash,
    correlationId,
  }) {
    return port.idempotent(
      `calendar:cancel:${familyId}:${eventId}`,
      idempotencyKey,
      requestHash,
      async (tx) => {
        const actor = await port.authorize(tx, { familyId, subject: principal.subject });
        requireGuardian(actor, 'event_forbidden', 'Only a guardian may cancel a family event.');
        const current = await port.readEvent(tx, { familyId, eventId }, { forUpdate: true });
        if (current == null) {
          throw new CalendarError(404, 'event_not_found', 'This event is not part of the family.');
        }
        if (current.status === 'cancelled') {
          throw new CalendarError(409, 'event_already_cancelled', 'This event was already cancelled.');
        }
        const row = await port.cancelEvent(tx, {
          familyId,
          eventId,
          cancelledByMembershipId: actor.id,
          cancelReason: reason,
        });
        await port.audit(tx, {
          familyId,
          actorMembershipId: actor.id,
          correlationId,
          subjectId: eventId,
          subjectType: 'family_event',
          eventType: 'family.event_cancelled',
        });
        const audience = await port.listAudience(tx, { familyId, eventIds: [eventId] });
        const responses = await port.listResponses(tx, { familyId, eventIds: [eventId] });
        const attendance = await port.listAttendance(tx, { familyId, eventIds: [eventId] });
        return { event: eventView(row, { audience, responses, attendance }) };
      },
    );
  };
}

export function calendarFor(store, { credentialMatches }) {
  const port = postgresCalendarPort(store, { credentialMatches });
  return {
    createEvent: createEventCreate({ port }),
    listEvents: createEventList({ port }),
    readEventsForDevice: createDeviceEventRead({ port }),
    respondToEvent: createEventResponseRecord({ port }),
    recordAttendance: createAttendanceRecord({ port }),
    updateEvent: createEventUpdate({ port }),
    cancelEvent: createEventCancel({ port }),
  };
}

/// The columns are stated once, as lists, because one read needs them prefixed (`e.title`)
/// and a template string cannot be both flat and prefixed without becoming a parser's job.
const EVENT_COLUMN_LIST = Object.freeze([
  'id', 'family_id', 'title', 'note', 'location', 'starts_at', 'ends_at', 'all_day',
  'reminder_minutes', 'status', 'version', 'created_by_membership_id',
  'cancelled_by_membership_id', 'cancelled_at', 'cancel_reason', 'created_at', 'updated_at',
]);
const columns = (list, prefix = '') =>
  list.map((column) => (prefix === '' ? column : `${prefix}.${column}`)).join(', ');
const EVENT_COLUMNS = columns(EVENT_COLUMN_LIST);

const RESPONSE_COLUMNS = `id, family_id, event_id, child_id, response, note,
                          responded_by_device_id, responded_by_membership_id,
                          created_at, updated_at`;

const ATTENDANCE_COLUMNS = `id, family_id, event_id, child_id, attended, note,
                            recorded_by_membership_id, recorded_at`;

export function postgresCalendarPort(store, { credentialMatches }) {
  return {
    credentialMatches,

    async withTransaction(run) {
      return store.withTransaction(run);
    },

    async read(run) {
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

    async readChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT id FROM family_children WHERE family_id = $1 AND id = $2`,
        [familyId, childId],
      );
      return rows[0] ?? null;
    },

    async requireDevice(client, { deviceId, deviceCredential }) {
      const { rows } = await client.query(
        `SELECT id, family_id, child_id, credential_hash, credential_revoked_at
           FROM family_child_devices WHERE id = $1`,
        [deviceId],
      );
      const device = rows[0];
      if (
        device == null ||
        device.credential_revoked_at != null ||
        !credentialMatches(device.credential_hash, deviceCredential)
      ) {
        throw new CalendarError(403, 'device_credential_rejected', 'This device credential is not accepted.');
      }
      return device;
    },

    async insertEvent(client, { familyId, title, note, location, startsAt, endsAt, allDay, reminderMinutes, createdByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_events
           (id, family_id, title, note, location, starts_at, ends_at, all_day,
            reminder_minutes, created_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         RETURNING ${EVENT_COLUMNS}`,
        [randomUUID(), familyId, title, note, location, startsAt, endsAt, allDay, reminderMinutes, createdByMembershipId],
      );
      return rows[0];
    },

    async insertAudience(client, { familyId, eventId, childIds }) {
      for (const childId of childIds) {
        await client.query(
          `INSERT INTO family_event_audience (family_id, event_id, child_id)
           VALUES ($1, $2, $3)`,
          [familyId, eventId, childId],
        );
      }
      const { rows } = await client.query(
        `SELECT child_id FROM family_event_audience
          WHERE family_id = $1 AND event_id = $2
          ORDER BY child_id`,
        [familyId, eventId],
      );
      return rows;
    },

    /// How many facts already exist about one child on one event: an answer, an attendance
    /// record, or both. Used to refuse an edit that would delete a fact by deleting its row.
    async audienceAnswerCount(client, { familyId, eventId, childId }) {
      const { rows } = await client.query(
        `SELECT (SELECT COUNT(*)::int FROM family_event_responses
                  WHERE family_id = $1 AND event_id = $2 AND child_id = $3)
              + (SELECT COUNT(*)::int FROM family_event_attendance
                  WHERE family_id = $1 AND event_id = $2 AND child_id = $3) AS answers`,
        [familyId, eventId, childId],
      );
      return rows[0]?.answers ?? 0;
    },

    async deleteAudience(client, { familyId, eventId }) {
      // The module refuses first when a name being removed already answered; by the time this
      // runs, every row here is one nobody has answered about or attended.
      await client.query(
        `DELETE FROM family_event_audience WHERE family_id = $1 AND event_id = $2`,
        [familyId, eventId],
      );
    },

    async readEvent(client, { familyId, eventId }, { forUpdate = false } = {}) {
      const { rows } = await client.query(
        `SELECT ${EVENT_COLUMNS} FROM family_events
          WHERE id = $1 AND family_id = $2
          ${forUpdate ? 'FOR UPDATE' : ''}`,
        [eventId, familyId],
      );
      return rows[0] ?? null;
    },

    async listEvents(client, { familyId, from, to }) {
      const { rows } = await client.query(
        `SELECT ${EVENT_COLUMNS} FROM family_events
          WHERE family_id = $1 AND starts_at >= $2 AND starts_at < $3
          ORDER BY starts_at ASC, id ASC`,
        [familyId, from, to],
      );
      return rows;
    },

    /// What this child is invited to, which is the child's screen: one query, because the
    /// invitation is the row that makes an event exist for them at all.
    async listEventsForChild(client, { familyId, childId, from, to }) {
      const { rows } = await client.query(
        `SELECT ${columns(EVENT_COLUMN_LIST, 'e')} FROM family_events e
           JOIN family_event_audience aura
             ON aura.family_id = e.family_id AND aura.event_id = e.id AND aura.child_id = $3
          WHERE e.family_id = $1 AND e.starts_at >= $2 AND e.starts_at < $4
          ORDER BY e.starts_at ASC, e.id ASC`,
        [familyId, from, childId, to],
      );
      return rows;
    },

    async listAudience(client, { familyId, eventIds }) {
      if (eventIds.length === 0) return [];
      const { rows } = await client.query(
        `SELECT family_id, event_id, child_id FROM family_event_audience
          WHERE family_id = $1 AND event_id = ANY($2::uuid[])
          ORDER BY event_id, child_id`,
        [familyId, eventIds],
      );
      return rows;
    },

    async readAudience(client, { familyId, eventId, childId }) {
      const { rows } = await client.query(
        `SELECT family_id, event_id, child_id FROM family_event_audience
          WHERE family_id = $1 AND event_id = $2 AND child_id = $3`,
        [familyId, eventId, childId],
      );
      return rows[0] ?? null;
    },

    async listResponses(client, { familyId, eventIds }) {
      if (eventIds.length === 0) return [];
      const { rows } = await client.query(
        `SELECT ${RESPONSE_COLUMNS} FROM family_event_responses
          WHERE family_id = $1 AND event_id = ANY($2::uuid[])
          ORDER BY event_id, child_id`,
        [familyId, eventIds],
      );
      return rows;
    },

    async listResponsesForChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT ${RESPONSE_COLUMNS} FROM family_event_responses
          WHERE family_id = $1 AND child_id = $2`,
        [familyId, childId],
      );
      return rows;
    },

    async upsertResponse(client, { familyId, eventId, childId, response, note, respondedByDeviceId, respondedByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_event_responses
           (id, family_id, event_id, child_id, response, note,
            responded_by_device_id, responded_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (event_id, child_id) DO UPDATE
            SET response = EXCLUDED.response,
                note = EXCLUDED.note,
                responded_by_device_id = EXCLUDED.responded_by_device_id,
                responded_by_membership_id = EXCLUDED.responded_by_membership_id,
                updated_at = NOW()
         RETURNING ${RESPONSE_COLUMNS}`,
        [randomUUID(), familyId, eventId, childId, response, note, respondedByDeviceId, respondedByMembershipId],
      );
      return rows[0];
    },

    async listAttendance(client, { familyId, eventIds }) {
      if (eventIds.length === 0) return [];
      const { rows } = await client.query(
        `SELECT ${ATTENDANCE_COLUMNS} FROM family_event_attendance
          WHERE family_id = $1 AND event_id = ANY($2::uuid[])
          ORDER BY event_id, child_id`,
        [familyId, eventIds],
      );
      return rows;
    },

    async listAttendanceForChild(client, { familyId, childId }) {
      const { rows } = await client.query(
        `SELECT ${ATTENDANCE_COLUMNS} FROM family_event_attendance
          WHERE family_id = $1 AND child_id = $2`,
        [familyId, childId],
      );
      return rows;
    },

    async upsertAttendance(client, { familyId, eventId, childId, attended, note, recordedByMembershipId }) {
      const { rows } = await client.query(
        `INSERT INTO family_event_attendance
           (id, family_id, event_id, child_id, attended, note, recorded_by_membership_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (event_id, child_id) DO UPDATE
            SET attended = EXCLUDED.attended,
                note = EXCLUDED.note,
                recorded_by_membership_id = EXCLUDED.recorded_by_membership_id,
                recorded_at = NOW()
         RETURNING ${ATTENDANCE_COLUMNS}`,
        [randomUUID(), familyId, eventId, childId, attended, note, recordedByMembershipId],
      );
      return rows[0];
    },

    async updateEvent(client, { familyId, eventId, title, note, location, startsAt, endsAt, allDay, reminderMinutes }) {
      const { rows } = await client.query(
        `UPDATE family_events
            SET title = $3, note = $4, location = $5, starts_at = $6, ends_at = $7,
                all_day = $8, reminder_minutes = $9,
                version = version + 1, updated_at = NOW()
          WHERE id = $1 AND family_id = $2
          RETURNING ${EVENT_COLUMNS}`,
        [eventId, familyId, title, note, location, startsAt, endsAt, allDay, reminderMinutes],
      );
      return rows[0];
    },

    async cancelEvent(client, { familyId, eventId, cancelledByMembershipId, cancelReason }) {
      const { rows } = await client.query(
        `UPDATE family_events
            SET status = 'cancelled',
                cancelled_by_membership_id = $3,
                cancelled_at = NOW(),
                cancel_reason = $4,
                version = version + 1,
                updated_at = NOW()
          WHERE id = $1 AND family_id = $2
          RETURNING ${EVENT_COLUMNS}`,
        [eventId, familyId, cancelledByMembershipId, cancelReason],
      );
      return rows[0];
    },

    async audit(client, {
      familyId,
      actorMembershipId,
      correlationId,
      subjectId,
      subjectType,
      eventType,
    }) {
      await store.appendAuditAndOutbox(client, {
        familyId,
        actorMembershipId,
        correlationId,
        subjectId,
        subjectType,
        eventType,
      });
    },
  };
}
