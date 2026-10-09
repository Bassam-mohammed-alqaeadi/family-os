# 08 — State Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Rule:** Do **not** collapse into one enum. Five orthogonal machines remain.

---

## 1. TIME BALANCE STATE (child entertainment)

| State | Definition |
|---|---|
| `AVAILABLE` | Countable remaining path open; not in warning window |
| `WARNING` | ≤ **5 minutes** remaining on the active countable path (S-3) |
| `EXPIRED` | No usable Daily remaining, Temporary Grant, or wallet-open path under policy |

**FROZEN:** No mandatory separate `LOW_TIME` state (ST-ADD-003).

`TEMPORARY_GRANT` is **not** a replacement balance enum — grant remaining is a **quantity** alongside daily remaining and wallet balances (ST-ADD-004).

---

## 2. POLICY STATE

`POLICY_ACTIVE` · `POLICY_STALE` · `POLICY_CONFLICT` · `POLICY_DEGRADED` · `POLICY_DEFAULT`

Stale handling: last known → grace → fail closed entertainment (ST-OD-009).

---

## 3. DEVICE ENFORCEMENT STATE

`SIMULATED` · `ENFORCING` · `RESTRICTED` · `BLOCKED` · `DEVICE_LOCKED` · `DEVICE_OFFLINE` · `UNSUPPORTED` · `TAMPER_SUSPECT`

Stage-1 honesty: expect `SIMULATED` until platform agents exist.

---

## 4. SYNC STATE

`SYNCED` · `PENDING` · `OFFLINE_QUEUED` · `SYNCING` · `CONFLICT` · `RECOVERY`

---

## 5. REQUEST STATE

`NONE` · `REQUESTING` · `REQUEST_PENDING` · `REQUEST_APPROVED` · `REQUEST_DENIED` · `REQUEST_EXPIRED` · `REQUEST_QUEUED_OFFLINE`

Max one `REQUEST_PENDING` per child.

---

## Child-perceived mapping

| Child sees | Machines |
|---|---|
| Minutes left + grant chip + wallet | TIME BALANCE quantities |
| “5 minutes left” | TIME BALANCE = WARNING |
| Calm expiry | TIME BALANCE = EXPIRED |
| “Waiting for parent” | REQUEST = REQUEST_PENDING |
| Lock banner | DEVICE = DEVICE_LOCKED |
| Sync honesty | SYNC / POLICY |

SOS availability is **never** derived from TIME BALANCE or P3 mode denies.
