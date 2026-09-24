# 06 — FS-003 Install and Exception Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-05…08 · APP-OD-13 · APP-OD-18/19  
**Non-authority:** Mock FAT-035 · Stage-1 pending rows  

```
OWNER DECISIONS: FROZEN
```

---

## 1. New-install governance

### 1.1 Detection

Child device observes package install / first-seen → Domain fact `install.observed` with package identity.  
Implementation = **T-APP-01** (not invented here).

### 1.2 Pending + default (APP-OD-08)

Package enters **`pending_decision`**.  
When **no applicable class default** exists → **Deny-until-approved** (cannot launch while pending, when plane `enforced`).

### 1.3 Parent decision authority (APP-OD-05)

**Primary + Partner + Full** may approve/deny. Observer cannot.

| Decision | Effect |
|---|---|
| **Approve** | Writes Allow for **this child** (APP-OD-18); clears pending |
| **Deny** | Writes Deny/Block disposition; clears pending |

**Forbidden:** Silent family-wide approval.  
**Forbidden:** Silent mutation of Web Filter lists.  
**Forbidden:** Approve minting Temporary Grant or Unlimited.

### 1.4 Audit

Actor · package ID · label snapshot · decision · policyVersion · timestamp · device/enrollment when known (APP-OD-16).

---

## 2. App Access Exception (ENABLED · APP-OD-06)

### 2.1 Separation laws (FROZEN)

| | App Access Exception | Temporary Grant (ST) | ST Unlimited |
|---|---|---|---|
| System | **FS-003** | Screen Time | Screen Time |
| Opens | Timed package access evaluation | Extra **minutes** | Past daily **cap** only |
| Permanent Block | **Does not delete or rewrite** underlying Permanent Block (APP-SF-16) | Never opens block | Never opens block |

**App Access Exception ≠ Temporary Grant ≠ ST Unlimited.**

### 2.2 Lifecycle

```
REQUEST (child)
  → PENDING
  → APPROVE | DENY (Primary + Partner + Full · APP-OD-07)
  → ACTIVE (timed evaluation override)
  → EXPIRE | REVOKE
  → Underlying Permanent Block / baseline resumed (policy row unchanged by exception)
```

| Rule | Law |
|---|---|
| Must be **timed** | No silent permanent reopen via exception |
| Must not mutate ST wallets / Unlimited / Limits | APP-OD-12 |
| Must not mutate WF lists | APP-SF-08 |
| Must not deny SOS / Required Chat / Quran | APP-SF-04 |
| Durations | **T-APP-06** — no invented numbers |

### 2.3 Authority

Decide: **Primary + Partner + Full** (APP-OD-07).  
Child may **request** only (APP-OD-17).

---

## 3. Per-app Lock Now (APP-OD-13)

| Property | Law |
|---|---|
| Nature | Temporary **deny** overlay |
| Distinct from | Permanent Block · Instant Device Lock |
| Does not | Rewrite Permanent Block policy |
| Configure class | Primary + Full (policy configure) |
| Duration | **T-APP-06** |

---

## 4. Restore Baseline (APP-OD-19)

Clears:

- Child overrides (back toward family baseline)  
- Temporary overlays (App Access Exceptions, Lock Now, applicable pending holds)

Does **not**:

- Erase / reopen Permanent Block unless **Primary** acts under APP-OD-04  

Must be audited.

---

## 5. Explicit non-adoptions

| Non-adoption |
|---|
| Mock FAT-035 as final UX law |
| CHD-020 time request as app unlock |
| Temporary Grant as App Access Exception |
| Exception approve → permanent unblock |
| Silent family-wide install approval |
