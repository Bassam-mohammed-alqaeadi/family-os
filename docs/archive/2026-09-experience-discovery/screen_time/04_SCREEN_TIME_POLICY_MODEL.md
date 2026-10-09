# 04 — Screen Time Policy Model

**Date:** 2026-09-23  
**Authority:** Policy Register §1–§3, §8 · Constitution Rules 4–6, 9, 11 · code `TimeEngine` / `ScreenTimePolicy`  
**Labels:** `CURRENT` · `TARGET` · `OWNER` · `UNKNOWN`

---

## Purpose

Define the policy objects that govern whether a child may open an entertainment surface, and how Minutes interact with those objects — without inventing OS enforcement.

---

## Policy objects

### 1. Daily entertainment allowance

| Field | CURRENT | TARGET |
|---|---|---|
| `dailyCapMinutes` | Present on `ScreenTimePolicy` | Keep |
| `usedMinutesToday` | Mock counter | Replace with metered countable usage |
| Scope | Device-level entertainment | Same; clarify multi-device (`OWNER`) |
| Counts | Entertainment only (S-1) | Same; per-app `countable` switch |

### 2. Schedule window

| Kind (code) | Role |
|---|---|
| `sleep` | Bedtime-style restriction |
| `prayer` | Prayer window |
| `study` | Study window |

CURRENT: stored + synced; feed into time context / sleep notice.  
TARGET: each window declares **allowed app set**, whether usage **counts** toward daily, and soft vs hard block.

### 3. Smart / routine mode

CURRENT: `modeActive`, `appAllowedInMode`, `hasModeException` on `TimeContext`; FAT-085 activation.  
TARGET: mode is a **named policy overlay** with grace (Register: 2 min default, 0–5), father instant activation, stricter-wins when two modes conflict (M-B).

### 4. App / category rule

| Rule type | CURRENT | TARGET |
|---|---|---|
| Permanent block | `permanentlyBlocked` flag in engine | Persist from FAT-034 |
| Per-app daily limit | Mock `limitMins` only | First-class in policy store |
| Allowed | Mock status | Maps to not-blocked + countable rules |
| Unlimited / free | Edu `free` / `-1` in mock | Father “unlimited entertainment” + S-1 non-countable |

### 5. Temporary grant

CURRENT: `TimeGrant` row after approve — **not** applied to remaining.  
TARGET: time-boxed credit for **today’s remaining** and/or wallet (`OWNER` which).

### 6. Wallet balance (earned Minutes)

CURRENT: `AppWallet.earnedMinutes` via `WalletLedger.deposit`.  
TARGET: same + immutable ledger entries + consume path.

### 7. Instant lock

CURRENT: top of ladder; exempt chat/Quran/SOS.  
TARGET: unchanged precedence; platform-backed where possible.

### 8. Web filter (adjacent)

CURRENT: separate allow/block for URLs.  
TARGET: remains **orthogonal gate** — unlock ≠ Minutes grant (`CURRENT` already).

---

## Countable usage (S-1)

| Surface | Counts toward daily? | Locked by expiry? |
|---|---|---|
| Entertainment apps | Yes (default) | Yes |
| Quran | No | No (Rule 11) |
| Education (`edu_*`) | No | Soft / mode-dependent (`UNKNOWN` detail) |
| Family chat | N/A (exempt TimeEngine) | Never (C-1) |
| SOS | N/A | Never (P-4 / Rule 11) |
| Family calls | No count (S-1) | `UNKNOWN` lock behavior beyond S-1 |

---

## Mother policy authority (law vs code)

| Action | Observer | Partner | Full | Father | Code today |
|---|---|---|---|---|---|
| View state | Yes | Yes | Yes | Yes | Approx. yes |
| Approve time request | No | Yes | Yes | Yes | Matches |
| Grant ≤ ceiling | No | Yes | Yes | Unlimited | Matches ADR-039 |
| Edit caps/schedules | No | No | Yes (law) | Yes | **Father-only UI** — gap |
| Instant lock | No | No | Yes | Yes | Matches Full |
| Anti-tamper / unblock father block | No | No | No | Yes | Matches |

---

## Non-negotiables (never weaken)

1. Minutes-only currency (E-1).
2. Father sets reward amounts (E-2).
3. Mother tasks earn no Minutes (E-4).
4. Chat / Quran / SOS never locked by time expiry (Rule 11).
5. SOS never subscription-gated (Rule 9 / P-4).
6. Instant lock above modes and caps (Register §2).
7. Wallet never opens permanently blocked apps (Ruling A).

---

## Open policy unknowns (`OWNER` or Stage-3)

- Per-device vs family shared daily pool.
- Whether temporary grants bypass schedule windows.
- Whether earned Minutes can open during active mode without exception.
- Day rollover timezone / travel.
- Education apps under Instant Lock (beyond exempt triad).

See: [05_TIME_PRECEDENCE_MODEL.md](05_TIME_PRECEDENCE_MODEL.md), [18_SCREEN_TIME_OWNER_DECISIONS.md](18_SCREEN_TIME_OWNER_DECISIONS.md).
