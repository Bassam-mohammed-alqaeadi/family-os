// The handset's half of the W3 location contract, checked from the server's side.
//
// `fixtures/native-location-fix.wire.json` holds the exact bytes the Android service
// (`LocationFixProtocol.body`) produces for a synthetic reading; the Kotlin test
// `LocationFixProtocolTest.bodyIsByteForByteTheSharedFixture` asserts the same file. If either
// side renames a field, one of the two suites fails before a child's phone does.
//
// The second half guards the one answer that makes a handset forget its pairing: HTTP 401
// with `invalid_device_credential`. The native client wipes its credential on that code and
// on nothing else, so the code must stay exactly what the server throws for a revoked or
// mismatched credential on the routes the service calls.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { locationFixInput } from '../src/validation.js';

const here = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = join(here, '..', '..');
const nativeSource = join(
  repositoryRoot,
  'app/android/app/src/main/kotlin/com/familyos/family_os',
);

async function wireFixture() {
  const text = await readFile(join(here, 'fixtures', 'native-location-fix.wire.json'), 'utf8');
  return { text: text.trim(), body: JSON.parse(text) };
}

test('the native wire body is accepted by the route validator as sent', async () => {
  const { body } = await wireFixture();
  const fix = locationFixInput(body);
  assert.deepEqual(fix, {
    fixId: '3f1c2a4e-8b7d-4c2a-9e1f-5a6b7c8d9e0f',
    acquisition: 'located',
    latitude: 15.3694,
    longitude: 44.191,
    accuracyMeters: 12.5,
    integritySoftWarning: false,
    recordedAt: '2026-10-10T00:00:00.123Z',
  });
});

test('the native wire body carries no field the server would refuse or ignore', async () => {
  const { body } = await wireFixture();
  assert.deepEqual(Object.keys(body).sort(), [
    'accuracyMeters',
    'acquisition',
    'fixId',
    'integritySoftWarning',
    'latitude',
    'longitude',
    'recordedAt',
  ]);
});

test('a mock-provider reading is accepted and keeps its warning', async () => {
  const { body } = await wireFixture();
  const fix = locationFixInput({ ...body, integritySoftWarning: true });
  assert.equal(fix.integritySoftWarning, true);
});

test('the handset revokes itself on exactly the code the server throws for a dead credential', async () => {
  const protocol = await readFile(join(nativeSource, 'LocationFixProtocol.kt'), 'utf8');
  const declared = /REVOKED_CREDENTIAL_CODE\s*=\s*"([a-z_]+)"/.exec(protocol)?.[1];
  assert.equal(declared, 'invalid_device_credential');

  // The two routes the service calls: the W3 fix route and the legacy heartbeat.
  const location = await readFile(join(here, '..', 'src', 'location-telemetry.js'), 'utf8');
  assert.match(location, /HttpError\(\s*401,\s*'invalid_device_credential'/);
  const store = await readFile(
    join(here, '..', 'src', 'store', 'postgres-foundation-store.js'),
    'utf8',
  );
  assert.match(store, /HttpError\(401, 'invalid_device_credential'/);

  // And only on a 401: the classifier must name the status and the code together.
  assert.match(protocol, /statusCode == 401 && errorCode\(body\) == REVOKED_CREDENTIAL_CODE/);
});

test('the native service reports to the W3 route with an idempotency key', async () => {
  const protocol = await readFile(join(nativeSource, 'LocationFixProtocol.kt'), 'utf8');
  assert.match(protocol, /"\/v1\/devices\/\$deviceId\/location-fixes"/);
  const service = await readFile(join(nativeSource, 'ChildTelemetryService.kt'), 'utf8');
  assert.match(service, /LocationFixProtocol\.path\(config\.deviceId\)/);
  assert.match(service, /LocationFixProtocol\.idempotencyKey\(reading\.fixId\)/);
  // Coordinates and the credential are never written to the Android log.
  assert.doesNotMatch(service, /\bLog\.[dviwe]\(/);
  assert.doesNotMatch(service, /println\(/);
});

test('the legacy heartbeat never carries coordinates the W3 route refused or a mock reading', async () => {
  const service = await readFile(join(nativeSource, 'ChildTelemetryService.kt'), 'utf8');
  const gate = service.indexOf('LocationFixProtocol.legacyHeartbeatAllowed(fixOutcome, reading)');
  const legacy = service.indexOf('/telemetry"');
  assert.ok(gate > 0, 'the heartbeat must be gated on the fix outcome');
  assert.ok(legacy > gate, 'the gate must come before the legacy telemetry call');
  // Revocation handling and the pairing screen share one process-wide lock.
  assert.match(service, /private val LOCK = Any\(\)/);
  const activity = await readFile(join(nativeSource, 'MainActivity.kt'), 'utf8');
  assert.match(activity, /TelemetryConfigStore\.locked \{/);
});

test('the foreground notification says the same thing in Arabic and English, and matches the code', async () => {
  const res = join(repositoryRoot, 'app/android/app/src/main/res');
  const names = (xml) => [...xml.matchAll(/<string name="([a-z_]+)">/g)].map((m) => m[1]).sort();
  const text = (xml, name) => new RegExp(`<string name="${name}">([^<]*)</string>`).exec(xml)?.[1] ?? '';
  const arabic = await readFile(join(res, 'values', 'strings.xml'), 'utf8');
  const english = await readFile(join(res, 'values-en', 'strings.xml'), 'utf8');
  assert.deepEqual(names(arabic), names(english));
  assert.ok(names(arabic).includes('location_sharing_notification_text'));

  // The sentence promises "at most once every 5 minutes"; the service must still collect
  // on that interval. Change one and this fails until the other is changed with it.
  const service = await readFile(join(nativeSource, 'ChildTelemetryService.kt'), 'utf8');
  assert.match(service, /UPDATE_INTERVAL_MILLIS = 5 \* 60 \* 1000L/);
  // Android applies the interval per provider (GPS and network), so the promise holds only
  // because one gate spans both.
  const protocolSource = await readFile(join(nativeSource, 'LocationFixProtocol.kt'), 'utf8');
  assert.match(protocolSource, /MIN_REPORT_INTERVAL_MILLIS = 5 \* 60 \* 1000L/);
  assert.match(service, /LocationFixProtocol\.dueForReport\(/);
  assert.match(text(arabic, 'location_sharing_notification_text'), /٥ دقائق/);
  assert.match(text(english, 'location_sharing_notification_text'), /5 minutes/);
  for (const xml of [arabic, english]) {
    assert.match(text(xml, 'location_sharing_notification_text'), /(أولياء الأمور|guardians)/);
  }

  // No hard-coded English left in the service's notification builder.
  assert.doesNotMatch(service, /setContentTitle\("/);
  assert.doesNotMatch(service, /setContentText\("/);
});
