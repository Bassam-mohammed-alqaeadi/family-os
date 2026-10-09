# W9 Family Chat Upgrade — Step 1 Proposal: Database and API Contract

Status: **PROPOSAL — awaiting owner approval.** No Flutter client code has been touched.
Scope: PostgreSQL schema, Node.js API, realtime transport, media, receipts.
Baseline measured on this branch: `npm test` in `backend/` → **244 pass, 0 fail, 18 skipped**
(the 18 skips are the PostgreSQL-gated integration tests, because `DATABASE_URL` is not set in this sandbox).

---

## 0. What the code says today (evidence)

| Area | Current state | Source |
|---|---|---|
| Thread kinds | `family`, `child` (109), `direct`, `group` (110) | `109_family_chat.sql`, `110_collaboration_flexibility.sql` |
| Message body | text only, `CHECK char_length(body) <= 2000`, live body must match `\S` | `109_family_chat.sql` |
| Ordering | per-thread `next_seq`, allocated inside the send transaction | `family-chat.js` `allocateSeq` |
| Idempotency | `UNIQUE(thread_id, author, client_message_id)` + `idempotent()` key | `109`, `createMessageSend` |
| Read state | `family_chat_thread_members.last_read_seq`, monotonic; `readCount` = other participants with `last_read_seq >= seq` | `109`, `family-chat.js` |
| Delivery state | **none** — explicitly excluded by design ("no push transport to prove a delivery") | header comment, `109` |
| Membership boundary | `joined_seq` / `left_at` on members; listing and `readCount` already respect `joined_seq` | `110`, `family-chat.js:1341,1442` |
| Child-to-child guardian rule | `family_collaboration_policies.guardian_inclusion_mode IN ('none','all_child_chats','child_to_child')`, enforced at thread create and add-member | `110`, `family-chat.js:337-342, 533, 638` |
| Transport | HTTP only; client polls. Capability flags say `transport: 'polling'`, `webSockets: false`, `serverSentEvents: false`, `attachments: false`, `audio: false` | `family-chat.js` `CHAT_CURRENT_CAPABILITIES` |
| Server | `express` 5 on `runtime.app.listen(port, '0.0.0.0')`; no WebSocket library in `package.json` | `server.js`, `package.json` |
| JSON body limit | `express.json({ limit: '64kb', strict: true })` globally | `app.js:159` |
| Contract guard | every route in `app.js` must be in `backend/openapi/foundation.v1.json` (drift test); capability flags are pinned by tests | `openapi-contract.test.js`, `family-chat-laws.test.js:457` |
| Device routes | every member route has a `/v1/devices/:deviceId/...` twin for a paired child handset | `app.js:2157-2371` |

Two points that shape the proposal:

1. **The room is the permission.** The W9 laws say a person reads a thread only if a
   `family_chat_thread_members` row exists for them. Media must follow the same law. A guardian
   who is not in a room cannot see its media, even if they are a guardian of the family.
2. **Doc 46 §5 requires** authoritative delivery/read acknowledgement APIs and a durable
   event store before any socket fan-out. The proposal below is built to that rule: the database
   is the source of truth, and the socket only says "something changed, go and ask the API".

---

## 1. Database schema alterations

Proposed as a single new migration: **`112_family_chat_realtime_media.sql`**. It is additive and does not rewrite existing rows.

### 1.1 `family_chat_thread_members` — delivery mark (receipts)

```sql
ALTER TABLE family_chat_thread_members
  ADD COLUMN last_delivered_seq BIGINT NOT NULL DEFAULT 0 CHECK (last_delivered_seq >= 0),
  ADD CONSTRAINT family_chat_thread_members_delivered_not_before_read
    CHECK (last_delivered_seq >= last_read_seq);
```

- `last_delivered_seq` is the participant's own high-water mark: "my client has received
  everything up to this seq over an authenticated channel". Monotonic, like `last_read_seq`.
- Stored **once per member row**, so there is still no per-message, per-person receipt table.
  This keeps the existing "no surveillance log" law.
- The write API will refuse values above the thread's `next_seq - 1` (same rule as `chat_read_ahead`).

### 1.2 `family_chat_media` — new table

