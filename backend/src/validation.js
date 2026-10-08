import { HttpError } from './http-error.js';

const MAX_DISPLAY_NAME_LENGTH = 120;
const MAX_SUBJECT_LENGTH = 255;
const MAX_CHILD_AGE_YEARS = 25;
const MAX_AVATAR_EMOJI_LENGTH = 32;
const CHILD_THEME_COLORS = new Set(['purple', 'sky', 'amber', 'coral', 'mint', 'teal']);
const BATTERY_STATUSES = new Set(['charging', 'unplugged']);
const MAX_DEVICE_LABEL_LENGTH = 80;
const MAX_LOCATION_LABEL_LENGTH = 160;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const INVITABLE_ROLES = new Set(['co_guardian', 'child']);
const ZONE_GEOMETRY_KINDS = new Set(['CIRCLE', 'POLYGON']);
const MAX_ZONE_NAME_LENGTH = 80;
const MAX_ZONE_EMOJI_LENGTH = 16;
// Smallest circle worth drawing is a building; the largest is a small city district. Both
// bounds are enforced again by migration 102, and the floor here is the courtesy refusal
// that names the field instead of letting the database answer with a constraint name.
const MIN_ZONE_RADIUS_METERS = 50;
const MAX_ZONE_RADIUS_METERS = 50000;
const MAX_ZONE_VERTICES = 64;
const MAX_ZONE_CHILDREN = 24;
const MAX_FIX_ACCURACY_METERS = 100000;
const LOCATION_ACQUISITIONS = new Set(['located', 'stale_last_known', 'acquiring', 'unavailable']);
/// How far in the past or future a device clock may be and still be believed. Wider than
/// it looks on purpose: a handset with a wrong timezone is common, a handset reporting a
/// crossing that has not happened yet is not, and migration 103 refuses the latter too.
const MAX_FIX_CLOCK_SKEW_MS = 5 * 60 * 1000;

function bodyObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'invalid_request', 'Request body must be a JSON object.');
  }
  return value;
}

function onlyKnownFields(body, allowed) {
  if (Object.keys(body).some((key) => !allowed.has(key))) {
    throw new HttpError(400, 'invalid_request', 'Request body contains unsupported fields.');
  }
}

export function requiredText(value, field, { maxLength = 255 } = {}) {
  if (typeof value !== 'string') {
    throw new HttpError(400, 'invalid_request', `${field} is required.`);
  }

  const normalized = value.trim();
  if (!normalized || normalized.length > maxLength || /[\u0000-\u001F\u007F]/.test(normalized)) {
    throw new HttpError(400, 'invalid_request', `${field} is invalid.`);
  }

  return normalized;
}

export function createFamilyInput(value) {
  const body = bodyObject(value);
  return {
    displayName: requiredText(body.displayName, 'displayName', { maxLength: MAX_DISPLAY_NAME_LENGTH }),
  };
}

export function createChildInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['displayName', 'ageYears', 'avatarEmoji', 'themeColor']));
  const ageYears = body.ageYears;
  if (!Number.isInteger(ageYears) || ageYears < 0 || ageYears > MAX_CHILD_AGE_YEARS) {
    throw new HttpError(400, 'invalid_request', 'ageYears must be an integer between 0 and 25.');
  }
  const avatarEmoji = requiredText(body.avatarEmoji, 'avatarEmoji', { maxLength: MAX_AVATAR_EMOJI_LENGTH });
  if (!/\p{Extended_Pictographic}/u.test(avatarEmoji)) {
    throw new HttpError(400, 'invalid_request', 'avatarEmoji must contain an emoji.');
  }
  const themeColor = requiredText(body.themeColor, 'themeColor', { maxLength: 16 });
  if (!CHILD_THEME_COLORS.has(themeColor)) {
    throw new HttpError(400, 'invalid_request', 'themeColor is invalid.');
  }
  return {
    displayName: requiredText(body.displayName, 'displayName', { maxLength: MAX_DISPLAY_NAME_LENGTH }),
    ageYears,
    avatarEmoji,
    themeColor,
  };
}

export function registerFamilyChildDeviceInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['deviceLabel']));
  return {
    deviceLabel: requiredText(body.deviceLabel, 'deviceLabel', { maxLength: MAX_DEVICE_LABEL_LENGTH }),
  };
}

export function createDevicePairingInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['deviceLabel']));
  return {
    deviceLabel: requiredText(body.deviceLabel, 'deviceLabel', { maxLength: MAX_DEVICE_LABEL_LENGTH }),
  };
}

export function claimDevicePairingInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['pairingCode']));
  const pairingCode = requiredText(body.pairingCode, 'pairingCode', { maxLength: 128 });
  if (!/^[A-Za-z0-9_-]{32,128}$/.test(pairingCode)) {
    throw new HttpError(400, 'invalid_request', 'pairingCode is invalid.');
  }
  return { pairingCode };
}

export function deviceTelemetryInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['batteryLevel', 'batteryStatus', 'locationLat', 'locationLng', 'locationLabel']));
  const batteryLevel = body.batteryLevel;
  if (!Number.isInteger(batteryLevel) || batteryLevel < 0 || batteryLevel > 100) {
    throw new HttpError(400, 'invalid_request', 'batteryLevel must be an integer between 0 and 100.');
  }
  const batteryStatus = requiredText(body.batteryStatus, 'batteryStatus', { maxLength: 16 });
  if (!BATTERY_STATUSES.has(batteryStatus)) {
    throw new HttpError(400, 'invalid_request', 'batteryStatus must be charging or unplugged.');
  }
  const locationLat = body.locationLat;
  const locationLng = body.locationLng;
  if (!Number.isFinite(locationLat) || locationLat < -90 || locationLat > 90) {
    throw new HttpError(400, 'invalid_request', 'locationLat must be between -90 and 90.');
  }
  if (!Number.isFinite(locationLng) || locationLng < -180 || locationLng > 180) {
    throw new HttpError(400, 'invalid_request', 'locationLng must be between -180 and 180.');
  }
  return {
    batteryLevel,
    batteryStatus,
    locationLat,
    locationLng,
    locationLabel: requiredText(body.locationLabel, 'locationLabel', { maxLength: MAX_LOCATION_LABEL_LENGTH }),
  };
}

export function createMembershipInput(value) {
  const body = bodyObject(value);
  const role = requiredText(body.role, 'role', { maxLength: 32 });
  if (!INVITABLE_ROLES.has(role)) {
    throw new HttpError(400, 'invalid_request', 'role must be co_guardian or child.');
  }

  return {
    role,
    targetSubject: requiredText(body.targetSubject, 'targetSubject', { maxLength: MAX_SUBJECT_LENGTH }),
  };
}

export function createGuardianTransferInput(value) {
  const body = bodyObject(value);
  return { candidateMembershipId: requireUuid(body.candidateMembershipId, 'candidateMembershipId') };
}

export function revokeMembershipInput(value) {
  const body = bodyObject(value);
  const reasonCode = requiredText(body.reasonCode, 'reasonCode', { maxLength: 64 });
  if (!/^[a-z][a-z0-9_]{2,63}$/.test(reasonCode)) {
    throw new HttpError(400, 'invalid_request', 'reasonCode must be a stable, non-sensitive machine code.');
  }
  return { reasonCode };
}

/**
 * Revoking a child device.
 *
 * `reasonCode` is optional, and its absence is meaningful rather than a missing
 * value: a guardian cutting off a stolen handset should not have to classify the
 * loss before the device stops being trusted. The vocabulary itself is closed and
 * is enforced at the database by migration 101 as well as by the operation, so a
 * value that gets past this layer still cannot reach storage.
 */
