# 04 — FS-003 Enforcement Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · APP-OD-14 · APP-SF-09/10 · **T-APP-02/03 OPEN**  
**Non-authority:** Platform-gates docs naming DO/Accessibility as if shipped  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Product vs platform (critical)

| Layer | Content |
|---|---|
| **Product law (FROZEN)** | **Hybrid verified enforcement plane** (APP-OD-14). Honesty states mandatory. |
| **Platform feasibility** | Which APIs can hide, block, intercept, or meter — **T-APP-02/03** after verification |

**Do not** freeze Device Owner, Accessibility, VPN, UsageStats, PackageManager hide, or lock-task as *the* product mechanism. Mechanisms remain technical verification items.

Discovery CURRENT proved no OS enforcement today — that is evidence, not target denial of hybrid law.

---

## 2. Availability / honesty states (normative — FROZEN)

| State | Meaning | Parent claim allowed? |
|---|---|---|
| `enforced` | Last-acked policy applied **and** verified plane actively enforcing | Yes |
| `degraded` | Partial enforcement; residual bypass known | Yes — with degradation disclosure |
| `pending_policy` | Saved > acked; or applying | Honesty: pending delivery |
| `unavailable` | Plane temporarily down | No false “protected” |
| `unsupported` | Platform/enrollment cannot support required plane | No false “protected” |
| `unknown` | Cannot determine | No false “protected” |
| `disabled_by_permission` | Required permission denied | Honesty + remediation |

**APP-SF-10:** Never claim blocking success in `unsupported` / `unknown` / `unavailable`.

---

## 3. Enforcement alternatives (analysis only — not selected)

| Mechanism | Notes | Status |
|---|---|---|
| Device Owner | Strong potential; enrollment cost | **T-APP-02** |
| Profile Owner | Profile-scoped | **T-APP-02** |
| Accessibility | Intercept possible; Play policy risk | **T-APP-02/03** |
| Usage Access | Metering / foreground — not hard block alone | **T-APP-01/02** |
| PackageManager | Inventory | **T-APP-01** |
| Lock-task / kiosk | Narrow — not general App Control | Lock system / not selected here |
| Hybrid verified plane | Product law APP-OD-14 | **FROZEN product**; impl TBD |

---

## 4. Product requirements (regardless of mechanism)

1. Deny launch/use of **permanently blocked** packages when plane = `enforced` (unless active App Access Exception overlay).  
2. Hold **unknown** packages **deny-until-approved** when no class default (APP-OD-08).  
3. Honor **timed App Access Exceptions** and **Lock Now** overlays.  
4. **SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control.**  
5. Survive reboot / process death via last-acked policy (**T-APP-09**).  
6. Report capability honesty continuously.  
7. Exception overlay must **not** rewrite Permanent Block policy store.

---

## 5. Relation to Anti-tamper (APP-OD-15)

Anti-tamper is a **separate subsystem**.  
FS-003 **consumes** capability/integrity facts.  
FS-003 does **not** own uninstall / management-removal resistance.
