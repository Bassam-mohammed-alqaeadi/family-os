// The media rules that need no database: what a file is, what it may carry, and where its bytes
// may be kept. These run in the ordinary suite, so a regression in the stripping logic fails on
// every push, not only in the PostgreSQL gate.
import assert from 'node:assert/strict';
import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  CHAT_IMAGE_BYTES_MAX,
  declaredChatMediaType,
  prepareChatMediaBytes,
  sniffChatMedia,
} from '../src/chat-media-format.js';
import { LocalDiskChatMediaStore, newStorageKey, assertStorageKey } from '../src/chat-media-store.js';
import { inspectChatUpload } from '../src/family-chat-media.js';

const SECRET = 'GPSSECRETLOCATION';

function jpegWithExif() {
  const exif = Buffer.concat([Buffer.from('Exif\0\0'), Buffer.from(SECRET)]);
  const app1 = Buffer.concat([Buffer.from([0xff, 0xe1]), u16(exif.length + 2), exif]);
  const dqt = Buffer.concat([Buffer.from([0xff, 0xdb]), u16(67), Buffer.alloc(65, 1)]);
  const sof0 = Buffer.concat([Buffer.from([0xff, 0xc0]), u16(11), Buffer.from([8, 0, 2, 0, 2, 1, 1, 0x11, 0])]);
  const sos = Buffer.concat([Buffer.from([0xff, 0xda]), u16(8), Buffer.from([1, 1, 0, 0, 63, 0]), Buffer.from([0x12, 0x34])]);
  return Buffer.concat([Buffer.from([0xff, 0xd8]), app1, dqt, sof0, sos, Buffer.from([0xff, 0xd9])]);
}

function u16(value) {
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16BE(value);
  return buffer;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  return Buffer.concat([length, Buffer.from(type, 'latin1'), data, Buffer.alloc(4)]);
}

function pngWithText() {
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = chunk('IHDR', Buffer.from([0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0]));
  const text = chunk('tEXt', Buffer.from(`Comment\0${SECRET}`));
  const exif = chunk('eXIf', Buffer.from(SECRET));
  const idat = chunk('IDAT', Buffer.from([0x78, 0x9c, 0x63, 0x00]));
  const iend = chunk('IEND', Buffer.alloc(0));
  return Buffer.concat([signature, ihdr, text, exif, idat, iend]);
}

function webpWithExif() {
  const vp8x = Buffer.concat([Buffer.from('VP8X'), u32le(10), Buffer.from([0x0c, 0, 0, 0, 0, 0, 0, 0, 0, 0])]);
  const exif = Buffer.concat([Buffer.from('EXIF'), u32le(SECRET.length), Buffer.from(SECRET), Buffer.alloc(SECRET.length % 2)]);
  const vp8l = Buffer.concat([Buffer.from('VP8L'), u32le(5), Buffer.from([0x2f, 0, 0, 0, 0]), Buffer.alloc(1)]);
  const body = Buffer.concat([Buffer.from('WEBP'), vp8x, exif, vp8l]);
  return Buffer.concat([Buffer.from('RIFF'), u32le(body.length), body]);
}

function u32le(value) {
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32LE(value);
  return buffer;
}

test('the bytes decide the type: signatures for each allowlisted container, and nothing else', () => {
  assert.deepEqual(sniffChatMedia(jpegWithExif()), { kind: 'image', mimeType: 'image/jpeg' });
  assert.deepEqual(sniffChatMedia(pngWithText()), { kind: 'image', mimeType: 'image/png' });
  assert.deepEqual(sniffChatMedia(webpWithExif()), { kind: 'image', mimeType: 'image/webp' });
  assert.deepEqual(sniffChatMedia(Buffer.concat([Buffer.from('OggS'), Buffer.alloc(40)])), { kind: 'audio', mimeType: 'audio/ogg' });
  assert.deepEqual(sniffChatMedia(Buffer.concat([Buffer.alloc(4), Buffer.from('ftypM4A '), Buffer.alloc(8)])), { kind: 'audio', mimeType: 'audio/mp4' });
  assert.deepEqual(sniffChatMedia(Buffer.concat([Buffer.from('ID3'), Buffer.alloc(40)])), { kind: 'audio', mimeType: 'audio/mpeg' });
  assert.equal(sniffChatMedia(Buffer.from('<script>alert(1)</script>plus padding')), null);
  assert.equal(sniffChatMedia(Buffer.alloc(3)), null);
});

test('a declared type is accepted only when it is on the allowlist, whatever its parameters', () => {
  assert.equal(declaredChatMediaType('image/jpeg; charset=binary'), 'image/jpeg');
  assert.equal(declaredChatMediaType('AUDIO/OGG'), 'audio/ogg');
  assert.equal(declaredChatMediaType('text/html'), null);
  assert.equal(declaredChatMediaType('image/svg+xml'), null);
  assert.equal(declaredChatMediaType(undefined), null);
});

test('JPEG metadata that reveals a location is removed, and the image data is kept byte for byte', () => {
  const original = jpegWithExif();
  assert.ok(original.includes(Buffer.from(SECRET)), 'the fixture really carries the secret');
  const cleaned = prepareChatMediaBytes(original, 'image/jpeg');
  assert.ok(cleaned, 'a well-formed JPEG is prepared');
  assert.equal(cleaned.includes(Buffer.from(SECRET)), false, 'the EXIF block is gone');
  assert.deepEqual(cleaned.subarray(0, 2), Buffer.from([0xff, 0xd8]));
  assert.deepEqual(cleaned.subarray(cleaned.length - 2), Buffer.from([0xff, 0xd9]));
  // The scan data after start-of-scan is untouched.
  assert.ok(cleaned.includes(Buffer.from([0x12, 0x34])));
  assert.equal(sniffChatMedia(cleaned).mimeType, 'image/jpeg');
});