export function revokeFamilyChildDeviceInput(value) {
  const body = value === undefined ? {} : bodyObject(value);
  onlyKnownFields(body, new Set(['reasonCode']));
  if (body.reasonCode === undefined || body.reasonCode === null) {
    return { reasonCode: null };
  }
  const reasonCode = requiredText(body.reasonCode, 'reasonCode', { maxLength: 32 });
  if (!/^[a-z][a-z0-9_]{2,31}$/.test(reasonCode)) {
    throw new HttpError(400, 'invalid_request', 'reasonCode must be a stable, non-sensitive machine code.');
  }
  return { reasonCode };
}

/**
 * A safe zone as the family defines it.
 *
 * Two shapes are first-class (circle and polygon), and the wire form carries exactly one
 * of them. The completeness rule is enforced here and again by migration 102, because a
 * circle missing its radius is not a zone with a default radius - it is a zone that would
 * silently never contain anyone.
 */
export function createSafeZoneInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set([
      'name',
      'emoji',
      'geometry',
      'childIds',
      'alertEnter',
      'alertExit',
    ]),
  );
  const name = requiredText(body.name, 'name', { maxLength: MAX_ZONE_NAME_LENGTH });
  const emoji = body.emoji === undefined
    ? '📍'
    : requiredText(body.emoji, 'emoji', { maxLength: MAX_ZONE_EMOJI_LENGTH });

  const geometryBody = bodyObject(body.geometry);
  const kind = requiredText(geometryBody.kind, 'geometry.kind', { maxLength: 16 }).toUpperCase();
  if (!ZONE_GEOMETRY_KINDS.has(kind)) {
    throw new HttpError(400, 'invalid_request', 'geometry.kind must be CIRCLE or POLYGON.');
  }

  let geometry;
  if (kind === 'CIRCLE') {
    onlyKnownFields(geometryBody, new Set(['kind', 'center', 'radiusMeters']));
    const center = bodyObject(geometryBody.center);
    onlyKnownFields(center, new Set(['latitude', 'longitude']));
    const latitude = coordinate(center.latitude, 'geometry.center.latitude', 90);
    const longitude = coordinate(center.longitude, 'geometry.center.longitude', 180);
    const radiusMeters = geometryBody.radiusMeters;
    if (
      !Number.isFinite(radiusMeters) ||
      radiusMeters < MIN_ZONE_RADIUS_METERS ||
      radiusMeters > MAX_ZONE_RADIUS_METERS
    ) {
      throw new HttpError(
        400,
        'invalid_request',
        `geometry.radiusMeters must be between ${MIN_ZONE_RADIUS_METERS} and ${MAX_ZONE_RADIUS_METERS}.`,
      );
    }
    geometry = { kind: 'CIRCLE', center: { latitude, longitude }, radiusMeters };
  } else {
    onlyKnownFields(geometryBody, new Set(['kind', 'vertices']));
    const vertices = geometryBody.vertices;
    if (!Array.isArray(vertices) || vertices.length < 3 || vertices.length > MAX_ZONE_VERTICES) {
      throw new HttpError(
        400,
        'invalid_request',
        `geometry.vertices must hold between 3 and ${MAX_ZONE_VERTICES} points.`,
      );
    }
    geometry = {
      kind: 'POLYGON',
      vertices: vertices.map((point, index) => {
        const entry = bodyObject(point);
        onlyKnownFields(entry, new Set(['latitude', 'longitude']));
        return {
          latitude: coordinate(entry.latitude, `geometry.vertices[${index}].latitude`, 90),
          longitude: coordinate(entry.longitude, `geometry.vertices[${index}].longitude`, 180),
        };
      }),
    };
  }

  const childIds = body.childIds;
  if (!Array.isArray(childIds) || childIds.length === 0 || childIds.length > MAX_ZONE_CHILDREN) {
    // Not a default. A zone assigned to nobody reads like protection and evaluates like
    // nothing at all, so the caller must say who it is for.
    throw new HttpError(
      400,
      'invalid_request',
      `childIds must name between 1 and ${MAX_ZONE_CHILDREN} children.`,
    );
  }
  const assigned = childIds.map((childId) => requireUuid(childId, 'childIds'));
  if (new Set(assigned).size !== assigned.length) {
    throw new HttpError(400, 'invalid_request', 'childIds must not repeat a child.');
  }

  return {
    name,
    emoji,
    geometry,
    childIds: assigned,
    alertEnter: optionalBoolean(body.alertEnter, 'alertEnter', true),
    alertExit: optionalBoolean(body.alertExit, 'alertExit', true),
  };
}

function coordinate(value, field, limit) {
  if (!Number.isFinite(value) || value < -limit || value > limit) {
    throw new HttpError(400, 'invalid_request', `${field} must be between ${-limit} and ${limit}.`);
  }
  return value;
}

function optionalBoolean(value, field, fallback) {
  if (value === undefined || value === null) return fallback;
  if (typeof value !== 'boolean') {
    throw new HttpError(400, 'invalid_request', `${field} must be true or false.`);
  }
  return value;
}

/**
 * One location fix reported by a child's device.
 *
 * The acquisition state is the honesty switch, not a hint: `located` and
 * `stale_last_known` must carry coordinates, and `acquiring` and `unavailable` must not.
 * A client that has not got a fix yet says so; it does not send a placeholder, and it
 * cannot send the last known position under the name of a live one.
 */
export function locationFixInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set([
      'fixId',
      'acquisition',
      'latitude',
      'longitude',
      'accuracyMeters',
      'integritySoftWarning',
      'recordedAt',
    ]),
  );

  const acquisition = requiredText(body.acquisition, 'acquisition', { maxLength: 32 });
  if (!LOCATION_ACQUISITIONS.has(acquisition)) {
    throw new HttpError(
      400,
      'invalid_request',
      `acquisition must be one of: ${[...LOCATION_ACQUISITIONS].join(', ')}.`,
    );
  }
  const carriesCoordinates = acquisition === 'located' || acquisition === 'stale_last_known';
  const latitude = carriesCoordinates ? coordinate(body.latitude, 'latitude', 90) : null;
  const longitude = carriesCoordinates ? coordinate(body.longitude, 'longitude', 180) : null;
  if (
    !carriesCoordinates &&
    (body.latitude !== undefined || body.longitude !== undefined)
  ) {
    throw new HttpError(
      400,
      'invalid_request',
      'A fix with no usable position must not carry coordinates.',
    );
  }

  let accuracyMeters = null;
  if (body.accuracyMeters !== undefined && body.accuracyMeters !== null) {
    if (
      !Number.isFinite(body.accuracyMeters) ||
      body.accuracyMeters <= 0 ||
      body.accuracyMeters > MAX_FIX_ACCURACY_METERS
    ) {
      throw new HttpError(
        400,
        'invalid_request',
        `accuracyMeters must be between 0 and ${MAX_FIX_ACCURACY_METERS}.`,
      );
    }
    accuracyMeters = body.accuracyMeters;
  }
  if (carriesCoordinates && accuracyMeters === null) {
    // The client's own invariant. A position with no stated accuracy is a position with
    // an unknown error, and the family would be shown a certainty nobody measured.
    throw new HttpError(400, 'invalid_request', 'accuracyMeters is required when a fix carries coordinates.');
  }

  const recordedAtRaw = requiredText(body.recordedAt, 'recordedAt', { maxLength: 40 });
  const recordedAt = new Date(recordedAtRaw);
  if (Number.isNaN(recordedAt.getTime())) {
    throw new HttpError(400, 'invalid_request', 'recordedAt must be an ISO-8601 timestamp.');
  }
  if (recordedAt.getTime() > Date.now() + MAX_FIX_CLOCK_SKEW_MS) {
    throw new HttpError(400, 'invalid_request', 'recordedAt is in the future.');
  }

  return {
    fixId: requireUuid(body.fixId, 'fixId'),
    acquisition,
    latitude,
    longitude,
    accuracyMeters,
    integritySoftWarning: optionalBoolean(body.integritySoftWarning, 'integritySoftWarning', false),
    recordedAt: recordedAt.toISOString(),
  };
}

