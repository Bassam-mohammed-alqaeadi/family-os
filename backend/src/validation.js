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
