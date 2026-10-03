# 07 — FS-004 Events, Audit, Notifications Discovery

**Mode:** Evidence only.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Documented intent (P-7)

On detection (prototype/Register): save snapshot · report to father · child transparency card.  

**No** canonical event catalog implemented for screenshot/camera parental control.

---

## 2. Current event/audit evidence

| Area | Finding | Class |
|---|---|---|
| Smart Alerts screenshot toggle | UI state change; rich audit pipeline **not verified** as capture events | **MOCK** |
| FAT-034 block camera slug | App rule persist; FS-003 notes mutations largely unaudited historically | **PARTIAL/MOCK** |
| Domain 1 ambient | Documented session model — **no** Flutter events | **DOCUMENTED ONLY** |
| SOS | Explicit: **no** audio capture/broadcast events (SOS-final) | **FROZEN adjacent** |
| FS-002/003 audit patterns | Deny + unlock / app_rule.* — **reusable patterns**, not FS-004 | Adjacent |

---

## 3. Notifications

| Type | Status |
|---|---|
| “Screenshot captured / app opened under watch” | **MISSING** impl |
| “Camera blocked on device” ack | **MISSING** |
| Plane degraded for capture agent | **MISSING** |
| QR/Studio permission repair | Local UX only (A) |

Delivery channel would be global Notifications later — **T-SC** / not invented.

---

## 4. Surveillance boundary (discovery note)

P-7 is **monitoring with transparency**, not silent surveillance (Register).  
Full open-app timeline was **rejected as default** in FS-003 (APP-OD-16).  
FS-004 L2 must decide capture-event depth (**Q-SC-01/03**) without assuming full screen streaming.

---

## 5. Gap

| Need | Status |
|---|---|
| Canonical FS-004 events | **MISSING** |
| Append-only audit for configure/monitor | **MISSING** |
| Child-visible monitoring state for screenshot tools | **MISSING** / **PARTIAL** vs P-7 |
