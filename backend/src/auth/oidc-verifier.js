import { createRemoteJWKSet, jwtVerify } from 'jose';
import { HttpError } from '../http-error.js';

function bearerToken(value) {
  if (typeof value !== 'string') {
    throw new HttpError(401, 'authentication_required', 'A bearer access token is required.');
  }

  const match = /^Bearer ([^\s]+)$/.exec(value);
  if (!match) {
    throw new HttpError(401, 'authentication_required', 'A bearer access token is required.');
  }
  return match[1];
}

export class DisabledAuthVerifier {
  configured = false;

  async verify() {
    throw new HttpError(
      503,
      'identity_provider_not_configured',
      'Identity verification is not configured for this environment.',
    );
  }
}

export class OidcAuthVerifier {
  configured = true;

  constructor({ issuer, audience, jwksUrl }) {
    this.issuer = issuer;
    this.audience = audience;
    this.remoteJwks = createRemoteJWKSet(new URL(jwksUrl));
  }

  async verify(authorizationHeader) {
    const token = bearerToken(authorizationHeader);

    try {
      const { payload } = await jwtVerify(token, this.remoteJwks, {
        issuer: this.issuer,
        audience: this.audience,
      });
      if (typeof payload.sub !== 'string' || !payload.sub.trim()) {
        throw new HttpError(401, 'invalid_token', 'The access token has no subject.');
      }

      return {
        subject: payload.sub,
        issuedAt: payload.iat,
        expiresAt: payload.exp,
      };
    } catch (error) {
      if (error instanceof HttpError) {
        throw error;
      }
      throw new HttpError(401, 'invalid_token', 'The access token could not be verified.');
    }
  }
}
