# 08 — FS-002 Event, Audit & Notification Contract (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-14 · WF-SF-07

---

## 1. Required event / audit scope (WF-OD-14)

| Include | Exclude (unless future OD) |
|---|---|
| Navigation **Deny** events | Full allow browse trail / surveillance history |
| Unlock **request** lifecycle | — |
| Unlock **approve/deny** decisions | — |
| Policy mutations (config audit) | — |
| Enforcement plane degraded/unsupported (honesty) | — |

---

## 2. Envelope

`eventId` · `familyId` · `childId` · device/enrollment · `occurredAt` · `policyVersion` · reason/source-of-deny when relevant.

---

## 3. Audit

Append-only product audit seam (not Stage-1 `AuditAppend` strings as normative).

---

## 4. Notifications

| Class | Guidance |
|---|---|
| Unlock request | Parent channel (Notifications system) |
| Unlock decision | Child honesty |
| Plane degraded | Parent honesty — never SOS-critical misuse |
| SOS | Untouched |

---

## 5. Child visibility

Events must not drive child admin UI; child sees interstitial + disclosure only (WF-OD-15).
