# FS-010 — Durable Family Chat — L2 Master Contract

**Canonical ID:** `FS_010_Ephemeral_Family_Chat`  
**Date:** 2026-09-25  
**Status:** L2 DRAFT from Domain 2 § أ + C-1…C-3 + Owner (A)  

---

## 1. Responsibility

Own **durable family chat threads and messages**: create/list/send/edit/delete-for-all/pin/lock, read receipts, reply, role gates, offline Local durability, and honest sync enqueue.

Does **not** own: call media plane, calendar, tasks, location-in-COM, notifications transport, identity, or audit store.

## 2. Ownership map

| Fact | Owner | Consumer |
|------|-------|----------|
| Message content + thread membership | **FS-010** | UI hosts |
| Ciphertext relay / push | Transport / REMOTE (ephemeral session) | FS-010 |
| Delivery ack | Transport | FS-010 interprets |
| Indelible safety audit (if required for abuse) | Audit Log | FS-010 emits |
| Push/in-app notify | Notification prefs + delivery | FS-010 requests |
| Actor identity | Identity | FS-010 |
| TimeEngine lock | Must **exempt** chat (C-1) | FS-010 / Modes / ST consumers |

## 3. Invariants

1. **Durable history** — no auto TTL wipe of messages.  
2. **C-1** — never locked by time expiry / entertainment lock / subscription.  
3. **C-2** — E2E; UI shows encrypted; server relays ciphertext only (when REM exists).  
4. **C-3** — edit within 15 minutes of send; delete-for-all available per Domain role matrix.  
5. **S-COM-050 forbidden** — no disappearing UX, no self-destruct, no evidence-erasing TTL.  
6. Child cannot create subgroups; cannot add contacts unilaterally (Domain matrix + outer-circle approval model).  
7. Conversation lock: father only (أ-٩).  
8. Advisor “forget” must **not** wipe chat (existing ChatMockStore spirit / Rule 10 adjacent).

## 4. Message lifecycle

```
COMPOSE → SEND_LOCAL (append durable)
  → ENQUEUE_OUTBOX (ephemeral relay intent; deliveryClaim queued_locally)
  → DELIVERED / FAILED (honest status; never fake remote success)
EDIT (if now < sentAt+15m) → append edit revision (history retained per product — Domain: edit, not silent rewrite without trace if required later)
DELETE_FOR_ALL → tombstone visible to members (not silent purge of accountability where Register requires)
PIN / UNPIN · LOCK / UNLOCK (role-gated)
```

**Ephemeral transport:** outbox/relay payloads may be short-lived; **Local message authority remains durable**.

## 5. Offline / Local-first

- Send works Local-first; appears in thread immediately.  
- Sync pending honest.  
- Offline: full Local history readable.  
- No Native requirement for core text chat (push optional REM).

## 6. Privacy / accountability

- Disappearing messages rejected (harassment evidence).  
- Delete-for-all ≠ disappearing (member-visible removal action with durable audit if mandated).  
- Mother/Partner/Observer: follow Domain matrix + Mother permissions doc (configure lock denied for mother).

## 7. Cross-system

| Peer | Boundary |
|------|----------|
| FS-008 / FS-009 | No ownership overlap |
| FS-006 SOS | Chat remains reachable; SOS never depends on chat delivery |
| Modes / ST / AC | Must not lock Family Chat |
| Outer circle / friends | Approval-owned elsewhere; FS-010 consumes allowlist |
| Calls (LiveKit) | COM § ب — separate FS/service lane |

## 8. OPEN (non-blocking for L2 draft)

| ID | Item |
|----|------|
| CHAT-C1 | Exact edit revision retention (full prior text vs last-only) — Domain says edit exists; depth UNRESOLVED |
| CHAT-C2 | Whether delete-for-all emits AuditLog row always — EXPLICITLY UNRESOLVED |
| CHAT-C3 | Local SQLite schema for messages — implementation Phase later |

## 9. L2 acceptance

```text
FS-010 L2: DRAFT COMPLETE (durable chat + ephemeral transport semantic)
S-COM-050: FORBIDDEN
IMPLEMENTATION: NOT AUTHORIZED
```
