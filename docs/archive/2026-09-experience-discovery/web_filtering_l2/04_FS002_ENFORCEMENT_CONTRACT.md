# 04 — FS-002 Enforcement Contract (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-04 · WF-OD-06 · WF-OD-07 · WF-OD-11 · WF-SF-10

---

## 1. Product enforcement law (WF-OD-04 = Hybrid)

| Layer | Law |
|---|---|
| **Primary** | Verified **on-device enforcement agent / equivalent** |
| **Fallback** | Only **platform-supported mechanisms that are actually verified** |
| **Unverified** | Honest `degraded` / `unsupported` — **never** claim enforced |
| **Product contracts** | Must **not** hard-code VPN, DNS, or Device Owner as *the* final mechanism |

Implementation may later select VPN/DNS/DO/other **after verification** (T-WF-03) without changing this product law.

---

## 2. Availability states (normative)

`enforced` · `degraded` · `pending_policy` · `unsupported` · `disabled_by_permission` · `unknown`

Parent claims must match state. `unknown`/`unsupported` → no “protected” claim.

---

## 3. Safe Search (WF-OD-06)

Mandatory **where the active platform can enforce it**.  
If not enforceable → capability honesty — no universal false success.

---

## 4. Private / incognito (WF-OD-07)

**Platform honesty matrix** (per OS/browser capability).  
No fake “incognito blocked” when unsupported.

---

## 5. Home router (WF-OD-11)

Optional add-on behind **explicit honesty**.  
FAT-078 mock must never imply real router protection.  
**Not** part of core on-device enforcement claim.

---

## 6. Coverage honesty

Declare supported browsers/WebViews/apps per verified plane.  
Residual bypass classes documented without pretending zero bypass.
