# 04 — Minutes Economy Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Currency:** Minutes only (E-1 / Rule 4)

---

## Three-bucket model (FROZEN)

```
Daily Allowance  →  Temporary Grant  →  Earned Wallet
```

| Bucket | Meaning | Resets / expires | Source |
|---|---|---|---|
| **Daily Allowance** | Child-level entertainment budget for the day | Resets at family-local end-of-day | Father/Mother Full policy |
| **Temporary Grant** | Same-day extra remaining (G-A) | Expires (day end / grant end) | Approved request or parent grant |
| **Earned Wallet** | Per-app earned Minutes | **Never** by default | E-3 channels via earn path + parent approval |

**UI law:** These three remain independently visible/derivable — never one unexplained number (ST-ADD-004).

---

## Target consumption order (FROZEN — do not implement in this phase)

When countable entertainment is allowed and time is spent:

```
Daily remaining  →  Temporary Grant remaining  →  Earned Wallet (app)
```

Subject to TimeEngine/precedence allow first. No consume API in this documentation phase.

---

## Earning (FROZEN)

| Rule | Status |
|---|---|
| Only Minutes | FROZEN |
| Father sets amounts at creation | ALREADY DEFINED (E-2) |
| Mother assignees earn 0 | ALREADY DEFINED (E-4) |
| Channels additive E-3 | ALREADY DEFINED |
| Direct balance writes forbidden | ALREADY DEFINED (Rule 5) |
| Self-discipline / AI | **Suggest only** — parent approve before credit (ST-OD-011) |
| Free wallet | **Not in this phase** (ST-OD-003) |

---

## Attribution (FROZEN)

- Credit targets a specific `appId` wallet.  
- Source identity retained for audit (channel, assignment, approver).  
- Idempotency required for credits (engineering later; principle frozen).

---

## Temporary Grant ≠ Earn (FROZEN)

| | Temporary Grant | Earned Wallet credit |
|---|---|---|
| Increases remaining today | Yes | Only via overflow/wallet path after cap rules |
| Goes into AppWallet | **No** | Yes |
| Counts as E-3 earn | **No** | Yes |
| Scope | Child-wide | Per-app |

---

## Overflow (Ruling B + ST-OD-012)

- Default: wallet inside cap; overflow off.  
- Overflow ON: earned wallet may open past daily cap for apps that exhausted countable limit — still blocked by P0–P3.  
- Mother Full may toggle overflow with audit + Primary visibility.

---

## Naming note (engineering debt — not product fork)

Constitution Rule 5 names `PolicyEngine.earn()`; Stage-1 code uses `WalletLedger.earn`. Product contract requires a single earn façade; naming cleanup is engineering, not an Owner decision.

---

## Explicit non-goals this phase

- Implement consume  
- Introduce free wallet  
- Auto-credit focus rewards  
- Expire earned Minutes by default  
