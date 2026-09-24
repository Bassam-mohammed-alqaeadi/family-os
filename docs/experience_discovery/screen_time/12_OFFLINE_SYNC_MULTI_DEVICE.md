# 12 — Offline, Sync, Multi-Device

**Date:** 2026-09-23  
**Authority:** Register G-1 (offline-first) · CURRENT buses · Constitution Rule 25  
**Labels:** `CURRENT` · `TARGET` · `ALREADY DEFINED` · `OWNER` · `UNKNOWN`

---

## CURRENT Stage-1 behavior

| Mechanism | Behavior |
|---|---|
| `PolicySyncBus` | Same-isolate publish; if child offline → `offlineQueued` until `markChildOnline` |
| `TimeRequestService` offline | Queues approve/reject; flush applies later |
| Persistence | Prefs / memory — not durable multi-device |
| FCM / backend sync | **NOT FOUND** |
| Clock / day rollover | **NOT FOUND** |
| Multi-device remaining pool | **NOT FOUND** |

---

## Target scenario matrix

| Scenario | Required semantics | Source |
|---|---|---|
| Parent changes policy offline | Queue with actor + version; show “will sync”; apply on reconnect | G-1 + TARGET |
| Child requests offline | Create local pending; sync up; parent sees when online | TARGET |
| Simultaneous parent changes | Version conflict → **father wins** + audit + mother notify | ADR-035 spirit · `OWNER` for CRDT later |
| Mother + father conflicting grants | Father supersedes; do not double-credit without idempotency | TARGET |
| Device reconnect | Flush queues in order; recompute mirror; show last synced | G-1 |
| Stale policy on child | `POLICY_STALE` until newer `updatedAt` applied (CURRENT has applyCount/idempotency cursor) | CURRENT + TARGET |
| Duplicate requests | Reject second pending (`OWNER`) | TARGET |
| Duplicate grants / replayed events | Idempotency keys on credit | TARGET |
| Clock differences | Prefer server time Stage-3; until then device local + skew warning | `OWNER` |
| Day rollover / timezone | Reset countable usage at local midnight of family TZ (`OWNER`) | `OWNER` |

---

## Already defined vs Owner

| Topic | Status |
|---|---|
| Offline-first + last synced honesty | `ALREADY DEFINED` (G-1) |
| Father wins mother lock conflict | `ALREADY DEFINED` (ADR-035) |
| Per-device vs shared daily Minutes | `OWNER` (Family Link is per-device) |
| Conflict CRDT vs last-write-father | `OWNER` for Stage-3 |
| Grant replay protection | Partially implied by non-pending approve throw — need ledger keys `OWNER` |

---

## Multi-device proposals (do not silently pick)

| Model | Pros | Cons |
|---|---|---|
| **Per-device cap** | Matches Family Link tip; simple metering | Child can multiply time across phones |
| **Shared family pool** | True household budget | Needs cross-device sync + conflict |
| **Hybrid** | Shared entertainment + per-device schedule | Complex UX |

Mark as **ST-OD-001** in Owner decisions.

---

## Recovery UX

Parent Policy Health must show: last sync, queue depth, stale age, enforcement mode (`SIMULATED` vs `ENFORCING`).

Child must never appear “unlimited” solely because sync failed — fail **closed** for entertainment when policy stale beyond TTL (`OWNER` TTL).
