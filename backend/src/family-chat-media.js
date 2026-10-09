// W9 media operations — upload and download, with the room as the only permission.
//
// The order of operations is the security argument, so it is stated once here:
//
//   1. The DECLARED type and the BYTES are checked against each other before anything is stored
//      (src/chat-media-format.js). A mismatch is refused; the server never trusts a header.
//   2. The metadata is stripped BEFORE the hash is taken, so the hash, the size and the served
//      bytes are the same bytes - the thing a family member downloads is the thing that was checked.
//   3. The bytes are written to the object store, and the metadata row is inserted in a
//      transaction that re-checks membership. If that transaction loses, the bytes are deleted
//      again, so a refused upload leaves nothing behind.
//   4. A download is authorised EVERY time, against the room as it is now: an active member row,
//      the media not removed, and - once the media has been sent - the message's sequence at or
//      after the member's joining point. A guardian who was never in the room, a child whose
//      membership ended, and a member added later for older history all receive the same 404.
//
// No URL in this module is a credential. The content route is authorised per request, and the
// storage key is an internal handle that never leaves the server.

import { createHash, randomUUID } from 'node:crypto';

import { ChatError, mediaView, postgresFamilyChatPort, threadPathPrefix } from './family-chat.js';
import {
  CHAT_AUDIO_BYTES_MAX,
  CHAT_AUDIO_DURATION_MS_MAX,
  CHAT_IMAGE_BYTES_MAX,
  declaredChatMediaType,
  prepareChatMediaBytes,
  sniffChatMedia,
} from './chat-media-format.js';
import { newStorageKey } from './chat-media-store.js';

function requireMediaStore(mediaStore) {
  if (mediaStore == null) {
    throw new ChatError(503, 'chat_media_unavailable', 'Media storage is not configured on this server.');
  }
  return mediaStore;
}

/// Everything about the upload that can be decided from the request alone, before a database
/// round-trip. Returns the sniffed kind, the canonical type and the prepared bytes.
export function inspectChatUpload({ bytes, declaredContentType, declaredDurationMs }) {
  const declared = declaredChatMediaType(declaredContentType);
  if (declared == null) {
    throw new ChatError(415, 'chat_media_type_unsupported', 'This file type is not accepted in a family chat.');
  }
  if (!Buffer.isBuffer(bytes) || bytes.length === 0) {
    throw new ChatError(400, 'chat_media_empty', 'The upload carried no bytes.');
  }
  const sniffed = sniffChatMedia(bytes);
  if (sniffed == null || sniffed.mimeType !== declared) {
    throw new ChatError(415, 'chat_media_type_mismatch', 'The file content does not match its declared type.');
  }
  if (sniffed.kind === 'image') {
    if (declaredDurationMs != null) {
      throw new ChatError(400, 'chat_media_duration_invalid', 'An image has no duration.');
    }
    if (bytes.length > CHAT_IMAGE_BYTES_MAX) {
      throw new ChatError(413, 'chat_media_too_large', 'This image is larger than the family chat allows.');
    }
  } else {
    if (declaredDurationMs == null || declaredDurationMs < 1 || declaredDurationMs > CHAT_AUDIO_DURATION_MS_MAX) {
      throw new ChatError(400, 'chat_media_duration_invalid', 'A voice note must state a duration of up to five minutes.');
    }
    if (bytes.length > CHAT_AUDIO_BYTES_MAX) {
      throw new ChatError(413, 'chat_media_too_large', 'This voice note is larger than the family chat allows.');
    }
  }
  const prepared = prepareChatMediaBytes(bytes, sniffed.mimeType);
  if (prepared == null || prepared.length === 0) {
    throw new ChatError(400, 'chat_media_malformed', 'The file structure could not be read safely.');
  }
  return { kind: sniffed.kind, mimeType: sniffed.mimeType, bytes: prepared };
}

/** Resolves the caller and their live room membership inside a transaction, or refuses. */
async function resolveRoom(port, tx, { principal, deviceId, deviceCredential, familyId, threadId }) {
  const { actor, device, participant } = await port.resolveParticipant(tx, {
    principal,
    deviceId,
    deviceCredential,
    familyId,
  });
  const thread = await port.readThread(tx, { familyId: participant.familyId, threadId });
  if (thread == null) {
    throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
  }
  const member = await port.readThreadMember(tx, {
    threadId,
    participantKind: participant.kind,
    participantId: participant.id,
  });
  if (member == null) {
    throw new ChatError(404, 'chat_thread_not_found', 'This conversation is not part of the family.');
  }
  return { actor, device, participant, member };
}