**As built in migration 112** (`backend/db/migrations/112_family_chat_realtime_media.sql` is the
source of truth; this section summarises it). The first draft put the bytes in a `content BYTEA`
column and tracked a `scan_status`. Owner decision D4 superseded that: metadata stays in
PostgreSQL and the bytes live behind an object-store port, so the table holds an opaque
`storage_key` and no byte column.

Columns: `id`, `family_id`, `thread_id`, `uploader_kind`/`uploader_id`, `client_media_id`
(8–64 chars, idempotency key), `kind` (`image`|`audio`), `mime_type` (the sniffed type, allowlisted),
`byte_size`, `sha256` (32 bytes, of the stored bytes), `declared_duration_ms` (client-declared,
audio only), `storage_key` (server-generated UUID, NULL once removed), `removed_at`, `created_at`.

Laws enforced by the database, not only by the route:
- **Thread-bound and family-bound** (composite FK to `family_chat_threads`).
- **Uploader must be a participant** of the room (composite FK to `family_chat_thread_members`).
- **Allowlisted MIME types and size caps** by `CHECK`: images ≤ 8 MiB; audio ≤ 6 MiB and a declared
  duration of 1–300 000 ms. Audio requires the duration to be present: a SQL `CHECK` passes on NULL,
  so the presence test is written out explicitly (`declared_duration_ms IS NOT NULL`).
- **Lifecycle:** a live row has a `storage_key`; a removed row has `removed_at` and no key. The trace of
  a removal is kept, the bytes are not.
- **Unique per uploader and client id** (`family_chat_media_client_unique`), so a retried upload is one item.

Deliberately not present: `width`/`height` (not measured by the server), `scan_status` (uploads are
all-or-nothing: a rejected file is never stored), and any byte column.

### 1.3 `family_chat_messages` — media reference and kind

```sql
ALTER TABLE family_chat_messages
  ADD COLUMN kind TEXT NOT NULL DEFAULT 'text' CHECK (kind IN ('text', 'image', 'audio')),
  ADD COLUMN media_id UUID NULL,
  ADD CONSTRAINT family_chat_messages_media_fk
    FOREIGN KEY (family_id, thread_id, media_id)
    REFERENCES family_chat_media (family_id, thread_id, id) ON DELETE RESTRICT,
  ADD CONSTRAINT family_chat_messages_media_once UNIQUE (media_id),
  ADD CONSTRAINT family_chat_messages_kind_matches_media CHECK (
    (kind = 'text' AND media_id IS NULL)
    OR (kind <> 'text' AND media_id IS NOT NULL));
```

Then the existing `lifecycle_complete` check is replaced so that a live message needs **either** a
body **or** media (a voice note may have an empty caption). Edits are text-only:
`kind = 'text'` is required for `family_chat_message_revisions` rows.

Deleting a message with media: body cleared as today, `family_chat_media.content` set to NULL and
`removed_at` stamped in the same transaction (the sequence number stays as a tombstone).

### 1.4 What the schema deliberately does not add

- No `family_chat_deliveries` table and no per-person "seen" list. Receipts stay aggregate (§3).
- No `device_tokens` table — FCM is out of scope for this step (see §6).
- No media URL column. URLs are computed by the API from the row id; nothing in the database
  is a bearer credential.

### 1.5 Migration test plan (PostgreSQL integration, runs in CI)

Each law gets a test that tries to break it and expects the constraint to refuse. Implemented in
`backend/test/postgres-chat-realtime-media.test.js` (the file runs in `backend_ci.yml`):
- media into a room the uploader is not in → FK violation (`family_chat_media_uploader_fk`);
- `audio` with no declared duration, or above 300 000 ms → CHECK violation;
- an image or audio over its byte cap → CHECK violation;
- a live row without a `storage_key`, or a removed row with one → CHECK violation;
- a `storage_key` that is not a UUID → CHECK violation;
- a message whose `kind` does not match its media → CHECK violation;
- `last_delivered_seq < last_read_seq` → CHECK violation.

Uniqueness of `media_id` on messages (one media, one message) is exercised through the API by
`chat_media_already_sent`.

---

## 2. API contract updates

All new routes come in **two twins**, following the existing convention: `/v1/families/:familyId/...`
for guardians and `/v1/devices/:deviceId/...` for paired child handsets. Authorization is decided
by the same `familyChat` port, so the twins cannot disagree.

