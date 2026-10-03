# 03 — Screen Time Policy Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Aligns with:** Register §2/§8 · Rulings A–D · Owner ST-OD-*  

---

## Policy objects (frozen set)

| Object | Scope | Notes |
|---|---|---|
| Daily entertainment allowance | **Child-level** (ST-OD-001) | Shared across enrolled devices |
| Used countable entertainment | Child-level aggregation | Device reports feed the shared meter (future) |
| Schedule windows | Child (+ optional device overlay) | Hard vs soft per schedule definition |
| Smart / routine modes | Child | Stricter-wins when overlapping (M-B law) |
| Permanent app block | Child × app | Wallet/grant never open (Ruling A) |
| Per-app / category daily limit | Child × app/category | Ladder P5 |
| Countable switch | App | S-1; distinct from Unlimited |
| Unlimited entertainment | App | ST-OD-010; may bypass daily cap only |
| Overflow switch (`allowWalletOverflow`) | Child | Ruling B; Mother Full may edit (ST-OD-012) |
| Temporary Grant | Child-wide (ST-ADD-001) | G-A remaining today (ST-OD-004) |
| ModeException / parent override | Child × app × mode/schedule | Required to pierce hard mode (ST-OD-005) |
| Instant lock | Device (and/or child broadcast) | Ladder P1 |
| Web filter | Independent gate | Not a Minutes grant |

---

## Distinct rule axes (never merge)

Per ST-OD-010, keep separate:

1. **Allowed** vs **Blocked**  
2. **Countable** vs non-countable (S-1)  
3. **Unlimited** entertainment (cap bypass only)  
4. **ModeException** (schedule/mode pierce)

---

## Temporary Grant (policy)

| Property | Value |
|---|---|
| Effect | Increases today’s remaining entertainment (G-A) |
| Wallet credit? | No |
| Scope | Child-wide |
| Bypasses hard schedule/mode? | No |
| Bypasses permanent block / instant lock? | No |
| Expires | End of family-local day (with grant lifecycle; see Request/Grant contract) |

---

## Earned Minutes (policy)

| Property | Value |
|---|---|
| Storage | Per-app wallet only (ST-OD-003) |
| Expiry | Never by default (ST-OD-002) |
| Bypass hard schedule/mode? | No (ST-ADD-002) |
| Open permanent block? | No (Ruling A) |
| Defeat instant lock? | No |
| Past daily cap? | Only if overflow ON or wallet excluded from cap (Ruling B) |

---

## Unlimited entertainment (policy)

May bypass **P4 daily entertainment cap** only.  
Still subject to P0–P3 (and P1/P2 always). Usage history retained.

---

## Stale policy (policy)

LAST KNOWN → bounded grace → **fail closed entertainment**.  
SOS exempt. Chat/Quran per constitution. TTL numeric value deferred.

---

## Multi-device (policy)

One child daily entertainment budget. Devices enforce locally but **consume the shared child meter**. Schedules/enforcement flags may differ per device without creating a second full daily allowance.
