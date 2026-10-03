# 01 — Location Owner Decisions (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** **FROZEN** — 2026-09-23 (updated same day: Decision Closure Sprint applied)  
**Authority:** Owner-approved L2 freeze (this package)  
**Evidence baseline:** System #4 Discovery report (conversation) + Policy Register + SOS Final + prototype/schema as **evidence only, not authority**  
**Application code modified:** **NO**

**Entry:** [11_LOCATION_FINAL_MASTER_CONTRACT.md](11_LOCATION_FINAL_MASTER_CONTRACT.md) · [10_DECISION_CLOSURE_REPORT.md](10_DECISION_CLOSURE_REPORT.md) · [12_L2_DECISION_CLOSURE_SPRINT.md](12_L2_DECISION_CLOSURE_SPRINT.md)

**Exception rule:** Only a demonstrated platform constraint that makes a frozen requirement technically impossible may be reported explicitly — never silently redesigned.

**L3 readiness:** **READY FOR L3 COMMISSIONING** (Owner/Product blockers closed; Technical/Platform numbers remain open without blocking L3 IA)

---

## LOC-OD register (frozen)

| ID | Frozen rule |
|---|---|
| **LOC-OD-01** | Normal location **trail retention = 90 days**. Do **not** use 24h as the product baseline. |
| **LOC-OD-02** | Core safety location **existence** is **never** subscription-gated (with SOS and family chat). |
| **LOC-OD-03** | **Live Location** access follows **existing role permissions** (mother location view does not grade). |
| **LOC-OD-04** | **Location History** operational access is MotherLevel-governed; Co-Parent is **not** automatically Primary-equivalent. **Mother Full ≠ Primary**. |
| **LOC-OD-05** | **Export** of location history = **Primary only**. |
| **LOC-OD-06** | **Archive** of location history = **Primary only**. |
| **LOC-OD-07** | Sensitive history access/actions are **auditable** (append-only audit). |
| **LOC-OD-08** | **Silent Location Request** is genuinely silent on the child: no accept/reject UI, no map, no coordinates, no history UI, no interactive response flow. Child device executes authorized request and reports honest result state to parent. |
| **LOC-OD-09** | Global child location UI is **fully silent**. **SOS is the only narrow exception:** during **active SOS**, child may see honest **LOCATION STATUS** only (acquiring / located / stale·last-known / unavailable). No map, coordinates, history, geofence UI, diagnostics, or disable/weaken controls. |
| **LOC-OD-10** | SOS **Break-glass** remains emergency **response override** only. It must **not** become general “Find My Child”. No standalone Find capability from SOS override. Future Emergency Find requires **separate Owner decision**. |
| **LOC-OD-11** | Geometry supports **both Circle and Polygon**. Circle = simple/common authoring. Polygon = first-class. Schema/API/domain must support both **without destructive removal** of circle. |
| **LOC-OD-12** | Child disclosure may be a **non-interactive** safety disclosure where platform/compliance requires it. Must **not** expose location data or provide disable/weaken controls. Operational silence preserved. |
| **LOC-OD-13** | Child **Check-In** belongs to **Child Safety** UX. Acknowledgement only; location evidence attached **silently**. Must not become a child location-map surface. |
| **LOC-OD-14** | **Location Domain** owns factual location, geometry, history, integrity, and evidence. |
| **LOC-OD-15** | **Policy Kernel** owns policy interpretation and resulting action. |
| **LOC-OD-16** | Child local location cache is **bounded**. Cloud becomes **authoritative historical store** after successful sync. |
| **LOC-OD-17** | Offline behavior must be **honest**. **No fake cloud success**. |
| **LOC-OD-18** | Every location event preserves **family + child + device/enrollment** identity context. |
| **LOC-OD-19** | Legacy mock implementation is **evidence only**, never authority. Polygon lock **overrides** legacy circle-only schema/implementation assumptions (additive dual support — no circle removal). |
| **LOC-OD-20** | **Zone assignment (Q-LOC-12 = B):** New geofences require **explicit child multi-select** before save. **No** silent family-all default. |
| **LOC-OD-21** | **L-S7 scope (Q-LOC-18 = A):** Location movement/geofence alerts in v1 are **geofence-event-only**: `ENTER` · `EXIT` · `NO_SHOW`. Do **not** absorb movement/driving alerts. **FAT-077 Road Safety** remains a **separate** product/system boundary. |
| **LOC-OD-22** | **Integrity posture (Q-LOC-07 = C):** Integrity/anti-spoof **signals** may produce a **soft Parent-facing warning** (e.g. low location confidence). **No** child integrity UI. **No** automatic Kernel lock, punishment, or punitive action. **Do not** invent distrust scores/numeric thresholds. **Do not** claim spoof-proof behavior. |
| **LOC-OD-23** | **Live View states (Q-LOC-03 = B):** Parent Live View has two product states — **Standard watch** and **Elevated live**. L3 may represent the state/control family. **Do not** invent refresh intervals, milliseconds, or numeric cadence. Preserve network/battery/location honesty. Actual intervals = Technical/Platform later. |
| **LOC-OD-24** | **Alert kinds v1 (Q-LOC-06 = A):** Parent alert kinds = `ENTER` · `EXIT` · `NO_SHOW`. Numeric dwell/hysteresis/NO_SHOW grace values remain **Technical** — **not invented** in product contracts or UI copy. |
| **LOC-OD-25** | **Sampling-band taxonomy (Q-LOC-04 = A):** Bands = `normal` · `low_battery` · `sos_active`. Numeric sampling intervals remain **Platform/Technical** — **not invented** in product contracts or UI copy. |

