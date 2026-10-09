# 06 — Request and Grant Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Implementation:** Not in this phase

---

## Desired request loop (FROZEN)

```
Child
  → createRequest()
  → REQUEST_PENDING
  → Parent / Mother decision
  → approved | denied
  → Temporary Grant (on approve)
  → child feedback
  → actual remaining update
```

Single service path — child UI and parent inbox must share one request model (discovery gap ST-GAP-001 becomes engineering work later).

---

## Request rules

| Rule | Frozen value |
|---|---|
| Max pending per child | **1** (ST-OD-006) |
| Timeout | **min(12h, family-local end-of-day)** (ST-OD-007 + ST-OD-008) |
| Amount | Positive Minutes |
| Child reason | Optional; reject reason **required** and child-visible (UF-05 law) |
| Duplicate while pending | Rejected / blocked |
| Approvers | Father; Mother Partner; Mother Full |
| Observer | Cannot decide |
| Mother grant ceiling | ADR-039 (default 30; Partner and Full) |
| Father over-ceiling | Allowed |
| On deny | No Temporary Grant; show reason |
| On approve | Create/activate Temporary Grant (G-A) — **not** wallet earn |

---

## Temporary Grant rules

| Rule | Frozen value |
|---|---|
| Model | G-A — increases today’s remaining entertainment |
| Wallet deposit | **No** |
| Scope | **Child-wide** (ST-ADD-001) |
| Bypass hard schedule/mode | **No** (ST-OD-005) |
| Bypass permanent block / instant lock | **No** |
| Relation to Unlimited | Orthogonal |
| Expiry | With day / grant lifecycle; unused grant does not become earned wallet unless a future Owner decision says so (**not invented**) |

---

## ModeException (separate)

When parent needs an app available during hard mode/schedule:

- Use **ModeException** / parent override — not Temporary Grant.
- Grant = more time. Exception = changed rule.

---

## Events (contract-level)

| Event | Meaning |
|---|---|
| `time_request.created` | Pending created |
| `time_request.approved` | Grant minutes + actor |
| `time_request.rejected` | Reason + actor |
| `time_request.expired` | Timeout hit |
| `temporary_grant.activated` | Remaining increased |
| `temporary_grant.exhausted` | Grant used up |
| `temporary_grant.expired` | Day/TTL end |

Audit append-only required at implementation time (Constitution audit law).
