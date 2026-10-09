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

export function loadListeningPort(environment = process.env) {
  return parsePort(environment.PORT);
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
    // W9 media bytes. Unset means media is unavailable on this server; there is no default folder.
    chatMediaDirectory: optionalText(environment.FAMILY_CHAT_MEDIA_DIR),
    // W9 media bytes in an S3-compatible bucket. Setting the bucket selects that store; the
    // secret is read here and never echoed in an error or a log.
    chatMediaS3: chatMediaS3Settings(environment),
    // Push nudges through Firebase Cloud Messaging. Both values or neither; the service-account
    // JSON is a secret and is never echoed in an error.
    pushFcm: pushFcmSettings(environment),
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

/** Firebase push settings. Absent means push is not configured; a partial setting is refused. */
function pushFcmSettings(environment) {
  const projectId = optionalText(environment.FAMILY_PUSH_FCM_PROJECT_ID);
  const serviceAccountJson = optionalText(environment.FAMILY_PUSH_FCM_SERVICE_ACCOUNT_JSON);
  if (projectId == null && serviceAccountJson == null) return null;
  if (projectId == null || serviceAccountJson == null) {
    throw new HttpError(
      500,
      'invalid_configuration',
      'Push notifications need FAMILY_PUSH_FCM_PROJECT_ID and FAMILY_PUSH_FCM_SERVICE_ACCOUNT_JSON together.',
    );
  }
  return { projectId, serviceAccountJson };
}

/** The optional S3-compatible media store. Absent bucket means the store is not S3. */
function chatMediaS3Settings(environment) {
  const bucket = optionalText(environment.FAMILY_CHAT_MEDIA_S3_BUCKET);
  if (bucket == null) return null;
  const region = optionalText(environment.FAMILY_CHAT_MEDIA_S3_REGION);
  const accessKeyId = optionalText(environment.FAMILY_CHAT_MEDIA_S3_ACCESS_KEY_ID);
  const secretAccessKey = optionalText(environment.FAMILY_CHAT_MEDIA_S3_SECRET_ACCESS_KEY);
  if (region == null || accessKeyId == null || secretAccessKey == null) {
    throw new HttpError(
      500,
      'invalid_configuration',
      'The S3 media store needs its bucket, region, access key id and secret access key together.',
    );
  }
  const forcePathStyle = optionalText(environment.FAMILY_CHAT_MEDIA_S3_FORCE_PATH_STYLE);
  if (forcePathStyle != null && forcePathStyle !== 'true' && forcePathStyle !== 'false') {
    throw new HttpError(500, 'invalid_configuration', 'FAMILY_CHAT_MEDIA_S3_FORCE_PATH_STYLE must be true or false.');
  }
  return {
    bucket,
    region,
    accessKeyId,
    secretAccessKey,
    endpoint: optionalText(environment.FAMILY_CHAT_MEDIA_S3_ENDPOINT),
    sessionToken: optionalText(environment.FAMILY_CHAT_MEDIA_S3_SESSION_TOKEN),
    prefix: optionalText(environment.FAMILY_CHAT_MEDIA_S3_PREFIX) ?? 'family-chat-media',
    forcePathStyle: forcePathStyle == null ? undefined : forcePathStyle === 'true',
  };
}