/**
 * Changing which transitions a zone announces.
 *
 * Only the two flags, and at least one of them. The shape, the name and the assignment are
 * deliberately not editable here: a boundary that moves is a different boundary to anyone
 * a crossing was reported about, and editing one in place would silently re-describe an
 * arrival that already happened.
 */
export function updateSafeZoneAlertsInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['alertEnter', 'alertExit']));
  if (body.alertEnter === undefined && body.alertExit === undefined) {
    throw new HttpError(400, 'invalid_request', 'alertEnter or alertExit is required.');
  }
  return {
    alertEnter: body.alertEnter === undefined ? undefined : optionalBoolean(body.alertEnter, 'alertEnter', true),
    alertExit: body.alertExit === undefined ? undefined : optionalBoolean(body.alertExit, 'alertExit', true),
  };
}

export function requireIdempotencyKey(value) {
  return requiredText(value, 'Idempotency-Key', { maxLength: 128 });
}

export function requireNoQueryParameters(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).length !== 0) {
    throw new HttpError(400, 'invalid_request', 'This operation does not accept query parameters.');
  }
}

export function requireUuid(value, field) {
  const id = requiredText(value, field, { maxLength: 64 });
  if (!UUID_PATTERN.test(id)) {
    throw new HttpError(400, 'invalid_request', `${field} must be a UUID.`);
  }
  return id;
}

// ---------------------------------------------------------------------------------------
// W4 — the emergency surface's inputs.
//
// The honesty switch the fix parser holds is held here too, and in the same direction:
// `ready` and `stale_last_known` must carry a position AND the accuracy it came with,
// while `acquiring` and `unavailable` must not carry coordinates at all. An alarm that
// states a place nobody measured sends a family to the wrong door, and the schema refuses
// the same shapes a second time.
// ---------------------------------------------------------------------------------------

const SOS_LOCATION_CLASSES = new Set(['ready', 'acquiring', 'stale_last_known', 'unavailable']);
const SOS_CONNECTION_CLASSES = new Set(['online', 'degraded', 'offline']);
const SOS_TERMINAL_REASONS = new Set(['helped', 'false_alarm', 'other']);
const SOS_VERIFICATIONS = new Set(['unverified', 'verified', 'revoked']);
const SOS_ALERT_QUERY_STATUSES = new Set(['open', 'resolved', 'all']);
const MAX_SOS_PLACE_LABEL_LENGTH = 120;
const MAX_BACKUP_CONTACT_NAME_LENGTH = 80;
const MAX_BACKUP_CONTACT_RELATION_LENGTH = 40;
const MAX_BACKUP_CONTACT_PRIORITY = 20;
const MAX_BATTERY_PERCENT = 100;
const E164_PATTERN = /^\+[1-9][0-9]{7,14}$/;

function optionalText(value, field, maxLength) {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') {
    throw new HttpError(400, 'invalid_request', `${field} must be text.`);
  }
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > maxLength) {
    throw new HttpError(400, 'invalid_request', `${field} must be between 1 and ${maxLength} characters.`);
  }
  return trimmed;
}

function optionalIntegerInRange(value, field, min, max) {
  if (value === undefined || value === null) return null;
  if (!Number.isInteger(value) || value < min || value > max) {
    throw new HttpError(400, 'invalid_request', `${field} must be a whole number between ${min} and ${max}.`);
  }
  return value;
}

/**
 * One press of the emergency button, as the handset that felt it describes it.
 *
 * The picture travels with the press rather than being looked up afterwards, because the
 * only honest answer to "where was she when she pressed it" is the answer that was true at
 * that moment. `pressedAt` is optional: a handset that was offline reports the press when
 * it can, and a press with no stated time is the server's own clock.
 */
export function sosFireInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set([
      'locationClass',
      'latitude',
      'longitude',
      'accuracyMeters',
      'connectionClass',
      'batteryPercent',
      'placeLabel',
      'panicQuiet',
      'fixId',
      'pressedAt',
    ]),
  );

  const locationClass = requiredText(body.locationClass, 'locationClass', { maxLength: 32 });
  if (!SOS_LOCATION_CLASSES.has(locationClass)) {
    throw new HttpError(
      400,
      'invalid_request',
      `locationClass must be one of: ${[...SOS_LOCATION_CLASSES].join(', ')}.`,
    );
  }
  const carriesCoordinates = locationClass === 'ready' || locationClass === 'stale_last_known';
  const latitude = carriesCoordinates ? coordinate(body.latitude, 'latitude', 90) : null;
  const longitude = carriesCoordinates ? coordinate(body.longitude, 'longitude', 180) : null;
  if (!carriesCoordinates && (body.latitude !== undefined || body.longitude !== undefined)) {
    throw new HttpError(
      400,
      'invalid_request',
      'A press with no usable position must not carry coordinates.',
    );
  }

  let accuracyMeters = null;
  if (body.accuracyMeters !== undefined && body.accuracyMeters !== null) {
    if (
      !Number.isFinite(body.accuracyMeters) ||
      body.accuracyMeters <= 0 ||
      body.accuracyMeters > MAX_FIX_ACCURACY_METERS
    ) {
      throw new HttpError(
        400,
        'invalid_request',
        `accuracyMeters must be between 0 and ${MAX_FIX_ACCURACY_METERS}.`,
      );
    }
    accuracyMeters = body.accuracyMeters;
  }
  if (carriesCoordinates && accuracyMeters === null) {
    throw new HttpError(
      400,
      'invalid_request',
      'accuracyMeters is required when a press carries a position.',
    );
  }
  if (!carriesCoordinates && accuracyMeters !== null) {
    throw new HttpError(
      400,
      'invalid_request',
      'A press with no usable position must not carry an accuracy.',
    );
  }

  const connectionClass = requiredText(body.connectionClass, 'connectionClass', { maxLength: 16 });
  if (!SOS_CONNECTION_CLASSES.has(connectionClass)) {
    throw new HttpError(
      400,
      'invalid_request',
      `connectionClass must be one of: ${[...SOS_CONNECTION_CLASSES].join(', ')}.`,
    );
  }

  let pressedAt = null;
  if (body.pressedAt !== undefined && body.pressedAt !== null) {
    const parsed = new Date(requiredText(body.pressedAt, 'pressedAt', { maxLength: 40 }));
    if (Number.isNaN(parsed.getTime())) {
      throw new HttpError(400, 'invalid_request', 'pressedAt must be an ISO-8601 timestamp.');
    }
    if (parsed.getTime() > Date.now() + MAX_FIX_CLOCK_SKEW_MS) {
      throw new HttpError(400, 'invalid_request', 'pressedAt is in the future.');
    }
    pressedAt = parsed.toISOString();
  }

  return {
    picture: {
      locationClass,
      latitude,
      longitude,
      accuracyMeters,
      connectionClass,
      batteryPercent: optionalIntegerInRange(body.batteryPercent, 'batteryPercent', 0, MAX_BATTERY_PERCENT),
      placeLabel: optionalText(body.placeLabel, 'placeLabel', MAX_SOS_PLACE_LABEL_LENGTH),
      panicQuiet: optionalBoolean(body.panicQuiet, 'panicQuiet', false),
      pressedAt,
    },
    fixId: body.fixId === undefined || body.fixId === null ? null : requireUuid(body.fixId, 'fixId'),
  };
}

/** How an incident ends. The reason is required: a closed incident with no reason explains nothing. */
export function sosResolveInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['terminalReason']));
  const terminalReason = requiredText(body.terminalReason, 'terminalReason', { maxLength: 24 });
  if (!SOS_TERMINAL_REASONS.has(terminalReason)) {
    throw new HttpError(
      400,
      'invalid_request',
      `terminalReason must be one of: ${[...SOS_TERMINAL_REASONS].join(', ')}.`,
    );
  }
  return { terminalReason };
}