### 2.1 Realtime (new)

`GET /v1/realtime` — HTTP upgrade to WebSocket.

- **Auth:** `Authorization` header (`Bearer` for guardians, device credential for handsets).
  No token in the query string (query strings end up in logs). Rejected before upgrade with the existing error envelope when no valid principal or device exists.
- **Client → server frames** (JSON, ≤ 1 KiB each):
  - `{"type":"subscribe","familyId","threadId"}` — server checks the member row **now** and on every reconnect; a non-member gets `chat_thread_not_found` and no subscription.
  - `{"type":"unsubscribe","threadId"}`
  - `{"type":"ping"}`
- **Server → client frames** (hints only, no message bodies):
  - `{"type":"chat.message","threadId","seq"}` — a message was created or changed.
  - `{"type":"chat.receipt","threadId","seq"}` — receipt counts moved.
  - `{"type":"chat.media","threadId","mediaId"}` — media became clean or was removed.
  - `{"type":"resync","threadId"}` — the server dropped events; client must refetch.
- Clients always **refetch via REST** after a hint. The socket never carries content, so the
  authorization path is the same one a polling client uses.
- **Limits:** max 20 subscriptions per socket, 60 frames/minute inbound, idle timeout 60 s with
  server heartbeat every 25 s, max 2 sockets per principal.
- **Fan-out across instances:** Postgres `LISTEN/NOTIFY` on `family_chat_events`, payload
  `{threadId, seq, kind}` only. Single Render instance works without it; it is the scale path.

### 2.2 Send a message (extended, backward compatible)

`POST /v1/families/:familyId/chat/threads/:threadId/messages` (and device twin)

Body becomes:

```json
{ "clientMessageId": "…8–64 chars…", "body": "optional caption ≤ 2000", "mediaId": "optional uuid" }
```

- `body` is required unless `mediaId` is present. `mediaId` must be **clean**, uploaded by the
  caller, and in this thread — otherwise `chat_media_not_found` (404, same as a room the caller is not in).
- Response adds `kind`, `media` (§2.5), and `receipt` (§3).
- Existing text-only requests keep working unchanged.

### 2.3 Upload media (new)

`POST /v1/families/:familyId/chat/threads/:threadId/media` (and device twin)

- Body: **raw bytes** (`Content-Type` = the file type the client believes), parsed by a
  route-scoped `express.raw({ limit: '6mb' })`. The global 64 kb JSON limit stays for everything else.
- Query: `clientMediaId` (8–64 chars) for idempotency; `durationMs` for audio; `width`/`height` optional for images.
- Server: sniffs magic bytes, rejects mismatched or unlisted types (`chat_media_type_unsupported`),
  rejects oversize (`chat_media_too_large`), computes `sha256`, strips image metadata by
  re-encoding (see §4), then sets `scan_status`.
- Response `201` with the media view, `scanStatus: 'pending' | 'clean'`. Only `clean` media can be sent.
- Idempotent: the same `clientMediaId` returns the same media, like a message resend.

### 2.4 Download media (new)

`GET /v1/families/:familyId/chat/threads/:threadId/media/:mediaId/content` (and device twin)

- Authorization on **every request**: caller must have an active member row in the thread, the
  media's message must have `seq >= joined_seq`, and the media must not be removed.
  Anything else returns `404 chat_media_not_found`. A guardian who is not in the room gets the same 404.
- Response: raw bytes, `Content-Type` from the stored sniffed type, `Cache-Control: private, no-store`,
  `X-Content-Type-Options: nosniff`, `Content-Disposition: inline` for images and audio.
- Revocation is immediate: when a member leaves (`left_at`) the next request fails.
- No pre-signed or public URLs in v1. If object storage is chosen later (§4), the API issues
  **short-lived (≤ 5 min) URLs only after** the same check runs, and the check re-runs on each issue.

### 2.5 Message view (extended)

