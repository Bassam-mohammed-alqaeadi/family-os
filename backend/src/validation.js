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
