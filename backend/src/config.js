import { HttpError } from './http-error.js';

const REQUIRED_OIDC_KEYS = ['OIDC_ISSUER', 'OIDC_AUDIENCE', 'OIDC_JWKS_URL'];

function optionalText(value) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

function requiredHttpsUrl(value, variable) {
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== 'https:' || parsed.username || parsed.password || parsed.hash) {
      throw new Error('invalid URL security shape');
    }
    return value;
  } catch {
    throw new HttpError(500, 'invalid_configuration', `${variable} must be an HTTPS URL without credentials or a fragment.`);
  }
}

function parsePort(value) {
  const parsed = Number.parseInt(value ?? '10000', 10);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new HttpError(500, 'invalid_configuration', 'PORT must be a valid TCP port.');
  }
  return parsed;
}

function optionalBoundedInteger(value, variable, { minimum, maximum }) {
  const normalized = optionalText(value);
  if (!normalized) {
    return undefined;
  }
  if (!/^[0-9]+$/.test(normalized)) {
    throw new HttpError(500, 'invalid_configuration', `${variable} must be an integer.`);
  }
  const parsed = Number.parseInt(normalized, 10);
  if (parsed < minimum || parsed > maximum) {
    throw new HttpError(500, 'invalid_configuration', `${variable} must be between ${minimum} and ${maximum}.`);
  }
  return parsed;
}

export function loadConfig(environment = process.env) {
  const oidcValues = Object.fromEntries(
    REQUIRED_OIDC_KEYS.map((key) => [key, optionalText(environment[key])]),
  );
  const configuredOidcKeys = Object.values(oidcValues).filter(Boolean).length;

  if (configuredOidcKeys > 0 && configuredOidcKeys !== REQUIRED_OIDC_KEYS.length) {
    throw new HttpError(
      500,
      'invalid_configuration',
      'OIDC issuer, audience, and JWKS URL must be configured together.',
    );
  }

  return {
    environment: optionalText(environment.NODE_ENV) ?? 'development',
    port: parsePort(environment.PORT),
    databaseUrl: optionalText(environment.DATABASE_URL),
    guardianTransferTtlHours: optionalBoundedInteger(environment.GUARDIAN_TRANSFER_TTL_HOURS, 'GUARDIAN_TRANSFER_TTL_HOURS', {
      minimum: 1,
      maximum: 168,
    }),
    oidc:
      configuredOidcKeys === REQUIRED_OIDC_KEYS.length
        ? {
            issuer: requiredHttpsUrl(oidcValues.OIDC_ISSUER, 'OIDC_ISSUER'),
            audience: oidcValues.OIDC_AUDIENCE,
            jwksUrl: requiredHttpsUrl(oidcValues.OIDC_JWKS_URL, 'OIDC_JWKS_URL'),
          }
        : undefined,
  };
}

export function configurationReadiness(config) {
  const missing = [];
  if (!config.databaseUrl) {
    missing.push('DATABASE_URL');
  }
  if (!config.oidc) {
    missing.push(...REQUIRED_OIDC_KEYS);
  }
  if (!config.guardianTransferTtlHours) {
    missing.push('GUARDIAN_TRANSFER_TTL_HOURS');
  }
  return { ready: missing.length === 0, missing };
}