/**
 * A new rung on the family's ladder.
 *
 * `verification` is deliberately absent from this parser: a contact is created
 * `unverified`, and only a separate act marks it verified. A number that verifies itself
 * on the way in is a number nobody checked.
 */
export function sosBackupContactInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['name', 'relation', 'phoneE164', 'priority', 'enabled']));
  const phoneE164 = requiredText(body.phoneE164, 'phoneE164', { maxLength: 20 }).trim();
  if (!E164_PATTERN.test(phoneE164)) {
    throw new HttpError(400, 'invalid_request', 'phoneE164 must be an E.164 number, for example +967771234567.');
  }
  return {
    name: requiredText(body.name, 'name', { maxLength: MAX_BACKUP_CONTACT_NAME_LENGTH }),
    relation: optionalText(body.relation, 'relation', MAX_BACKUP_CONTACT_RELATION_LENGTH) ?? '',
    phoneE164,
    priority: optionalIntegerInRange(body.priority, 'priority', 1, MAX_BACKUP_CONTACT_PRIORITY) ?? 1,
    enabled: optionalBoolean(body.enabled, 'enabled', true),
  };
}

/** Changing one rung: rename it, renumber it, verify it, switch it off or archive it. */
export function sosBackupContactUpdateInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set(['name', 'relation', 'phoneE164', 'verification', 'enabled', 'priority', 'archived']),
  );
  if (Object.keys(body).length === 0) {
    throw new HttpError(400, 'invalid_request', 'At least one field must be provided.');
  }

  let phoneE164;
  if (body.phoneE164 !== undefined) {
    phoneE164 = requiredText(body.phoneE164, 'phoneE164', { maxLength: 20 }).trim();
    if (!E164_PATTERN.test(phoneE164)) {
      throw new HttpError(400, 'invalid_request', 'phoneE164 must be an E.164 number, for example +967771234567.');
    }
  }

  let verification;
  if (body.verification !== undefined) {
    verification = requiredText(body.verification, 'verification', { maxLength: 16 });
    if (!SOS_VERIFICATIONS.has(verification)) {
      throw new HttpError(
        400,
        'invalid_request',
        `verification must be one of: ${[...SOS_VERIFICATIONS].join(', ')}.`,
      );
    }
  }

  return {
    name: body.name === undefined ? undefined : requiredText(body.name, 'name', { maxLength: MAX_BACKUP_CONTACT_NAME_LENGTH }),
    relation: body.relation === undefined ? undefined : (optionalText(body.relation, 'relation', MAX_BACKUP_CONTACT_RELATION_LENGTH) ?? ''),
    phoneE164,
    verification,
    enabled: body.enabled === undefined ? undefined : optionalBoolean(body.enabled, 'enabled', true),
    priority: body.priority === undefined ? undefined : optionalIntegerInRange(body.priority, 'priority', 1, MAX_BACKUP_CONTACT_PRIORITY),
    archived: body.archived === undefined ? undefined : optionalBoolean(body.archived, 'archived', false),
  };
}

/** Which incidents a family read is asking for. Defaults to the ones still in flight. */
export function sosAlertListQuery(value) {
  const query = bodyObject(value ?? {});
  onlyKnownFields(query, new Set(['status']));
  if (query.status === undefined) return 'open';
  const status = requiredText(query.status, 'status', { maxLength: 16 });
  if (!SOS_ALERT_QUERY_STATUSES.has(status)) {
    throw new HttpError(
      400,
      'invalid_request',
      `status must be one of: ${[...SOS_ALERT_QUERY_STATUSES].join(', ')}.`,
    );
  }
  return status;
}

// ---------------------------------------------------------------------------------------
// W5 — the screen-time surface's inputs.
//
// Every number a family sets is bounded here as well as in the schema, and the bounds are
// the product's: a day holds 1440 minutes, an extension is asked for in minutes up to four
// hours, a lock has a reason, and a usage report is a cumulative figure per app rather than
// a delta - so a handset cannot report "5 minutes" and have the server subtract anything.
//
// The one shape worth stating: an app report carries what the handset SAW (name, category)
// and what it MEASURED (minutes). A report that omits the name is refused rather than
// stored under the app id, because a family reading "com.unknown.pkg" learns nothing.
// ---------------------------------------------------------------------------------------

const APP_CATEGORY_VALUES = new Set(['games', 'social', 'edu', 'tools']);
const APP_RULE_STATUS_VALUES = new Set(['allowed', 'free', 'blocked', 'pending']);
const LOCK_REASON_VALUES = new Set(['parent_lock', 'check_in', 'task_time', 'other']);
const TIME_REQUEST_STATUSES = new Set(['pending', 'approved', 'denied', 'expired']);
const TIME_REQUEST_DECISIONS = new Set(['approve', 'deny']);
const MAX_APP_ID_LENGTH = 120;
const MAX_APP_NAME_LENGTH = 120;
const MAX_AGE_RATING_LENGTH = 16;
const MAX_REQUESTED_MINUTES = 240;
const MAX_DAILY_LIMIT_MINUTES = 1440;
const MAX_APP_REPORTS = 200;
const MAX_USAGE_MINUTES_PER_APP = 1440;
const MAX_LOCK_REASON_CODE_LENGTH = 40;
const DAY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const APP_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$/;

function requiredWholeNumber(value, field, min, max) {
  if (!Number.isInteger(value) || value < min || value > max) {
    throw new HttpError(
      400,
      'invalid_request',
      `${field} must be a whole number between ${min} and ${max}.`,
    );
  }
  return value;
}

function optionalWholeNumber(value, field, min, max) {
  if (value === undefined || value === null) return null;
  return requiredWholeNumber(value, field, min, max);
}

/** One day of the week, 1 = Monday ... 7 = Sunday. */
function schoolDays(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpError(400, 'invalid_request', 'schoolMode.days must list at least one weekday.');
  }
  const days = value.map((entry, index) =>
    requiredWholeNumber(entry, `schoolMode.days[${index}]`, 1, 7));
  return [...new Set(days)].sort((left, right) => left - right);
}

/**
 * The family's policy for one child. Every field optional, because a screen that changes
 * bedtime should not have to resend the daily cap - and the unchanged fields keep their
 * stored value rather than being reset to a default nobody chose.
 */
export function screenTimePolicyInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set([
      'dailyLimitMinutes',
      'schoolMode',
      'bedtime',
      'timezoneOffsetMinutes',
      'expectedVersion',
    ]),
  );
  const policy = {};
  if (body.dailyLimitMinutes !== undefined) {
    policy.dailyLimitMinutes = requiredWholeNumber(
      body.dailyLimitMinutes,
      'dailyLimitMinutes',
      0,
      MAX_DAILY_LIMIT_MINUTES,
    );
  }
  if (body.schoolMode !== undefined) {
    const school = bodyObject(body.schoolMode);
    onlyKnownFields(school, new Set(['enabled', 'days', 'startMinute', 'endMinute']));
    policy.schoolMode = {
      enabled: school.enabled === undefined
        ? undefined
        : optionalBoolean(school.enabled, 'schoolMode.enabled', false),
      days: school.days === undefined ? undefined : schoolDays(school.days),
      startMinute: school.startMinute === undefined
        ? undefined
        : requiredWholeNumber(school.startMinute, 'schoolMode.startMinute', 0, 1439),
      endMinute: school.endMinute === undefined
        ? undefined
        : requiredWholeNumber(school.endMinute, 'schoolMode.endMinute', 0, 1439),
    };
  }
  if (body.bedtime !== undefined) {
    const bedtime = bodyObject(body.bedtime);
    onlyKnownFields(bedtime, new Set(['startMinute', 'endMinute']));
    policy.bedtime = {
      startMinute: bedtime.startMinute === undefined
        ? undefined
        : requiredWholeNumber(bedtime.startMinute, 'bedtime.startMinute', 0, 1439),
      endMinute: bedtime.endMinute === undefined
        ? undefined
        : requiredWholeNumber(bedtime.endMinute, 'bedtime.endMinute', 0, 1439),
    };
  }
  if (body.timezoneOffsetMinutes !== undefined) {
    policy.timezoneOffsetMinutes = requiredWholeNumber(
      body.timezoneOffsetMinutes,
      'timezoneOffsetMinutes',
      -720,
      840,
    );
  }
  if (Object.keys(policy).length === 0) {
    throw new HttpError(400, 'invalid_request', 'At least one policy field must be sent.');
  }
  const expectedVersion = optionalWholeNumber(body.expectedVersion, 'expectedVersion', 0, 1_000_000);
  return { policy, expectedVersion };
}