```json
{
  "id": "…", "seq": 12, "kind": "audio", "authorKind": "child", "authorId": "…",
  "body": "caption or null", "revision": 1, "deleted": false,
  "media": {
    "id": "…", "kind": "audio", "mimeType": "audio/ogg", "byteSize": 48211,
    "durationMs": 9340, "width": null, "height": null,
    "scanStatus": "clean", "contentPath": "/v1/families/…/media/…/content"
  },
  "receipt": { "deliveredCount": 2, "readCount": 1, "otherParticipantCount": 3 }
}
```

`media` is `null` for text. `contentPath` is a path, not a credential; the client still needs the
caller's own authorization to fetch it.

### 2.6 Receipts (new)

`POST /v1/families/:familyId/chat/threads/:threadId/delivered` (and device twin)
Body: `{ "deliveredSeq": 12 }`

- Monotonic: a lower value is a no-op, not an error (same as read marks, which only move forward).
- Refused with `chat_delivered_ahead` (409) above the thread's highest seq, and with
  `chat_read_before_join` semantics below `joined_seq - 1`.
- Clients call it when a batch of messages has been **received and stored locally** — not when
  the notification appears.

`POST …/reads` already exists and is unchanged. Its response gains the same `receipt` block.

### 2.7 Thread list and capabilities (updated)

- `CHAT_CURRENT_CAPABILITIES` changes from `transport: 'polling'` to `'websocket+poll'`,
  `webSockets: true`, `attachments: true`, `audio: true`, `contentTypes` extended with the
  allowlist in §1.2. `presence` and `richReactions` stay `false`.
- Polling intervals remain as fallback (`listPollSeconds`, `threadPollSeconds`) — the client
  must still work when the socket is down.
- Thread list items gain `unreadCount` computed from `last_read_seq` (server-owned, not a client counter).

### 2.8 OpenAPI and tests

- Every new route is added to `backend/openapi/foundation.v1.json`, so the existing drift test covers them.
- The `/v1/realtime` upgrade is documented as an `101 Switching Protocols` operation with the frame
  schemas in `components/schemas`.
- `family-chat-laws.test.js` pins the new capability values; `openapi-contract.test.js` pins the new capability keys.

---

## 3. Read and delivery receipts — the honest model

| State shown to a sender | Claim | Stored as | Who computes it |
|---|---|---|---|
| **Sent** | The server stored the message and assigned its seq. | the message row | server (always true once shown) |
| **Delivered** | At least one other participant's client acknowledged receiving this seq. | `last_delivered_seq` ≥ seq | server, aggregate |
| **Read** | At least one other participant has marked read up to this seq. | `last_read_seq` ≥ seq | server, aggregate (existing `readCount`) |

Rules:
- The sender's own status never counts toward delivered/read.
- Counts only, no names, no per-person list — the family-room law (doc 40 / migration 109).
- A "Delivered" claim is only shown when the acknowledgement came from an authenticated
  connection. A push notification alone never produces it (doc 46 §4).
- A child's handset can read and deliver for the child member row. A child in a room is still
  one participant, not a family member with extra rights.

**This is the one place where the proposal changes an existing law** (see §5, decision D1).

---

## 4. Media storage and safety

As built (owner decision D4):
- **Metadata** lives in `family_chat_media` (PostgreSQL). **Bytes** live behind an object-store port
  (`backend/src/chat-media-store.js`). The v1 adapter is `LocalDiskChatMediaStore`, rooted at
  `FAMILY_CHAT_MEDIA_DIR`. If that is unset, media routes answer 503 `chat_media_unavailable`; there is
  no silent fallback. An S3 adapter is deferred: the interface exists, the adapter does not.
- **Upload pipeline** (`backend/src/chat-media-format.js`, `family-chat-media.js`): size cap → magic-byte
  sniff → declared type must match the sniffed type → **metadata stripping** → `sha256` of the stored
  bytes → store under a server-generated key. The row is written in the same transaction as the
  membership check. A refused upload is never stored, and the bytes are removed if the transaction fails.
- **Metadata stripping, as built.** JPEG: EXIF/APP1 and other non-essential APP segments are removed
  (APP0, APP2 and APP14 are kept). PNG: `tEXt`, `zTXt`, `iTXt`, `eXIf` and `tIME` chunks are removed.
  WebP: EXIF and XMP chunks are removed and their header flags cleared. MP3: a leading ID3v2 tag is
  removed. **Limitation, declared:** OGG and MP4/M4A are stored unchanged, and their embedded metadata
  is not stripped. Stripping is not a re-encode, so no image library is added.
