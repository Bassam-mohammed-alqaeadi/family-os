// W9 media bytes behind an S3-compatible object store (AWS S3, MinIO, Cloudflare R2, Wasabi,
// Backblaze B2 through its S3 API, and similar). It implements the same three-method port as the
// local-disk adapter, so no route or rule changes when it is selected.
//
// Requests are signed with AWS Signature Version 4, implemented here with `node:crypto` only. The
// signer is verified against the official AWS SigV4 test suite (see the fixtures and the test),
// because a signing mistake would fail every request with a 403 rather than a clear error.
//
// Selection is explicit (config.js): setting the bucket selects this adapter. The local-disk
// adapter stays the default and the only adapter when no bucket is configured.

import { createHash, createHmac } from 'node:crypto';

import { assertStorageKey } from './chat-media-store.js';

const ALGORITHM = 'AWS4-HMAC-SHA256';
const BUCKET_PATTERN = /^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$/;
const REGION_PATTERN = /^[a-z0-9-]{2,32}$/;
const PREFIX_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._/-]{0,126}$/;

export function sha256Hex(data) {
  return createHash('sha256').update(data).digest('hex');
}

function hmac(key, data) {
  return createHmac('sha256', key).update(data).digest();
}

/** RFC 3986 unreserved characters only: SigV4 encodes everything else, including `!'()*`. */
export function encodeRfc3986(value) {
  return encodeURIComponent(value).replace(
    /[!'()*]/g,
    (char) => `%${char.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

function canonicalUri(path) {
  if (!path.startsWith('/')) throw new Error('A SigV4 request path must start with "/".');
  return path
    .split('/')
    .map((segment) => encodeRfc3986(decodeURIComponent(segment)))
    .join('/');
}

/**
 * The canonical query: each name and value encoded once with RFC 3986, then sorted by name and
 * value. The input is taken literally, so a `+` stays a plus sign and is not read as a space.
 */
function canonicalQuery(query) {
  if (!query) return '';
  const pairs = query
    .split('&')
    .filter((pair) => pair !== '')
    .map((pair) => {
      const equals = pair.indexOf('=');
      const name = equals < 0 ? pair : pair.slice(0, equals);
      const value = equals < 0 ? '' : pair.slice(equals + 1);
      return [encodeRfc3986(name), encodeRfc3986(value)];
    });
  pairs.sort(([aKey, aValue], [bKey, bValue]) => {
    if (aKey !== bKey) return aKey < bKey ? -1 : 1;
    if (aValue === bValue) return 0;
    return aValue < bValue ? -1 : 1;
  });
  return pairs.map(([key, value]) => `${key}=${value}`).join('&');
}

/**
 * Signs one request with AWS Signature Version 4 and returns the Authorization header.
 *
 * `headers` are the headers that will be sent, and every one of them is signed. Names are
 * lower-cased and values are trimmed with inner runs of spaces collapsed, as the spec requires.
 * `payloadHash` is the lower-case hex SHA-256 of the body (or of the empty string).
 */
export function signV4Request({
  method,
  path,
  query = '',
  headers,
  payloadHash,
  amzDate,
  region,
  service,
  credentials,
}) {
  if (!/^\d{8}T\d{6}Z$/.test(amzDate)) throw new Error('amzDate must be YYYYMMDDTHHMMSSZ.');
  if (!/^[0-9a-f]{64}$/.test(payloadHash)) throw new Error('payloadHash must be a SHA-256 hex digest.');
  const dateStamp = amzDate.slice(0, 8);
  const signed = {};
  for (const [name, value] of Object.entries(headers)) {
    signed[name.toLowerCase()] = String(value).trim().replace(/\s+/g, ' ');
  }
  const names = Object.keys(signed).sort();
  const canonicalHeaders = names.map((name) => `${name}:${signed[name]}\n`).join('');
  const signedHeaders = names.join(';');
  const canonicalRequest = [
    method.toUpperCase(),
    canonicalUri(path),
    canonicalQuery(query),
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');
  const scope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = [ALGORITHM, amzDate, scope, sha256Hex(canonicalRequest)].join('\n');
  const kDate = hmac(`AWS4${credentials.secretAccessKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  const kSigning = hmac(kService, 'aws4_request');
  const signature = createHmac('sha256', kSigning).update(stringToSign).digest('hex');
  return `${ALGORITHM} Credential=${credentials.accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;
}

/** Validates the S3 settings and fails loudly on anything that would otherwise be a silent 403. */
export function validateS3Settings({
  bucket,
  region,
  endpoint,
  accessKeyId,
  secretAccessKey,
  prefix,
}) {
  if (typeof bucket !== 'string' || !BUCKET_PATTERN.test(bucket)) {
    throw new Error('The media bucket name is not a valid S3 bucket name.');
  }
  if (typeof region !== 'string' || !REGION_PATTERN.test(region)) {
    throw new Error('The media bucket region is not a valid AWS region name.');
  }
  if (typeof accessKeyId !== 'string' || accessKeyId.length < 16) {
    throw new Error('The media object store access key id is missing.');
  }
  if (typeof secretAccessKey !== 'string' || secretAccessKey.length < 16) {
    throw new Error('The media object store secret access key is missing.');
  }
  if (typeof prefix !== 'string' || !PREFIX_PATTERN.test(prefix)) {
    throw new Error('The media object prefix is not a safe key prefix.');
  }
  if (endpoint != null) {
    let url;
    try {
      url = new URL(endpoint);
    } catch {
      throw new Error('The media object store endpoint is not a valid URL.');
    }
    const loopback = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    if (url.protocol !== 'https:' && !(url.protocol === 'http:' && loopback)) {
      throw new Error('The media object store endpoint must use https (http is allowed only for loopback).');
    }
    if (url.search || url.hash || url.username || url.password || (url.pathname !== '/' && url.pathname !== '')) {
      throw new Error('The media object store endpoint must be an origin without path, query or credentials.');
    }
  }
}

export class S3ChatMediaStore {
  /**
   * @param {object} options
   * @param {string} options.bucket           the bucket that holds the media objects
   * @param {string} options.region           the bucket's region, for SigV4 (e.g. "eu-central-1")
   * @param {string} [options.endpoint]       an origin for an S3-compatible store; omit for AWS
   * @param {boolean} [options.forcePathStyle] path-style addressing; defaults to true with an endpoint
   * @param {string} options.accessKeyId
   * @param {string} options.secretAccessKey
   * @param {string} [options.sessionToken]   for temporary credentials
   * @param {string} [options.prefix]         object key prefix inside the bucket
   * @param {Function} [options.fetch]        injectable transport (tests)
   * @param {() => Date} [options.now]        injectable clock (tests)
   */
  constructor({
    bucket,
    region,
    endpoint = null,
    forcePathStyle,
    accessKeyId,
    secretAccessKey,
    sessionToken = null,
    prefix = 'family-chat-media',
    fetch: transport = globalThis.fetch,
    now = () => new Date(),
  }) {
    validateS3Settings({ bucket, region, endpoint, accessKeyId, secretAccessKey, prefix });
    if (typeof transport !== 'function') throw new Error('An S3 transport must be a function.');
    this.kind = 's3';
    this.bucket = bucket;
    this.region = region;
    this.endpoint = endpoint == null ? null : new URL(endpoint).origin;
    this.forcePathStyle = forcePathStyle ?? this.endpoint != null;
    this.prefix = prefix;
    this.#credentials = { accessKeyId, secretAccessKey, sessionToken };
    this.#fetch = transport;
    this.#now = now;
  }

  #credentials;
  #fetch;
  #now;

  /** The object's location: the host, the URL path, and the full object key. */
  locate(key) {
    const objectKey = `${this.prefix}/${assertStorageKey(key)}`;
    const base = this.endpoint == null ? null : new URL(this.endpoint);
    if (this.forcePathStyle) {
      const host = base == null ? `s3.${this.region}.amazonaws.com` : base.host;
      return { host, path: `/${this.bucket}/${objectKey}`, objectKey };
    }
    const host = base == null
      ? `${this.bucket}.s3.${this.region}.amazonaws.com`
      : `${this.bucket}.${base.host}`;
    return { host, path: `/${objectKey}`, objectKey };
  }

  async #send(method, key, body = null, extra = {}) {
    const { host, path } = this.locate(key);
    const payload = body ?? Buffer.alloc(0);
    const payloadHash = sha256Hex(payload);
    const amzDate = toAmzDate(this.#now());
    const headers = {
      host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      ...extra,
    };
    if (this.#credentials.sessionToken) {
      headers['x-amz-security-token'] = this.#credentials.sessionToken;
    }
    headers.authorization = signV4Request({
      method,
      path,
      headers,
      payloadHash,
      amzDate,
      region: this.region,
      service: 's3',
      credentials: this.#credentials,
    });
    // The transport derives the Host header from the URL, which carries the same host that was
    // signed. Bucket, prefix and key are validated to URL-safe characters, so the path is final.
    const scheme = this.endpoint == null ? 'https' : new URL(this.endpoint).protocol.slice(0, -1);
    const { host: _signedHost, ...sent } = headers;
    return this.#fetch(`${scheme}://${host}${path}`, {
      method,
      headers: sent,
      body: body == null || body.length === 0 ? undefined : body,
      redirect: 'error',
    });
  }

  /** Writes the bytes once. A key already in use is refused, never overwritten. */
  async put(key, bytes) {
    const response = await this.#send('PUT', key, bytes, {
      'content-type': 'application/octet-stream',
      'if-none-match': '*',
    });
    await discard(response);
    if (response.status !== 200) {
      throw new Error(`The object store refused the upload with HTTP ${response.status}.`);
    }
  }

  /** The stored bytes, or null when the object is absent. */
  async get(key) {
    const response = await this.#send('GET', key);
    if (response.status === 404) {
      await discard(response);
      return null;
    }
    if (response.status !== 200) {
      await discard(response);
      throw new Error(`The object store answered HTTP ${response.status} for a read.`);
    }
    return Buffer.from(await response.arrayBuffer());
  }

  /** Removing an absent object is success: deletion is idempotent. */
  async delete(key) {
    const response = await this.#send('DELETE', key);
    await discard(response);
    if (response.status !== 204 && response.status !== 200 && response.status !== 404) {
      throw new Error(`The object store answered HTTP ${response.status} for a delete.`);
    }
  }
}

async function discard(response) {
  try {
    await response.arrayBuffer();
  } catch {
    // The body is not needed; the status alone decides the outcome.
  }
}

export function toAmzDate(date) {
  return date.toISOString().replace(/[:-]|\.\d{3}/g, '');
}
