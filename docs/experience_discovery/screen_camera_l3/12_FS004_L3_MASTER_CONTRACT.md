# 12 — FS-004 L3 Master Contract

**System:** FS-004 Screen & Camera Control  
**Layer:** L3 UX / Behavioral Design  
**Status:** COMPLETE (documentation)  
**Implementation:** NOT AUTHORIZED  

**Authority chain:** Policy Register → FS-004 L2 (`screen_camera_l2/`) → this L3 package → (future) ScreenBuild  
**Evidence:** Repository Stage-1 code is **evidence only**, not target law.

---

## Package index

| # | File | Role |
|---|---|---|
| 01 | [01_FS004_L3_IA.md](01_FS004_L3_IA.md) | Information architecture / screen IDs |
| 02 | [02_FS004_L3_ROLE_MATRIX.md](02_FS004_L3_ROLE_MATRIX.md) | Role × action |
| 03 | [03_FS004_L3_STATE_MATRIX.md](03_FS004_L3_STATE_MATRIX.md) | Policy / honesty / delivery states |
| 04 | [04_FS004_L3_FLOW_CATALOG.md](04_FS004_L3_FLOW_CATALOG.md) | Major flows F01–F24 |
| 05 | [05_FS004_L3_PARENT_WIREFRAMES.md](05_FS004_L3_PARENT_WIREFRAMES.md) | Parent surfaces |
| 06 | [06_FS004_L3_CHILD_WIREFRAMES.md](06_FS004_L3_CHILD_WIREFRAMES.md) | Child transparency + status |
| 07 | [07_FS004_L3_CAMERA_CONTROL_FLOWS.md](07_FS004_L3_CAMERA_CONTROL_FLOWS.md) | OS camera + protected paths |
| 08 | [08_FS004_L3_CAPTURE_MONITORING_FLOWS.md](08_FS004_L3_CAPTURE_MONITORING_FLOWS.md) | P-7 monitoring UX |
| 09 | [09_FS004_L3_ENFORCEMENT_HONESTY_UX.md](09_FS004_L3_ENFORCEMENT_HONESTY_UX.md) | Honesty states |
| 10 | [10_FS004_L3_CROSS_SYSTEM_UX.md](10_FS004_L3_CROSS_SYSTEM_UX.md) | Boundaries + five-way separation |
| 11 | [11_FS004_L3_COVERAGE_AND_CLOSURE.md](11_FS004_L3_COVERAGE_AND_CLOSURE.md) | SC-OD + law cross-check |
| 12 | This master | Gate + invariants |

**Upstream L2:** `docs/experience_discovery/screen_camera_l2/` (01–11), especially SC-OD freezes and master contract.

---

## Non-negotiable L3 invariants

1. **FS-004 owns Prevent + Monitor + Protect.**  
2. **Five-way separation** of package deny / OS camera / prevention / monitoring / protected-surface — never one generic “camera blocked.”  
3. **Monitoring** is explicit, scoped, child-transparent; no silent full-device surveillance; no fake observations.  
4. **Microphone and SOS audio are OUT** of FS-004.  
5. **Protected/exception** paths never silently erase underlying policy.  
6. **Family baseline + child override; override wins.**  
7. **Primary + Full configure; Primary + Partner + Full decide** exception/monitoring-related tickets; **Observer view-only; Child no configure.**  
8. **Modes** own scheduling; may tighten only; cannot silently permanently weaken FS-004.  
9. **Screen Time / Web Filter / FS-003 / SOS Final** keep their ownership; deep-link, do not duplicate stores.  
10. **Enforcement claims** require intent + ack + capability `enforced`.  
11. **iOS** uses honesty — no fake Android parity.  
12. **Offline child** = last-acked; **multi-device** = child policy + per-device plane/ack.  
13. **Audit** append-only; **AI** never mutates without authorized approval.  
14. **Smart Alerts / FAT-065** = entry/notify only — not a second policy store.  
15. **T-SC-*** and platform APIs remain open — L3 consumes honesty states only.

---

## Screen ID convention (L3)

| Prefix | Meaning |
|---|---|
| `SC-P-*` | Parent Screen & Camera surfaces |
| `SC-C-*` | Child surfaces |

Exact registry merge into `screens.csv` is a future ScreenBuild task — IDs here are L3 behavioral addresses.

---

## Gate lines

```
FS-004 DISCOVERY: COMPLETE
FS-004 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-004 L3: COMPLETE
IMPLEMENTATION: NOT AUTHORIZED
```

---

## Next (not authorized here)

ScreenBuild / implementation may proceed only after explicit owner authorization.  
Open T-SC items must be resolved under technical design authority without inventing product law that contradicts this L3.
