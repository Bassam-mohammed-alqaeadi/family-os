# 11 — State Machine

**Date:** 2026-09-23  
**Critical:** Do **not** collapse into one enum. Five orthogonal machines.

---

## 1. POLICY STATE

| State | Meaning |
|---|---|
| `POLICY_ACTIVE` | Cap/schedules/modes loaded |
| `POLICY_STALE` | Child mirror older than parent version |
| `POLICY_CONFLICT` | Concurrent parent edits unresolved |
| `POLICY_DEGRADED` | Missing permissions / unsupported platform feature |
| `POLICY_DEFAULT` | Using Stage-1 defaults |

Transitions: save → sync → apply; conflict → father-wins resolve; permission loss → degraded.

---

## 2. TIME BALANCE STATE

| State | Meaning |
|---|---|
| `AVAILABLE` | Countable remaining > warning threshold |
| `WARNING` | Within S-3 window (≤5 min) |
| `LOW_TIME` | Optional sub-threshold (`OWNER` if distinct from WARNING) |
| `EXPIRED` | Cap exhausted and no usable grant/wallet path |
| `TEMPORARY_GRANT` | Grant remaining > 0 (may coexist with AVAILABLE) |
| `WALLET_ONLY` | Cap exhausted but overflow/wallet opens apps |
| `OVERFLOW_BLOCKED` | Cap exhausted, wallet>0, overflow off → deniedCap |

Note: `TEMPORARY_GRANT` is a **balance mode**, not a replace-all status.

---

## 3. DEVICE ENFORCEMENT STATE

| State | Meaning |
|---|---|
| `ENFORCING` | OS agents applying blocks |
| `SIMULATED` | Flutter-only (CURRENT Stage-1) |
| `RESTRICTED` | Apps blocked by engine decision |
| `BLOCKED` | Permanent block list hit |
| `DEVICE_LOCKED` | Instant lock engaged |
| `DEVICE_OFFLINE` | Child device unreachable |
| `TAMPER_SUSPECT` | Anti-tamper signal (future) |
| `UNSUPPORTED` | Platform cannot enforce claimed rule |

CURRENT production path is overwhelmingly **`SIMULATED`**.

---

## 4. SYNC STATE

| State | Meaning |
|---|---|
| `SYNCED` | Parent status delivered + mirror applied |
| `PENDING` | Publish in flight |
| `OFFLINE_QUEUED` | Child marked offline |
| `SYNCING` | Flush in progress |
| `CONFLICT` | Version divergence |
| `RECOVERY` | Reconcile after reconnect |

Maps to CURRENT `PolicySyncStatus`: `pending` · `delivered` · `offlineQueued`.

---

## 5. REQUEST STATE

| State | Meaning |
|---|---|
| `NONE` | No active request |
| `REQUESTING` | Child composing |
| `REQUEST_PENDING` | Submitted awaiting parent |
| `REQUEST_APPROVED` | Decided approve |
| `REQUEST_DENIED` | Decided reject |
| `REQUEST_EXPIRED` | Timeout without decision (`OWNER`) |
| `REQUEST_QUEUED_OFFLINE` | Parent decision queued |

---

## Cross-machine example

Child entertainment expired, request pending, policy synced, Flutter-only:

| Machine | State |
|---|---|
| POLICY | `POLICY_ACTIVE` |
| TIME BALANCE | `EXPIRED` |
| DEVICE | `SIMULATED` (+ UI restricted) |
| SYNC | `SYNCED` |
| REQUEST | `REQUEST_PENDING` |

---

## UI mapping (do not overload)

| Child UI | Primary machine |
|---|---|
| Remaining chip | TIME BALANCE |
| “Waiting for Dad” | REQUEST |
| Calm expiry screen | TIME BALANCE=`EXPIRED` |
| Sync honesty | SYNC / POLICY |
| Lock banner | DEVICE=`DEVICE_LOCKED` |

See: [12_OFFLINE_SYNC_MULTI_DEVICE.md](12_OFFLINE_SYNC_MULTI_DEVICE.md).
