// W9 media — what a file IS, decided from its bytes, and what it must not carry out of the house.
//
// Three rules, and each is checked here rather than trusted from the client:
//
//   * THE BYTES DECIDE THE TYPE. The Content-Type a phone declares is compared with the type the
//     signature of the file says it is, and a mismatch is refused. A file named `photo.jpg` that
//     is really a script is not stored as an image, and nothing is served with a type it did not
//     prove.
//   * ONLY ALLOWLISTED CONTAINERS ARE STORED. Eight-bit images in JPEG, PNG or WebP; audio notes
//     in Ogg (Opus), MP4/AAC or MPEG (MP3). Anything else is refused before it reaches storage.
//   * METADATA IS STRIPPED WHERE THE FORMAT ALLOWS IT SAFELY. A phone photo carries GPS
//     coordinates in its EXIF block. A family chat that re-serves that block to every member of a
//     room is a location leak nobody asked for, so JPEG APP segments other than the colour
//     profile and the Adobe marker are removed, PNG text and EXIF chunks are removed, WebP EXIF
//     and XMP chunks are removed, and an MP3's leading ID3 tag is removed.
//
// What this module does NOT claim: it does not decode the image or the audio, so a file that
// has a valid signature and corrupt payload is stored as the bytes it is. It does not scan for
// malware. And it does not strip MP4 (`udta`) or Ogg Vorbis comment metadata: those are recorded
// as a known limitation in the W9 proposal, not hidden behind a claim of privacy.

export const CHAT_MEDIA_IMAGE_TYPES = Object.freeze(['image/jpeg', 'image/png', 'image/webp']);
export const CHAT_MEDIA_AUDIO_TYPES = Object.freeze(['audio/mp4', 'audio/ogg', 'audio/mpeg']);
export const CHAT_MEDIA_TYPES = Object.freeze([...CHAT_MEDIA_IMAGE_TYPES, ...CHAT_MEDIA_AUDIO_TYPES]);

export const CHAT_IMAGE_BYTES_MAX = 8 * 1024 * 1024;
export const CHAT_AUDIO_BYTES_MAX = 6 * 1024 * 1024;
export const CHAT_AUDIO_DURATION_MS_MAX = 5 * 60 * 1000;

/// The type the signature proves, or null when no allowlisted signature matches.
export function sniffChatMedia(bytes) {
  if (!Buffer.isBuffer(bytes) || bytes.length < 12) return null;
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return { kind: 'image', mimeType: 'image/jpeg' };
  }
  if (bytes.subarray(0, 8).equals(PNG_SIGNATURE)) {
    return { kind: 'image', mimeType: 'image/png' };
  }
  if (bytes.subarray(0, 4).toString('latin1') === 'RIFF' && bytes.subarray(8, 12).toString('latin1') === 'WEBP') {
    return { kind: 'image', mimeType: 'image/webp' };
  }
  if (bytes.subarray(0, 4).toString('latin1') === 'OggS') {
    return { kind: 'audio', mimeType: 'audio/ogg' };
  }
  if (bytes.subarray(4, 8).toString('latin1') === 'ftyp') {
    return { kind: 'audio', mimeType: 'audio/mp4' };
  }
  if (bytes.subarray(0, 3).toString('latin1') === 'ID3' || (bytes[0] === 0xff && (bytes[1] & 0xe0) === 0xe0)) {
    return { kind: 'audio', mimeType: 'audio/mpeg' };
  }
  return null;
}

/// The declared Content-Type without parameters, lower-cased, or null when it is not allowlisted.
export function declaredChatMediaType(headerValue) {
  if (typeof headerValue !== 'string') return null;
  const base = headerValue.split(';')[0].trim().toLowerCase();
  return CHAT_MEDIA_TYPES.includes(base) ? base : null;
}

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

// A JPEG marker segment is `FF xx`, and every marker except the standalone ones carries a
// two-byte big-endian length that counts itself but not the marker. Start-of-scan ends the
// header area: everything after it is entropy-coded image data and is copied verbatim.
const JPEG_STANDALONE = new Set([0x01, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7]);
const JPEG_KEEP_APP = new Set([0xe0, 0xe2, 0xee]); // JFIF, ICC colour profile, Adobe colour marker

