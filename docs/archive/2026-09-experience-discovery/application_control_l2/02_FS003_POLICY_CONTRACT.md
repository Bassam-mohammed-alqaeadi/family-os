# 02 — FS-003 Policy Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-01…20 · APP-SF-01…18  
**Authority:** [01_FS003_L2_OWNER_DECISIONS.md](01_FS003_L2_OWNER_DECISIONS.md)  
**Non-authority:** Stage-1 FAT-034/035 implementation  

```
FS-003 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
```

---

## 1. Mission

**FS-003 Application & System Control** answers:

> Which applications (and which system surfaces, where in-scope) may a given child launch / use under family policy — independently of how many Minutes remain, and independently of which URLs a browser may load.

### Purpose

- Govern **application access** (allow / block / exempt / pending / Lock Now / exception overlays).  
- Govern **new & unrecognized package** decisions (deny-until-approved when no class default).  
- Publish **facts** about access state and enforcement capability for Policy Kernel.  
- Intersect honestly with Web Filter, Modes, Screen Time, Instant Lock, SOS.

### Explicit non-goals (do not duplicate)

| Concern | Owner system |
|---|---|
| Daily entertainment budgets, Temporary Grant minutes, earned wallets, **Limit / Unlimited / Countable** | **Screen Time** (APP-OD-12 · APP-SF-14) |
| URL / category / Safe Search / host unlock | **FS-002 Web Filtering** |
| Lifestyle / exam / sleep **scheduling overlays** | **FS-005 Modes** (APP-OD-10) |
| Instant device-wide lock | **Lock / Instant Lock** (APP-SF-15) |
| Uninstall / management-removal resistance | **Anti-tamper** (APP-OD-15) |
| SOS lifecycle | **SOS Final** |
| Minutes currency / PolicyEngine.earn | **Minutes economy / Kernel** |

---

## 2. What an “app” is (summary)

See [05_FS003_APP_IDENTITY_CONTRACT.md](05_FS003_APP_IDENTITY_CONTRACT.md).

Normative product identity = **platform-stable package/application identifier** — **not** Stage-1 marketing slugs.

---

## 3. Policy document shape (FROZEN · APP-OD-01)

| Layer | Contents |
|---|---|
| **Family baseline** | Default access rules / class defaults / protected classes reference |
| **Child override** | Per-child allow/block/exempt and install decisions — **wins when present** |
| **Overlays** | Timed App Access Exceptions; Mode tighten context; per-app Lock Now; pending-install holds |
| **Version** | Monotonic `policyVersion` (or equivalent) per document |
| **Capability report** | Device-plane honesty — required for claims |

---

## 4. Core actions — ownership (FROZEN)

| Action | Meaning | Owner |
|---|---|---|
| **Allow** | Package may launch subject to ST / Modes / Lock / WF | **FS-003** |
| **Block** (permanent) | Hard deny; Minutes/grants/Unlimited never open (APP-SF-05) | **FS-003** (set: Primary+Full; reopen: Primary only) |
| **App Access Exempt** | Package not denied by App Control access plane; **≠ ST Unlimited** (APP-SF-17); does not bypass Instant Device Lock, SOS rules, or higher layers | **FS-003** |
| **Limit** (per-app daily minutes) | Time budget facet | **Screen Time** (APP-OD-12) |
| **Unlimited** | Bypass P4 cap only | **Screen Time** (APP-OD-12) |
| **Countable** | S-1 entertainment counting | **Screen Time** (APP-OD-12) |
| **Lock Now** (per-app) | Temporary deny overlay ≠ Permanent Block ≠ Instant Device Lock | **FS-003** (APP-OD-13) |
| **App Access Exception** | Timed evaluation override; **does not delete/rewrite Permanent Block** (APP-SF-16); **≠ Temporary Grant ≠ ST Unlimited** (APP-SF-07) | **FS-003** (APP-OD-06) |
| **Restore Baseline** | Clears child overrides + temporary overlays; **does not** reopen Permanent Block without APP-OD-04 | **FS-003** (APP-OD-19) |
| **New-install decide** | Approve/deny unknown package; child-scoped (APP-OD-18) | **FS-003** |

---

## 5. Separation laws (FROZEN)

| Concept | Is | Is not |
|---|---|---|
| **App Access Exception** | Temporary evaluation override for a package | Temporary Grant; ST Unlimited; Permanent Block deletion |
| **Temporary Grant** | Extra entertainment **minutes** (ST, child-wide) | App unlock / package exception |
| **ST Unlimited** | Bypass daily entertainment **cap** only | App Access Exempt; block reopen |
| **App Access Exempt** | Access-plane exempt under App Control | ST Unlimited; Instant Lock bypass; SOS bypass |

---

## 6. Evaluation inputs / outputs

### Domain (FS-003) emits

- Effective access disposition for `(childId, packageId)` under last-acked policy + overlays  
- Pending-install state (deny-until-approved default)  
- Active exception / Lock Now state  
- Enforcement capability state  
- Source contribution for deny (app-control)  

### Policy Kernel

- Merges App Control with ST ladder, Modes context, Instant Lock, WF intersection  
- Must not let Minutes reopen permanent block  
- Must keep **SOS / Required Family Chat / Quran reachable and cannot be denied by App Control**

### Forbidden

- FS-003 mutating Web Filter lists  
- FS-003 minting Minutes / Temporary Grants / Unlimited  
- FS-003 creating a second scheduler  
- Claiming `enforced` without ack + verified plane  

---

## 7. Effective access (conceptual)

```
P0  Protected surfaces — SOS / Required Family Chat / Quran / Family OS
    (remain reachable; cannot be denied by App Control)
P1  Instant Device Lock (Lock system)
P2  Permanent App Block (FS-003)     ← Minutes / Grant / Unlimited never open
P2b Pending unknown — Deny-until-approved (APP-OD-08) when no class default
P2c App Access Exception overlay (timed; does not rewrite P2 policy)
P2d Per-app Lock Now overlay (temporary deny)
P3  Mode / schedule context (FS-005 Modes — tighten-only; cannot reopen P2)
     then stricter ∩ with Web Filter for browser packages (APP-SF-08)
P4+ Screen Time remaining / limits / Unlimited / Countable (ST-owned)
```

| Condition | Outcome |
|---|---|
| App permanently blocked (no active Exception) | DENY — grants/wallets/Unlimited irrelevant |
| App blocked + active App Access Exception | May allow for exception TTL only — **underlying block remains** |
| Time exhausted | DENY entertainment (ST) unless Unlimited/grant/wallet rules — and app not blocked |
| Mode tightened | DENY if not allowed; Modes cannot reopen Permanent Block |
| Temporary Grant active | Adds **minutes** only — does not clear Permanent Block |
| Per-app Lock Now active | Temporary DENY overlay |
| WF allow + App block | DENY (App) |
| WF deny + App allow | DENY (Web) |
| Both deny | DENY (both) |

---

## 8. Protected surfaces (APP-OD-09)

**Cannot be denied by App Control:** SOS · Family OS · Required Family Chat · Quran.  

Other system/OEM packages: explicit protected/controllable matrix (non-core rows = T-APP-08).
