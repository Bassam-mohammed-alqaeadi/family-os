// Firebase Cloud Messaging, HTTP v1 API. Sends one nudge to one device token.
//
// The sender signs a JWT with the service account's private key (RS256, via `jose`), exchanges it
// at Google's token endpoint for a short-lived OAuth access token, and caches that token until
// shortly before it expires. Nothing else is stored.
//
// What a nudge carries: a fixed, neutral title and body in the registered language, and a data
// payload of `type` and `threadId`. It never carries message text, a sender name or media, so a
// device that receives a nudge learns only that a room changed; the app then reads the room
// through its own authenticated connection.

import { importPKCS8, SignJWT } from 'jose';

export const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
export const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FCM_ORIGIN = 'https://fcm.googleapis.com';
const PROJECT_ID = /^[a-z][a-z0-9-]{4,61}[a-z0-9]$/;

/** The words of a nudge. Neutral by design: they name the app and the kind of change only. */
export const PUSH_COPY = Object.freeze({
  ar: Object.freeze({ title: 'عائلتي', body: 'رسالة جديدة' }),
  en: Object.freeze({ title: 'Family OS', body: 'New message' }),
});

/**
 * Parses a service-account JSON document (as downloaded from Google Cloud) and returns the parts
 * the sender needs. Throws without echoing any part of the document, because it holds a key.
 */
export function parseServiceAccount(json) {
  let parsed;
  try {
    parsed = JSON.parse(json);
  } catch {
    throw new Error('The FCM service account is not valid JSON.');
  }
  if (
    typeof parsed?.client_email !== 'string' ||
    !parsed.client_email.endsWith('.iam.gserviceaccount.com') ||
    typeof parsed?.private_key !== 'string' ||
    !parsed.private_key.includes('BEGIN PRIVATE KEY')
  ) {
    throw new Error('The FCM service account is missing its client_email or private_key.');
  }
  return { clientEmail: parsed.client_email, privateKey: parsed.private_key };
}

export class FcmSender {
  /**
   * @param {object} options
   * @param {string} options.projectId     the Firebase project id
   * @param {{clientEmail: string, privateKey: string}} options.serviceAccount
   * @param {Function} [options.fetch]     injectable transport (tests)
   * @param {() => number} [options.now]   injectable clock in milliseconds (tests)
   * @param {string} [options.tokenUrl]    Google's token endpoint (tests may point it elsewhere)
   * @param {string} [options.fcmOrigin]   FCM origin (tests may point it elsewhere)
   */
  constructor({
    projectId,
    serviceAccount,
    fetch: transport = globalThis.fetch,
    now = () => Date.now(),
    tokenUrl = GOOGLE_TOKEN_URL,
    fcmOrigin = FCM_ORIGIN,
  }) {
    if (typeof projectId !== 'string' || !PROJECT_ID.test(projectId)) {
      throw new Error('The FCM project id is not valid.');
    }
    if (typeof serviceAccount?.clientEmail !== 'string' || typeof serviceAccount?.privateKey !== 'string') {
      throw new Error('The FCM sender needs a service account.');
    }
    this.kind = 'fcm_http_v1';
    this.projectId = projectId;
    this.#serviceAccount = serviceAccount;
    this.#fetch = transport;
    this.#now = now;
    this.#tokenUrl = tokenUrl;
    this.#fcmOrigin = fcmOrigin;
  }

  #serviceAccount;
  #fetch;
  #now;
  #tokenUrl;
  #fcmOrigin;
  #access = null;
  #key = null;

  async #accessToken() {
    const nowMs = this.#now();
    if (this.#access && this.#access.expiresAt - 60_000 > nowMs) return this.#access.token;
    this.#key ??= await importPKCS8(this.#serviceAccount.privateKey, 'RS256');
    const seconds = Math.floor(nowMs / 1000);
    const assertion = await new SignJWT({ scope: FCM_SCOPE })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(this.#serviceAccount.clientEmail)
      .setSubject(this.#serviceAccount.clientEmail)
      .setAudience(this.#tokenUrl)
      .setIssuedAt(seconds)
      .setExpirationTime(seconds + 3600)
      .sign(this.#key);
    const response = await this.#fetch(this.#tokenUrl, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
      redirect: 'error',
    });
    const body = await response.json().catch(() => null);
    if (response.status !== 200 || typeof body?.access_token !== 'string') {
      throw new Error(`Google refused the FCM access token with HTTP ${response.status}.`);
    }
    this.#access = {
      token: body.access_token,
      expiresAt: nowMs + Number(body.expires_in ?? 3600) * 1000,
    };
    return this.#access.token;
  }

  /**
   * Sends one nudge. Resolves to `sent`, or `unregistered` when FCM says the token no longer names
   * a device (the caller then deletes that registration). Any other failure throws, so a transient
   * error never removes a device.
   */
  async send({ token, locale, data }) {
    const copy = PUSH_COPY[locale] ?? PUSH_COPY.en;
    const accessToken = await this.#accessToken();
    const response = await this.#fetch(
      `${this.#fcmOrigin}/v1/projects/${this.projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          authorization: `Bearer ${accessToken}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: copy.title, body: copy.body },
            data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
            android: { priority: 'HIGH' },
          },
        }),
        redirect: 'error',
      },
    );
    if (response.status === 200) {
      await response.arrayBuffer();
      return 'sent';
    }
    const body = await response.json().catch(() => null);
    const details = Array.isArray(body?.error?.details) ? body.error.details : [];
    if (
      details.some((detail) => detail?.errorCode === 'UNREGISTERED') ||
      body?.error?.status === 'NOT_FOUND'
    ) {
      return 'unregistered';
    }
    throw new Error(`FCM refused the nudge with HTTP ${response.status}.`);
  }
}
