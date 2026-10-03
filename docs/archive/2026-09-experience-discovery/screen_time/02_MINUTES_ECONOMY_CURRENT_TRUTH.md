# 02 — Minutes Economy Current Truth

**System:** Screen Time + Minutes Economy  
**Date:** 2026-09-23  
**Mode:** Discovery — `CURRENT FACT` vs `POLICY LAW` vs `UNKNOWN`

---

## What Minutes are (`POLICY LAW` + `CURRENT FACT`)

| Source | Statement |
|---|---|
| Register **E-1** | Only currency app-wide is **minutes**. No points, XP, or coins. |
| Constitution **Rule 4** | `Minutes` value object mandatory; raw int for rewards forbidden. |
| Code | `app/lib/core/domain/minutes.dart` — non-negative immutable VO; `+` / `-` with underflow throw |

**What Minutes represent (product):** entertainment **time budget** the child may spend on countable apps — earned into **per-app wallets** (S-2), gated by daily cap / modes / locks (Register §2).

**What they are NOT (today):** OS-enforced meters, global XP, or a single pooled “points” balance.

---

## Dual budget model (`POLICY LAW`)

Family OS uses **both**:

1. **Daily entertainment allowance** — `ScreenTimePolicy.dailyCapMinutes` (device-level entertainment ceiling).
2. **Per-app earned wallet** — `AppWallet.earnedMinutes` for each `appId` (S-2).

| Rule | Law | Code |
|---|---|---|
| Wallet inside cap by default | Ruling B | `dailyCapIncludesWallet` default true; `allowWalletOverflow` default false |
| Overflow opt-in | SET-024 | Father toggle on FAT-032 |
| Education never countable | S-1 | `EducationAppIds` forces `countable: false` for `quran` / `edu_*` |
| Deduct daily first, then wallet | Doc 33 | **Not implemented as consume API** (`NOT FOUND`) |

---

## Earning (`CURRENT FACT`)

### Intended path (Constitution Rule 5)

> All earning through `PolicyEngine.earn()` — direct balance writes forbidden.

### Actual code naming

| Expected name | Actual |
|---|---|
| `PolicyEngine.earn` | **Does not exist** |
| Earn entry | `WalletLedger.earn` → `PolicyEngine.rewardForAssignee` → `depositOnApproval` → `deposit` |

```23:42:app/lib/core/policy/wallet_ledger.dart
  Future<Minutes> earn({
    required ChildId childId,
    required String appId,
    required AppRole assignee,
    required Minutes fatherSetReward,
  }) async {
    final reward = PolicyEngine.rewardForAssignee(...);
    ...
    await deposit(...);
```

### Assignee rules (`CURRENT FACT` = Register E-4)

| Assignee | Result |
|---|---|
| Child | Father-set reward deposited |
| Mother | `null` — no minutes |
| Father | `null` — not an earning assignee |

### Protected channels (`POLICY LAW` E-3 / code enum)

`EarningChannel`: `quranPortion`, `athkar`, `learningChallenge`, `familyTaskChild`, `conditionalAppUnlock`  
— **catalog only** (`E`); not every channel is wired end-to-end.

### Confirmed earn integration

| Source | Path | Class |
|---|---|---|
| Education attribution FAT-045 | `AttributionRewardRepository.assign` → `WalletLedger.earn` | **A** |
| Time-request approval | Saves `TimeGrant` only | **B** — no ledger deposit |
| CHD-019 display | Fixture `totalMinutes` / `walletMinutes` | **G** — not ledger |

---

## Spending / consumption (`CURRENT FACT`)

| Capability | Status |
|---|---|
| `WalletLedger.consume` / `spend` / `debit` | **H — not found** |
| Automatic deduction from usage | **H** |
| `usedMinutesToday` increment from OS | **F** — manual/mock field |
| Negative balances | Impossible via `Minutes` factory + subtract underflow |

**Implication:** Remaining time (`cap − used`) and wallet balances can diverge from real device usage indefinitely until Stage-3 metering + consume land.

---

## Attribution (`CURRENT FACT`)

| Concept | Status |
|---|---|
| Father sets minutes at creation | **A** on attribution / task screens that call ledger |
| Target app wallet | `appId` argument on `earn` / `deposit` |
| Free wallet (spend among allowed apps) | Doc 33 concept — **UNKNOWN** in code as distinct wallet type |
| Duplicate reward protection | **UNKNOWN** / partial — attribution may have local guards; no global immutable ledger of entries |

WalletLedger today is a **balance mutator on AppWallet**, not an append-only transaction log.

---

## Temporary grants vs earned Minutes

| Artifact | Behavior today |
|---|---|
| `TimeGrant` | Written on approve; fields: id, requestId, childId, minutes, grantedBy, createdAt |
| Effect on remaining | **None automatic** — does not bump `dailyCap`, `usedMinutesToday`, or wallet |
| Effect on TimeEngine | **None** unless something else mutates policy |
| Mother ceiling | ADR-039 enforced in `TimeRequestActor.canGrantMinutes` (default 30) |

---

## Expiration & carry-over

| Question | Answer |
|---|---|
| Do earned Minutes expire daily? | **UNKNOWN** in Register; code never expires wallets |
| Does daily cap reset? | **Assumed** midnight product law; code has **no day-rollover job** (`NOT FOUND`) |
| Carry-over of unused allowance | **UNKNOWN** / not implemented |
| Temporary grant duration | Stored as minute count only — **no end timestamp** on `TimeGrant` |

---

## Parent manual adjustments

| Action | Today |
|---|---|
| Change daily cap | FAT-032 → policy save |
| Toggle overflow | FAT-032 |
| Direct wallet edit in UI | **Not found** as parent control |
| Approve request amount | FAT-033 grant minutes (ledger gap) |
| Instant lock | Separate — not Minutes |

---

## Terminology inconsistencies (`CURRENT FACT`)

| Location | Issue |
|---|---|
| Registry titles CHD-004 / CHD-019 / FAT-045 | Legacy “نقاط” wording |
| ADR-036 | Declares registry labels legacy; product = Minutes; CHD-019 = per-app wallets |
| Child UI fixtures | Use minutes fields correctly in models; titles may still say points in ARB legacy keys — verify per screen |

**Discovery rule:** treat “points/XP” as **terminology debt**, never as product currency.

---

## Maturity score — Minutes Economy

| Layer | Maturity |
|---|---|
| Domain VO + PolicyEngine helpers | **High** (A) |
| WalletLedger earn/deposit | **Medium-High** (A, no consume) |
| Education attribution → earn | **Medium** (A path) |
| Time request → credit | **Low** (B) |
| Child wallet UI | **Low** (G) |
| Consumption / metering | **Absent** (H) |
| Immutable audit ledger | **Absent** (H) |
| Backend tables | **Absent** (H / D proposal) |

**Overall Minutes Economy maturity:** **Partial in-process credit path; no real spend path; split UI.**

See: [06_MINUTES_ECONOMY_POLICY.md](06_MINUTES_ECONOMY_POLICY.md).
