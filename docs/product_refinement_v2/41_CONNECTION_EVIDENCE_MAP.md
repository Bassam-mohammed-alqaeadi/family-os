# Family Connection Evidence Map — CONNECTION-G1-DISCOVERY

> **Status:** Evidence baseline complete; product decisions are documented separately in G1 direction.
> **Inspected:** 2026-09-29
> **Purpose:** Distinguish existing local Flutter experiences from actual multi-device messaging, calling, media, calendar, task, contact, and location-delivery capabilities.

## 1. Current evidence summary

- The registry contains 39 communication/coordination services across 7 systems, with family, guardian, and child journeys for messages, calls, calendar, tasks, media, friend approval, and location check-ins.
- Flutter contains screens/repositories/models for conversation lists/threads, child chats, active call/call history, child media share, friends/approval, outer circle, calendar, tasks, arrival/check-in, and location map/history/safe zones.
- The main runtime binds local family chat, calendar, outer-circle, media, arrival, task and other FamilyOps repositories through the local SQLite/session foundation where available.
- The source intentionally identifies several of these facilities as mock/local/no-Firebase or no-LiveKit. These are UI/domain/persistence foundations, not production communication delivery.

## 2. System-by-system evidence

| System | Observed UI/domain evidence | Local/test evidence | Production gap to resolve |
|---|---|---|---|
| Conversations | Parent/child conversation lists and threads, reply/edit/delete/read-state concepts, local family chat store. | Conversation/list/child-chat screen and local-persistence tests. | Multi-device transport, identity/contact authorization, ordering, sync, delivery/read receipts, edit/delete retention semantics, reporting/support. |
| Calls | Active-call, child active-call, call-history and call-play surfaces. | Mock/repository/widget tests. | Real audio/video transport, signaling, device permissions, call state, background/notification behavior, quality, emergency boundary, group calls. |
| Media & files | Child media-share, stickers/backgrounds, family-moment surfaces. | Local media-share repository and tests. | Capture/picker/upload/download, storage, scanning, permission, media processing/transcription, delivery/expiry/removal, rights and moderation. |
| Safe contact circle | Outer circle, child friends, friend approval/repository/models. | Local outer-circle storage and screen tests. | Contact verification, invitation, consent, relationship/age policy, blocking/reporting, cross-family boundaries, audit and support. |
| Family calendar | Calendar and add-event surfaces with Hijri/Gregorian and prayer-display models. | Local calendar repository/persistence and calendar tests. | Multi-device sync, real calendar conversion/prayer data, timezone/travel, invitation/reminder delivery, conflict resolution. |
| Tasks & responsibilities | Parent/child task lists, create task, smart chore distributor, reward fields. | Local tasks persistence/repository and widget tests. | Shared assignment sync, completion proof/review, reward/security-link contracts, conflict/recurrence/reminder model, ChoreAI capability. |
| Location in communication | Arrival/check-in, location map/history and related routes. | Local arrival/location bridges and screen tests. | Real consented location collection, freshness, request/response, background state, push delivery, accuracy/battery and privacy controls. |

## 3. Explicit local/mock truth

- No real chat transport, push delivery, WebSocket, Firebase, or backend synchronization is evidenced in the current Flutter source.
- No LiveKit/WebRTC/voice/video transport is evidenced; call screens and histories are local/mock UI models.
- No production media upload, file picker, camera capture pipeline, transcription service, content scanning, or cloud storage is evidenced.
- Calendar’s Hijri/Gregorian/prayer presentation contains local/sample/prototype evidence; real conversion, prayer calculation/region source and synchronized family scheduling remain future capability work.
- ChoreAI, group calls, media transcription, call play and stickers are surfaces/registered ideas, not production services.
- Location check-in UI does not prove live-location collection/delivery; it inherits the same native/backend truth boundary established by Security.

## 4. Journey reconciliation work

Four communication services do not appear in a registered journey:

- `S-COM-003` — subgroups.
- `S-COM-008` — pinned message.
- `S-COM-009` — conversation lock.
- `S-COM-012` — group call.

They require a V2 choice: gain a closed journey, merge into an approved system, defer as an existing system, or retire with documented replacement.

## 5. Discovery implications

1. Family Connection already has a broad local UX foundation. G2 must organize it as one family coordination experience rather than multiply navigation destinations.
2. The largest technical gaps are real-time transport/delivery, contact identity/consent, media lifecycle, shared synchronization, and native location/call behaviour.
3. Safe-circle policies and child dignity must be designed before any external-contact or communication surveillance capability; contact approval alone is not a complete trust model.
4. Calendar/tasks are high-value daily habits and should be treated as connected operational systems, not decorative family features.
5. Location check-ins offer a safer initial family coordination loop than an unqualified “live tracking in chat” promise.