/**
 * An app identifier as it appears in a path: a package name, not a UUID.
 *
 * It is checked here rather than trusted from the URL for the same reason every other
 * identifier is: the value ends up in a row keyed by (child, app), and a client that could
 * put a slash or a space in it could make two different apps collide in a family's screen.
 */
export function requireAppId(value) {
  const appId = requiredText(value, 'appId', { maxLength: MAX_APP_ID_LENGTH });
  if (!APP_ID_PATTERN.test(appId)) {
    throw new HttpError(
      400,
      'invalid_request',
      'appId must be a package-style identifier of letters, digits, dot, dash or underscore.',
    );
  }
  return appId;
}

/** One app's rule. A limit on an app that does not count is refused, as the schema refuses it. */
export function appRuleInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['status', 'limitMinutes', 'unlimited']));
  const status = requiredText(body.status, 'status', { maxLength: 16 });
  if (!APP_RULE_STATUS_VALUES.has(status)) {
    throw new HttpError(
      400,
      'invalid_request',
      `status must be one of: ${[...APP_RULE_STATUS_VALUES].join(', ')}.`,
    );
  }
  const limitMinutes = optionalWholeNumber(body.limitMinutes, 'limitMinutes', 1, MAX_DAILY_LIMIT_MINUTES);
  const unlimited = body.unlimited === undefined
    ? false
    : optionalBoolean(body.unlimited, 'unlimited', false);
  if (status !== 'allowed' && limitMinutes != null) {
    throw new HttpError(400, 'invalid_request', 'Only an allowed app may carry a limit.');
  }
  if (status !== 'allowed' && unlimited) {
    throw new HttpError(400, 'invalid_request', 'Only an allowed app may be unlimited.');
  }
  return { status, limitMinutes, unlimited };
}

/** An instant lock's reason. A lock without one is a lock nobody can explain later. */
export function lockInput(value) {
  const body = value === undefined || value === null ? {} : bodyObject(value);
  onlyKnownFields(body, new Set(['reasonCode']));
  const reasonCode = body.reasonCode === undefined
    ? 'parent_lock'
    : requiredText(body.reasonCode, 'reasonCode', { maxLength: 24 });
  if (!LOCK_REASON_VALUES.has(reasonCode)) {
    throw new HttpError(
      400,
      'invalid_request',
      `reasonCode must be one of: ${[...LOCK_REASON_VALUES].join(', ')}.`,
    );
  }
  return { reasonCode };
}

/** The child's question: how many minutes, and optionally why. */
export function timeRequestInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['requestedMinutes', 'reasonCode']));
  return {
    requestedMinutes: requiredWholeNumber(body.requestedMinutes, 'requestedMinutes', 1, MAX_REQUESTED_MINUTES),
    reasonCode: body.reasonCode === undefined
      ? null
      : requiredText(body.reasonCode, 'reasonCode', { maxLength: MAX_LOCK_REASON_CODE_LENGTH }),
  };
}

/** A guardian's answer: approve with minutes, or deny. Nothing else. */
export function timeRequestDecisionInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['decision', 'grantedMinutes']));
  const decision = requiredText(body.decision, 'decision', { maxLength: 8 });
  if (!TIME_REQUEST_DECISIONS.has(decision)) {
    throw new HttpError(
      400,
      'invalid_request',
      `decision must be one of: ${[...TIME_REQUEST_DECISIONS].join(', ')}.`,
    );
  }
  if (decision === 'deny' && body.grantedMinutes !== undefined) {
    throw new HttpError(400, 'invalid_request', 'A denied request carries no granted minutes.');
  }
  return {
    decision,
    grantedMinutes: optionalWholeNumber(body.grantedMinutes, 'grantedMinutes', 1, MAX_REQUESTED_MINUTES),
  };
}

/** Which requests a read is asking for. */
export function timeRequestListQuery(value) {
  const query = bodyObject(value ?? {});
  onlyKnownFields(query, new Set(['status']));
  if (query.status === undefined) return 'all';
  const status = requiredText(query.status, 'status', { maxLength: 16 });
  if (!TIME_REQUEST_STATUSES.has(status) && status !== 'all') {
    throw new HttpError(
      400,
      'invalid_request',
      `status must be one of: ${[...TIME_REQUEST_STATUSES, 'all'].join(', ')}.`,
    );
  }
  return status;
}

/** One app's usage as the handset measured it: cumulative minutes for a day. */
function usageEntry(value, index) {
  const entry = bodyObject(value);
  onlyKnownFields(entry, new Set(['appId', 'usedMinutes', 'date']));
  const date = entry.date === undefined ? null : requiredText(entry.date, `usage[${index}].date`, { maxLength: 10 });
  if (date != null && !DAY_PATTERN.test(date)) {
    throw new HttpError(400, 'invalid_request', `usage[${index}].date must be YYYY-MM-DD.`);
  }
  return {
    appId: requiredText(entry.appId, `usage[${index}].appId`, { maxLength: MAX_APP_ID_LENGTH }),
    usedMinutes: requiredWholeNumber(entry.usedMinutes, `usage[${index}].usedMinutes`, 0, MAX_USAGE_MINUTES_PER_APP),
    date,
  };
}

/** One installed app as the handset described it. */
function appEntry(value, index) {
  const entry = bodyObject(value);
  onlyKnownFields(entry, new Set(['appId', 'displayName', 'category', 'ageRating']));
  const category = requiredText(entry.category, `apps[${index}].category`, { maxLength: 16 });
  if (!APP_CATEGORY_VALUES.has(category)) {
    throw new HttpError(
      400,
      'invalid_request',
      `apps[${index}].category must be one of: ${[...APP_CATEGORY_VALUES].join(', ')}.`,
    );
  }
  return {
    appId: requiredText(entry.appId, `apps[${index}].appId`, { maxLength: MAX_APP_ID_LENGTH }),
    displayName: requiredText(entry.displayName, `apps[${index}].displayName`, { maxLength: MAX_APP_NAME_LENGTH }),
    category,
    ageRating: entry.ageRating === undefined
      ? ''
      : requiredText(entry.ageRating, `apps[${index}].ageRating`, { maxLength: MAX_AGE_RATING_LENGTH }),
  };
}

/** What a child's handset reports in one call: minutes, inventory, and maybe a question. */
export function deviceScreenTimeReportInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['usage', 'apps', 'request']));
  const rawUsage = body.usage === undefined ? [] : body.usage;
  const rawApps = body.apps === undefined ? [] : body.apps;
  if (!Array.isArray(rawUsage) || rawUsage.length > MAX_APP_REPORTS) {
    throw new HttpError(400, 'invalid_request', `usage must hold at most ${MAX_APP_REPORTS} entries.`);
  }
  if (!Array.isArray(rawApps) || rawApps.length > MAX_APP_REPORTS) {
    throw new HttpError(400, 'invalid_request', `apps must hold at most ${MAX_APP_REPORTS} entries.`);
  }
  const usage = rawUsage.map(usageEntry);
  const apps = rawApps.map(appEntry);
  const seen = new Set(usage.map((entry) => `${entry.date ?? ''}\u0000${entry.appId}`));
  if (seen.size !== usage.length) {
    throw new HttpError(400, 'invalid_request', 'usage must name each app once per day.');
  }
  const request = body.request === undefined ? null : timeRequestInput(body.request);
  return { usage, apps, request };
}