/** Returns the JPEG without its metadata segments, or null when the marker structure is broken. */
function stripJpeg(bytes) {
  const out = [bytes.subarray(0, 2)];
  let offset = 2;
  while (offset < bytes.length) {
    if (bytes[offset] !== 0xff) return null;
    // Padding fill bytes (FF FF …) may precede a marker.
    while (bytes[offset + 1] === 0xff) offset += 1;
    const marker = bytes[offset + 1];
    if (marker === 0xda) {
      // Start of scan: the rest is image data and the end marker.
      out.push(bytes.subarray(offset));
      return Buffer.concat(out);
    }
    if (marker === 0xd9) {
      out.push(bytes.subarray(offset));
      return Buffer.concat(out);
    }
    if (JPEG_STANDALONE.has(marker)) {
      out.push(bytes.subarray(offset, offset + 2));
      offset += 2;
      continue;
    }
    if (offset + 4 > bytes.length) return null;
    const length = bytes.readUInt16BE(offset + 2);
    if (length < 2 || offset + 2 + length > bytes.length) return null;
    const isApp = marker >= 0xe0 && marker <= 0xef;
    const keep = !isApp || JPEG_KEEP_APP.has(marker);
    if (keep && marker !== 0xfe) out.push(bytes.subarray(offset, offset + 2 + length));
    offset += 2 + length;
  }
  return null;
}

const PNG_DROP = new Set(['eXIf', 'tEXt', 'zTXt', 'iTXt']);

/** Returns the PNG without text and EXIF chunks, or null when a chunk length is broken. */
function stripPng(bytes) {
  const out = [PNG_SIGNATURE];
  let offset = PNG_SIGNATURE.length;
  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString('latin1');
    const end = offset + 12 + length;
    if (end > bytes.length) return null;
    if (!PNG_DROP.has(type)) out.push(bytes.subarray(offset, end));
    offset = end;
    if (type === 'IEND') break;
  }
  if (offset !== bytes.length) return null;
  return Buffer.concat(out);
}

/** Returns the WebP without EXIF and XMP chunks, clearing their header flags. */
function stripWebp(bytes) {
  const chunks = [];
  let offset = 12;
  let flagsIndex = -1;
  while (offset + 8 <= bytes.length) {
    const fourcc = bytes.subarray(offset, offset + 4).toString('latin1');
    const size = bytes.readUInt32LE(offset + 4);
    const padded = size + (size % 2);
    const end = offset + 8 + padded;
    if (end > bytes.length) return null;
    if (fourcc === 'VP8X') flagsIndex = offset + 8;
    if (fourcc !== 'EXIF' && fourcc !== 'XMP ') chunks.push(bytes.subarray(offset, end));
    offset = end;
  }
  if (offset !== bytes.length) return null;
  const body = Buffer.concat(chunks);
  const out = Buffer.concat([Buffer.from('RIFF\0\0\0\0WEBP', 'latin1'), body]);
  out.writeUInt32LE(out.length - 8, 4);
  if (flagsIndex !== -1) {
    // VP8X flags: bit 0x08 = EXIF present, 0x04 = XMP present. Both are cleared with their data.
    const flagsOffset = 20;
    out[flagsOffset] = out[flagsOffset] & ~0x0c;
  }
  return out;
}

/** Removes a leading ID3v2 tag; its size is a 28-bit syncsafe integer. */
function stripMp3(bytes) {
  if (bytes.subarray(0, 3).toString('latin1') !== 'ID3') return bytes;
  if (bytes.length < 10) return null;
  const size =
    (bytes[6] & 0x7f) * 0x200000 + (bytes[7] & 0x7f) * 0x4000 + (bytes[8] & 0x7f) * 0x80 + (bytes[9] & 0x7f);
  const end = 10 + size;
  if (end > bytes.length) return null;
  return bytes.subarray(end);
}

/**
 * The bytes that will be stored and served. Returns null when the container is malformed in a
 * way that makes stripping unsafe; the caller refuses the upload rather than store a file it
 * could not clean.
 */
export function prepareChatMediaBytes(bytes, mimeType) {
  switch (mimeType) {
    case 'image/jpeg':
      return stripJpeg(bytes);
    case 'image/png':
      return stripPng(bytes);
    case 'image/webp':
      return stripWebp(bytes);
    case 'audio/mpeg':
      return stripMp3(bytes);
    default:
      // Ogg and MP4 are stored as they are; see the module comment for the stated limitation.
      return bytes;
  }
}
