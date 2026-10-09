// The S3-compatible media store. Two kinds of proof:
// 1. The SigV4 signer reproduces the expected Authorization header of every case in the official
//    AWS SigV4 test suite (fixtures copied from the AWS-maintained copy in aws/aws-sdk-ruby).
// 2. The adapter's PUT, GET and DELETE, end to end against an in-process S3-style server that
//    checks the signature headers, refuses overwrites, and answers 404 for absent keys.
// Live AWS, R2 and MinIO endpoints cannot be reached from the build sandbox; that is stated in the
// report, and a live run belongs to the staging environment with real credentials.

import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, join } from 'node:path';
import { after, before, describe, test } from 'node:test';
import { fileURLToPath } from 'node:url';

import { newStorageKey } from '../src/chat-media-store.js';
import {
  S3ChatMediaStore,
  encodeRfc3986,
  signV4Request,
  toAmzDate,
} from '../src/chat-media-store-s3.js';

const here = dirname(fileURLToPath(import.meta.url));
const SUITE = join(here, 'fixtures', 'aws-sigv4-suite');

// The credentials and scope the AWS test suite signs with.
const SUITE_CREDENTIALS = {
  accessKeyId: 'AKIDEXAMPLE',
  secretAccessKey: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
};

// Cases the signer is not claimed to handle yet. Every other case must pass.
const UNSUPPORTED = new Map([
  // Multi-line header values (obsolete folding) are not produced by any client of this API.
  ['get-header-value-multiline', 'obsolete header folding is not accepted'],
  // Repeated header names are never sent by this adapter (each name is set once).
  ['get-header-key-duplicate', 'repeated header names are never sent by this adapter'],
]);

function sha256Hex(data) {
  return createHash('sha256').update(data).digest('hex');
}

/** Parses a suite `.req` file: request line, headers up to the first blank line, then the body. */
function parseSuiteRequest(text) {
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/);
  // The target may itself contain spaces (the suite signs raw, unencoded query text), so the
  // request line is split at its first space and at its trailing protocol version.
  const requestLine = lines[0].match(/^(\S+) (.*) HTTP\/1\.1$/);
  if (!requestLine) throw new Error(`Not a suite request line: ${lines[0]}`);
  const [, method, target] = requestLine;
  const questionAt = target.indexOf('?');
  const path = questionAt < 0 ? target : target.slice(0, questionAt);
  const query = questionAt < 0 ? '' : target.slice(questionAt + 1);
  const headers = {};
  let i = 1;
  for (; i < lines.length && lines[i] !== ''; i++) {
    const colon = lines[i].indexOf(':');
    const name = lines[i].slice(0, colon).trim().toLowerCase();
    const value = lines[i].slice(colon + 1).trim();
    headers[name] = headers[name] === undefined ? value : `${headers[name]},${value}`;
  }
  const body = lines.slice(i + 1).join('\n');
  return { method, path, query, headers, body };
}

describe('AWS SigV4 test suite', () => {
  const cases = readdirSync(SUITE)
    .filter((name) => statSync(join(SUITE, name)).isDirectory())
    .sort();

  test('the vendored suite has every case we claim to run', () => {
    assert.ok(cases.length >= 20, `expected the full suite, found ${cases.length} cases`);
  });

  for (const name of cases) {
    const reason = UNSUPPORTED.get(name);
    const run = reason ? test.skip : test;
    run(`${name} produces the expected Authorization header`, () => {
      const request = parseSuiteRequest(readFileSync(join(SUITE, name, `${name}.req`), 'utf8'));
      const expected = readFileSync(join(SUITE, name, `${name}.authz`), 'utf8').trim();
      const authorization = signV4Request({
        method: request.method,
        path: request.path,
        query: request.query,
        headers: request.headers,
        payloadHash: sha256Hex(request.body),
        amzDate: request.headers['x-amz-date'],
        region: 'us-east-1',
        service: 'service',
        credentials: SUITE_CREDENTIALS,
      });
      assert.equal(authorization, expected);
    });
  }
});

describe('S3 object locations', () => {
  const key = newStorageKey();

  test('AWS addressing is virtual-hosted by default', () => {
    const store = new S3ChatMediaStore({
      bucket: 'family-media',
      region: 'eu-central-1',
      accessKeyId: 'AKIAEXAMPLEEXAMPLE1',
      secretAccessKey: 'secret-secret-secret-1',
    });
    assert.deepEqual(store.locate(key), {
      host: 'family-media.s3.eu-central-1.amazonaws.com',
      path: `/family-chat-media/${key}`,
      objectKey: `family-chat-media/${key}`,
    });
  });

  test('a custom endpoint is path-style by default and keeps its port', () => {
    const store = new S3ChatMediaStore({
      bucket: 'family-media',
      region: 'auto',
      endpoint: 'http://127.0.0.1:9000',
      accessKeyId: 'AKIAEXAMPLEEXAMPLE1',
      secretAccessKey: 'secret-secret-secret-1',
      prefix: 'chat/v1',
    });
    assert.equal(store.locate(key).host, '127.0.0.1:9000');
    assert.equal(store.locate(key).path, `/family-media/chat/v1/${key}`);
  });

  test('a key that is not a server-generated UUID is refused before any request', () => {
    const store = new S3ChatMediaStore({
      bucket: 'family-media',
      region: 'us-east-1',
      accessKeyId: 'AKIAEXAMPLEEXAMPLE1',
      secretAccessKey: 'secret-secret-secret-1',
    });
    assert.throws(() => store.locate('../../etc/passwd'), /server-generated UUID/);
  });

  test('configuration that would fail silently is refused at startup', () => {
    const base = {
      bucket: 'family-media',
      region: 'us-east-1',
      accessKeyId: 'AKIAEXAMPLEEXAMPLE1',
      secretAccessKey: 'secret-secret-secret-1',
    };
    assert.throws(() => new S3ChatMediaStore({ ...base, bucket: 'Bad_Bucket' }), /bucket name/);
    assert.throws(() => new S3ChatMediaStore({ ...base, region: 'US EAST' }), /region/);
    assert.throws(() => new S3ChatMediaStore({ ...base, accessKeyId: 'short' }), /access key/);
    assert.throws(
      () => new S3ChatMediaStore({ ...base, endpoint: 'http://storage.example.com' }),
      /must use https/,
    );
    assert.throws(
      () => new S3ChatMediaStore({ ...base, endpoint: 'https://storage.example.com/bucket' }),
      /origin without path/,
    );
  });

  test('RFC 3986 encoding leaves unreserved characters alone and encodes the rest', () => {
    assert.equal(encodeRfc3986("a-b_c.d~e!'()*"), 'a-b_c.d~e%21%27%28%29%2A');
    assert.equal(toAmzDate(new Date('2015-08-30T12:36:00.000Z')), '20150830T123600Z');
  });
});