// ── W6 WEB FILTER ──────────────────────────────────────────────────────────────────────
//
// The body rules for the filtering surface. Two of them are the whole wave in miniature:
// a category key the server does not know is refused here rather than stored, because a
// toggle that does nothing is worse than a toggle that errors; and a temporary-allow
// request is bounded in the body as well as in the schema, so an absurd number never
// reaches the database to be refused there.

const MAX_FILTER_HOST_LENGTH = 253;

// W7 bounds. They live here rather than in two files so a route and a validator cannot
// disagree about what a task may say.
const MAX_TASK_TITLE_LENGTH = 120;
const MAX_TASK_NOTE_LENGTH = 300;
const TASK_POINTS_MIN = 1;
const TASK_POINTS_MAX = 200;
const MAX_FILTER_LIST_ENTRIES = 200;
const MAX_FILTER_KEYWORD_LENGTH = 64;
const MAX_TEMP_ALLOW_MINUTES = 240;
const MAX_TEMP_ALLOW_GRANT_MINUTES = 120;
const WEB_FILTER_LEVELS = new Set(['strict', 'balanced', 'open']);
const WEB_FILTER_OBSERVED_STATES = new Set([
  'healthy',
  'vpn_active',
  'profile_removed',
  'permission_revoked',
  'dns_bypassed',
  'device_admin_removed',
  'unsupported',
]);

function hostList(value, field) {
  if (!Array.isArray(value)) {
    throw new HttpError(400, 'invalid_request', `${field} must be a list of hostnames.`);
  }
  if (value.length > MAX_FILTER_LIST_ENTRIES) {
    throw new HttpError(400, 'invalid_request', `${field} must hold at most ${MAX_FILTER_LIST_ENTRIES} entries.`);
  }
  return value.map((entry, index) => {
    if (typeof entry !== 'string') {
      throw new HttpError(400, 'invalid_request', `${field}[${index}] must be a hostname.`);
    }
    const host = entry.trim().toLowerCase();
    if (host.length > MAX_FILTER_HOST_LENGTH || /[\u0000-\u001F\u007F\s]/.test(host)) {
      throw new HttpError(400, 'invalid_request', `${field}[${index}] is not a hostname.`);
    }
    return host;
  });
}

function keywordList(value, field) {
  if (!Array.isArray(value)) {
    throw new HttpError(400, 'invalid_request', `${field} must be a list of keywords.`);
  }
  if (value.length > MAX_FILTER_LIST_ENTRIES) {
    throw new HttpError(400, 'invalid_request', `${field} must hold at most ${MAX_FILTER_LIST_ENTRIES} entries.`);
  }
  return value.map((entry, index) => {
    if (typeof entry !== 'string' || entry.trim() === '' || entry.trim().length > MAX_FILTER_KEYWORD_LENGTH) {
      throw new HttpError(400, 'invalid_request', `${field}[${index}] is not a usable keyword.`);
    }
    return entry.trim().toLowerCase();
  });
}

/**
 * A partial statement of the family's filter policy. Every field optional for the same
 * reason screen time's policy is: flipping one switch must not reset the other five.
 */
export function webFilterPolicyInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set(['level', 'categories', 'allowHosts', 'blockHosts', 'dictionaryKeywords', 'expectedVersion']),
  );
  const change = {};
  if (body.level !== undefined) {
    if (typeof body.level !== 'string' || !WEB_FILTER_LEVELS.has(body.level.trim().toLowerCase())) {
      throw new HttpError(400, 'invalid_request', 'level must be one of strict, balanced, open.');
    }
    change.level = body.level.trim().toLowerCase();
  }
  if (body.categories !== undefined) {
    if (!Array.isArray(body.categories)) {
      throw new HttpError(400, 'invalid_request', 'categories must be a list of category keys.');
    }
    change.categories = body.categories.map((entry, index) => {
      if (typeof entry !== 'string' || entry.trim() === '') {
        throw new HttpError(400, 'invalid_request', `categories[${index}] must be a category key.`);
      }
      return entry.trim().toLowerCase();
    });
  }
  if (body.allowHosts !== undefined) change.allowHosts = hostList(body.allowHosts, 'allowHosts');
  if (body.blockHosts !== undefined) change.blockHosts = hostList(body.blockHosts, 'blockHosts');
  if (body.dictionaryKeywords !== undefined) {
    change.dictionaryKeywords = keywordList(body.dictionaryKeywords, 'dictionaryKeywords');
  }
  // Zero is a real value here, not a sentinel: a policy that has never been saved has no
  // version, and a screen that read `version: 0` must be able to send it back.
  const expectedVersion = optionalWholeNumber(body.expectedVersion, 'expectedVersion', 0, 1000000);
  return { change, expectedVersion };
}

/** A question from a handset or a guardian: one host, a bounded number of minutes. */
export function tempAllowRequestInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['host', 'minutes', 'reason']));
  const host = requiredText(body.host, 'host', { maxLength: MAX_FILTER_HOST_LENGTH }).toLowerCase();
  const minutes = requiredWholeNumber(body.minutes, 'minutes', 1, MAX_TEMP_ALLOW_MINUTES);
  const reason = body.reason === undefined ? '' : optionalText(body.reason, 'reason', 300);
  return { host, minutes, reason: reason ?? '' };
}

/** The answer: approve (optionally for fewer minutes than asked) or deny. */
export function tempAllowDecisionInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['decision', 'grantedMinutes']));
  const decision = requiredText(body.decision, 'decision', { maxLength: 16 }).toLowerCase();
  if (decision !== 'approve' && decision !== 'deny') {
    throw new HttpError(400, 'invalid_request', 'decision must be approve or deny.');
  }
  const grantedMinutes = optionalWholeNumber(
    body.grantedMinutes,
    'grantedMinutes',
    1,
    MAX_TEMP_ALLOW_GRANT_MINUTES,
  );
  return { decision, grantedMinutes };
}

/** A handset's testimony about its own protection plane. */
export function protectionReportInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['observedState', 'signals', 'detail', 'observedAt']));
  const observedState = requiredText(body.observedState, 'observedState', { maxLength: 40 }).toLowerCase();
  if (!WEB_FILTER_OBSERVED_STATES.has(observedState)) {
    throw new HttpError(400, 'invalid_request', 'observedState is not a state this server knows.');
  }
  const rawSignals = body.signals === undefined ? [] : body.signals;
  if (!Array.isArray(rawSignals) || rawSignals.length > 32) {
    throw new HttpError(400, 'invalid_request', 'signals must hold at most 32 entries.');
  }
  const signals = rawSignals.map((entry, index) => {
    if (typeof entry !== 'string' || entry.trim() === '' || entry.trim().length > 64) {
      throw new HttpError(400, 'invalid_request', `signals[${index}] is not a usable signal.`);
    }
    return entry.trim().toLowerCase();
  });
  const detail = body.detail === undefined ? '' : (optionalText(body.detail, 'detail', 500) ?? '');
  let observedAt = null;
  if (body.observedAt !== undefined) {
    const parsed = typeof body.observedAt === 'string' ? new Date(body.observedAt) : new Date(NaN);
    if (Number.isNaN(parsed.getTime())) {
      throw new HttpError(400, 'invalid_request', 'observedAt must be an ISO-8601 instant.');
    }
    observedAt = parsed;
  }
  return { observedState, signals, detail, observedAt };
}