---

## Q-LOC closure map

| Q-ID | Status | Maps to |
|---|---|---|
| Q-LOC-01 | **CLOSED** | LOC-OD-01, LOC-OD-02 |
| Q-LOC-02 | **CLOSED** | LOC-OD-03…07 |
| Q-LOC-03 | **CLOSED** (product states) | LOC-OD-23 — intervals remain Technical/Platform |
| Q-LOC-04 | **CLOSED** (taxonomy) | LOC-OD-25 — interval numbers remain Platform/Technical |
| Q-LOC-05 | **OPEN** (Technical) | Cloud density / batching numbers — does **not** block L3 |
| Q-LOC-06 | **CLOSED** (kinds) | LOC-OD-24 — grace/dwell/hysteresis numbers remain Technical |
| Q-LOC-07 | **CLOSED** (posture) | LOC-OD-22 — signal engineering / scores remain Technical |
| Q-LOC-08 | **CLOSED** | LOC-OD-08 |
| Q-LOC-09 | **CLOSED** | LOC-OD-09 |
| Q-LOC-10 | **CLOSED** | LOC-OD-10 |
| Q-LOC-11 | **CLOSED** | LOC-OD-11, LOC-OD-19 |
| Q-LOC-12 | **CLOSED** | LOC-OD-20 |
| Q-LOC-14 | **CLOSED** | LOC-OD-12 |
| Q-LOC-15 | **OPEN** (Platform/Technical) | Map SDK — provider-agnostic seam for L3; pick before GPS sprint |
| Q-LOC-16 | **CLOSED** | LOC-OD-13 |
| Q-LOC-17 | **OPEN** (Technical/Privacy) | Cache size/TTL numbers — does **not** block L3 |
| Q-LOC-18 | **CLOSED** | LOC-OD-21 |

---

## Explicit non-goals (this freeze)

1. Inventing sampling intervals, Live View refresh rates, alert grace minutes, anti-spoof scores, or cache byte/TTL numbers.  
2. Creating a Find-My-Child product from SOS Break-glass.  
3. Child map, history, coordinates, geofence tooling, or location disable controls.  
4. Subscription gating of core location/SOS/chat availability.  
5. Treating Stage-1 mock screens/repos as product law.  
6. Starting L3 screen engineering or application code in this package (commission L3 separately).  
7. Silent family-all zone assignment.  
8. Absorbing FAT-077 Road Safety into Location L-S7.  
9. Automatic Kernel punishment from integrity signals.  
10. Claiming spoof-proof location.

---

## Cross-system deference

| System | Deference |
|---|---|
| **#1 SOS** | Incident lifecycle, Break-glass allowlist, SOS evidence retention classes, location honesty classes during ACTIVE — SOS Final remains authoritative for SOS. This package defines **handoff** only ([08_SOS_LOCATION_HANDOFF_CONTRACT.md](08_SOS_LOCATION_HANDOFF_CONTRACT.md)). `sos_active` sampling band coordinates with SOS ACTIVE without redefining SOS law. |
| **#3 Identity** | Family/child/device/enrollment identity context on every event (LOC-OD-18); explicit child assignment lists (LOC-OD-20). |
| **Policy Register** | Forever-free safety (SOS/location/chat); mother location reassurance does not grade. |
| **Screen Time** | Time expiry / modes must never disable location or SOS. |
| **FAT-077 Road Safety** | Separate system boundary (LOC-OD-21). |
