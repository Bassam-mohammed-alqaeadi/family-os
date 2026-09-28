import { HttpError } from './http-error.js';

const REQUIRED_OIDC_KEYS = ['OIDC_ISSUER', 'OIDC_AUDIENCE', 'OIDC_JWKS_URL'];

function optionalText(value) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
}

function parsePort(value) {
  const parsed = Number.parseInt(value ?? '10000', 10);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new HttpError(500, 'invalid_configuration', 'PORT must be a valid TCP port.');
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
    oidc:
      configuredOidcKeys === REQUIRED_OIDC_KEYS.length
        ? {
            issuer: oidcValues.OIDC_ISSUER,
            audience: oidcValues.OIDC_AUDIENCE,
            jwksUrl: oidcValues.OIDC_JWKS_URL,
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
  return { ready: missing.length === 0, missing };
}