/** The preview query a father uses to see what his child would get. */
export function webFilterEvaluateQuery(value) {
  const host = requiredText(value?.host, 'host', { maxLength: MAX_FILTER_HOST_LENGTH });
  return { host };
}

// ── W7 — family tasks and points ───────────────────────────────────────────────────────

/** A guardian states a task: what it is, what "done" means, and what it pays. */
export function taskCreateInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['title', 'note', 'points']));
  const title = requiredText(body.title, 'title', { maxLength: MAX_TASK_TITLE_LENGTH });
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_TASK_NOTE_LENGTH) ?? '');
  // Whole numbers only, and bounded on both sides: a screen may not round a guardian's
  // decision, and it may not turn a chore into pocket money beyond what one task can state.
  const points = requiredWholeNumber(body.points, 'points', TASK_POINTS_MIN, TASK_POINTS_MAX);
  return { title, note, points };
}

/** "I did it" - said by a handset or by a guardian for a child who spoke instead. */
export function taskClaimInput(value) {
  const body = value === undefined || value === null ? {} : bodyObject(value);
  onlyKnownFields(body, new Set(['note']));
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_TASK_NOTE_LENGTH) ?? '');
  return { note };
}

/** The guardian's word on a claim. Note what is absent: no number of points, because the
 *  task states the reward and this request may not restate it. */
export function taskDecisionInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['decision', 'note']));
  const decision = requiredText(body.decision, 'decision', { maxLength: 16 }).toLowerCase();
  if (decision !== 'confirm' && decision !== 'decline') {
    throw new HttpError(400, 'invalid_request', 'decision must be confirm or decline.');
  }
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_TASK_NOTE_LENGTH) ?? '');
  return { decision, note };
}

// ── W8 — the family calendar ────────────────────────────────────────────────────────────

const MAX_EVENT_TITLE_LENGTH = 120;
const MAX_EVENT_NOTE_LENGTH = 300;
const MAX_EVENT_LOCATION_LENGTH = 160;
const MAX_EVENT_CANCEL_REASON_LENGTH = 200;
const MAX_EVENT_AUDIENCE = 24;
const EVENT_REMINDER_MAX_MINUTES = 10080;
/// How far ahead a family may state an event. A bound, not a policy: it exists so a wrong year
/// is a refusal naming the field instead of a row that will never be looked at again.
const MAX_EVENT_HORIZON_MS = 1095 * 24 * 3600 * 1000;
const EVENT_RESPONSE_VALUES = new Set(['accepted', 'declined']);

/** One instant, as ISO-8601. The parser refuses a date-only value on purpose: "2026-10-08"
 *  is a day, and an event is at a moment. */
function requiredInstant(value, field) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpError(400, 'invalid_request', `${field} must be an ISO-8601 instant.`);
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpError(400, 'invalid_request', `${field} must be an ISO-8601 instant.`);
  }
  return parsed.toISOString();
}

function optionalInstant(value, field) {
  if (value === undefined || value === null) return null;
  return requiredInstant(value, field);
}

/** The audience: at least one child, at most the bound the schema also enforces. */
function eventAudience(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpError(400, 'invalid_request', 'childIds must name at least one child.');
  }
  if (value.length > MAX_EVENT_AUDIENCE) {
    throw new HttpError(400, 'invalid_request', `childIds may name at most ${MAX_EVENT_AUDIENCE} children.`);
  }
  const seen = new Set();
  const childIds = [];
  for (const entry of value) {
    if (typeof entry !== 'string' || !UUID_PATTERN.test(entry)) {
      throw new HttpError(400, 'invalid_request', 'childIds must contain uuids.');
    }
    // A duplicate is a client bug, not a bigger audience; collapsing it keeps the stored
    // audience equal to what the guardian actually ticked.
    if (seen.has(entry.toLowerCase())) continue;
    seen.add(entry.toLowerCase());
    childIds.push(entry);
  }
  return childIds;
}

/** A guardian states an event: when, what, where, who it is for, and what reminder they want.
 *  Note what is absent: any notion of who was notified, because this request cannot know. */
export function eventCreateInput(value, { now = new Date() } = {}) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set(['title', 'note', 'location', 'startsAt', 'endsAt', 'allDay', 'reminderMinutes', 'childIds']),
  );
  const title = requiredText(body.title, 'title', { maxLength: MAX_EVENT_TITLE_LENGTH });
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_EVENT_NOTE_LENGTH) ?? '');
  const location = body.location === undefined ? '' : (optionalText(body.location, 'location', MAX_EVENT_LOCATION_LENGTH) ?? '');
  const startsAt = requiredInstant(body.startsAt, 'startsAt');
  const endsAt = requiredInstant(body.endsAt, 'endsAt');
  if (new Date(endsAt) <= new Date(startsAt)) {
    throw new HttpError(400, 'invalid_request', 'endsAt must be after startsAt.');
  }
  if (new Date(startsAt).getTime() > now.getTime() + MAX_EVENT_HORIZON_MS) {
    throw new HttpError(400, 'invalid_request', 'startsAt is further away than a calendar should hold.');
  }
  if (body.allDay !== undefined && typeof body.allDay !== 'boolean') {
    throw new HttpError(400, 'invalid_request', 'allDay must be true or false.');
  }
  const reminderMinutes =
    body.reminderMinutes === undefined || body.reminderMinutes === null
      ? null
      : requiredWholeNumber(body.reminderMinutes, 'reminderMinutes', 0, EVENT_REMINDER_MAX_MINUTES);
  return {
    title,
    note,
    location,
    startsAt,
    endsAt,
    allDay: body.allDay === true,
    reminderMinutes,
    childIds: eventAudience(body.childIds),
  };
}

/** An edit states the version it read. `childIds` is optional: absent means the audience is
 *  not part of this edit, and present means it is replaced. */
export function eventUpdateInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(
    body,
    new Set(['version', 'title', 'note', 'location', 'startsAt', 'endsAt', 'allDay', 'reminderMinutes', 'childIds']),
  );
  const version = requiredWholeNumber(body.version, 'version', 1, 1000000);
  const changes = {};
  if (body.title !== undefined) changes.title = requiredText(body.title, 'title', { maxLength: MAX_EVENT_TITLE_LENGTH });
  if (body.note !== undefined) changes.note = optionalText(body.note, 'note', MAX_EVENT_NOTE_LENGTH) ?? '';
  if (body.location !== undefined) changes.location = optionalText(body.location, 'location', MAX_EVENT_LOCATION_LENGTH) ?? '';
  if (body.startsAt !== undefined) changes.startsAt = requiredInstant(body.startsAt, 'startsAt');
  if (body.endsAt !== undefined) changes.endsAt = requiredInstant(body.endsAt, 'endsAt');
  if (body.allDay !== undefined) {
    if (typeof body.allDay !== 'boolean') {
      throw new HttpError(400, 'invalid_request', 'allDay must be true or false.');
    }
    changes.allDay = body.allDay;
  }
  if (body.reminderMinutes !== undefined) {
    changes.reminderMinutes =
      body.reminderMinutes === null
        ? null
        : requiredWholeNumber(body.reminderMinutes, 'reminderMinutes', 0, EVENT_REMINDER_MAX_MINUTES);
  }
  if (body.childIds !== undefined) changes.childIds = eventAudience(body.childIds);
  if (Object.keys(changes).length === 0) {
    // An edit that changes nothing would still bump the version and wake every reader; a
    // request with no fields is a client bug, and refusing it keeps the version meaningful.
    throw new HttpError(400, 'invalid_request', 'An update must change at least one field.');
  }
  return { version, changes };
}

/** Calling an event off: a reason is required, because a cancellation a child cannot
 *  understand is worse than the cancellation itself. */
export function eventCancelInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['reason']));
  const reason = requiredText(body.reason, 'reason', { maxLength: MAX_EVENT_CANCEL_REASON_LENGTH });
  return { reason };
}