export function createMediaUpload({ port, mediaStore }) {
  return async function uploadChatMedia({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    clientMediaId,
    declaredContentType,
    declaredDurationMs = null,
    bytes,
    correlationId,
  }) {
    const store = requireMediaStore(mediaStore);
    const inspected = inspectChatUpload({ bytes, declaredContentType, declaredDurationMs });
    const sha256 = createHash('sha256').update(inspected.bytes).digest();

    // First look: the same client media id from the same uploader is the same media, and a
    // different file under that id is a conflict rather than a silent replacement.
    const earlier = await port.transact(async (tx) => {
      const { participant } = await resolveRoom(port, tx, {
        principal, deviceId, deviceCredential, familyId, threadId,
      });
      const existing = await port.readMediaByClientId(tx, {
        threadId,
        uploaderKind: participant.kind,
        uploaderId: participant.id,
        clientMediaId,
      });
      return existing == null ? null : { existing, familyId: participant.familyId };
    });
    if (earlier != null) {
      return replayedUpload({ port, deviceId, threadId, row: earlier.existing, familyId: earlier.familyId, sha256 });
    }

    // The bytes first, outside any transaction: a slow disk must not hold a database lock.
    const storageKey = newStorageKey();
    await store.put(storageKey, inspected.bytes);

    try {
      const result = await port.transact(async (tx) => {
        const { participant, device } = await resolveRoom(port, tx, {
          principal, deviceId, deviceCredential, familyId, threadId,
        });
        const row = await port.insertMedia(tx, {
          id: randomUUID(),
          familyId: participant.familyId,
          threadId,
          uploaderKind: participant.kind,
          uploaderId: participant.id,
          clientMediaId,
          kind: inspected.kind,
          mimeType: inspected.mimeType,
          byteSize: inspected.bytes.length,
          sha256,
          declaredDurationMs,
          storageKey,
        });
        if (row == null) {
          // A concurrent identical upload won the conflict inside this transaction's view.
          const winner = await port.readMediaByClientId(tx, {
            threadId,
            uploaderKind: participant.kind,
            uploaderId: participant.id,
            clientMediaId,
          });
          return { winner, familyId: participant.familyId };
        }
        await port.audit(tx, {
          familyId: participant.familyId,
          actorMembershipId: participant.kind === 'membership' ? participant.id : null,
          correlationId,
          subjectId: row.id,
          subjectType: 'family_chat_media',
          eventType: device == null ? 'family.chat_media_uploaded' : 'family.chat_media_uploaded_device',
        });
        return { row, familyId: participant.familyId };
      });
      if (result.row != null) {
        return {
          media: mediaView(result.row, { pathPrefix: pathPrefixFor({ familyId: result.familyId, deviceId, threadId }) }),
          replayed: false,
        };
      }
      // This copy lost: its bytes are not described by any row, so they go.
      await store.delete(storageKey);
      return replayedUpload({ port, deviceId, threadId, row: result.winner, familyId: result.familyId, sha256 });
    } catch (error) {
      // A refused insert must not leave bytes that no row describes.
      await store.delete(storageKey);
      throw error;
    }
  };
}

function pathPrefixFor({ familyId, deviceId, threadId }) {
  return threadPathPrefix({ familyId, deviceId, threadId });
}

function replayedUpload({ deviceId, threadId, row, familyId, sha256 }) {
  if (row == null || !Buffer.from(row.sha256).equals(sha256)) {
    throw new ChatError(409, 'chat_media_client_id_conflict', 'That upload id already holds a different file.');
  }
  return {
    media: mediaView(row, { pathPrefix: pathPrefixFor({ familyId, deviceId, threadId }) }),
    replayed: true,
  };
}

/// Serves the bytes, after the same authorisation a message read performs - every time.
export function createMediaContent({ port, mediaStore }) {
  return async function readChatMediaContent({
    principal,
    deviceId,
    deviceCredential,
    familyId,
    threadId,
    mediaId,
  }) {
    const store = requireMediaStore(mediaStore);
    const grant = await port.read(async (tx) => {
      const { participant, member } = await resolveRoom(port, tx, {
        principal, deviceId, deviceCredential, familyId, threadId,
      });
      const media = await port.readMediaInThread(tx, { familyId: participant.familyId, threadId, mediaId });
      if (media == null || media.removed_at != null || media.storage_key == null) {
        throw new ChatError(404, 'chat_media_not_found', 'This media is not part of the conversation.');
      }
      // Sent media follows the message: visible from the member's joining point onward.
      // Unsent media is visible only to the person who uploaded it, while they are composing.
      const visible = media.attached_message_id != null
        ? Number(media.attached_seq) >= Number(member.joined_seq ?? 1)
        : media.uploader_kind === participant.kind && media.uploader_id === participant.id;
      if (!visible) {
        throw new ChatError(404, 'chat_media_not_found', 'This media is not part of the conversation.');
      }
      return {
        storageKey: media.storage_key,
        mimeType: media.mime_type,
        sha256: Buffer.from(media.sha256),
      };
    });

    const bytes = await store.get(grant.storageKey);
    if (bytes == null) {
      // The row says the bytes exist and the store disagrees: that is an integrity failure, not a 404.
      throw new ChatError(500, 'chat_media_integrity_failed', 'The stored media could not be read.');
    }
    if (!createHash('sha256').update(bytes).digest().equals(grant.sha256)) {
      throw new ChatError(500, 'chat_media_integrity_failed', 'The stored media could not be verified.');
    }
    return { mimeType: grant.mimeType, bytes };
  };
}

/// The media operations, built on the same port as the rest of the chat so one credential check
/// and one room rule apply to every route. `mediaStore` may be null: the routes then answer
/// `chat_media_unavailable` instead of writing somewhere by default.
export function chatMediaFor(store, { credentialMatches, mediaStore = null }) {
  const port = postgresFamilyChatPort(store, { credentialMatches });
  return {
    upload: createMediaUpload({ port, mediaStore }),
    content: createMediaContent({ port, mediaStore }),
    available: mediaStore != null,
  };
}
