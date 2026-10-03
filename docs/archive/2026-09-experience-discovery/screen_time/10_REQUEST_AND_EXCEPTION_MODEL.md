# 10 — Request and Exception Model

**Date:** 2026-09-23  
**Labels:** `CURRENT` · `TARGET` · `OWNER`

---

## A. Time requests

### CURRENT

| Piece | Behavior |
|---|---|
| Parent service | `TimeRequestService.createRequest / approve / reject` |
| Statuses | `pending` · `approved` · `rejected` |
| Actor gate | Father; Mother partner/full; Observer/child cannot decide |
| Ceiling | Mother ≤ `activeCeilingMinutes` (default 30, ADR-039) |
| Reject | Requires non-empty child-visible reason |
| Offline | Queue decisions; flush later |
| On approve | Persist `TimeRequest` + `TimeGrant` — **no wallet/cap mutation** |
| Child UI | `ChildTimeRequestRepository` — **does not call** `createRequest` |
| Decision bus | `TimeRequestDecisionBus` for service path |

### TARGET request lifecycle

```
draft → submitted(REQUEST_PENDING) → approved | denied | expired_timeout
                         ↓
              TEMPORARY_GRANT active → consumed/expired
```

| Rule | Spec |
|---|---|
| Duplicate pending | One open pending per child (`OWNER` confirm) |
| Amount | `Minutes` > 0; mother grant clamped at ceiling |
| Father over-ceiling | Allowed |
| Idempotent approve | Second approve on non-pending throws (CURRENT already) |
| Credit effect | Apply TemporaryGrant per Owner ST-OD-004 |
| Child confirmation | See new remaining within sync SLA |
| Audit | Append-only event with actor label |

---

## B. Temporary grants / exceptions

### CURRENT

| Type | Present? |
|---|---|
| `TimeGrant` after approve | Yes (inert) |
| Mode exception (child×app×mode) | Flag on `TimeContext` — persistence UI unclear |
| Ruling C grant-vs-mode dialog | Law present — UI/engine incomplete |
| Manual father bonus without request | Cap edit only |

### TARGET exception kinds

| Kind | Meaning | Bypasses |
|---|---|---|
| `TemporaryGrant` | Same-day extra entertainment minutes | Cap exhaustion only (not lock/block) |
| `ModeException` | App allowed during mode | Mode deny only |
| `CountableOff` | App doesn’t count (S-1) | Metering only |
| `UnlimitedEntertainment` | Father marks app unlimited | Cap counting (`OWNER` vs Always Allowed semantics) |
| `FatherUnlock` | Clears mother lock / temporary parental unlock | Mother lock |

**Never bypass:** permanent block, SOS-irrelevant; Instant Lock only cleared by unlock action.

---

## C. Ruling C (grant intersects mode) — TARGET UX

When granting while a mode will start:

Dialog (mandatory per law):

1. **Complete grant to end** — child keeps grant through mode if exception allows, OR
2. **Freeze when mode starts** — remainder returns to app wallet after mode

`grant.onModeStart: complete | freeze`

CURRENT: not fully productized in Flutter UI.

---

## D. Mother ceiling

| Rule | Status |
|---|---|
| Default 30 minutes | CURRENT + ADR-039 |
| Applies Partner **and** Full for one-shot grant | ADR-039 |
| Father may edit ceiling as rule | Law — UI incomplete |
| Over-ceiling one-shot | OWNER only |

---

## E. Events (TARGET)

| Event | Payload essentials |
|---|---|
| `time_request.created` | childId, requestedMinutes, reason |
| `time_request.approved` | grantMinutes, actor, ceilingApplied |
| `time_request.rejected` | reason, actor |
| `time_grant.activated` | grantId, expiresAt |
| `time_grant.consumed` | amount |
| `time_grant.frozen` | remainder → wallet |
| `mode_exception.set` | childId, appId, modeId |

See: [11_STATE_MACHINE.md](11_STATE_MACHINE.md).