test('a JPEG whose segment lengths do not add up is refused, not stored as-is', () => {
  const broken = Buffer.from([0xff, 0xd8, 0xff, 0xe1, 0xff, 0xff, 0x00]);
  assert.equal(prepareChatMediaBytes(broken, 'image/jpeg'), null);
});

test('PNG text and EXIF chunks are removed while the image chunks stay', () => {
  const cleaned = prepareChatMediaBytes(pngWithText(), 'image/png');
  assert.ok(cleaned);
  assert.equal(cleaned.includes(Buffer.from(SECRET)), false);
  assert.ok(cleaned.includes(Buffer.from('IHDR')));
  assert.ok(cleaned.includes(Buffer.from('IDAT')));
  assert.ok(cleaned.includes(Buffer.from('IEND')));
  assert.equal(sniffChatMedia(cleaned).mimeType, 'image/png');
});

test('WebP EXIF is removed, its header flag is cleared, and the RIFF size is recomputed', () => {
  const original = webpWithExif();
  const cleaned = prepareChatMediaBytes(original, 'image/webp');
  assert.ok(cleaned);
  assert.equal(cleaned.includes(Buffer.from(SECRET)), false);
  assert.equal(cleaned.readUInt32LE(4), cleaned.length - 8, 'the RIFF size matches the new length');
  assert.equal(cleaned[20] & 0x0c, 0, 'the EXIF and XMP flags are cleared with their data');
  assert.equal(sniffChatMedia(cleaned).mimeType, 'image/webp');
});

test('an MP3 with a leading ID3 tag has the tag removed; the audio frames stay', () => {
  const frames = Buffer.from([0xff, 0xfb, 0x90, 0x00, 1, 2, 3, 4]);
  const tagBody = Buffer.from('TIT2xxxx' + SECRET);
  const size = Buffer.from([0, 0, 0, tagBody.length]); // syncsafe: each byte < 0x80
  const tag = Buffer.concat([Buffer.from('ID3'), Buffer.from([4, 0, 0]), size, tagBody]);
  const cleaned = prepareChatMediaBytes(Buffer.concat([tag, frames]), 'audio/mpeg');
  assert.deepEqual(cleaned, frames);
});

test('upload inspection: the declared type must match the bytes, and each kind has its own limits', () => {
  const jpeg = jpegWithExif();
  assert.throws(
    () => inspectChatUpload({ bytes: jpeg, declaredContentType: 'image/png', declaredDurationMs: null }),
    (error) => error.status === 415 && error.code === 'chat_media_type_mismatch',
  );
  assert.throws(
    () => inspectChatUpload({ bytes: jpeg, declaredContentType: 'text/html', declaredDurationMs: null }),
    (error) => error.status === 415 && error.code === 'chat_media_type_unsupported',
  );
  assert.throws(
    () => inspectChatUpload({ bytes: jpeg, declaredContentType: 'image/jpeg', declaredDurationMs: 1000 }),
    (error) => error.status === 400 && error.code === 'chat_media_duration_invalid',
  );
  const ogg = Buffer.concat([Buffer.from('OggS'), Buffer.alloc(60)]);
  assert.throws(
    () => inspectChatUpload({ bytes: ogg, declaredContentType: 'audio/ogg', declaredDurationMs: null }),
    (error) => error.code === 'chat_media_duration_invalid',
  );
  assert.throws(
    () => inspectChatUpload({ bytes: ogg, declaredContentType: 'audio/ogg', declaredDurationMs: 300001 }),
    (error) => error.code === 'chat_media_duration_invalid',
  );
  assert.equal(inspectChatUpload({ bytes: ogg, declaredContentType: 'audio/ogg', declaredDurationMs: 9000 }).kind, 'audio');
  const huge = Buffer.concat([jpeg, Buffer.alloc(CHAT_IMAGE_BYTES_MAX + 1 - jpeg.length)]);
  assert.throws(
    () => inspectChatUpload({ bytes: huge, declaredContentType: 'image/jpeg', declaredDurationMs: null }),
    (error) => error.status === 413 && error.code === 'chat_media_too_large',
  );
  assert.throws(
    () => inspectChatUpload({ bytes: Buffer.alloc(0), declaredContentType: 'image/jpeg', declaredDurationMs: null }),
    (error) => error.code === 'chat_media_empty',
  );
});

test('the disk store writes only server-generated keys, never overwrites, and treats absence as success', async () => {
  assert.throws(() => new LocalDiskChatMediaStore({ root: 'relative/path' }));
  assert.throws(() => assertStorageKey('../../etc/passwd'));
  assert.throws(() => assertStorageKey('0123456789abcdef0123456789abcdef0123'));
  const root = await mkdtemp(join(tmpdir(), 'family-os-media-test-'));
  try {
    const store = new LocalDiskChatMediaStore({ root });
    const key = newStorageKey();
    await store.put(key, Buffer.from('bytes'));
    assert.deepEqual(await store.get(key), Buffer.from('bytes'));
    await assert.rejects(store.put(key, Buffer.from('other')), (error) => error.code === 'EEXIST');
    await store.delete(key);
    assert.equal(await store.get(key), null);
    await store.delete(key); // deleting what is already gone is not an error
    await assert.rejects(stat(join(root, key)), (error) => error.code === 'ENOENT');
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