- **Malware scanning: not claimed.** A real scanner would be a provider decision.
- **Serving:** `Content-Type` is the sniffed type, with `nosniff`, a `sandbox` Content-Security-Policy,
  and `Cache-Control: private, no-store`.

Child safety rules (required by the brief):
- Child-to-child rooms with a guardian present: the guardian is a member row, so they download
  media through the same endpoint as everyone in the room. Nothing extra is granted.
- A child in a `direct` room with no guardian gets 404 for media outside it.
- Guardians cannot download from a room they were not added to, even under
  `guardian_inclusion_mode = 'child_to_child'`. Inclusion is decided at thread creation / member add
  by the existing policy, and media follows whatever membership exists.
- A guardian added later does **not** get media from before `joined_seq`.
- Deletion by the author removes bytes immediately; a guardian cannot delete a child's media (same rule as text).

---

## 5. Decisions needed from you (before the Flutter step)

| # | Decision | Options | Recommendation |
|---|---|---|---|
| **D1** | **Delivered receipts reverse the migration-109 "no delivery claim" law.** | (a) approve ack-based aggregate delivery (§3); (b) keep read-only receipts | **(a)** — the socket plus an explicit ack makes delivery provable, which is what doc 46 §5 asks for. |
| **D2** | **Read receipts: aggregate or per-person blue ticks?** | (a) aggregate counts only (current law); (b) per-person "seen by" list | **(a)** — per-person lists turn a family room into a surveillance log. You asked for WhatsApp-like; this is the one place I recommend *not* copying it. |
| **D3** | **Realtime transport.** | (a) WebSocket (`ws` library, new dependency; matches doc 46 wording); (b) Server-Sent Events (no new dependency, one-way, uses the same Last-Event-ID replay) | **(a)** WebSocket, because doc 46 names it and subscriptions need client→server frames. (b) is a valid fallback. |
| **D4** | **Media storage and scanning.** | (a) BYTEA in Postgres with local checks (§4); (b) S3-compatible object store + external malware scanner | **(a)** for v1 — no new vendor; **(b)** is a cost and provider decision that doc 46 §7 reserves to you. |
| **D5** | **Push notifications (FCM).** | (a) defer; (b) add FCM hints now | **(a)** — FCM needs an approved provider and privacy model (doc 46 §4). The socket covers instant delivery while the app is open. Background delivery is a later step. |

**Owner decisions, approved.** D1 and D2: aggregate receipts only ("N of M"), with a per-member
`last_delivered_seq`; no per-person lists. D3: WebSocket, carrying hints only; payloads are fetched over
REST. D4: metadata in PostgreSQL, bytes behind an object-store port with a local-disk adapter for
development and tests. This supersedes the BYTEA option in §4. D5: FCM deferred; the app WebSocket
lifecycle comes first.

Also flagged, not blocking (resolved by the W9 Realtime & Media exception in the plan): W9 was still listed as "local complete, CI environment gates pending" in
`docs/CURRENT_EXECUTION_PLAN.md`. This upgrade should not start until W9 closes its 4/4 gate, or it
should be recorded as an explicit exception.

---

## 6. Out of scope for this step

- No Flutter/Dart changes (waiting for your approval).
- No FCM, no calls, no end-to-end encryption claims (doc 46 §6).
- No reactions, presence or typing indicators.

## 7. Proposed execution order after approval

1. Migration 112 + PostgreSQL integration tests for every law in §1.5 (runs on real PostgreSQL).
2. Media port + upload/download routes + authorization matrix tests (guardian in room, guardian not in room, child before `joined_seq`, removed member, guardian-only child rooms).
3. Receipt endpoint + aggregate `receipt` block + monotonic/ahead tests.
4. WebSocket gateway with auth on upgrade, subscribe checks, limits, hint frames, and a replay/resync test.
5. OpenAPI and capability updates; drift tests green.
6. **Then** — after your approval — Dart client (API client methods, WebSocket client with REST refetch, upload and record pipeline) and the UI screens.

Backend steps 1–5 keep the existing 244 tests green. Each step adds its own tests.
