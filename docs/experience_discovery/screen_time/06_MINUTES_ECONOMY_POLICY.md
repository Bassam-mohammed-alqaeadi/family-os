# 06 — Minutes Economy Policy (Target Contract)

**Date:** 2026-09-23  
**Currency:** Minutes only — never points/XP/coins  
**Labels:** `CURRENT` · `TARGET` · `OWNER` · `ALREADY DEFINED`

---

## Pipeline (TARGET)

```
EARNING → ATTRIBUTION → CREDIT → BALANCE → ALLOCATION → CONSUMPTION → EXPIRY → ADJUSTMENT → AUDIT
```

---

## Stage contracts

### 1. EARNING

| Rule | Status |
|---|---|
| Only E-3 channels (additive) | `ALREADY DEFINED` |
| Father sets amount at creation — no hidden defaults | `ALREADY DEFINED` (E-2) |
| Mother assignees earn zero | `ALREADY DEFINED` (E-4) + code |
| Entry API | TARGET: single `WalletLedger.earn` (or rename PolicyEngine facade) — no silent balance writes |

### 2. ATTRIBUTION

| Rule | Status |
|---|---|
| Credit targets an `appId` wallet (S-2) | `ALREADY DEFINED` |
| Optional “free wallet” among allowed apps | Doc 33 — `OWNER` if first-class |
| Education rewards → `WalletLedger.earn` | `CURRENT` on FAT-045 path |

### 3. CREDIT

| Rule | TARGET |
|---|---|
| On father approval of proof | Instant deposit (E-5) |
| On time-request approve | `OWNER`: TemporaryGrant and/or wallet deposit |
| Idempotency key | Required: `(sourceType, sourceId, childId)` — prevent double credit |
| Overflow | Deposits **not** clamped (CURRENT SET-024); use gated by TimeEngine |

### 4. BALANCE

| Rule | TARGET |
|---|---|
| Balance = sum(credits) − sum(consumptions) − sum(reversals) | Append-only ledger preferred |
| `AppWallet.earnedMinutes` | Cached projection, not sole source of truth |
| Negative balance | Forbidden (`Minutes` non-negative) |
| CHD-019 | Must read ledger projection — not fixtures |

### 5. ALLOCATION

| Concept | Meaning |
|---|---|
| Daily allowance | Renewable entertainment budget (not “earned”) |
| Earned Minutes | Wallet balance from channels |
| Temporary grant | Same-day parent/mother credit with explicit kind |

Do **not** merge these into one number without labeling source in UI.

### 6. CONSUMPTION

| Rule | TARGET |
|---|---|
| Only countable surfaces consume | S-1 |
| Order | Daily remaining → temporary grant → wallet (`OWNER` confirm grant vs wallet order) |
| API | `WalletLedger.consume` + daily usage meter — **missing today** |
| Hard blocks / instant lock | Consumption irrelevant — access denied first |

### 7. EXPIRY

| Question | Status |
|---|---|
| Daily allowance resets | Expected midnight local — implement rollover (`OWNER` timezone) |
| Wallet Minutes expire? | `OWNER` — default proposal: **do not expire** until Owner says otherwise |
| Temporary grant | Expires end of local day or explicit TTL |

### 8. ADJUSTMENT

| Actor | Allowed |
|---|---|
| Father | Manual grant, revoke unused grant, edit cap, overflow, reverse erroneous credit with audit |
| Mother Partner/Full | Grant ≤ ceiling; no silent reverse of father credits |
| Observer | None |
| Child | Request only |
| AI | Suggest only — approve button required |

### 9. AUDIT

| Event | Must log |
|---|---|
| earn / deposit | childId, appId, amount, channel, actor, sourceId |
| consume | childId, appId, amount, sessionId |
| grant approve/reject | actor, ceiling check, reason |
| reverse | father only + reason |
| overflow toggle | father |

CURRENT: time decide stores `decidedBy` string — **insufficient** vs append-only audit repo law.

---

## Immutable ledger principles (TARGET)

1. Append-only entries; no update/delete of posted rows.
2. Balance is derived (or cached with rebuild).
3. Every credit has an idempotency key.
4. Reversals are compensating entries, not edits.
5. Mock/`InMemory` must implement the same interface as future API (Rule 25).

---

## Bypass rules (hard)

| Can earned Minutes bypass…? | Answer |
|---|---|
| Instant lock | **No** |
| Permanent block | **No** (Ruling A) |
| Active mode without exception | **No** |
| Daily cap | **Only if** overflow ON or wallet excluded from cap (Ruling B) |
| Schedule hard window | `OWNER` |
| Web filter | **No** — orthogonal |
| SOS/chat/Quran need Minutes? | **No** — exempt |

---

## Constitution naming note

Constitution Rule 5 says `PolicyEngine.earn()`; code uses `WalletLedger.earn`. TARGET: keep one public earn façade; treat naming as engineering debt, not product change.

---

## What must not be silently decided

- Wallet expiry
- Free-wallet vs per-app only
- Grant → wallet vs grant → daily remaining
- Multi-device shared Minutes pool
- Whether self-discipline focus reward can auto-credit without father proof (S-5 says rewardSelfDiscipline untouchable — confirm UX)

See: [18_SCREEN_TIME_OWNER_DECISIONS.md](18_SCREEN_TIME_OWNER_DECISIONS.md).
