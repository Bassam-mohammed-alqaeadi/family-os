# Family Connection Capability & Architecture Readiness — Gate G3

> **Status:** Product-readiness technical design complete
> **Infrastructure boundary:** Render is authoritative; Firebase is only approved no-cost auxiliary tooling under `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`.

## 1. Architecture outcome

The connection platform must make one dependable promise:

> A family member can communicate, coordinate, or check in with the right people, while every relationship, delivery, acknowledgement, permission and recovery state remains truthful.

The product separates:

| State | Meaning |
|---|---|
| Relationship permission | Who may contact/share/call/request with whom, under which family authority. |
| Intent | What a person attempted: message, call, media share, event, task, check-in, location request. |
| Delivery | Whether the intended recipient/device/service accepted, queued, received, displayed or failed the action. |
| Acknowledgement | Whether a human read, responded, accepted, completed or resolved it where relevant. |
| Effective coordination state | The current event/task/contact/check-in state after permissions, changes, conflicts and expiry. |

## 2. Render-first topology

```text
Parent / co-guardian / child Flutter clients
                    │
          authenticated Render API + realtime gateway
                    │
 ┌──────────────────┼───────────────────────────────────────────────┐
 │ Render family/role service       Render relationship/contact svc   │
 │ Render conversation/message svc  Render calendar/task svc          │
 │ Render check-in/location svc     Render media metadata/lifecycle   │
 │ Render event/timeline/audit svc  Render notification orchestrator  │
 │ Render report/support services   Render job queue/workers          │
 └──────────────────┴───────────────────────────────────────────────┘
                    │
       Render durable data / queue / object-storage-compatible path
                    │
    Firebase FCM only if approved: push transport attempt to devices
```

Render owns the authoritative state. FCM may deliver a push hint but does not prove a message, task, check-in, or SOS was received/read/resolved.

## 3. Domain responsibilities

| Domain | Owns | Must not own |
|---|---|---|
| Relationship/contact service | Family/relative/friend relationship lifecycle, scope, guardian approval, block/revoke, invitation state. | Broad content surveillance or public discovery. |
| Conversation/message service | Thread membership, message revisions, send/delivery/read receipts, moderation/report states, retention metadata. | A claim of end-to-end encryption unless the implemented protocol/properties prove it. |
| Call service | Call intent, participant permission, signaling/session state/history and capability receipt. | Media transport/quality promise before real provider/SFU/native implementation is selected. |
| Media service | Asset metadata, authorization, upload/download lifecycle, expiry/removal/report state and source context. | Direct client trust or indefinite storage without data policy. |
| Calendar service | Event revision, members, recurrence/timezone/calendar context, reminders, conflicts, activity state. | Local-clock-only assumed family truth. |
| Task service | Assignment, completion/review/reopen, recurrence, recognition link, reminder/activity state. | Silent AI assignment or financial balance. |
| Check-in/location service | Consent/request/check-in/response, freshness/accuracy references and coordination event. | Live location claim without Security native capability proof. |
| Notification orchestrator | Recipient preference, priority, push attempt, grouping, retry/quiet hours. | Source-of-truth delivery/read or incident resolution. |

## 4. Capability programme

| Capability | Required future work | User behaviour until proven |
|---|---|---|
| Realtime conversations | Render authenticated API, durable message store, ordered event stream, WebSocket reconnect/scale model, receipts. | Local/mock conversation is labeled local; no cross-device sent/delivered claim. |
| Push notifications | Render chooses recipients and sends FCM only if approved; client registration/receipt/retry/privacy model. | A push attempt is not message delivery/read; app refresh/recovery path exists. |
| Calls | Select/evaluate transport/signaling/SFU/recording policy, native permissions, background/incoming behavior, quality and support. | Calls show unavailable/unsupported; no real call claim. |
| Media/files | Client picker/camera/voice permissions, Render-backed upload path, durable storage, content limits/scanning, download/removal/expiry and audit. | Existing sharing UI cannot say media was uploaded or transcribed. |
| Safe contacts | Consent/invitation/verification, role/age boundaries, reporting/blocking/recovery, external family boundary. | Contact changes are pending until server-authorized/accepted. |
| Calendar | Server time/timezone, recurrence, Hijri/Gregorian display source, prayer-time source/region, reminders/conflicts/sync. | Prototype/sample calendar labels remain local/non-authoritative. |
| Tasks | Shared assignment/completion/review/recurrence, notification, fairness and reward/security contract. | Local task completion is not family-wide confirmation. |
| Location check-in | Security location consent/native truth, Render check-in request/response/delivery, stale/accuracy and escalation. | “I arrived” is limited/unavailable until actual delivery is verified. |

## 5. Realtime design requirements

Render supports WebSockets, but a connection is not a durable state store. The implementation must provide:

- Authenticated subscription scope by family/relationship/role.
- Durable event/message writes before client fan-out.
- Reconnect cursor, replay/deduplication and ordering strategy.
- Heartbeat/stale-connection handling and multi-instance coordination.
- Backpressure/rate limits/spam/abuse protection.
- Authoritative read/delivery acknowledgement APIs rather than transient socket assumptions.
- Fallback refresh/poll/recovery when realtime or FCM is unavailable.

## 6. Calls and encryption decision boundary

Family Connection may eventually require strong transport/content privacy. No marketing or UI claim of end-to-end encryption, permanent reachability, call recording, transcript, group-call availability, or emergency calling is permitted until the exact transport, key/session model, device/platform support, metadata handling and operational recovery are implemented and verified.

## 7. Architecture decisions deferred

The product readiness phase does not select a chat/call vendor, WebRTC SFU, media storage engine, anti-abuse provider, calendar/Hijri/prayer provider, encryption protocol, object store, Render datastore plan, or real-time library. These choices must meet the contracts above and the Render/Firebase cost policy.
