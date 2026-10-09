# Family Connection Data, Event & Delivery Contracts — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define authoritative family-connection data and lifecycle contracts for Render-backed services.

## 1. Canonical lineage

```text
Account → Family → Membership / role → Child or guardian → managed device
                                  │
              relationship / conversation / event / task / check-in
                                  │
                     intent → delivery → acknowledgement → activity/audit
```

Every record carries family context, authorized actor, visibility, source/freshness where applicable, and audit links.

## 2. Canonical entities

| Entity | Required contract |
|---|---|
| Relationship | Family member/external relative/friend, child/guardian scope, permission bundle, lifecycle, invitation/approval/block/revoke history. |
| Contact request | Requester, requested person/context, child-visible explanation, guardian decision, expiry, invitation/acceptance state. |
| Conversation | Membership, relationship basis, type, privacy/retention policy, lock/pin state only if approved later. |
| Message revision | Author, conversation, body/media references, sent/edit/delete state, client/server time, delivery/read receipts, report/removal/audit metadata. |
| Call session | Participants, authorization, requested transport, state transition, capability/delivery/quality summary, history; no unproven recording/transcript data. |
| Media asset | Owner/source, authorized recipients, upload/scan/availability/expiry/removal state, storage reference and rights metadata. |
| Calendar event revision | Owner, participants, local/timezone/recurrence/calendar context, visibility/edit permissions, reminder/conflict/change/cancel history. |
| Task | Author, assignee, due/recurrence/context, status, completion evidence/review, recognition/security-policy link, audit. |
| Check-in / location request | Initiator/recipient, consent basis, requested/sent/acknowledged/expired state, location freshness/accuracy reference, escalation link. |
| Connection event | Immutable source event that drives timeline, notification and aggregate; carries causality and data quality. |
| Delivery receipt | Intent reference, recipient/device/service, transport attempt, server state, acknowledgement/effective evidence, retry/expiry/failure reason. |

## 3. Conversation and relationship contracts

### Relationship lifecycle

```text
Proposed/requested → guardian review → invited/verified → active
→ paused | blocked | revoked | reported | expired
```

### Message lifecycle

```text
Draft → accepted by Render → dispatched → recipient device/app receipt → read/acknowledged
                                  ↘ queued | failed | expired | relationship revoked
```

Rules:

- A server acceptance receipt differs from device receipt and human read receipt.
- Message edit/delete references revisions and recipient-visible semantics; history/audit retention follows later policy, not client deletion alone.
- Relationship authorization is checked on every create/read/mutate action.
- Moderation/reporting data cannot become a secret content-visibility backdoor.

## 4. Calendar and task contracts

### Event

```text
Draft → saved revision → participant delivery/visibility → reminder
→ updated/cancelled/conflict-resolved → archived
```

Event time includes timezone, recurrence and calendar-display metadata. Local device time is never the sole family calendar authority.

### Task

```text
Draft → assigned → delivered/seen → in progress → child confirms complete
→ guardian accepts / requests revision / reopens → recognition or closure
```

Task recognition references evidence/policy; any time privilege is requested through the Security contract and must carry expiry and receipt.

## 5. Check-in / location contract

```text
Check-in or request created → permission/consent/capability evaluated
→ sent/queued/delivered → recipient acknowledges or expires
→ follow-up / escalation / resolved
```

Location references include source, freshness, accuracy, consent and visibility classification. A check-in can be delivered without a precise location if the family policy/capability allows; UI must say which occurred.

## 6. Connection event envelope

```text
ConnectionEvent
- eventId, type, schemaVersion
- familyId, actorMemberId, childId?, deviceId?
- relationshipId?, conversationId?, messageId?, eventId?, taskId?, checkInId?
- occurredAtClient?, observedAtServer, receivedAtServer
- sourceTrust: reported | verified | inferred | unknown
- dataQuality: fresh | stale | partial | unavailable
- causalityId / deliveryId / policyId?
- visibility and retention classification
```

Examples: contact requested/approved, message accepted/delivered/read, call attempt ended, media available/removed, event changed, task completed/reopened, check-in acknowledged, location unavailable.

## 7. Privacy and support boundaries

- Family members only access conversations, assets, events and tasks according to relationship/role permissions enforced by Render.
- Guardian contact approval is not a blanket permission for private-content access.
- Check-in/location requests retain consent/freshness/audit metadata; sensitive location is minimized and scoped.
- Support diagnostics expose lifecycle IDs/states and approved metadata, not unrestricted message/media content.
- Firebase FCM registration token is a delivery endpoint managed as operational device data; it cannot authorize access or represent a person’s read state.

## 8. Contract acceptance checks

A Connection service is acceptable only when it proves authorization/family scope, durable versioned state, idempotent mutation/retry, ordered/recoverable realtime behavior, explicit delivery versus acknowledgement, offline/expiry/revocation handling, data-quality truth, auditability, and Render authority over Firebase transport.
