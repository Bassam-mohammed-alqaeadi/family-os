# 07 — FS-005 Offline / Sync Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-14 · MODE-SF-20  
**Technical open:** T-MODE-03 · T-MODE-04 · T-MODE-05  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Offline-first law

| Rule | Law |
|---|---|
| Source of truth offline | **Last-acked** Mode policy / activation state for that enrolled child device |
| Honesty | Show sync / ack / stale / unsupported honestly — **no fake cloud success** |
| Enforcement claim | `enforced` only when last-acked Mode overlay + verified capability plane for the affected system |

---

## 2. Multi-device

| Rule | Law |
|---|---|
| Scope | Per **enrolled child device** |
| Acknowledgement | Each device has acknowledgement state for Mode policy delivery |
| Conflict | Authorized parent mutations queue; device applies last-acked; unresolved sync = honest degraded — algorithms **T-MODE-04** |

---

## 3. Outbox / persistence

| Rule | Law |
|---|---|
| Durable Mode store | Required for target product (schema **T-MODE-03**) |
| Outbox | Mode mutations and activation intents must be replay-safe across process death — design **T-MODE-04** |
| Stage-1 | In-memory prefs + in-process activation bus = **non-authority** |

---

## 4. Ack / stale

| Rule | Law |
|---|---|
| Device ack | Required for honesty of “applied on child device” |
| Stale TTL numbers | **Not invented** — **T-MODE-05** |

---

## 5. What sync must not do

- Silently expand Mode scope from one child to family-all  
- Silently mutate FS-002 / FS-003 / FS-004 permanent stores  
- Claim Mode enforced when only parent UI toggled  
