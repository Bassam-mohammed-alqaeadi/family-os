import { HttpError } from './http-error.js';

const MAX_DISPLAY_NAME_LENGTH = 120;
const MAX_SUBJECT_LENGTH = 255;
const INVITABLE_ROLES = new Set(['co_guardian', 'child']);

function bodyObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'invalid_request', 'Request body must be a JSON object.');
  }
  return value;
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

export function requirePathId(value, field) {
  return requiredText(value, field, { maxLength: 64 });
}