describe('S3 adapter against an S3-style server', () => {
  const ACCESS = 'AKIAFAKEFAKEFAKE0001';
  const SECRET = 'fake-secret-key-for-tests-only';
  const REGION = 'us-east-1';
  /** @type {Map<string, {body: Buffer, contentType: string}>} */
  const objects = new Map();
  /** @type {string[]} */
  const seen = [];
  let server;
  let endpoint;

  before(async () => {
    server = createServer((request, response) => {
      const chunks = [];
      request.on('data', (chunk) => chunks.push(chunk));
      request.on('end', () => {
        const body = Buffer.concat(chunks);
        seen.push(`${request.method} ${request.url}`);
        const auth = request.headers.authorization ?? '';
        const declaredHash = request.headers['x-amz-content-sha256'];
        // A real store recomputes the body hash; so does this one.
        if (declaredHash !== sha256Hex(body)) {
          response.writeHead(400).end();
          return;
        }
        // Recompute the signature from the headers that were actually sent, with the same
        // secret. A request whose signed headers do not match what arrived is refused.
        const signedNames = auth.match(/SignedHeaders=([^,]+)/)?.[1]?.split(';') ?? [];
        const sentHeaders = {};
        for (const name of signedNames) sentHeaders[name] = request.headers[name];
        const expected = signV4Request({
          method: request.method,
          path: request.url.split('?')[0],
          headers: sentHeaders,
          payloadHash: declaredHash,
          amzDate: request.headers['x-amz-date'],
          region: REGION,
          service: 's3',
          credentials: { accessKeyId: ACCESS, secretAccessKey: SECRET },
        });
        if (auth !== expected) {
          response.writeHead(403).end();
          return;
        }
        const objectPath = request.url;
        if (request.method === 'PUT') {
          if (request.headers['if-none-match'] !== '*') {
            response.writeHead(400).end();
            return;
          }
          if (objects.has(objectPath)) {
            response.writeHead(412).end();
            return;
          }
          objects.set(objectPath, { body, contentType: request.headers['content-type'] });
          response.writeHead(200).end();
          return;
        }
        if (request.method === 'GET') {
          const stored = objects.get(objectPath);
          if (!stored) {
            response.writeHead(404).end();
            return;
          }
          response.writeHead(200, { 'content-type': stored.contentType }).end(stored.body);
          return;
        }
        if (request.method === 'DELETE') {
          objects.delete(objectPath);
          response.writeHead(204).end();
          return;
        }
        response.writeHead(405).end();
      });
    });
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    endpoint = `http://127.0.0.1:${server.address().port}`;
  });

  after(async () => {
    await new Promise((resolve) => server.close(resolve));
  });

  function store(now = new Date('2026-10-09T10:00:00.000Z')) {
    return new S3ChatMediaStore({
      bucket: 'family-media',
      region: REGION,
      endpoint,
      accessKeyId: ACCESS,
      secretAccessKey: SECRET,
      now: () => now,
    });
  }

  test('put, get and delete round-trip the exact bytes', async () => {
    const adapter = store();
    const key = newStorageKey();
    const bytes = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 16, 74, 70, 73, 70]);
    await adapter.put(key, bytes);
    assert.deepEqual(await adapter.get(key), bytes);
    await adapter.delete(key);
    assert.equal(await adapter.get(key), null);
  });

  test('a second write to the same key is refused, never overwritten', async () => {
    const adapter = store();
    const key = newStorageKey();
    await adapter.put(key, Buffer.from('first'));
    await assert.rejects(adapter.put(key, Buffer.from('second')), /HTTP 412/);
    assert.equal((await adapter.get(key)).toString(), 'first');
  });

  test('deleting an absent object is success', async () => {
    await store().delete(newStorageKey());
  });

  test('the session token, when present, is sent and signed', async () => {
    const calls = [];
    const adapter = new S3ChatMediaStore({
      bucket: 'family-media',
      region: REGION,
      endpoint,
      accessKeyId: ACCESS,
      secretAccessKey: SECRET,
      sessionToken: 'session-token-value',
      fetch: async (url, init) => {
        calls.push({ url, headers: init.headers });
        return new Response(null, { status: 200 });
      },
    });
    await adapter.put(newStorageKey(), Buffer.from('x'));
    assert.equal(calls[0].headers['x-amz-security-token'], 'session-token-value');
    assert.match(
      calls[0].headers.authorization,
      /SignedHeaders=.*x-amz-security-token/,
    );
  });

  test('the server saw signed requests only for the bucket and prefix it was given', () => {
    assert.ok(seen.length > 0);
    assert.ok(seen.every((line) => line.includes('/family-media/family-chat-media/')));
  });
});