/** The child's answer - or the guardian's record of it. */
export function eventResponseInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['response', 'note']));
  const response = requiredText(body.response, 'response', { maxLength: 16 }).toLowerCase();
  if (!EVENT_RESPONSE_VALUES.has(response)) {
    throw new HttpError(400, 'invalid_request', 'response must be accepted or declined.');
  }
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_EVENT_NOTE_LENGTH) ?? '');
  return { response, note };
}

/** What happened, recorded after the fact. */
export function eventAttendanceInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['childId', 'attended', 'note']));
  const childId = requiredText(body.childId, 'childId', { maxLength: 64 });
  if (!UUID_PATTERN.test(childId)) {
    throw new HttpError(400, 'invalid_request', 'childId must be a uuid.');
  }
  if (typeof body.attended !== 'boolean') {
    throw new HttpError(400, 'invalid_request', 'attended must be true or false.');
  }
  const note = body.note === undefined ? '' : (optionalText(body.note, 'note', MAX_EVENT_NOTE_LENGTH) ?? '');
  return { childId, attended: body.attended, note };
}

/** The window a calendar read asks for. `from` and `to` are required and bounded: a read
 *  without a window would ask the server for a family's whole history to draw one week. */
export function eventRangeQuery(value) {
  const from = requiredInstant(value?.from, 'from');
  const to = requiredInstant(value?.to, 'to');
  if (new Date(to) <= new Date(from)) {
    throw new HttpError(400, 'invalid_request', 'to must be after from.');
  }
  const days = (new Date(to).getTime() - new Date(from).getTime()) / (24 * 3600 * 1000);
  if (days > 400) {
    throw new HttpError(400, 'invalid_request', 'A calendar window may span at most 400 days.');
  }
  return { from, to };
}

// ── W9 — the family chat ────────────────────────────────────────────────────────────────
//
// The inputs here hold the two honesty rules this wave cannot afford to lose at the door:
// a message body is text the family wrote (so control characters are refused but lines and
// tabs are kept), and a client message id is a name the CLIENT gives its own message - which
// is why it has a shape the server can trust to be an identifier and not a fragment of
// content. Everything else about authorship is decided by how the request arrived, never by
// a field in these bodies.

const MAX_CHAT_TITLE_LENGTH = 120;
const MAX_CHAT_BODY_LENGTH = 2000;
const MAX_CHAT_PARTICIPANTS = 24;
const MAX_CHAT_PAGE = 200;
const CHAT_THREAD_KINDS = new Set(['family', 'child']);
const CHAT_PARTICIPANT_KINDS = new Set(['membership', 'child']);
/// A client-generated identifier for the sender's own message: long enough to be unique and
/// short enough to be stored. It is the field that makes a resend the same message.
const CLIENT_MESSAGE_ID_PATTERN = /^[A-Za-z0-9_.:-]{8,64}$/;

/** Text a person wrote, with its lines intact. Tabs, newlines and carriage returns survive;
 *  every other control character is refused, because a message that can carry them can carry
 *  a screen's worth of invisible damage into a family's history. */
function chatBody(value, field) {
  if (typeof value !== 'string') {
    throw new HttpError(400, 'invalid_request', `${field} is required.`);
  }
  const normalized = value.replace(/\r\n?/g, '\n').trim();
  if (!normalized || normalized.length > MAX_CHAT_BODY_LENGTH) {
    throw new HttpError(
      400,
      'invalid_request',
      `${field} must be between 1 and ${MAX_CHAT_BODY_LENGTH} characters.`,
    );
  }
  if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.test(normalized)) {
    throw new HttpError(400, 'invalid_request', `${field} contains characters a message cannot carry.`);
  }
  return normalized;
}

function clientMessageId(value) {
  if (typeof value !== 'string' || !CLIENT_MESSAGE_ID_PATTERN.test(value)) {
    throw new HttpError(
      400,
      'invalid_request',
      'clientMessageId must be 8 to 64 characters of letters, digits, dot, colon, dash or underscore.',
    );
  }
  return value;
}

/** A list of uuids, deduplicated, bounded. A duplicate is a client bug, not a bigger audience. */
function uuidList(value, field, { maxItems }) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) {
    throw new HttpError(400, 'invalid_request', `${field} must be a list.`);
  }
  if (value.length > maxItems) {
    throw new HttpError(400, 'invalid_request', `${field} may name at most ${maxItems} people.`);
  }
  const seen = new Set();
  const ids = [];
  for (const entry of value) {
    if (typeof entry !== 'string' || !UUID_PATTERN.test(entry)) {
      throw new HttpError(400, 'invalid_request', `${field} must contain uuids.`);
    }
    if (seen.has(entry.toLowerCase())) continue;
    seen.add(entry.toLowerCase());
    ids.push(entry);
  }
  return ids;
}

/** Opening a conversation: what kind of room, what to call it, and who is in it from the first
 *  moment. `kind` is required because the two rooms have different laws - the household room is
 *  guardians, a child's room names exactly one child. */
export function chatThreadCreateInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['kind', 'title', 'participantMembershipIds', 'childIds']));
  const kind = requiredText(body.kind, 'kind', { maxLength: 16 }).toLowerCase();
  if (!CHAT_THREAD_KINDS.has(kind)) {
    throw new HttpError(400, 'invalid_request', 'kind must be family or child.');
  }
  const title =
    body.title === undefined || body.title === null ? '' : optionalText(body.title, 'title', MAX_CHAT_TITLE_LENGTH) ?? '';
  return {
    kind,
    title,
    participantMembershipIds: uuidList(body.participantMembershipIds, 'participantMembershipIds', {
      maxItems: MAX_CHAT_PARTICIPANTS,
    }),
    childIds: uuidList(body.childIds, 'childIds', { maxItems: MAX_CHAT_PARTICIPANTS }),
  };
}

/** Adding one participant to an existing room. */
export function chatThreadMemberInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['participantKind', 'participantId']));
  const participantKind = requiredText(body.participantKind, 'participantKind', { maxLength: 16 }).toLowerCase();
  if (!CHAT_PARTICIPANT_KINDS.has(participantKind)) {
    throw new HttpError(400, 'invalid_request', 'participantKind must be membership or child.');
  }
  const participantId = requireUuid(body.participantId, 'participantId');
  return { participantKind, participantId };
}

/** What a person wrote, and the client's own name for this message. */
export function chatMessageInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['body', 'clientMessageId']));
  return {
    body: chatBody(body.body, 'body'),
    clientMessageId: clientMessageId(body.clientMessageId),
  };
}

/** An edit states the revision it read, so two editors collide loudly instead of one silently
 *  replacing the other's words. */
export function chatMessageEditInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['body', 'revision']));
  return {
    body: chatBody(body.body, 'body'),
    revision: requiredWholeNumber(body.revision, 'revision', 1, 1000000),
  };
}

/** How far the caller has read. It is their own statement, and the module refuses one that
 *  runs past the newest message in the thread. */
export function chatReadInput(value) {
  const body = bodyObject(value);
  onlyKnownFields(body, new Set(['readSeq']));
  return { readSeq: requiredWholeNumber(body.readSeq, 'readSeq', 0, Number.MAX_SAFE_INTEGER) };
}

/** The page a message read asks for. `afterSeq` is what makes an incremental read possible
 *  without a push transport; the bound is what keeps one screen from asking for a family's
 *  entire history. */
export function chatMessageQuery(value) {
  const afterSeq =
    value?.afterSeq === undefined || value?.afterSeq === ''
      ? 0
      : requiredWholeNumber(Number(value.afterSeq), 'afterSeq', 0, Number.MAX_SAFE_INTEGER);
  const limit =
    value?.limit === undefined || value?.limit === ''
      ? undefined
      : requiredWholeNumber(Number(value.limit), 'limit', 1, MAX_CHAT_PAGE);
  return { afterSeq, limit };
}
